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
use tracing::{error, info, warn, instrument}; // Changed debug -> info
use invariant_engine::EngineError;

/// Handles the proof of liveness signal.
/// The `#[instrument]` macro ensures every log inside this function
/// automatically includes the identity_id.
#[instrument(skip(state, payload), fields(identity_id = %payload.identity_id))]
pub async fn heartbeat_handler(
    Extension(state): Extension<SharedState>,
    Json(payload): Json<Heartbeat>,
) -> StatusCode {
    // Log the attempt at DEBUG level (so we don't spam INFO if we don't want to)
    // But since we want visibility now, let's keep it clean.

    match state.engine.process_heartbeat(payload).await {
        Ok(new_score) => {
            // PROMOTED TO INFO: Now you will see every successful mine in the logs
            info!(
                event = "heartbeat_accepted",
                score = new_score,
                "✅ Proof of Latency Verified"
            );
            StatusCode::OK
        }
        Err(EngineError::RateLimitExceeded) => {
            // Now distinguishing "Spam" vs "Too Early"
            warn!(
                event = "heartbeat_rejected",
                reason = "rate_limit",
                "⏳ Miner is running too fast (Cooldown active)"
            );
            StatusCode::TOO_MANY_REQUESTS // 429
        }
        Err(EngineError::InvalidSignature) => {
            warn!(
                event = "heartbeat_rejected",
                reason = "crypto_fail",
                "⚠️ Invalid ECDSA Signature"
            );
            StatusCode::UNAUTHORIZED
        }
        Err(e) => {
            // Catch-all for DB errors or weird states
            error!(
                event = "heartbeat_error",
                error = ?e,
                "❌ Internal Engine Error"
            );
            StatusCode::INTERNAL_SERVER_ERROR
        }
    }
}