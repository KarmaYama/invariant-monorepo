/*
 * Copyright (c) 2025 Invariant Protocol
 * Use of this software is governed by the Business Source License.
 */

use axum::{Extension, Json, http::StatusCode, response::IntoResponse};
use axum::extract::ConnectInfo;
use std::net::SocketAddr;
use invariant_shared::GenesisRequest;
use crate::state::SharedState;
use tracing::{error, info, warn, instrument};
use rand::{Rng, thread_rng};
use redis::AsyncCommands; 

use std::sync::Mutex;
use std::collections::HashMap;
use std::time::{Instant, Duration};
use once_cell::sync::Lazy;

const NONCE_TTL_SECONDS: u64 = 300; 
const CONFIG_KEY_PAUSED: &str = "invariant:config:genesis_paused";

static RATE_LIMITER: Lazy<Mutex<HashMap<String, (u32, Instant)>>> = Lazy::new(|| {
    Mutex::new(HashMap::new())
});

fn check_rate_limit(ip: String) -> bool {
    let mut store = RATE_LIMITER.lock().unwrap();
    
    // FIX 1: Clone 'ip' here so we don't give away ownership yet
    let (count, last_reset) = store.entry(ip.clone()).or_insert((0, Instant::now()));

    if last_reset.elapsed() > Duration::from_secs(3600) {
        *count = 0;
        *last_reset = Instant::now();
    }

    if *count >= 5 {
        // FIX 1 (Result): Now we can still use 'ip' for logging because we only gave a clone to the map
        warn!("Rate Limit Exceeded for IP: {}", ip);
        return false;
    }

    *count += 1;
    true
}

pub async fn get_challenge_handler(
    Extension(state): Extension<SharedState>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
) -> impl IntoResponse {
    
    let ip = addr.ip().to_string();
    if !check_rate_limit(ip) {
        return (StatusCode::TOO_MANY_REQUESTS, Json(serde_json::json!({ "error": "Rate limit exceeded. Try again later." })));
    }

    let mut conn = match state.redis.get_multiplexed_async_connection().await {
        Ok(c) => c,
        Err(e) => {
            error!("CRITICAL: Redis connection failed: {}", e);
            return (StatusCode::INTERNAL_SERVER_ERROR, Json(serde_json::json!({ "error": "Infrastructure Error" })));
        }
    };

    let is_paused: bool = conn.exists(CONFIG_KEY_PAUSED).await.unwrap_or(false);
    if is_paused {
        return (StatusCode::SERVICE_UNAVAILABLE, Json(serde_json::json!({ "error": "Genesis paused." })));
    }

    let (nonce_hex, redis_key) = {
        let mut rng = thread_rng();
        let mut nonce_bytes = [0u8; 32];
        rng.fill(&mut nonce_bytes);
        let hex_val = hex::encode(nonce_bytes);
        
        // FIX 2: Clone 'hex_val' for the first usage so the second usage (format!) can borrow the original
        (hex_val.clone(), format!("nonce:{}", hex_val))
    };

    let result: Result<(), redis::RedisError> = conn.set_ex(&redis_key, "true", NONCE_TTL_SECONDS).await;

    match result {
        Ok(_) => (StatusCode::OK, Json(serde_json::json!({ "nonce": nonce_hex }))),
        Err(_) => (StatusCode::INTERNAL_SERVER_ERROR, Json(serde_json::json!({ "error": "Challenge Generation Failed" })))
    }
}

#[instrument(skip(state, payload))]
pub async fn genesis_handler(
    Extension(state): Extension<SharedState>,
    Json(payload): Json<GenesisRequest>,
) -> impl IntoResponse {
    let mut conn = match state.redis.get_multiplexed_async_connection().await {
        Ok(c) => c,
        Err(e) => {
            error!("Redis connection failed: {}", e);
            return (StatusCode::INTERNAL_SERVER_ERROR, Json(serde_json::json!({ "error": "Infrastructure Error" })));
        }
    };

    let is_paused: bool = conn.exists(CONFIG_KEY_PAUSED).await.unwrap_or(false);
    if is_paused {
        return (StatusCode::SERVICE_UNAVAILABLE, Json(serde_json::json!({ "error": "Genesis paused." })));
    }

    let nonce_hex = hex::encode(&payload.nonce);
    let redis_key = format!("nonce:{}", nonce_hex);

    let val: Option<String> = match conn.get_del(&redis_key).await {
        Ok(v) => v,
        Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, Json(serde_json::json!({ "error": "Nonce Validation Error" })))
    };

    if val.is_none() {
        return (StatusCode::BAD_REQUEST, Json(serde_json::json!({ "error": "Invalid or Expired Challenge." })));
    }

    match state.engine.process_genesis(payload).await {
        Ok(identity) => {
            info!("✅ Genesis Success! Minted: {}", identity.id);
            (StatusCode::CREATED, Json(serde_json::json!({ 
                "id": identity.id,
                "status": "active",
                "tier": "Verified TEE" 
            })))
        },
        Err(e) => {
            error!("❌ Genesis Rejected: {}", e);
            (StatusCode::BAD_REQUEST, Json(serde_json::json!({ "error": format!("Attestation Failed: {}", e) })))
        },
    }
}