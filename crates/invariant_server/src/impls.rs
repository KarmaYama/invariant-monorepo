/*
 * Copyright (c) 2026 Invariant Protocol.
 *
 * This source code is licensed under the Business Source License (BSL 1.1) 
 * found in the LICENSE.md file in the root directory of this source tree.
 */
 
use async_trait::async_trait;
use invariant_engine::ports::NonceStorage;
use invariant_engine::EngineError;
use redis::AsyncCommands;
use tracing::warn;

pub struct RedisNonceManager {
    pub client: redis::Client,
}

#[async_trait]
impl NonceStorage for RedisNonceManager {
    async fn consume_nonce(&self, nonce: &[u8], ttl_seconds: u64) -> Result<bool, EngineError> {
        let mut conn = self.client.get_multiplexed_async_connection().await
            .map_err(|e| EngineError::Storage(format!("Redis connect failed: {}", e)))?;

        let hex_nonce = hex::encode(nonce);
        let key = format!("nonce_lock:{}", hex_nonce);

        // Atomic SETNX (Set if Not eXists)
        let result: bool = conn.set_nx(&key, "1").await
            .map_err(|e| EngineError::Storage(format!("Redis SETNX failed: {}", e)))?;

        if result {
            // Set expiry to prevent memory leaks in Redis
            let _: () = conn.expire(&key, ttl_seconds as i64).await
                .map_err(|e| warn!("⚠️ Failed to set TTL on nonce {}: {}", key, e)).ok().unwrap_or(());
            
            Ok(true) 
        } else {
            warn!("⛔ Replay detected for nonce: {}", hex_nonce);
            Ok(false) 
        }
    }
}