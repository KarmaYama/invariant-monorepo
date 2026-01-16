// crates/invariant_shared/src/identity.rs
/*
 * Copyright (c) 2026 Invariant Protocol.
 * Use of this software is governed by the MIT License.
 */

use serde::{Deserialize, Serialize};
use uuid::Uuid;
use chrono::{DateTime, Utc};
use utoipa::ToSchema;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, ToSchema)]
#[serde(rename_all = "lowercase")]
pub enum IdentityStatus {
    Active,
    Stale,   // ⚠️ NEW: Identity is valid, but hardware trust has decayed.
    Dormant,
    Revoked,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, ToSchema)]
#[serde(rename_all = "lowercase")]
pub enum Network {
    Testnet,
    Mainnet,
    Dev,
}

impl ToString for Network {
    fn to_string(&self) -> String {
        match self {
            Network::Testnet => "testnet".into(),
            Network::Mainnet => "mainnet".into(),
            Network::Dev => "dev".into(),
        }
    }
}

/// The core invariant representing a persistent entity.
#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct Identity {
    pub id: Uuid,
    pub public_key: Vec<u8>,
    pub continuity_score: u64,
    
    #[serde(default)] 
    pub streak: u64,

    pub username: Option<String>,

    #[serde(default)]
    pub is_genesis_eligible: bool,

    pub fcm_token: Option<String>,

    pub created_at: DateTime<Utc>,
    
    /// The last time a valid Heartbeat signature was received.
    pub last_heartbeat: DateTime<Utc>,
    
    /// 🛡️ NEW: The last time we verified the HARDWARE CHAIN integrity.
    /// This decays over time (e.g. 7 days).
    pub last_attestation: DateTime<Utc>,

    pub status: IdentityStatus,

    pub hardware_brand: Option<String>,
    pub hardware_device: Option<String>,
    pub hardware_product: Option<String>,

    pub genesis_version: u16,
    pub network: Network,
}