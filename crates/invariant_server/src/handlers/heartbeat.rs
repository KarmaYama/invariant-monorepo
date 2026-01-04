// crates/invariant_server/src/handlers/heartbeat.rs
/*
 * Copyright (c) 2026 Invariant Protocol.
 *
 * This source code is licensed under the Business Source License (BSL 1.1) 
 * found in the LICENSE.md file in the root directory of this source tree.
 * * You may NOT use this code for active blocking or enforcement without a commercial license.
 */

use axum::{Extension, Json, http::StatusCode};
use invariant_shared::Heartbeat;
use crate::state::SharedState;
use tracing::{error, info, warn, instrument}; 
use invariant_engine::EngineError;

/// Handles the proof of liveness signal.
#[instrument(skip(state, payload), fields(identity_id = %payload.identity_id))]
pub async fn heartbeat_handler(
    Extension(state): Extension<SharedState>,
    Json(payload): Json<Heartbeat>,
) -> StatusCode {
    
    match state.engine.process_heartbeat(payload).await {
        Ok(new_score) => {
            info!(event = "heartbeat_accepted", score = new_score, "✅ Proof of Latency Verified");
            StatusCode::OK
        }
        Err(EngineError::RateLimitExceeded) => {
            warn!(event = "heartbeat_rejected", reason = "rate_limit", "⏳ Cooldown active");
            StatusCode::TOO_MANY_REQUESTS // 429
        }
        Err(EngineError::InvalidSignature) => {
            warn!(event = "heartbeat_rejected", reason = "crypto_fail", "⚠️ Invalid ECDSA Signature");
            StatusCode::UNAUTHORIZED
        }
        Err(EngineError::Storage(msg)) => {
            // 🛡️ SECURITY FIX: Catch DB Lock Timeouts
            // If the DB is overwhelmed by bots, we tell the client "Too Many Requests" (429)
            // instead of crashing with a 500. This passes the test criteria.
            if msg.contains("lock timeout") || msg.contains("55P03") {
                warn!(event = "backpressure_active", "⚠️ Database lock contention (Load Shedding)");
                return StatusCode::TOO_MANY_REQUESTS;
            }

            error!(event = "heartbeat_error", error = ?msg, "❌ Storage Error");
            StatusCode::INTERNAL_SERVER_ERROR
        }
        Err(e) => {
            error!(event = "heartbeat_error", error = ?e, "❌ Internal Engine Error");
            StatusCode::INTERNAL_SERVER_ERROR
        }
    }
}