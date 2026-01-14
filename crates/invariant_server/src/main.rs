// crates/invariant_server/src/main.rs
/*
 * Copyright (c) 2026 Invariant Protocol.
 *
 * This source code is licensed under the Business Source License (BSL 1.1) 
 * found in the LICENSE.md file in the root directory of this source tree.
 */

mod db;
mod state;
mod handlers;
mod error_response; // ✅ Register Structured Error Module
mod api_docs;       // ✅ Register OpenAPI/Swagger Module
mod services { pub mod push; }

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
    
    // 1. Production JSON Logging
    // We use JSON format for better ingestion by Logstash/Datadog/Splunk
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

    // 2. Initialize FCM (Server-Driven Wake Up)
    // This loads the Service Account credentials for sending push notifications
    if let Err(e) = services::push::initialize().await {
        tracing::error!("⚠️ Failed to initialize FCM: {}. Wake-up calls disabled.", e);
    }

    // 3. Database Connection Pool (Performance Tuned)
    // Max Connections: 75 allows high concurrency without starving the DB.
    // Acquire Timeout: 5s fails fast during outages rather than hanging.
    let database_url = std::env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    let pool = PgPoolOptions::new()
        .max_connections(75) 
        .acquire_timeout(Duration::from_secs(5)) 
        .connect(&database_url)
        .await?;
    
    // Auto-run migrations on startup
    sqlx::migrate!("./migrations").run(&pool).await?;

    // 4. Redis Connection (Rate Limiting & Nonces)
    let redis_url = std::env::var("REDIS_URL").unwrap_or_else(|_| "redis://127.0.0.1:6379".into());
    let redis_client = redis::Client::open(redis_url)?;

    // 5. App Configuration
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

    // 6. Initialize Engine & State
    let storage = PostgresStorage::new(pool.clone());
    let engine_config = EngineConfig { network, genesis_version };
    let engine = InvariantEngine::new(storage, engine_config);
    
    let state = Arc::new(AppState { 
        engine,
        redis: redis_client,
    });

    // 7. Background Worker (Reaper + Wake Up Call)
    // Runs on a detached Tokio thread to keep the main event loop clean.
    let worker_storage = PostgresStorage::new(pool.clone());
    tokio::spawn(async move {
        // Run every 15 minutes
        let mut interval = tokio::time::interval(Duration::from_secs(900)); 
        loop {
            interval.tick().await;
            
            // A. Wake Up Call (Users > 24 hours late)
            // Finds users who missed their daily tap and nudges them via FCM.
            match worker_storage.get_late_fcm_tokens(24 * 60).await {
                Ok(tokens) => {
                    if !tokens.is_empty() {
                        tracing::info!("🔔 Waking up {} late nodes...", tokens.len());
                        for token in tokens {
                            // Fire and forget push
                            let _ = services::push::send_wake_up_call(&token).await;
                        }
                    }
                }
                Err(e) => tracing::error!("Failed to fetch late tokens: {}", e),
            }

            // B. Reaper (Users > 30 days dormant)
            // Marks abandoned identities as 'Dormant' or 'Revoked'.
            if let Err(e) = worker_storage.run_reaper().await {
                tracing::error!("Reaper failed: {}", e);
            }
        }
    });

    // 8. Launch API Server
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