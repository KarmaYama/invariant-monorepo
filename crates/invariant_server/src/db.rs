/*
 * Copyright (c) 2025 Invariant Protocol
 * Use of this software is governed by the Business Source License.
 */

use async_trait::async_trait;
use sqlx::{PgPool, Row};
use uuid::Uuid;
use invariant_engine::{IdentityStorage, EngineError};
use invariant_shared::{Identity, Heartbeat, IdentityStatus};
use sha2::{Sha256, Digest};

pub struct PostgresStorage {
    pub pool: PgPool,
}

impl PostgresStorage {
    pub fn new(pool: PgPool) -> Self { Self { pool } }
}

#[async_trait]
impl IdentityStorage for PostgresStorage {
    async fn get_identity(&self, id: &Uuid) -> Result<Option<Identity>, EngineError> {
        let result = sqlx::query(r#"
            SELECT id, public_key, continuity_score, streak, created_at, last_heartbeat, status,
                   hardware_brand, hardware_device_hash, hardware_product,
                   genesis_version, network, username, is_genesis_eligible
            FROM identities WHERE id = $1
        "#)
        .bind(id).fetch_optional(&self.pool).await.map_err(|e| EngineError::Storage(e.to_string()))?;
        
        map_row_to_identity(result)
    }

    async fn get_identity_by_public_key(&self, public_key: &[u8]) -> Result<Option<Identity>, EngineError> {
        let result = sqlx::query(r#"
            SELECT id, public_key, continuity_score, streak, created_at, last_heartbeat, status,
                   hardware_brand, hardware_device_hash, hardware_product,
                   genesis_version, network, username, is_genesis_eligible
            FROM identities WHERE public_key = $1
        "#)
        .bind(public_key).fetch_optional(&self.pool).await.map_err(|e| EngineError::Storage(e.to_string()))?;
        
        map_row_to_identity(result)
    }

    async fn save_identity(&self, identity: &Identity) -> Result<(), EngineError> {
        let status_str = match identity.status {
            IdentityStatus::Active => "active",
            IdentityStatus::Dormant => "dormant",
            _ => "revoked",
        };

        let network_str = identity.network.to_string();

        let device_hash = if let Some(raw_device) = &identity.hardware_device {
            let mut hasher = Sha256::new();
            hasher.update(raw_device.as_bytes());
            Some(hex::encode(hasher.finalize()))
        } else {
            None
        };

        sqlx::query(r#"
            INSERT INTO identities (
                id, public_key, continuity_score, streak, created_at, last_heartbeat, status,
                hardware_brand, hardware_device_hash, hardware_product,
                genesis_version, network, username, is_genesis_eligible
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
            ON CONFLICT (id) DO UPDATE SET 
                status = $7, 
                continuity_score = $3, 
                last_heartbeat = $6
        "#)
        .bind(identity.id)
        .bind(&identity.public_key)
        .bind(identity.continuity_score as i64)
        .bind(identity.streak as i64)
        .bind(identity.created_at)
        .bind(identity.last_heartbeat)
        .bind(status_str)
        .bind(&identity.hardware_brand)
        .bind(device_hash)
        .bind(&identity.hardware_product)
        .bind(identity.genesis_version as i16)
        .bind(network_str)
        .bind(&identity.username)
        .bind(identity.is_genesis_eligible)
        .execute(&self.pool)
        .await
        .map_err(|e| EngineError::Storage(e.to_string()))?;
        
        Ok(())
    }

    async fn log_heartbeat(&self, identity: &Identity, heartbeat: &Heartbeat) -> Result<u64, EngineError> {
        let mut tx = self.pool.begin().await.map_err(|e| EngineError::Storage(e.to_string()))?;

        let row = sqlx::query("
            UPDATE identities 
            SET 
                continuity_score = continuity_score + 1,
                streak = CASE 
                    WHEN NOW() - last_heartbeat < INTERVAL '360 minutes' THEN streak + 1 
                    ELSE 1 
                END,
                last_heartbeat = NOW(), 
                status = 'active'
            WHERE id = $1
            RETURNING continuity_score
        ")
        .bind(identity.id)
        .fetch_one(&mut *tx)
        .await
        .map_err(|e| EngineError::Storage(e.to_string()))?;

        let new_score: i64 = row.try_get("continuity_score").map_err(|e| EngineError::Storage(e.to_string()))?;

        let insert_result = sqlx::query("INSERT INTO heartbeats (identity_id, device_signature, timestamp) VALUES ($1, $2, $3)")
            .bind(heartbeat.identity_id)
            .bind(&heartbeat.device_signature)
            .bind(heartbeat.timestamp)
            .execute(&mut *tx)
            .await;

        match insert_result {
            Ok(_) => {
                tx.commit().await.map_err(|e| EngineError::Storage(e.to_string()))?;
                Ok(new_score as u64)
            },
            Err(e) => {
                if let Some(db_err) = e.as_database_error() {
                    if db_err.code().as_deref() == Some("23505") {
                        return Ok(identity.continuity_score); 
                    }
                }
                return Err(EngineError::Storage(e.to_string()));
            }
        }
    }

    async fn run_reaper(&self) -> Result<u64, EngineError> {
        let mut tx = self.pool.begin().await.map_err(|e| EngineError::Storage(e.to_string()))?;

        let result = sqlx::query(r#"
            UPDATE identities SET status = 'dormant', streak = 0
            WHERE status = 'active' AND last_heartbeat < NOW() - INTERVAL '30 days'
        "#).execute(&mut *tx).await.map_err(|e| EngineError::Storage(e.to_string()))?;

        let dormant_count = result.rows_affected();

        sqlx::query(r#"
            UPDATE identities SET switch_status = 'armed' 
            WHERE status = 'dormant' AND last_heartbeat < NOW() - INTERVAL '365 days'
            AND switch_status = 'inactive'
        "#).execute(&mut *tx).await.map_err(|e| EngineError::Storage(e.to_string()))?;

        tx.commit().await.map_err(|e| EngineError::Storage(e.to_string()))?;
        Ok(dormant_count)
    }

    async fn set_username(&self, id: &Uuid, username: &str) -> Result<bool, EngineError> {
        // Attempts to set username. Fails if ID doesn't exist OR username is not NULL.
        // The UNIQUE constraint in Postgres handles global uniqueness collisions.
        let result = sqlx::query("UPDATE identities SET username = $1 WHERE id = $2 AND username IS NULL")
            .bind(username)
            .bind(id)
            .execute(&self.pool)
            .await
            .map_err(|e| EngineError::Storage(e.to_string()))?;
        
        Ok(result.rows_affected() > 0)
    }

    async fn get_leaderboard(&self, limit: i64) -> Result<Vec<Identity>, EngineError> {
        let rows = sqlx::query(r#"
            SELECT id, public_key, continuity_score, streak, created_at, last_heartbeat, status,
                   hardware_brand, hardware_device_hash, hardware_product,
                   genesis_version, network, username, is_genesis_eligible
            FROM identities 
            WHERE status = 'active'
            ORDER BY continuity_score DESC, streak DESC
            LIMIT $1
        "#)
        .bind(limit)
        .fetch_all(&self.pool)
        .await
        .map_err(|e| EngineError::Storage(e.to_string()))?;

        let mut identities = Vec::new();
        for row in rows {
            if let Ok(Some(id)) = map_row_to_identity(Some(row)) {
                identities.push(id);
            }
        }
        Ok(identities)
    }
}

fn map_row_to_identity(row: Option<sqlx::postgres::PgRow>) -> Result<Option<Identity>, EngineError> {
    match row {
        Some(row) => {
            let status_str: String = row.try_get("status").unwrap_or_default();
            let status = match status_str.as_str() {
                "active" => IdentityStatus::Active,
                "dormant" => IdentityStatus::Dormant,
                _ => IdentityStatus::Revoked,
            };

            let net_str: String = row.try_get("network").unwrap_or_else(|_| "testnet".to_string());
            let network = match net_str.as_str() {
                "mainnet" => invariant_shared::Network::Mainnet,
                "dev" => invariant_shared::Network::Dev,
                _ => invariant_shared::Network::Testnet,
            };

            Ok(Some(Identity {
                id: row.try_get("id").map_err(|e| EngineError::Storage(e.to_string()))?,
                public_key: row.try_get("public_key").map_err(|e| EngineError::Storage(e.to_string()))?,
                continuity_score: row.try_get::<i64, _>("continuity_score").unwrap_or(0) as u64,
                streak: row.try_get::<i64, _>("streak").unwrap_or(0) as u64,
                created_at: row.try_get("created_at").map_err(|e| EngineError::Storage(e.to_string()))?,
                last_heartbeat: row.try_get("last_heartbeat").map_err(|e| EngineError::Storage(e.to_string()))?,
                status,
                username: row.try_get("username").ok(),
                is_genesis_eligible: row.try_get("is_genesis_eligible").unwrap_or(false),
                hardware_brand: row.try_get("hardware_brand").ok(),
                hardware_device: row.try_get("hardware_device_hash").ok(),
                hardware_product: row.try_get("hardware_product").ok(),
                genesis_version: row.try_get::<i16, _>("genesis_version").unwrap_or(1) as u16,
                network,
            }))
        }
        None => Ok(None),
    }
}