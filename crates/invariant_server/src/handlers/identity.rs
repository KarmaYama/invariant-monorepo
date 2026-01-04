/*
 * Copyright (c) 2026 Invariant Protocol.
 *
 * This source code is licensed under the Business Source License (BSL 1.1) 
 * found in the LICENSE.md file in the root directory of this source tree.
 * * You may NOT use this code for active blocking or enforcement without a commercial license.
 */

use axum::{Extension, Json, http::StatusCode, response::IntoResponse};
use serde::Deserialize;
use uuid::Uuid;
use crate::state::SharedState;
use invariant_engine::IdentityStorage;

#[derive(Deserialize)]
pub struct ClaimUsernameRequest {
    pub identity_id: Uuid,
    pub username: String,
}

/// POST /identity/claim_username
pub async fn claim_username_handler(
    Extension(state): Extension<SharedState>,
    Json(payload): Json<ClaimUsernameRequest>,
) -> StatusCode {
    if payload.username.len() < 3 || payload.username.len() > 15 {
        return StatusCode::BAD_REQUEST;
    }
    
    if !payload.username.chars().all(|c| c.is_alphanumeric() || c == '_') {
        return StatusCode::BAD_REQUEST;
    }

    match state.engine.get_storage().set_username(&payload.identity_id, &payload.username).await {
         Ok(true) => StatusCode::OK,
         Ok(false) => StatusCode::CONFLICT,
         Err(_) => StatusCode::INTERNAL_SERVER_ERROR,
    }
}

/// GET /leaderboard
/// FIXED: Ensured both match arms return a compatible Axum Response type
pub async fn get_leaderboard_handler(
    Extension(state): Extension<SharedState>,
) -> impl IntoResponse {
    match state.engine.get_storage().get_leaderboard(50).await {
        Ok(identities) => {
            let response: Vec<serde_json::Value> = identities.into_iter().enumerate().map(|(index, id)| {
                serde_json::json!({
                    "rank": index + 1,
                    "handle": id.username.unwrap_or_else(|| "ANONYMOUS".to_string()),
                    "score": id.continuity_score,
                    "id": id.id,
                    "tier": if id.hardware_device.as_deref().unwrap_or("").contains("strongbox") { "TITANIUM" } else { "STEEL" }
                })
            }).collect();
            
            (StatusCode::OK, Json(response)).into_response()
        },
        Err(e) => {
            tracing::error!("Leaderboard fetch failed: {:?}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR, 
                Json(serde_json::json!({"error": "Failed to fetch leaderboard"}))
            ).into_response()
        }
    }
}