// crates/invariant_engine/src/core.rs
/*
 * Copyright (c) 2026 Invariant Protocol.
 *
 * This source code is licensed under the Business Source License (BSL 1.1) 
 * found in the LICENSE.md file in the root directory of this source tree.
 */

use invariant_shared::{Heartbeat, IdentityStatus, GenesisRequest, Identity, Network};
use crate::ports::IdentityStorage;
use crate::error::EngineError;
use crate::crypto;      
use crate::attestation; 
use chrono::Utc;
use uuid::Uuid;

/// Configuration injected at startup.
#[derive(Debug, Clone)]
pub struct EngineConfig {
    pub network: Network,
    pub genesis_version: u16,
}

/// The central logic controller for the Invariant Protocol.
pub struct InvariantEngine<S: IdentityStorage> {
    storage: S,
    config: EngineConfig, 
}

impl<S: IdentityStorage> InvariantEngine<S> {
    pub fn new(storage: S, config: EngineConfig) -> Self { 
        Self { storage, config } 
    }
    
    pub fn get_storage(&self) -> &S { &self.storage }

    pub async fn check_identity(&self, id: Uuid) -> Result<bool, EngineError> {
        let identity = self.storage.get_identity(&id).await?;
        Ok(identity.is_some())
    }

    pub async fn process_genesis(&self, request: GenesisRequest) -> Result<Identity, EngineError> {
        // 1. Sybil Resistance
        if let Some(existing) = self.storage.get_identity_by_public_key(&request.public_key).await? {
            return Ok(existing); 
        }

        // 2. STRICT BINDING & METADATA EXTRACTION
        let metadata = attestation::validate_attestation_chain(
            &request.attestation_chain, 
            &request.public_key,
            Some(&request.nonce)
        )?;

        // 3. MINT IDENTITY
        let identity = Identity {
            id: Uuid::new_v4(),
            public_key: request.public_key,
            continuity_score: 0,
            streak: 0,
            is_genesis_eligible: false,
            username: None,
            // 🚀 FIX: Initialize as None. Client sends this via /identity/push_token later.
            fcm_token: None, 
            created_at: Utc::now(),
            last_heartbeat: Utc::now(),
            status: IdentityStatus::Active,
            hardware_brand: metadata.brand,
            hardware_device: metadata.device,
            hardware_product: metadata.product,
            genesis_version: self.config.genesis_version,
            network: self.config.network.clone(),
        };

        self.storage.save_identity(&identity).await?;
        Ok(identity)
    }

    /// The "Forgiving" Heartbeat Processor
    /// Accepts signals within a 25-hour rolling window.
    pub async fn process_heartbeat(&self, heartbeat: Heartbeat) -> Result<u64, EngineError> {
        let identity = self.storage
            .get_identity(&heartbeat.identity_id)
            .await?
            .ok_or(EngineError::IdentityNotFound(heartbeat.identity_id))?;

        if identity.status == IdentityStatus::Revoked {
             return Err(EngineError::Storage("Identity is Revoked".into()));
        }

        let now = Utc::now();
        
        // 1. CRYPTO FIRST: Verify the signature immediately.
        // Even if the signal is "late" due to bad cell service or Doze mode,
        // a valid TEE signature proves the user *was* there.
        let payload_str = format!("{}|{}", heartbeat.identity_id, heartbeat.timestamp.to_rfc3339());
        crypto::verify_signature(
            &identity.public_key,
            payload_str.as_bytes(),
            &heartbeat.device_signature
        )?;

        // 2. RATE LIMIT (Anti-Battery Drain)
        // We only allow one successful heartbeat every 55 minutes.
        // This prevents a bugged client from mining 100 times an hour.
        let time_since_last = now.signed_duration_since(identity.last_heartbeat);
        if identity.continuity_score > 0 && time_since_last.num_minutes() < 55 {
             return Err(EngineError::RateLimitExceeded);
        }

        // 3. THE GRACE BUFFER (The "25-Hour Day")
        // We accept timestamps generated up to 28 hours ago.
        // This handles cases where a phone generates a signal but has no internet
        // for a full day (e.g. long flight, hiking).
        let sig_age = now.signed_duration_since(heartbeat.timestamp);
        if sig_age.num_hours() > 28 {
             return Err(EngineError::StaleHeartbeat("Signature too old (>28h)".into()));
        }

        // 4. FUTURE PROTECTION
        // Reject signatures from the future (clock skew > 5 mins)
        if sig_age.num_minutes() < -5 {
            return Err(EngineError::StaleHeartbeat("Timestamp in the future".into()));
        }

        // 5. Update Score
        let new_score = self.storage.log_heartbeat(&identity, &heartbeat).await?;
        Ok(new_score)
    }
}