/*
 * Copyright (c) 2025 Invariant Protocol
 * Use of this software is governed by the Business Source License.
 */

use std::sync::Arc;
use invariant_engine::InvariantEngine;
use crate::db::PostgresStorage;
use redis::Client as RedisClient;

pub type SharedState = Arc<AppState>;

pub struct AppState {
    pub engine: InvariantEngine<PostgresStorage>,
    pub redis: RedisClient,
}