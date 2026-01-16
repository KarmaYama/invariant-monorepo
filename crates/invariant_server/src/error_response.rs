// crates/invariant_server/src/error_response.rs
/*
 * Copyright (c) 2026 Invariant Protocol.
 *
 * This source code is licensed under the Business Source License (BSL 1.1) 
 * found in the LICENSE.md file in the root directory of this source tree.
 */

use axum::{http::StatusCode, response::{IntoResponse, Response}, Json};
use serde_json::json;
use invariant_engine::EngineError;

/// A wrapper around EngineError that implements IntoResponse.
pub struct AppError(pub anyhow::Error);

impl From<EngineError> for AppError {
    fn from(inner: EngineError) -> Self { AppError(inner.into()) }
}

impl From<anyhow::Error> for AppError {
    fn from(inner: anyhow::Error) -> Self { AppError(inner) }
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, error_code, message) = match self.0.downcast_ref::<EngineError>() {
            Some(EngineError::IdentityNotFound(_)) => (StatusCode::NOT_FOUND, "IDENTITY_NOT_FOUND", self.0.to_string()),
            Some(EngineError::AlreadyExists) => (StatusCode::CONFLICT, "IDENTITY_EXISTS", self.0.to_string()),
            Some(EngineError::InvalidSignature) => (StatusCode::UNAUTHORIZED, "INVALID_SIGNATURE", "Cryptographic proof failed.".to_string()),
            Some(EngineError::RateLimitExceeded) => (StatusCode::TOO_MANY_REQUESTS, "RATE_LIMIT", "Daily verification limit reached (23h).".to_string()),
            Some(EngineError::StaleHeartbeat(msg)) => (StatusCode::BAD_REQUEST, "STALE_TIMESTAMP", msg.clone()),
            Some(EngineError::InvalidAttestation(msg)) => (StatusCode::BAD_REQUEST, "ATTESTATION_FAILED", msg.clone()),
            Some(EngineError::Storage(_)) => (StatusCode::INTERNAL_SERVER_ERROR, "INTERNAL_ERROR", "Storage unavailable.".to_string()),
            
            // 🛡️ NEW SECURITY ERRORS - Fixed .to_string() calls
            Some(EngineError::ReplayDetected) => (
                StatusCode::CONFLICT, 
                "REPLAY_DETECTED", 
                "Security Alert: This nonce has already been used.".to_string()
            ),
            Some(EngineError::AttestationRequired) => (
                StatusCode::from_u16(426).unwrap(), // 426 Upgrade Required
                "ATTESTATION_REQUIRED", 
                "Trust decayed. Please perform background re-attestation.".to_string()
            ),
            
            None => (StatusCode::INTERNAL_SERVER_ERROR, "UNKNOWN_ERROR", "An unexpected error occurred.".to_string()),
        };

        let body = Json(json!({
            "error": {
                "code": error_code,
                "message": message,
            }
        }));

        (status, body).into_response()
    }
}