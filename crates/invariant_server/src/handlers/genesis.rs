/*
 * Copyright (c) 2026 Invariant Protocol.
 *
 * This source code is licensed under the Business Source License (BSL 1.1) 
 * found in the LICENSE.md file in the root directory of this source tree.
 */

use axum::{Extension, Json, http::StatusCode};
use axum::extract::ConnectInfo;
use std::net::SocketAddr;
use invariant_shared::GenesisRequest;
use crate::state::SharedState;
use crate::error_response::AppError;
use tracing::{error, info, warn, instrument};
use rand::{Rng, thread_rng};
use redis::AsyncCommands; 

const NONCE_TTL_SECONDS: u64 = 300; 
const CONFIG_KEY_PAUSED: &str = "invariant:config:genesis_paused";
const MAX_GENESIS_PER_HOUR: i64 = 100;

/// 🛡️ REDIS RATE LIMITER
/// Uses the "Fixed Window" algorithm with atomic increments.
/// Returns TRUE if the request is allowed, FALSE if blocked.
async fn check_rate_limit(redis: &mut redis::aio::MultiplexedConnection, ip: &str) -> bool {
    let key = format!("rate_limit:genesis:{}", ip);
    
    // 1. Atomic INCR
    let count: i64 = match redis.incr(&key, 1).await {
        Ok(v) => v,
        Err(e) => {
            error!("Rate limiter Redis error: {}", e);
            return true; // Fail open (allow traffic) if Redis breaks
        }
    };

    // 2. Set Expiry on first request (start of window)
    if count == 1 {
        let _ = redis.expire::<&str, ()>(&key, 3600).await;
    }

    // 3. Check Limit
    if count > MAX_GENESIS_PER_HOUR {
        warn!("⛔ Rate Limit Exceeded for IP: {}", ip);
        return false;
    }

    true
}

/// GET /genesis/challenge
/// Returns a 5-minute cryptographic nonce for the TEE to sign.
#[utoipa::path(
    get,
    path = "/genesis/challenge",
    responses(
        (status = 200, description = "Challenge generated", body = inline(serde_json::Value)),
        (status = 429, description = "Rate limit exceeded"),
        (status = 503, description = "Service Unavailable")
    )
)]
pub async fn get_challenge_handler(
    Extension(state): Extension<SharedState>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
) -> Result<Json<serde_json::Value>, AppError> {
    let mut conn = state.redis.get_multiplexed_async_connection().await
        .map_err(|e| anyhow::anyhow!("Redis Error: {}", e))?;

    // 1. Check Rate Limit (Redis)
    let ip = addr.ip().to_string();
    if !check_rate_limit(&mut conn, &ip).await {
        return Err(invariant_engine::EngineError::RateLimitExceeded.into());
    }

    // 2. Feature Flag Check
    let is_paused: bool = conn.exists(CONFIG_KEY_PAUSED).await.unwrap_or(false);
    if is_paused {
        return Err(anyhow::anyhow!("Genesis paused").into());
    }

    // 3. Generate Nonce
    let (nonce_hex, redis_key) = {
        let mut rng = thread_rng();
        let mut nonce_bytes = [0u8; 32];
        rng.fill(&mut nonce_bytes);
        let hex_val = hex::encode(nonce_bytes);
        
        (hex_val.clone(), format!("nonce:{}", hex_val))
    };

    let _: () = conn.set_ex(&redis_key, "true", NONCE_TTL_SECONDS).await
        .map_err(|e| anyhow::anyhow!("Challenge Generation Failed: {}", e))?;

    Ok(Json(serde_json::json!({ "nonce": nonce_hex })))
}

/// STATEFUL GENESIS (For the Mobile App) - Mints ID to DB
#[utoipa::path(
    post,
    path = "/genesis",
    request_body = GenesisRequest,
    responses(
        (status = 201, description = "Identity Minted", body = inline(serde_json::Value)),
        (status = 400, description = "Invalid Attestation or Challenge"),
        (status = 503, description = "Genesis Paused")
    )
)]
// 🛠️ FIX: Removed `ret` from instrument to prevent JSON serialization crash
#[instrument(skip(state, payload))]
pub async fn genesis_handler(
    Extension(state): Extension<SharedState>,
    Json(payload): Json<GenesisRequest>,
) -> Result<(StatusCode, Json<serde_json::Value>), AppError> {
    let mut conn = state.redis.get_multiplexed_async_connection().await
        .map_err(|e| anyhow::anyhow!("Redis connection failed: {}", e))?;

    let is_paused: bool = conn.exists(CONFIG_KEY_PAUSED).await.unwrap_or(false);
    if is_paused {
        return Err(anyhow::anyhow!("Genesis paused").into());
    }

    let nonce_hex = hex::encode(&payload.nonce);
    let redis_key = format!("nonce:{}", nonce_hex);

    // Atomic Get & Delete - Prevents Replay Attacks
    let val: Option<String> = conn.get_del(&redis_key).await
        .map_err(|e| anyhow::anyhow!("Nonce Validation Error: {}", e))?;

    if val.is_none() {
        return Ok((StatusCode::BAD_REQUEST, Json(serde_json::json!({ "error": "Invalid or Expired Challenge." }))));
    }

    match state.engine.process_genesis(payload).await {
        Ok(identity) => {
            info!("✅ Genesis Success! Minted: {}", identity.id);
            Ok((StatusCode::CREATED, Json(serde_json::json!({ 
                "id": identity.id,
                "status": "active",
                "tier": "Verified TEE" 
            }))))
        },
        Err(e) => {
            error!("❌ Genesis Rejected: {}", e);
            Err(e.into())
        },
    }
}

/// STATELESS VERIFICATION (For the SDK/B2B) - NO DB WRITE
/// This is the endpoint Craig's partners will use.
#[utoipa::path(
    post,
    path = "/verify",
    request_body = GenesisRequest,
    responses(
        (status = 200, description = "Verification Result", body = inline(serde_json::Value))
    )
)]
#[instrument(skip(state, payload))]
pub async fn verify_stateless_handler(
    Extension(state): Extension<SharedState>,
    Json(payload): Json<GenesisRequest>,
) -> Result<(StatusCode, Json<serde_json::Value>), AppError> {
    // 1. Redis Connection
    let mut conn = state.redis.get_multiplexed_async_connection().await
        .map_err(|e| anyhow::anyhow!("Infrastructure Error: {}", e))?;

    // 2. Check Nonce (Anti-Replay)
    let nonce_hex = hex::encode(&payload.nonce);
    let redis_key = format!("nonce:{}", nonce_hex);

    let val: Option<String> = conn.get_del(&redis_key).await.unwrap_or(None);
    if val.is_none() {
        return Ok((StatusCode::BAD_REQUEST, Json(serde_json::json!({ 
            "verified": false,
            "error": "Invalid or Expired Challenge" 
        }))));
    }

    // 3. PURE CRYPTO CHECK (Engine without Storage)
    match invariant_engine::validate_attestation_chain(
        &payload.attestation_chain,
        &payload.public_key,
        Some(&payload.nonce)
    ) {
        Ok(metadata) => {
            info!("🔍 Stateless Verification: {} - {}", metadata.trust_tier, metadata.product.as_deref().unwrap_or("Unknown"));
            
            Ok((StatusCode::OK, Json(serde_json::json!({
                "verified": true,
                "tier": metadata.trust_tier,
                "device_model": metadata.device,
                "risk_score": 0.0 // 0.0 = Pure Hardware Trust
            }))))
        },
        Err(e) => {
            warn!("⚠️ Stateless Verification Failed: {}", e);
            Ok((StatusCode::OK, Json(serde_json::json!({
                "verified": false,
                "tier": "REJECTED",
                "error": e.to_string(),
                "risk_score": 100.0 // 100.0 = High Risk / Emulator
            }))))
        }
    }
}