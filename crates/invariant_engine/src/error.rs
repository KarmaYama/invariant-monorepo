// crates/invariant_engine/src/error.rs
/*
 * Copyright (c) 2026 Invariant Protocol.
 * Use of this software is governed by the MIT License.
 */
 
use thiserror::Error;
use uuid::Uuid;

#[derive(Error, Debug)]
pub enum EngineError {
    #[error("Identity {0} not found")]
    IdentityNotFound(Uuid),

    #[error("Identity already exists")]
    AlreadyExists,

    #[error("Cryptographic signature validation failed")]
    InvalidSignature,

    #[error("Hardware Attestation failed: {0}")]
    InvalidAttestation(String),

    #[error("Verification rejected: Timestamp {0} is too old")]
    StaleHeartbeat(String),

    #[error("Rate Limit: Verification is allowed once every 24 hours.")]
    RateLimitExceeded, 

    #[error("Storage failure: {0}")]
    Storage(String),

    // 🛡️ NEW SECURITY ERRORS
    #[error("Security Alert: Replay Attack Detected (Nonce used twice).")]
    ReplayDetected,

    #[error("Trust Decay: Hardware attestation is stale. Please re-attest.")]
    AttestationRequired,
}