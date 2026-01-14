// crates/invariant_server/src/services/push.rs
/*
 * Copyright (c) 2026 Invariant Protocol.
 *
 * This source code is licensed under the Business Source License (BSL 1.1) 
 * found in the LICENSE.md file in the root directory of this source tree.
 */

use serde_json::json;
use std::env;
use gcp_auth::{AuthenticationManager, CustomServiceAccount};
use reqwest::Client;
use tracing::{info, error, instrument};
use std::path::PathBuf;
use once_cell::sync::Lazy;
use tokio::sync::RwLock;

// Singleton Auth Manager to cache tokens efficiently
static AUTH_MANAGER: Lazy<RwLock<Option<AuthenticationManager>>> = Lazy::new(|| RwLock::new(None));

/// Initializes the GCP Auth Manager using the JSON file path from env.
pub async fn initialize() -> Result<(), String> {
    let path_str = env::var("FIREBASE_SERVICE_ACCOUNT_PATH")
        .expect("FIREBASE_SERVICE_ACCOUNT_PATH must be set");
    
    let path = PathBuf::from(path_str);
    let service_account = CustomServiceAccount::from_file(&path)
        .map_err(|e| format!("Failed to load Service Account: {}", e))?;

    let manager = AuthenticationManager::from(service_account);
    
    let mut lock = AUTH_MANAGER.write().await;
    *lock = Some(manager);
    
    info!("✅ FCM Auth Manager Initialized");
    Ok(())
}

/// Sends a Data-Only, High-Priority message via FCM HTTP v1 API.
#[instrument(skip(fcm_token))]
pub async fn send_wake_up_call(fcm_token: &str) -> Result<(), String> {
    let project_id = env::var("FIREBASE_PROJECT_ID")
        .expect("FIREBASE_PROJECT_ID must be set");

    // 1. Get Access Token
    let lock = AUTH_MANAGER.read().await;
    let manager = lock.as_ref().ok_or("Auth Manager not initialized")?;
    
    let token = manager.get_token(&["https://www.googleapis.com/auth/firebase.messaging"])
        .await
        .map_err(|e| format!("Token generation failed: {}", e))?;

    // 2. Construct Payload (Data Only, High Priority)
    let payload = json!({
        "message": {
            "token": fcm_token,
            "android": {
                "priority": "HIGH" // Critical for Doze mode breakthrough
            },
            "data": {
                "type": "wake_up_call",
                "reason": "anchor_decay",
                "timestamp": chrono::Utc::now().to_rfc3339(),
                "action": "VERIFY_NOW"
            }
        }
    });

    let url = format!("https://fcm.googleapis.com/v1/projects/{}/messages:send", project_id);
    let client = Client::new();

    // 3. Send
    let res = client.post(&url)
        .header("Authorization", format!("Bearer {}", token.as_str()))
        .header("Content-Type", "application/json")
        .json(&payload)
        .send()
        .await
        .map_err(|e| e.to_string())?;

    if res.status().is_success() {
        info!("🔔 Wake-Up Signal sent to device");
        Ok(())
    } else {
        let err_body = res.text().await.unwrap_or_default();
        error!("❌ FCM Error: {}", err_body);
        Err(format!("FCM Failure: {}", err_body))
    }
}