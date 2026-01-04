/*
 * Copyright (c) 2026 Invariant Protocol.
 *
 * This source code is licensed under the Business Source License (BSL 1.1) 
 * found in the LICENSE.md file in the root directory of this source tree.
 * * You may NOT use this code for active blocking or enforcement without a commercial license.
 */

use axum::{Router, routing::{get, post}, extract::Path, http::StatusCode, Extension, Json};
use crate::state::SharedState;
use uuid::Uuid;
use invariant_engine::IdentityStorage;
use chrono::{Duration};
use tower_http::cors::{CorsLayer, Any}; 

pub mod genesis;
pub mod heartbeat;
pub mod identity; 

/// Checks if an Identity ID exists and returns its full status/score.
/// GET /identity/:id
async fn check_identity_handler(
    Path(id): Path<Uuid>,
    Extension(state): Extension<SharedState>,
) -> impl axum::response::IntoResponse {
    match state.engine.get_storage().get_identity(&id).await {
        Ok(Some(identity)) => {
            // Calculate next available mining time (235 min cooldown)
            let next_available = identity.last_heartbeat + Duration::minutes(235);
            
            (
                StatusCode::OK,
                Json(serde_json::json!({
                    "id": identity.id,
                    "score": identity.continuity_score,
                    "streak": identity.streak,
                    "status": format!("{:?}", identity.status).to_uppercase(),
                    "tier": identity.hardware_device.as_deref().unwrap_or("Hardware TEE"),
                    "username": identity.username, 
                    "is_genesis_eligible": identity.is_genesis_eligible,
                    "next_available": next_available.to_rfc3339()
                }))
            )
        },
        _ => (
            StatusCode::NOT_FOUND, 
            Json(serde_json::json!({ "error": "Identity not found" }))
        ),
    }
}

pub fn app_router(state: SharedState) -> Router {
    // CORS: Allow everything for the public API
    let cors = CorsLayer::new()
        .allow_origin(Any)     
        .allow_methods(Any)    
        .allow_headers(Any);   

    Router::new()
        .route("/health", get(|| async { "Invariant Node Online" }))
        // STATEFUL (For App)
        .route("/genesis", post(genesis::genesis_handler))
        // STATELESS (For SDK/B2B)
        .route("/verify", post(genesis::verify_stateless_handler)) // <--- ADDED THIS
        .route("/heartbeat", post(heartbeat::heartbeat_handler))
        .route("/identity/:id", get(check_identity_handler))
        .route("/identity/claim_username", post(identity::claim_username_handler))
        .route("/leaderboard", get(identity::get_leaderboard_handler))
        .route("/genesis/challenge", get(genesis::get_challenge_handler))
        .layer(cors)
        .layer(axum::Extension(state))
}