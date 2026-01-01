/*
 * Copyright (c) 2025 Invariant Protocol
 * Use of this software is governed by the Business Source License.
 */

use async_trait::async_trait;
use uuid::Uuid;
use invariant_shared::{Identity, Heartbeat};
use crate::error::EngineError;

#[async_trait]
pub trait IdentityStorage: Send + Sync {
    /// Retrieves an identity by its UUID.
    async fn get_identity(&self, id: &Uuid) -> Result<Option<Identity>, EngineError>;

    /// Retrieves an identity by its public key.
    async fn get_identity_by_public_key(&self, public_key: &[u8]) -> Result<Option<Identity>, EngineError>;

    /// Persists a new or updated identity.
    async fn save_identity(&self, identity: &Identity) -> Result<(), EngineError>;

    /// Atomically persists a heartbeat and increments continuity score.
    async fn log_heartbeat(&self, identity: &Identity, heartbeat: &Heartbeat) -> Result<u64, EngineError>;

    /// Scans for silent identities and updates their status to Dormant or Armed.
    async fn run_reaper(&self) -> Result<u64, EngineError>;

    /// Sets the username for a Genesis Node. Fails if username is taken.
    async fn set_username(&self, id: &Uuid, username: &str) -> Result<bool, EngineError>;

    /// Retrieves the leaderboard of top identities by continuity score.
    async fn get_leaderboard(&self, limit: i64) -> Result<Vec<Identity>, EngineError>;
}