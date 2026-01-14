/*
 * Copyright (c) 2026 Invariant Protocol.
 *
 * This source code is licensed under the Business Source License (BSL 1.1) 
 * found in the LICENSE.md file in the root directory of this source tree.
 */

use axum::{Extension, Json, http::StatusCode};
use invariant_shared::Heartbeat;
use crate::state::SharedState;
use crate::error_response::AppError; 
use tracing::{info, warn, instrument, Span}; // Removed 'error'
use rand::{Rng, thread_rng};
use redis::AsyncCommands;

const CHALLENGE_TTL: u64 = 300; // 5 Minutes

/// GET /heartbeat/challenge
/// Returns a fresh nonce for the Daily Tap.
#[utoipa::path(
    get,
    path = "/heartbeat/challenge",
    responses(
        (status = 200, description = "Challenge generated", body = inline(serde_json::Value))
    )
)]
pub async fn get_heartbeat_challenge_handler(
    Extension(state): Extension<SharedState>,
) -> Result<Json<serde_json::Value>, AppError> {
    let mut conn = state.redis.get_multiplexed_async_connection().await
        .map_err(|e| anyhow::anyhow!("Redis Error: {}", e))?;

    let (nonce_hex, redis_key) = {
        let mut rng = thread_rng();
        let mut nonce_bytes = [0u8; 32];
        rng.fill(&mut nonce_bytes);
        let hex_val = hex::encode(nonce_bytes);
        (hex_val.clone(), format!("challenge:{}", hex_val))
    };

    let _: () = conn.set_ex(&redis_key, "true", CHALLENGE_TTL).await
        .map_err(|e| anyhow::anyhow!("Redis Set Error: {}", e))?;

    Ok(Json(serde_json::json!({ "nonce": nonce_hex })))
}

/// POST /heartbeat
/// Verifies the Daily Tap signal.
#[utoipa::path(
    post,
    path = "/heartbeat",
    request_body = Heartbeat,
    responses(
        (status = 200, description = "Tap Verified"),
        (status = 401, description = "Invalid Signature"),
        (status = 429, description = "Daily Limit Reached")
    )
)]
#[instrument(skip(state, payload), fields(identity_id = tracing::field::Empty))] 
pub async fn heartbeat_handler(
    Extension(state): Extension<SharedState>,
    Json(payload): Json<Heartbeat>,
) -> Result<StatusCode, AppError> {
    
    // 1. Log ID safely
    Span::current().record("identity_id", &payload.identity_id.to_string());

    // 2. Validate Nonce (Anti-Replay)
    let mut conn = state.redis.get_multiplexed_async_connection().await
        .map_err(|e| anyhow::anyhow!("Redis Error: {}", e))?;
    
    let nonce_hex = hex::encode(&payload.nonce);
    let redis_key = format!("challenge:{}", nonce_hex);

    // Atomic GET + DEL (Single Use)
    let val: Option<String> = conn.get_del(&redis_key).await
        .map_err(|e| anyhow::anyhow!("Redis Auth Error: {}", e))?;

    if val.is_none() {
        warn!("⚠️ Invalid or Expired Challenge Used");
        return Ok(StatusCode::UNAUTHORIZED);
    }

    // 3. Process Engine Logic
    match state.engine.process_heartbeat(payload).await {
        Ok(new_score) => {
            info!(event = "heartbeat_accepted", score = new_score, "✅ Daily Verification Verified");
            Ok(StatusCode::OK)
        }
        Err(e) => Err(e.into()) // Convert to structured AppError
    }
}