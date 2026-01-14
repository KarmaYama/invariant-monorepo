/*
 * Copyright (c) 2026 Invariant Protocol.
 *
 * This source code is licensed under the Business Source License (BSL 1.1) 
 * found in the LICENSE.md file in the root directory of this source tree.
 * * You may NOT use this code for active blocking or enforcement without a commercial license.
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
}