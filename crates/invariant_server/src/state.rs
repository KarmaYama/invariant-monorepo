/*
 * Copyright (c) 2026 Invariant Protocol.
 *
 * This source code is licensed under the Business Source License (BSL 1.1) 
 * found in the LICENSE.md file in the root directory of this source tree.
 * * You may NOT use this code for active blocking or enforcement without a commercial license.
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