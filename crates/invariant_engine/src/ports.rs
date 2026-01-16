// crates/invariant_engine/src/ports.rs
/*
 * Copyright (c) 2026 Invariant Protocol.
 *
 * This source code is licensed under the Business Source License (BSL 1.1) 
 * found in the LICENSE.md file in the root directory of this source tree.
 */

use async_trait::async_trait;
use uuid::Uuid;
use invariant_shared::{Identity, Heartbeat};
use crate::error::EngineError;

#[async_trait]
pub trait IdentityStorage: Send + Sync {
    async fn get_identity(&self, id: &Uuid) -> Result<Option<Identity>, EngineError>;
    async fn get_identity_by_public_key(&self, public_key: &[u8]) -> Result<Option<Identity>, EngineError>;
    async fn save_identity(&self, identity: &Identity) -> Result<(), EngineError>;
    async fn log_heartbeat(&self, identity: &Identity, heartbeat: &Heartbeat) -> Result<u64, EngineError>;
    
    async fn run_reaper(&self) -> Result<u64, EngineError>;
    async fn set_username(&self, id: &Uuid, username: &str) -> Result<bool, EngineError>;
    async fn get_leaderboard(&self, limit: i64) -> Result<Vec<Identity>, EngineError>;

    async fn update_fcm_token(&self, id: &Uuid, token: &str) -> Result<(), EngineError>;
    async fn get_late_fcm_tokens(&self, minutes_since_heartbeat: i64) -> Result<Vec<String>, EngineError>;
}

/// 🛡️ NEW: Interface for Atomic Nonce Management (Redis SETNX)
#[async_trait]
pub trait NonceStorage: Send + Sync {
    /// Atomically checks if a nonce exists and marks it as used.
    /// Returns:
    /// - Ok(true): Nonce was fresh and is now consumed.
    /// - Ok(false): Nonce was ALREADY used (Replay Attack).
    async fn consume_nonce(&self, nonce: &[u8], ttl_seconds: u64) -> Result<bool, EngineError>;
}