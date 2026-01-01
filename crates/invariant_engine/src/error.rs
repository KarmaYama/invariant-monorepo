/*
 * Copyright (c) 2025 Invariant Protocol
 * Use of this software is governed by the Business Source License.
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

    #[error("Heartbeat rejected: Timestamp {0} is too old")]
    StaleHeartbeat(String),

    #[error("Rate Limit: You are mining too fast. Wait 4 hours.")]
    RateLimitExceeded, // <--- NEW

    #[error("Storage failure: {0}")]
    Storage(String),
}