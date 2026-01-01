/*
 * Copyright (c) 2025 Invariant Protocol
 * Use of this software is governed by the MIT License.
 */

use serde::{Deserialize, Serialize};

/// The initial payload to create a new Identity.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GenesisRequest {
    /// The P-256 Public Key generated in StrongBox.
    pub public_key: Vec<u8>,

    /// The Android KeyStore Attestation Certificate Chain.
    /// Used to prove the key is hardware-backed.
    pub attestation_chain: Vec<Vec<u8>>,

    /// The cryptographic nonce (challenge) issued by the server.
    /// The device MUST have included this in the attestation extension.
    /// If this does not match the attestation's internal challenge, Genesis fails.
    pub nonce: Vec<u8>,
}