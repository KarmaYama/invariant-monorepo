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

#[derive(Debug, Clone)]
pub struct EngineConfig {
    pub network: Network,
    pub genesis_version: u16,
}

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
        if let Some(existing) = self.storage.get_identity_by_public_key(&request.public_key).await? {
            return Ok(existing); 
        }

        let metadata = attestation::validate_attestation_chain(
            &request.attestation_chain, 
            &request.public_key,
            Some(&request.nonce)
        )?;

        let identity = Identity {
            id: Uuid::new_v4(),
            public_key: request.public_key,
            continuity_score: 0,
            streak: 0,
            is_genesis_eligible: false,
            username: None,
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

    /// The "Secure Tap" Verification Processor
    pub async fn process_heartbeat(&self, heartbeat: Heartbeat) -> Result<u64, EngineError> {
        let identity = self.storage
            .get_identity(&heartbeat.identity_id)
            .await?
            .ok_or(EngineError::IdentityNotFound(heartbeat.identity_id))?;

        if identity.status == IdentityStatus::Revoked {
             return Err(EngineError::Storage("Identity is Revoked".into()));
        }

        let now = Utc::now();
        
        // 1. NONCE-BOUND CRYPTO CHECK
        // Payload = IDENTITY_ID || NONCE || TIMESTAMP
        // This binds the signature to:
        //  - The specific user (ID)
        //  - The specific session (Nonce)
        //  - The specific time (Timestamp)
        let payload_str = format!("{}|{}|{}", 
            heartbeat.identity_id, 
            hex::encode(&heartbeat.nonce),
            heartbeat.timestamp.to_rfc3339()
        );
        
        crypto::verify_signature(
            &identity.public_key,
            payload_str.as_bytes(),
            &heartbeat.device_signature
        )?;

        // 2. DAILY VERIFICATION CADENCE (23 Hours)
        // 1380 minutes allows for slight drift while enforcing 1 tap/day.
        let time_since_last = now.signed_duration_since(identity.last_heartbeat);
        if identity.continuity_score > 0 && time_since_last.num_minutes() < 1380 {
             return Err(EngineError::RateLimitExceeded);
        }

        // 3. TIMESTAMP SANITY CHECK
        let sig_age = now.signed_duration_since(heartbeat.timestamp);
        if sig_age.num_hours() > 1 {
             return Err(EngineError::StaleHeartbeat("Timestamp too old (>1h)".into()));
        }
        if sig_age.num_minutes() < -5 {
            return Err(EngineError::StaleHeartbeat("Timestamp in the future".into()));
        }

        // 4. Update Score
        let new_score = self.storage.log_heartbeat(&identity, &heartbeat).await?;
        Ok(new_score)
    }

    /// Tier 2 Authorization: Generic Action Validator
    pub async fn validate_action_signature(
        &self, 
        identity_id: Uuid, 
        payload_hash: &[u8],
        nonce: &[u8],
        signature: &[u8]
    ) -> Result<bool, EngineError> {
        let identity = self.storage
            .get_identity(&identity_id)
            .await?
            .ok_or(EngineError::IdentityNotFound(identity_id))?;

        // Construct signed payload: NONCE || PAYLOAD_HASH
        let mut signed_data = Vec::new();
        signed_data.extend_from_slice(nonce);
        signed_data.extend_from_slice(payload_hash);

        match crypto::verify_signature(
            &identity.public_key, 
            &signed_data, 
            signature
        ) {
            Ok(_) => Ok(true),
            Err(_) => Ok(false),
        }
    }
}