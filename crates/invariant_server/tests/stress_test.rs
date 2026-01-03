use reqwest::Client;
use serde_json::json;
use uuid::Uuid;
use chrono::Utc;
use std::sync::Arc;
use tokio::sync::Semaphore;
use rand::Rng; // Add rand to your Cargo.toml

#[tokio::test]
async fn dirty_fraud_swarm_test() {
    let client = Client::new();
    let server_url = "http://16.171.151.222:3000"; 
    let semaphore = Arc::new(Semaphore::new(500)); 
    let mut handles = vec![];

    println!("\n👺 DEPLOYING DIRTY FRAUDSTER SWARM...");

    for i in 0..5000 {
        let c = client.clone();
        let sem = Arc::clone(&semaphore);
        
        let handle = tokio::spawn(async move {
            let _permit = sem.acquire().await.unwrap();
            let mut rng = rand::thread_rng();
            
            for _ in 0..5 {
                // FUZZING: Generate random signature lengths and content
                let junk_sig_len = rng.gen_range(10..200);
                let mut junk_sig = vec![0u8; junk_sig_len];
                rng.fill(&mut junk_sig[..]);

                let payload = json!({
                    "identity_id": Uuid::new_v4(),
                    "device_signature": junk_sig, 
                    "timestamp": Utc::now()
                });

                // Simulation of different User-Agents (often used by botnets)
                let _ = c.post(format!("{}/heartbeat", server_url))
                    .header("User-Agent", format!("BotNet-Node-{}", i))
                    .json(&payload)
                    .send()
                    .await;
            }
        });
        handles.push(handle);
    }

    futures::future::join_all(handles).await;
    println!("✅ DIRTY SWARM COMPLETE. THE WALL HELD.");
}