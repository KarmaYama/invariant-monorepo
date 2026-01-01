/*
 * Copyright (c) 2025 Invariant Protocol
 * Use of this software is governed by the Business Source License.
 */

use axum::{Extension, Json, http::StatusCode};
use invariant_shared::Heartbeat;
use crate::state::SharedState;
use tracing::{error, debug, warn};
use invariant_engine::EngineError;

/// Handles the proof of liveness signal.
pub async fn heartbeat_handler(
    Extension(state): Extension<SharedState>,
    Json(payload): Json<Heartbeat>,
) -> StatusCode {
    debug!("Received heartbeat from: {}", payload.identity_id);

    match state.engine.process_heartbeat(payload).await {
        Ok(new_score) => {
            debug!("Heartbeat accepted. Score: {}", new_score);
            StatusCode::OK
        }
        Err(EngineError::RateLimitExceeded) => {
            warn!("Heartbeat rejected: Rate Limit Exceeded");
            StatusCode::TOO_MANY_REQUESTS // 429
        }
        Err(e) => {
            error!("Heartbeat rejected: {:?}", e);
            StatusCode::UNAUTHORIZED
        }
    }
}