// crates/invariant_server/src/handlers/mod.rs
/*
 * Copyright (c) 2025 Invariant Protocol
 * Use of this software is governed by the Business Source License.
 */

use axum::{Router, routing::{get, post}, extract::Path, http::StatusCode, Extension, Json};
use crate::state::SharedState;
use uuid::Uuid;
use invariant_engine::IdentityStorage;
use chrono::{Duration};
// [FIX] Import CORS components
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
    // [FIX] Define CORS Layer
    // This allows your Next.js frontend (running on Vercel/Localhost) to talk to this AWS backend.
    let cors = CorsLayer::new()
        .allow_origin(Any)     // Allow requests from anywhere (Public API)
        .allow_methods(Any)    // Allow GET, POST, OPTIONS, etc.
        .allow_headers(Any);   // Allow any headers (Content-Type, etc.)

    Router::new()
        .route("/health", get(|| async { "Invariant Node Online" }))
        .route("/genesis", post(genesis::genesis_handler))
        .route("/heartbeat", post(heartbeat::heartbeat_handler))
        .route("/identity/:id", get(check_identity_handler))
        .route("/identity/claim_username", post(identity::claim_username_handler))
        .route("/leaderboard", get(identity::get_leaderboard_handler))
        .route("/genesis/challenge", get(genesis::get_challenge_handler))
        .layer(cors) // [FIX] Apply the layer here (Order matters: Layer wraps the routes)
        .layer(axum::Extension(state))
}