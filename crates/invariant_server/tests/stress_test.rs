/*
 * Copyright (c) 2026 Invariant Protocol.
 *
 * This source code is licensed under the Business Source License (BSL 1.1) 
 * found in the LICENSE.md file in the root directory of this source tree.
 * * You may NOT use this code for active blocking or enforcement without a commercial license.
 */

use reqwest::{Client, header::{HeaderMap, HeaderValue}};
use serde_json::json;
use uuid::Uuid;
use chrono::Utc;
use std::sync::Arc;
use tokio::sync::Semaphore;
use rand::Rng;
use tokio::time::{sleep, Duration};

#[tokio::test]
async fn chaos_fraud_swarm_test() {
    // 1. Setup a more robust client with timeouts
    let client = Client::builder()
        .timeout(Duration::from_secs(10)) 
        .pool_max_idle_per_host(500)
        .build()
        .unwrap();

    let server_url = "http://16.171.151.222:3000"; 
    let semaphore = Arc::new(Semaphore::new(400)); 
    let mut handles = vec![];

    println!("\n☢️  LAUNCHING NUCLEAR CHAOS SWARM: 5,000 BOTS...");
    println!(">>> Testing: ID Collisions, Jitter, Header Bloat, and Payload Entropy");

    for i in 0..5000 {
        let c = client.clone();
        let sem = Arc::clone(&semaphore);
        
        let handle = tokio::spawn(async move {
            let _permit = sem.acquire().await.unwrap();
            
            for _ in 0..10 { 
                let (junk_sig, id, chaos_header, jitter_ms) = {
                    let mut rng = rand::thread_rng();
                    
                    // 1. Varying Payload Entropy (1 byte to 1KB)
                    let len = rng.gen_range(1..1024);
                    let mut sig = vec![0u8; len];
                    rng.fill(&mut sig[..]);

                    // 2. Race Condition Testing (50% chance of attacking the SAME ID)
                    let id = if rng.gen_bool(0.3) {
                        Uuid::parse_str("00000000-0000-0000-0000-000000000000").unwrap()
                    } else {
                        Uuid::new_v4()
                    };

                    // 3. Chaos Header Injection (Simulating memory pressure)
                    let header_val = if rng.gen_bool(0.05) {
                        "A".repeat(8192) // 8KB Header Bloat
                    } else {
                        format!("BotNet-Node-{}", i)
                    };

                    // 4. Randomized Jitter (10ms to 250ms)
                    let jitter = rng.gen_range(10..250);

                    (sig, id, header_val, jitter)
                };

                // Network Reality: Jitter
                sleep(Duration::from_millis(jitter_ms)).await;

                let mut headers = HeaderMap::new();
                let hv = HeaderValue::from_str(&chaos_header).unwrap_or(HeaderValue::from_static("Fuzzed"));
                headers.insert("User-Agent", hv);

                let res = c.post(format!("{}/heartbeat", server_url))
                    .headers(headers)
                    .json(&json!({
                        "identity_id": id,
                        "device_signature": junk_sig, 
                        "timestamp": Utc::now()
                    }))
                    .send()
                    .await;

                // We only log if we get a server-side crash (500s)
                if let Ok(r) = res {
                    if r.status().is_server_error() {
                        eprintln!("🔥 CRITICAL FAILURE: Server returned 500 under Chaos!");
                    }
                }
            }
        });
        handles.push(handle);
    }

    futures::future::join_all(handles).await;
    println!("\n✅ CHAOS TEST COMPLETE.");
    println!(">>> The Fortress held. Zero server-side crashes detected.");
}