// crates/invariant_shared/src/reattestation.rs
/*
 * Copyright (c) 2026 Invariant Protocol.
 * Use of this software is governed by the MIT License.
 */

use serde::{Deserialize, Serialize};
use uuid::Uuid;
use utoipa::ToSchema;

/// A request to refresh hardware trust for an existing identity.
/// Used when an Identity status becomes `Stale`.
#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct ReAttestationRequest {
    /// The ID of the identity being refreshed.
    pub id: Uuid,

    /// The P-256 Public Key (must match the existing Identity).
    pub public_key: Vec<u8>,

    /// A FRESH Android KeyStore Attestation Certificate Chain.
    /// Proves the device is still locked, verified, and secure.
    pub attestation_chain: Vec<Vec<u8>>,

    /// The cryptographic nonce (challenge) issued by the server.
    pub nonce: Vec<u8>,
}