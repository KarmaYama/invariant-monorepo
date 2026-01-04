// crates/invariant_server/src/main.rs
/*
 * Copyright (c) 2026 Invariant Protocol.
 *
 * This source code is licensed under the Business Source License (BSL 1.1) 
 * found in the LICENSE.md file in the root directory of this source tree.
 * * You may NOT use this code for active blocking or enforcement without a commercial license.
 */

mod db;
mod state;
mod handlers;

use std::net::SocketAddr;
use std::sync::Arc;
use std::time::Duration;
use sqlx::postgres::PgPoolOptions;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

use invariant_engine::{InvariantEngine, IdentityStorage, core::EngineConfig};
use invariant_shared::Network;
use crate::db::PostgresStorage;
use crate::state::AppState;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    dotenvy::dotenv().ok();
    
    // JSON Logging for Production
    let log_format = tracing_subscriber::fmt::format()
        .with_level(true)
        .with_target(true)
        .with_thread_ids(false)
        .with_thread_names(false)
        .json(); 

    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::new(
            std::env::var("RUST_LOG").unwrap_or_else(|_| "invariant_server=info,tower_http=info".into()),
        ))
        .with(tracing_subscriber::fmt::layer().event_format(log_format))
        .init();

    // ⚡ PERFORMANCE TUNING
    // Max Connections: 75 allows more bots to queue.
    // Acquire Timeout: 5s gives the pool time to find a connection during a spike.
    let database_url = std::env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    let pool = PgPoolOptions::new()
        .max_connections(75) 
        .acquire_timeout(Duration::from_secs(5)) 
        .connect(&database_url)
        .await?;
    
    sqlx::migrate!("./migrations").run(&pool).await?;

    let redis_url = std::env::var("REDIS_URL").unwrap_or_else(|_| "redis://127.0.0.1:6379".into());
    let redis_client = redis::Client::open(redis_url)?;

    let network_str = std::env::var("INVARIANT_NETWORK").unwrap_or_else(|_| "testnet".into());
    let network = match network_str.to_lowercase().as_str() {
        "mainnet" => Network::Mainnet,
        "dev" => Network::Dev,
        _ => Network::Testnet,
    };

    let genesis_version = std::env::var("INVARIANT_GENESIS_VERSION")
        .unwrap_or_else(|_| "1".into())
        .parse::<u16>()
        .expect("Invalid GENESIS_VERSION");

    tracing::info!(
        event = "startup",
        network = ?network,
        version = genesis_version,
        "🚀 Booting Invariant Node"
    );

    let storage = PostgresStorage::new(pool.clone());
    let engine_config = EngineConfig { network, genesis_version };
    let engine = InvariantEngine::new(storage, engine_config);
    
    let state = Arc::new(AppState { 
        engine,
        redis: redis_client,
    });

    // Background Reaper (Isolated thread)
    let reaper_storage = PostgresStorage::new(pool.clone());
    tokio::spawn(async move {
        let mut interval = tokio::time::interval(Duration::from_secs(3600)); 
        loop {
            interval.tick().await;
            tracing::debug!("Running Reaper cycle...");
            match reaper_storage.run_reaper().await {
                Ok(count) => {
                    if count > 0 { 
                        tracing::info!(event = "reaper_run", dormant_count = count, "Reaper marked identities dormant"); 
                    }
                },
                Err(e) => {
                    tracing::error!(event = "reaper_fail", error = ?e, "Reaper cycle failed");
                }
            }
        }
    });

    let app = handlers::app_router(state);
    let addr = SocketAddr::from(([0, 0, 0, 0], 3000));
    
    tracing::info!(event = "server_listening", address = %addr, "Invariant Node Online");
    
    let listener = tokio::net::TcpListener::bind(addr).await?;
    
    axum::serve(
        listener, 
        app.into_make_service_with_connect_info::<SocketAddr>()
    ).await?;

    Ok(())
}