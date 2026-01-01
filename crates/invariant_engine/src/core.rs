/*
 * Copyright (c) 2025 Invariant Protocol
 * Use of this software is governed by the Business Source License.
 */

use invariant_shared::{Heartbeat, IdentityStatus, GenesisRequest, Identity, Network};
use crate::ports::IdentityStorage;
use crate::error::EngineError;
use crate::crypto;      
use crate::attestation; 
use chrono::Utc;
use uuid::Uuid;

/// Configuration injected at startup to control Identity Minting rules.
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

        // 3. MINT IDENTITY (With Versioning & Network)
        let identity = Identity {
            id: Uuid::new_v4(),
            public_key: request.public_key,
            continuity_score: 0,
            streak: 0,
            is_genesis_eligible: false,
            username: None,
            created_at: Utc::now(),
            last_heartbeat: Utc::now(),
            status: IdentityStatus::Active,
            hardware_brand: metadata.brand,
            hardware_device: metadata.device,
            hardware_product: metadata.product,
            // Guardrails injected from Config
            genesis_version: self.config.genesis_version,
            network: self.config.network.clone(),
        };

        self.storage.save_identity(&identity).await?;
        Ok(identity)
    }

    pub async fn process_heartbeat(&self, heartbeat: Heartbeat) -> Result<u64, EngineError> {
        let identity = self.storage
            .get_identity(&heartbeat.identity_id)
            .await?
            .ok_or(EngineError::IdentityNotFound(heartbeat.identity_id))?;

        if identity.status == IdentityStatus::Revoked {
             return Err(EngineError::Storage("Identity is Revoked".into()));
        }

        let now = Utc::now();
        let time_since_last = now.signed_duration_since(identity.last_heartbeat);
        if identity.continuity_score > 0 && time_since_last.num_minutes() < 235 {
             return Err(EngineError::RateLimitExceeded);
        }

        let time_diff = now.signed_duration_since(heartbeat.timestamp);
        if time_diff.num_minutes().abs() > 5 {
             return Err(EngineError::StaleHeartbeat(heartbeat.timestamp.to_string()));
        }

        let payload_str = format!("{}|{}", heartbeat.identity_id, heartbeat.timestamp.to_rfc3339());
        
        crypto::verify_signature(
            &identity.public_key,
            payload_str.as_bytes(),
            &heartbeat.device_signature
        )?;

        let new_score = self.storage.log_heartbeat(&identity, &heartbeat).await?;
        Ok(new_score)
    }
}