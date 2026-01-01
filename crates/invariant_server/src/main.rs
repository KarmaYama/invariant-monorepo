/*
 * Copyright (c) 2025 Invariant Protocol
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
    
    // Default log level to INFO for production to reduce noise
    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::new(
            std::env::var("RUST_LOG").unwrap_or_else(|_| "invariant_server=info".into()),
        ))
        .with(tracing_subscriber::fmt::layer())
        .init();

    // 1. Infrastructure
    let database_url = std::env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    let pool = PgPoolOptions::new().max_connections(20).connect(&database_url).await?;
    sqlx::migrate!("./migrations").run(&pool).await?;

    let redis_url = std::env::var("REDIS_URL").unwrap_or_else(|_| "redis://127.0.0.1:6379".into());
    let redis_client = redis::Client::open(redis_url)?;

    // 2. Config
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

    tracing::info!("🚀 Booting Invariant Node ({:?}) - v{}", network, genesis_version);

    // 3. Engine
    let storage = PostgresStorage::new(pool.clone());
    let engine_config = EngineConfig { network, genesis_version };
    let engine = InvariantEngine::new(storage, engine_config);
    
    let state = Arc::new(AppState { 
        engine,
        redis: redis_client,
    });

    // 4. Background Reaper
    let reaper_storage = PostgresStorage::new(pool.clone());
    tokio::spawn(async move {
        let mut interval = tokio::time::interval(Duration::from_secs(3600)); 
        loop {
            interval.tick().await;
            tracing::debug!("Running Reaper cycle...");
            if let Ok(count) = reaper_storage.run_reaper().await {
                if count > 0 { tracing::info!("Reaper: {} identities marked DORMANT", count); }
            }
        }
    });

    // 5. Serve
    let app = handlers::app_router(state);
    let addr = SocketAddr::from(([0, 0, 0, 0], 3000));
    tracing::info!("Invariant Node listening on {}", addr);
    
    let listener = tokio::net::TcpListener::bind(addr).await?;
    
    // 🚀 CRITICAL: Enable ConnectInfo for Rate Limiting
    axum::serve(
        listener, 
        app.into_make_service_with_connect_info::<SocketAddr>()
    ).await?;

    Ok(())
}