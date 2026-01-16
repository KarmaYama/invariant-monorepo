// crates/invariant_server/src/handlers/identity.rs
/*
 * Copyright (c) 2026 Invariant Protocol.
 *
 * This source code is licensed under the Business Source License (BSL 1.1) 
 * found in the LICENSE.md file in the root directory of this source tree.
 */

use axum::{Extension, Json, http::StatusCode, response::IntoResponse, extract::Path};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use crate::state::SharedState;
use invariant_engine::IdentityStorage;
use invariant_shared::{ReAttestationRequest, IdentityStatus};
use crate::error_response::AppError;
use chrono::{DateTime, Utc};

#[derive(Deserialize)]
pub struct ClaimUsernameRequest {
    pub identity_id: Uuid,
    pub username: String,
}

#[derive(Deserialize)]
pub struct UpdatePushTokenRequest {
    pub identity_id: Uuid,
    pub fcm_token: String,
}

// --- RE-ATTESTATION (RECOVERY) ---

#[utoipa::path(
    post,
    path = "/identity/reattest",
    request_body = ReAttestationRequest,
    responses(
        (status = 200, description = "Trust Restored"),
        (status = 401, description = "Invalid Key or Proof"),
        (status = 404, description = "Identity Not Found"),
        (status = 426, description = "Upgrade Required")
    )
)]
pub async fn reattest_handler(
    Extension(state): Extension<SharedState>,
    Json(payload): Json<ReAttestationRequest>,
) -> Result<StatusCode, AppError> {
    state.engine.process_reattestation(payload).await?;
    Ok(StatusCode::OK)
}

// --- FULL ENTERPRISE MANIFEST ---

#[derive(Serialize)]
pub struct SystemManifest {
    pub identity_id: Uuid,
    pub status: IdentityStatus,
    
    // 🛡️ RISK & TRUST SIGNALS
    pub trust: TrustProfile,
    
    // 📱 HARDWARE FINGERPRINT
    pub device: DeviceProfile,
    
    // ⏱️ LIFECYCLE & TIMING
    pub lifecycle: LifecycleProfile,
    
    // 🔧 PROTOCOL METADATA
    pub meta: MetaProfile,
}

#[derive(Serialize)]
pub struct TrustProfile {
    pub tier: String,           // TITANIUM vs STEEL
    pub continuity_score: u64,  // Total successful verifications
    pub streak: u64,            // Consecutive daily verifications
    pub trust_decay_days: i64,  // Days since last hardware proof (Risk metric)
}

#[derive(Serialize)]
pub struct DeviceProfile {
    pub brand: Option<String>,
    pub product: Option<String>,
    pub model_hash: Option<String>, // Hashed for privacy, identifiable by partner if they own the salt
    pub hardware_backed: bool,
}

#[derive(Serialize)]
pub struct LifecycleProfile {
    pub created_at: DateTime<Utc>,
    pub last_heartbeat: DateTime<Utc>,
    pub last_attestation: DateTime<Utc>,
    pub next_heartbeat_available: DateTime<Utc>,
}

#[derive(Serialize)]
pub struct MetaProfile {
    pub network: String,
    pub genesis_version: u16,
    pub is_genesis_eligible: bool,
}

/// GET /identity/:id/manifest
/// Returns the FULL technical audit of the Identity.
/// Used by B2B Risk Engines to make decisions (Block/Allow/Limit).
pub async fn get_manifest_handler(
    Path(id): Path<Uuid>,
    Extension(state): Extension<SharedState>,
) -> Result<Json<SystemManifest>, AppError> {
    
    let identity = state.engine.get_storage().get_identity(&id).await?
        .ok_or(invariant_engine::EngineError::IdentityNotFound(id))?;

    // Calculate derived risk metrics
    let now = Utc::now();
    let days_since_attest = now.signed_duration_since(identity.last_attestation).num_days();
    let next_available = identity.last_heartbeat + chrono::Duration::minutes(1380);

    let manifest = SystemManifest {
        identity_id: identity.id,
        status: identity.status.clone(),
        
        trust: TrustProfile {
            tier: if identity.hardware_device.as_deref().unwrap_or("").contains("strongbox") { 
                "TITANIUM (StrongBox)".to_string() 
            } else { 
                "STEEL (TEE)".to_string() 
            },
            continuity_score: identity.continuity_score,
            streak: identity.streak,
            trust_decay_days: days_since_attest, // Critical for Partner Risk Engines
        },
        
        device: DeviceProfile {
            brand: identity.hardware_brand,
            product: identity.hardware_product,
            model_hash: identity.hardware_device, // Mapped to hash in DB layer
            hardware_backed: true, // Invariant: Software keys are rejected at Genesis
        },
        
        lifecycle: LifecycleProfile {
            created_at: identity.created_at,
            last_heartbeat: identity.last_heartbeat,
            last_attestation: identity.last_attestation,
            next_heartbeat_available: next_available,
        },
        
        meta: MetaProfile {
            network: identity.network.to_string(),
            genesis_version: identity.genesis_version,
            is_genesis_eligible: identity.is_genesis_eligible,
        }
    };

    Ok(Json(manifest))
}

// --- EXISTING UTILITY HANDLERS ---

pub async fn claim_username_handler(
    Extension(state): Extension<SharedState>,
    Json(payload): Json<ClaimUsernameRequest>,
) -> StatusCode {
    if payload.username.len() < 3 || payload.username.len() > 15 { return StatusCode::BAD_REQUEST; }
    if !payload.username.chars().all(|c| c.is_alphanumeric() || c == '_') { return StatusCode::BAD_REQUEST; }

    match state.engine.get_storage().set_username(&payload.identity_id, &payload.username).await {
         Ok(true) => StatusCode::OK,
         Ok(false) => StatusCode::CONFLICT,
         Err(_) => StatusCode::INTERNAL_SERVER_ERROR,
    }
}

pub async fn update_push_token_handler(
    Extension(state): Extension<SharedState>,
    Json(payload): Json<UpdatePushTokenRequest>,
) -> StatusCode {
    match state.engine.get_storage().update_fcm_token(&payload.identity_id, &payload.fcm_token).await {
        Ok(_) => StatusCode::OK,
        Err(e) => {
            tracing::error!("Failed to update FCM token: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        }
    }
}

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
            (StatusCode::INTERNAL_SERVER_ERROR, Json(serde_json::json!({"error": "Failed"}))).into_response()
        }
    }
}