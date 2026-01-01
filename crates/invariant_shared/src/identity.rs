// crates/invariant_shared/src/identity.rs
/*
 * Copyright (c) 2025 Invariant Protocol
 * Use of this software is governed by the MIT License.
 */

use serde::{Deserialize, Serialize};
use uuid::Uuid;
use chrono::{DateTime, Utc};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "lowercase")] // Ensures JSON uses "active", "dormant", "revoked"
pub enum IdentityStatus {
    Active,
    Dormant,
    Revoked,
}

/// Defines the operating environment.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
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
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Identity {
    pub id: Uuid,
    pub public_key: Vec<u8>,
    pub continuity_score: u64,
    
    /// The Consistency Streak.
    #[serde(default)] 
    pub streak: u64,

    // 🚀 NEW: Social Layer (Added in Phase 1 Hardening)
    pub username: Option<String>,

    // 🚀 NEW: Gamification Flag (True if streak > 14 days)
    #[serde(default)]
    pub is_genesis_eligible: bool,

    pub created_at: DateTime<Utc>,
    pub last_heartbeat: DateTime<Utc>,
    pub status: IdentityStatus,

    // --- Hardware Provenance ---
    // Note: On the backend, 'hardware_device' will now contain the HASH, not the raw ID.
    pub hardware_brand: Option<String>,
    pub hardware_device: Option<String>,
    pub hardware_product: Option<String>,

    // --- Operational Guardrails ---
    pub genesis_version: u16,
    pub network: Network,
}