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
use sha2::{Sha256, Digest}; 

const NONCE_TTL_SECONDS: u64 = 300; 
const CONFIG_KEY_PAUSED: &str = "invariant:config:genesis_paused";
const MAX_GENESIS_PER_HOUR: i64 = 100;

/// 🛡️ REDIS RATE LIMITER
/// Prevents IP-based flooding of the expensive attestation endpoint.
async fn check_rate_limit(redis: &mut redis::aio::MultiplexedConnection, ip: &str) -> bool {
    let key = format!("rate_limit:genesis:{}", ip);
    
    // Atomic Increment
    let count: i64 = match redis.incr(&key, 1).await {
        Ok(v) => v,
        Err(e) => {
            error!("Rate limiter Redis error: {}", e);
            return true; // Fail open if Redis is down, but log it.
        }
    };

    // Set Expiry window (1 hour)
    if count == 1 {
        let _ = redis.expire::<&str, ()>(&key, 3600).await;
    }

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

    // 1. Check Rate Limit
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

    // 4. Store with TTL
    let _: () = conn.set_ex(&redis_key, "true", NONCE_TTL_SECONDS).await
        .map_err(|e| anyhow::anyhow!("Challenge Generation Failed: {}", e))?;

    Ok(Json(serde_json::json!({ "nonce": nonce_hex })))
}

/// STATEFUL GENESIS (Mobile App)
/// Registers the Identity in the Database.
#[utoipa::path(
    post,
    path = "/genesis",
    request_body = GenesisRequest,
    responses(
        (status = 201, description = "Identity Minted", body = inline(serde_json::Value)),
        (status = 400, description = "Invalid Attestation or Challenge"),
        (status = 409, description = "Concurrent Request Conflict"),
        (status = 503, description = "Genesis Paused")
    )
)]
// 🚀 STRUCTURED LOGGING FIX
// We skip the full 'payload' to prevent JSON parser crashes on large cert chains.
// We explicitly define fields to capture essential metadata instead.
#[instrument(
    skip(state, payload), 
    fields(
        nonce_prefix = tracing::field::Empty, 
        chain_len = tracing::field::Empty, 
        pk_fingerprint = tracing::field::Empty
    )
)]
pub async fn genesis_handler(
    Extension(state): Extension<SharedState>,
    Json(payload): Json<GenesisRequest>,
) -> Result<(StatusCode, Json<serde_json::Value>), AppError> {
    
    // 1. Populate Structured Logs
    let span = tracing::Span::current();
    
    // Log prefix of nonce to correlate with Redis errors (safe to log prefix)
    let nonce_prefix = hex::encode(payload.nonce.get(0..4).unwrap_or(&[]));
    
    // Log SHA256 fingerprint of the user's public key (safe ID)
    let pk_hash = hex::encode(Sha256::digest(&payload.public_key));
    
    span.record("nonce_prefix", &nonce_prefix);
    span.record("chain_len", &payload.attestation_chain.len());
    span.record("pk_fingerprint", &pk_hash);

    let mut conn = state.redis.get_multiplexed_async_connection().await
        .map_err(|e| anyhow::anyhow!("Redis connection failed: {}", e))?;

    // 2. Feature Flag
    let is_paused: bool = conn.exists(CONFIG_KEY_PAUSED).await.unwrap_or(false);
    if is_paused {
        return Err(anyhow::anyhow!("Genesis paused").into());
    }

    // 3. Nonce Validation (Peek)
    let nonce_hex = hex::encode(&payload.nonce);
    let redis_key = format!("nonce:{}", nonce_hex);
    let nonce_exists: bool = conn.exists(&redis_key).await.unwrap_or(false);
    
    if !nonce_exists {
        return Ok((StatusCode::BAD_REQUEST, Json(serde_json::json!({ "error": "Invalid or Expired Challenge." }))));
    }

    // 4. 🔒 DISTRIBUTED LOCK (Anti-Race Condition)
    // We use the computed pk_hash from above
    let lock_key = format!("lock:genesis:{}", pk_hash);

    // Try to acquire lock for 10 seconds. Returns true if acquired.
    let lock_acquired: bool = redis::cmd("SET")
        .arg(&lock_key)
        .arg("1")
        .arg("NX") // Not Exists
        .arg("EX") // Expiry
        .arg(10)   // Seconds
        .query_async(&mut conn)
        .await
        .unwrap_or(false);

    if !lock_acquired {
        warn!("⚠️ Concurrent Genesis Blocked");
        return Ok((StatusCode::CONFLICT, Json(serde_json::json!({ 
            "error": "Request already in progress. Please wait." 
        }))));
    }

    // 5. Consume Nonce (Atomic Delete)
    // We own the lock, so we burn the nonce now.
    let _: () = conn.del(&redis_key).await.unwrap_or(());

    // 6. Engine Processing
    match state.engine.process_genesis(payload).await {
        Ok(identity) => {
            info!("✅ Genesis Success! Minted: {}", identity.id);
            Ok((StatusCode::CREATED, Json(serde_json::json!({ 
                "id": identity.id,
                "status": "active",
                "tier": identity.hardware_device.unwrap_or_else(|| "Verified TEE".into()) 
            }))))
        },
        Err(e) => {
            error!("❌ Genesis Rejected: {}", e);
            Err(e.into())
        },
    }
}

/// STATELESS VERIFICATION (B2B SDK)
/// Verifies hardware but does not create a user account.
#[utoipa::path(
    post,
    path = "/verify",
    request_body = GenesisRequest,
    responses(
        (status = 200, description = "Verification Result", body = inline(serde_json::Value))
    )
)]
// 🚀 APPLY SAME LOGGING FIX HERE
#[instrument(
    skip(state, payload), 
    fields(
        nonce_prefix = tracing::field::Empty, 
        chain_len = tracing::field::Empty, 
        pk_fingerprint = tracing::field::Empty
    )
)]
pub async fn verify_stateless_handler(
    Extension(state): Extension<SharedState>,
    Json(payload): Json<GenesisRequest>,
) -> Result<(StatusCode, Json<serde_json::Value>), AppError> {
    
    // 1. Populate Logs
    let span = tracing::Span::current();
    let nonce_prefix = hex::encode(payload.nonce.get(0..4).unwrap_or(&[]));
    let pk_hash = hex::encode(Sha256::digest(&payload.public_key));
    
    span.record("nonce_prefix", &nonce_prefix);
    span.record("chain_len", &payload.attestation_chain.len());
    span.record("pk_fingerprint", &pk_hash);

    let mut conn = state.redis.get_multiplexed_async_connection().await
        .map_err(|e| anyhow::anyhow!("Infrastructure Error: {}", e))?;

    // 2. Nonce Check (Consume immediately for stateless)
    let nonce_hex = hex::encode(&payload.nonce);
    let redis_key = format!("nonce:{}", nonce_hex);

    let val: Option<String> = conn.get_del(&redis_key).await.unwrap_or(None);
    if val.is_none() {
        return Ok((StatusCode::BAD_REQUEST, Json(serde_json::json!({ 
            "verified": false,
            "error": "Invalid or Expired Challenge" 
        }))));
    }

    // 3. Pure Crypto Verification
    match invariant_engine::validate_attestation_chain(
        &payload.attestation_chain,
        &payload.public_key,
        Some(&payload.nonce)
    ) {
        Ok(metadata) => {
            info!("🔍 Stateless Verification: {} - {}", metadata.trust_tier, metadata.product.as_deref().unwrap_or("Unknown"));
            
            // ✅ Return Full Hardware Metadata (Raw fields allowed to be null)
            Ok((StatusCode::OK, Json(serde_json::json!({
                "verified": true,
                "tier": metadata.trust_tier,
                "brand": metadata.brand,
                "device_model": metadata.device,
                "product": metadata.product,
                "boot_locked": metadata.is_boot_locked,
                "risk_score": 0.0 // 0.0 = Trustworthy
            }))))
        },
        Err(e) => {
            warn!("⚠️ Stateless Verification Failed: {}", e);
            Ok((StatusCode::OK, Json(serde_json::json!({
                "verified": false,
                "tier": "REJECTED",
                "error": e.to_string(),
                "risk_score": 100.0 // 100.0 = Fraud
            }))))
        }
    }
}