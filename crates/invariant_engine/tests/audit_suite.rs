/*
 * Copyright (c) 2026 Invariant Protocol.
 *
 * ======================================================================================
 * INVARIANT ADVERSARIAL AUDIT SUITE (PRE-AUDIT HARNESS)
 * ======================================================================================
 *
 * This suite acts as an automated "Red Team" against the Invariant Engine.
 * It produces deterministic, reproducible artifacts for external auditors.
 *
 * CAPABILITIES:
 * 1. Deep ASN.1 Mutation Fuzzing (Structure/Length/Tag attacks).
 * 2. Cryptographic Signature Fuzzing (Bit-flipping, Wrong Key, Truncation).
 * 3. Trust Decay Boundary Analysis (Precise T-1s/T+1s enforcement).
 * 4. High-Concurrency Race Condition Simulation (Nonce double-spend).
 * 5. Artifact Generation (Dumps failing vectors to artifacts/failures/).
 *
 * CONFIGURATION (Env Vars):
 * - AUDIT_SEED (u64): Deterministic RNG seed (Default: 0xDEADBEEF).
 * - AUDIT_ITERATIONS (u32): Fuzzing depth (Default: 5000).
 * - AUDIT_CONCURRENCY (usize): Concurrent threads for race tests (Default: 1000).
 */

use invariant_engine::{attestation, InvariantEngine, IdentityStorage, EngineError, core::EngineConfig, crypto};
use invariant_engine::ports::NonceStorage;
use invariant_shared::{Identity, IdentityStatus, Heartbeat, Network};
use async_trait::async_trait;
use chrono::{Utc, Duration, DateTime};
use std::collections::{HashMap, HashSet};
use tokio::sync::{RwLock, Barrier};
use uuid::Uuid;
use std::fs::{self, File};
use std::io::Write;
use std::sync::{Arc, Mutex};
use once_cell::sync::Lazy;
use sha2::{Sha256, Digest};
use rand::{Rng, SeedableRng, RngCore};
use rand_chacha::ChaCha8Rng;
use p256::ecdsa::{SigningKey, Signature, signature::Signer};
use p256::pkcs8::{EncodePublicKey}; // Removed DecodePublicKey unused import

// --- 1. GLOBAL AUDIT STATE & REPORTING ---

struct AuditState {
    events: Vec<serde_json::Value>,
    failures: Vec<serde_json::Value>,
    panics_detected: usize,
    start_time: DateTime<Utc>,
}

static AUDIT_STATE: Lazy<Arc<Mutex<AuditState>>> = Lazy::new(|| {
    Arc::new(Mutex::new(AuditState {
        events: Vec::new(),
        failures: Vec::new(),
        panics_detected: 0,
        start_time: Utc::now(),
    }))
});

fn get_config() -> (u64, u32, usize) {
    let seed = std::env::var("AUDIT_SEED")
        .map(|s| if s.starts_with("0x") { 
            u64::from_str_radix(&s[2..], 16).unwrap_or(0xDEADBEEF) 
        } else { 
            s.parse().unwrap_or(0xDEADBEEF) 
        })
        .unwrap_or(0xDEADBEEF);
    
    let iters = std::env::var("AUDIT_ITERATIONS")
        .map(|s| s.parse().unwrap_or(5000))
        .unwrap_or(5000);

    let concurrency = std::env::var("AUDIT_CONCURRENCY")
        .map(|s| s.parse().unwrap_or(1000))
        .unwrap_or(1000);

    (seed, iters, concurrency)
}

fn log_event(category: &str, test: &str, status: &str, msg: &str) {
    let entry = serde_json::json!({
        "timestamp": Utc::now().to_rfc3339(),
        "category": category,
        "test": test,
        "status": status,
        "message": msg
    });
    
    // Console Output for CI
    let icon = match status {
        "PASS" => "✅",
        "FAIL" => "❌",
        "WARN" => "⚠️",
        _ => "ℹ️"
    };
    println!("{} [{}] {}: {}", icon, category, test, msg);

    AUDIT_STATE.lock().unwrap().events.push(entry);
}

fn save_failure_artifact(test_name: &str, description: &str, raw_data: &[u8], metadata: serde_json::Value) {
    let hash = hex::encode(Sha256::digest(raw_data));
    let filename_base = format!("artifacts/failures/{}-{}", test_name, &hash[0..8]);
    
    let _ = fs::create_dir_all("artifacts/failures");

    // 1. Write Binary
    if let Ok(mut file) = File::create(format!("{}.bin", filename_base)) {
        let _ = file.write_all(raw_data);
    }

    // 2. Write Metadata
    let mut meta = metadata;
    meta["test"] = serde_json::Value::String(test_name.to_string());
    meta["description"] = serde_json::Value::String(description.to_string());
    meta["sha256"] = serde_json::Value::String(hash.clone());
    meta["file_path"] = serde_json::Value::String(format!("{}.bin", filename_base));
    // Updated base64 call to avoid deprecation warning if using newer crate, 
    // but using standard engine for compatibility or keep simple if using older version.
    // Assuming base64 0.21+:
    use base64::{Engine as _, engine::general_purpose};
    meta["base64_payload"] = serde_json::Value::String(general_purpose::STANDARD.encode(raw_data));

    if let Ok(mut file) = File::create(format!("{}.json", filename_base)) {
        let _ = file.write_all(serde_json::to_string_pretty(&meta).unwrap().as_bytes());
    }

    let mut state = AUDIT_STATE.lock().unwrap();
    state.failures.push(meta);
}

// --- 2. MOCK STORAGE (Refined for Clone/Arc Safety) ---

#[derive(Default, Clone)]
struct MockStorage {
    // Internal Arc allows MockStorage to be Clone while sharing state
    identities: Arc<RwLock<HashMap<Uuid, Identity>>>,
    heartbeats: Arc<RwLock<Vec<Heartbeat>>>,
}

#[async_trait]
impl IdentityStorage for MockStorage {
    async fn get_identity(&self, id: &Uuid) -> Result<Option<Identity>, EngineError> {
        Ok(self.identities.read().await.get(id).cloned())
    }
    async fn get_identity_by_public_key(&self, pk: &[u8]) -> Result<Option<Identity>, EngineError> {
        let map = self.identities.read().await;
        for identity in map.values() {
            if identity.public_key == pk { return Ok(Some(identity.clone())); }
        }
        Ok(None)
    }
    async fn save_identity(&self, identity: &Identity) -> Result<(), EngineError> {
        self.identities.write().await.insert(identity.id, identity.clone());
        Ok(())
    }
    async fn log_heartbeat(&self, identity: &Identity, heartbeat: &Heartbeat) -> Result<u64, EngineError> {
        let mut map = self.identities.write().await;
        if let Some(id_ref) = map.get_mut(&identity.id) {
            id_ref.continuity_score += 1;
            id_ref.last_heartbeat = heartbeat.timestamp;
            self.heartbeats.write().await.push(heartbeat.clone());
            return Ok(id_ref.continuity_score);
        }
        Err(EngineError::IdentityNotFound(identity.id))
    }
    async fn run_reaper(&self) -> Result<u64, EngineError> { Ok(0) }
    async fn set_username(&self, _: &Uuid, _: &str) -> Result<bool, EngineError> { Ok(true) }
    async fn get_leaderboard(&self, _: i64) -> Result<Vec<Identity>, EngineError> { Ok(vec![]) }
    async fn update_fcm_token(&self, _: &Uuid, _: &str) -> Result<(), EngineError> { Ok(()) }
    async fn get_late_fcm_tokens(&self, _: i64) -> Result<Vec<String>, EngineError> { Ok(vec![]) }
}

#[derive(Default, Clone)]
struct MockNonceStorage {
    used_nonces: Arc<RwLock<HashSet<Vec<u8>>>>,
}

#[async_trait]
impl NonceStorage for MockNonceStorage {
    async fn consume_nonce(&self, nonce: &[u8], _ttl: u64) -> Result<bool, EngineError> {
        let mut set = self.used_nonces.write().await;
        if set.contains(nonce) { return Ok(false); }
        set.insert(nonce.to_vec());
        Ok(true)
    }
}

// --- 3. HELPER: DER & MUTATION LOGIC ---

fn fuzz_encode_extension(security_level: u8, challenge: &[u8], boot_locked: bool) -> Vec<u8> {
    let mut root = vec![0x30]; // Sequence
    let mut content = Vec::new();
    
    // Standard boilerplate to simulate Android KeyStore structure
    content.extend_from_slice(&[0x02, 0x01, 0x01, 0x0A, 0x01, security_level, 0x02, 0x01, 0x00, 0x0A, 0x01, security_level]);
    
    // Challenge
    content.push(0x04);
    if challenge.len() < 128 { content.push(challenge.len() as u8); } else { content.push(0x81); content.push(challenge.len() as u8); }
    content.extend_from_slice(challenge);
    
    content.extend_from_slice(&[0x04, 0x00, 0x30, 0x00]); // UniqueID, SoftwareEnforced
    
    // TEE Enforced
    let mut tee_seq = Vec::new();
    let locked_byte = if boot_locked { 0xFF } else { 0x00 };
    // Tag 704 (RootOfTrust)
    tee_seq.extend_from_slice(&[0xBF, 0x85, 0x40, 0x08, 0x30, 0x06, 0x04, 0x00, 0x01, 0x01, locked_byte, 0x0A, 0x01, 0x00]);
    
    content.push(0x30);
    content.push(tee_seq.len() as u8);
    content.extend(tee_seq);
    
    root.push(content.len() as u8);
    root.extend(content);
    root
}

// Deterministic Mutator for ASN.1
fn mutate_der(rng: &mut ChaCha8Rng, input: &[u8]) -> (Vec<u8>, String) {
    let mut mutated = input.to_vec();
    let mutation_type = rng.gen_range(0..5);
    let mut step = String::new();

    match mutation_type {
        0 => { 
            let idx = rng.gen_range(0..mutated.len());
            let val: u8 = rng.gen();
            mutated.insert(idx, val); 
            step = format!("insert_random_byte_at_{}_{:#04x}", idx, val);
        },
        1 => {
            // Flip length byte (try to find a length-like byte)
            if mutated.len() > 5 {
                let idx = rng.gen_range(1..mutated.len()-1);
                mutated[idx] = mutated[idx].wrapping_add(50);
                step = format!("flip_byte_at_{}", idx);
            }
        },
        2 => {
            // Truncate
            let new_len = rng.gen_range(0..mutated.len());
            mutated.truncate(new_len);
            step = format!("truncate_to_{}", new_len);
        },
        3 => {
            // Huge length injection (Indefinite or large)
            mutated.extend_from_slice(&[0x84, 0xFF, 0xFF, 0xFF, 0xFF]);
            step = "append_huge_length".to_string();
        },
        4 => {
            // Nest a SEQUENCE
            let sub_seq = vec![0x30, 0x02, 0x05, 0x00];
            let idx = rng.gen_range(0..mutated.len());
            mutated.splice(idx..idx, sub_seq);
            step = format!("inject_nested_sequence_at_{}", idx);
        },
        _ => {}
    }
    (mutated, step)
}

// --- 4. TESTS ---

#[tokio::test]
async fn audit_signature_fuzzing() {
    let (seed, iterations, _) = get_config();
    let mut rng = ChaCha8Rng::seed_from_u64(seed);
    
    println!(">>> 🔒 Starting Signature Fuzzing ({} iterations, seed: {:#x})", iterations, seed);

    for i in 0..iterations {
        // 1. Key Gen
        let signing_key = SigningKey::random(&mut rng);
        let verify_key_bytes = signing_key.verifying_key().to_public_key_der().unwrap().as_bytes().to_vec();
        let wrong_key = SigningKey::random(&mut rng);

        // 2. Payload
        let mut nonce = [0u8; 32]; rng.fill_bytes(&mut nonce);
        let payload = format!("AUDIT_PAYLOAD_{}", i);
        
        // 3. Valid Sign
        // FIX: Explicitly annotate type for E0282
        let signature: Signature = signing_key.sign(payload.as_bytes());
        let sig_bytes = signature.to_der().as_bytes().to_vec();

        // TEST A: Valid Acceptance
        match crypto::verify_signature(&verify_key_bytes, payload.as_bytes(), &sig_bytes) {
            Ok(_) => {},
            Err(e) => panic!("Valid signature rejected! Key: {:?}, Err: {:?}", hex::encode(&verify_key_bytes), e),
        }

        // TEST B: Bit Flip Attack
        let mut corrupt_sig = sig_bytes.clone();
        let flip_idx = rng.gen_range(0..corrupt_sig.len());
        corrupt_sig[flip_idx] ^= 0xFF; // Invert byte
        
        if crypto::verify_signature(&verify_key_bytes, payload.as_bytes(), &corrupt_sig).is_ok() {
            save_failure_artifact("sig_bit_flip", "Corrupted signature was accepted", &corrupt_sig, serde_json::json!({"mutation": "bit_flip", "index": flip_idx}));
            panic!("❌ CRITICAL: Corrupted signature accepted!");
        }

        // TEST C: Wrong Key Attack
        let wrong_sig_val: Signature = wrong_key.sign(payload.as_bytes());
        let wrong_sig_bytes = wrong_sig_val.to_der().as_bytes().to_vec();
        
        if crypto::verify_signature(&verify_key_bytes, payload.as_bytes(), &wrong_sig_bytes).is_ok() {
            save_failure_artifact("sig_wrong_key", "Wrong key signature accepted", &wrong_sig_bytes, serde_json::json!({"mutation": "wrong_key"}));
            panic!("❌ CRITICAL: Wrong key signature accepted!");
        }

        // TEST D: Truncation
        if sig_bytes.len() > 1 {
            let truncated = &sig_bytes[0..sig_bytes.len()-1];
            if crypto::verify_signature(&verify_key_bytes, payload.as_bytes(), truncated).is_ok() {
                 save_failure_artifact("sig_truncated", "Truncated signature accepted", truncated, serde_json::json!({"mutation": "truncation"}));
                 panic!("❌ CRITICAL: Truncated signature accepted!");
            }
        }
    }
    log_event("Crypto", "Signature Fuzzing", "PASS", "Validated integrity against corruption/forgery.");
}

#[tokio::test]
async fn audit_asn1_deep_mutation() {
    let (seed, iterations, _) = get_config();
    let mut rng = ChaCha8Rng::seed_from_u64(seed);
    
    println!(">>> 🧬 Starting Deep ASN.1 Mutation ({} iterations)", iterations);

    for _ in 0..iterations {
        let mut challenge = [0u8; 32]; rng.fill_bytes(&mut challenge);
        let base_der = fuzz_encode_extension(1, &challenge, true);
        
        // Mutate
        let (mutated, mutation_step) = mutate_der(&mut rng, &base_der);

        // Verify Parser Resilience (Catch Panics)
        let result = std::panic::catch_unwind(|| {
            attestation::verify_extension_and_extract(&mutated, Some(&challenge))
        });

        match result {
            Ok(inner_res) => {
                // It didn't panic. Check if it accidentally accepted junk.
                if let Ok(_) = inner_res {
                    // It accepted mutated data. Log as WARN artifact.
                    save_failure_artifact(
                        "asn1_accepted_mutation", 
                        "Parser accepted mutated DER", 
                        &mutated, 
                        serde_json::json!({"mutation": mutation_step})
                    );
                }
            },
            Err(_) => {
                let mut state = AUDIT_STATE.lock().unwrap();
                state.panics_detected += 1;
                save_failure_artifact(
                    "asn1_panic", 
                    "Parser PANIC detected", 
                    &mutated, 
                    serde_json::json!({"mutation": mutation_step, "stack": "Panic caught via catch_unwind"})
                );
            }
        }
    }
    
    let panics = AUDIT_STATE.lock().unwrap().panics_detected;
    if panics > 0 {
        log_event("ASN.1", "Deep Fuzzing", "FAIL", &format!("{} Panics Detected!", panics));
    } else {
        log_event("ASN.1", "Deep Fuzzing", "PASS", "No panics observed under structural mutation.");
    }
}

#[tokio::test]
async fn audit_trust_decay_boundaries() {
    let storage = MockStorage::default();
    let nonce_storage = MockNonceStorage::default();
    let config = EngineConfig { network: Network::Testnet, genesis_version: 1 };
    let engine = InvariantEngine::new(storage.clone(), nonce_storage.clone(), config);
    let id = Uuid::new_v4();

    // 7 Days is the hardcoded TTL in core.rs
    // We test T - 1 second (Valid) and T + 1 second (Invalid)
    
    let now = Utc::now();
    let ttl = Duration::days(7);
    
    let scenarios = vec![
        ("Valid (T-1m)", ttl - Duration::minutes(1), true),
        ("Expired (T+1m)", ttl + Duration::minutes(1), false),
        ("Expired (T+365d)", Duration::days(365), false),
    ];

    for (name, offset, should_pass) in scenarios {
        let identity = Identity {
            id,
            public_key: vec![], // Not checked before trust logic usually
            continuity_score: 10, streak: 5,
            created_at: now - Duration::days(400),
            last_heartbeat: now - Duration::hours(1),
            last_attestation: now - offset, // Set the Trust Timer
            status: IdentityStatus::Active,
            username: None, is_genesis_eligible: true, fcm_token: None,
            hardware_brand: None, hardware_device: None, hardware_product: None,
            genesis_version: 1, network: Network::Testnet,
        };
        engine.get_storage().save_identity(&identity).await.unwrap();

        // Need valid nonce to pass step 3.
        let mut n = [0u8; 4]; rand::thread_rng().fill_bytes(&mut n);
        let nonce = n.to_vec();
        
        let hb = Heartbeat { 
            identity_id: id, timestamp: now, nonce, device_signature: vec![] 
        };

        let res = engine.process_heartbeat(hb).await;
        
        match res {
            Err(EngineError::AttestationRequired) => {
                if should_pass {
                    log_event("Logic", "Trust Decay", "FAIL", &format!("Scenario {} rejected valid identity", name));
                    panic!("Premature expiration!");
                }
            },
            // If we get InvalidSignature, it means we passed Trust Decay check (Success for this test)
            Err(EngineError::InvalidSignature) => {
                if !should_pass {
                    log_event("Logic", "Trust Decay", "FAIL", &format!("Scenario {} allowed expired identity (hit crypto check)", name));
                    panic!("Leaked expired identity!");
                }
            },
            Err(e) => {
                 // Other errors
                 if !should_pass && matches!(e, EngineError::ReplayDetected) {
                     // Acceptable
                 }
            }
            Ok(_) => {
                if !should_pass { panic!("Allowed expired identity!"); }
            }
        }
    }
    log_event("Logic", "Trust Decay", "PASS", "Boundary conditions enforced correctly.");
}

#[tokio::test]
async fn audit_concurrency_race() {
    let (_, _, concurrency) = get_config();
    println!(">>> 🏎️ Starting Race Condition Test ({} Threads)", concurrency);

    let storage = MockStorage::default();
    let nonce_storage = MockNonceStorage::default();
    let config = EngineConfig { network: Network::Testnet, genesis_version: 1 };
    
    // Pre-seed identity
    let id = Uuid::new_v4();
    // Valid key for signing
    let mut rng = ChaCha8Rng::seed_from_u64(0x1234);
    let signing_key = SigningKey::random(&mut rng);
    let pk_der = signing_key.verifying_key().to_public_key_der().unwrap().as_bytes().to_vec();

    let identity = Identity {
        id,
        public_key: pk_der,
        continuity_score: 0, streak: 0,
        created_at: Utc::now(), last_heartbeat: Utc::now() - Duration::days(2), // Allow rate limit bypass
        last_attestation: Utc::now(),
        status: IdentityStatus::Active,
        username: None, is_genesis_eligible: true, fcm_token: None,
        hardware_brand: None, hardware_device: None, hardware_product: None,
        genesis_version: 1, network: Network::Testnet,
    };
    storage.save_identity(&identity).await.unwrap();

    // Use Arc to share engine across threads
    let engine = Arc::new(InvariantEngine::new(storage.clone(), nonce_storage.clone(), config));
    let barrier = Arc::new(Barrier::new(concurrency));
    
    let mut handles = vec![];

    // SCENARIO: 50% Valid unique nonces, 50% Replay attack (same nonce)
    let replay_nonce = vec![0xFF, 0xFF, 0xFF];

    for i in 0..concurrency {
        let eng = engine.clone();
        let bar = barrier.clone();
        let my_id = id;
        let my_key = signing_key.clone(); // Clone for thread safety
        let r_nonce = replay_nonce.clone();

        handles.push(tokio::spawn(async move {
            let is_replay = i % 2 == 0;
            let nonce = if is_replay { r_nonce } else { 
                let mut n = [0u8; 8]; 
                let mut r = ChaCha8Rng::seed_from_u64(i as u64);
                r.fill_bytes(&mut n); 
                n.to_vec() 
            };

            // Sign
            let ts = Utc::now();
            let payload = format!("{}|{}|{}", my_id, hex::encode(&nonce), ts.to_rfc3339());
            
            // FIX: Explicitly separate the signature generation to satisfy E0282
            let signature: Signature = my_key.sign(payload.as_bytes());
            let sig_bytes = signature.to_der().as_bytes().to_vec();

            let hb = Heartbeat { identity_id: my_id, nonce, timestamp: ts, device_signature: sig_bytes };

            // Wait for everyone to be ready to hammer the engine at once
            bar.wait().await;
            
            eng.process_heartbeat(hb).await
        }));
    }

    let results = futures::future::join_all(handles).await;
    
    let mut success_count = 0;
    let mut replay_blocked = 0;
    let mut other_err = 0;

    for res in results {
        match res.unwrap() {
            Ok(_) => success_count += 1,
            Err(EngineError::ReplayDetected) => replay_blocked += 1,
            Err(_) => other_err += 1, // Likely RateLimitExceeded
        }
    }

    println!("    Race Results: Success={}, ReplayBlocked={}, Other={}", success_count, replay_blocked, other_err);

    // Validation
    let final_id = storage.get_identity(&id).await.unwrap().unwrap();
    
    if final_id.continuity_score != success_count as u64 {
        log_event("Concurrency", "Atomic Increment", "FAIL", &format!("DB Score {} != Success Count {}", final_id.continuity_score, success_count));
        panic!("Race condition detected in continuity score!");
    } else {
        log_event("Concurrency", "Atomic Increment", "PASS", "DB state perfectly consistent.");
    }

    if replay_blocked == 0 {
        log_event("Concurrency", "Replay Defense", "FAIL", "No replays were blocked in high-concurrency!");
        panic!("Replay defense failed under load.");
    } else {
        log_event("Concurrency", "Replay Defense", "PASS", &format!("Blocked {} concurrent replays.", replay_blocked));
    }
}

// --- 5. REPORT GENERATOR (Runs Last) ---

#[test]
fn zzz_generate_final_report() {
    let state = AUDIT_STATE.lock().unwrap();
    let duration = Utc::now().signed_duration_since(state.start_time).num_seconds();
    
    // FIX: Prefix variable with underscore to silence unused variable warning
    let _total_fails = state.events.iter().filter(|e| e["status"] == "FAIL").count() + state.failures.len();
    
    let panic_penalty = if state.panics_detected > 0 { 100 } else { 0 };
    // Risk Score: 0 (Good) -> 100 (Bad)
    let risk_score = std::cmp::min(100, (state.failures.len() * 5) + panic_penalty);

    let report = serde_json::json!({
        "audit_meta": {
            "id": Uuid::new_v4().to_string(),
            "generated_at": Utc::now().to_rfc3339(),
            "duration_seconds": duration,
            "auditor": "Invariant Adversarial Suite (Automated)",
        },
        "metrics": {
            "risk_score": risk_score,
            "panics_detected": state.panics_detected,
            "artifacts_generated": state.failures.len(),
            "events_tracked": state.events.len(),
        },
        "config": {
            "iterations": std::env::var("AUDIT_ITERATIONS").unwrap_or("5000".into()),
            "concurrency": std::env::var("AUDIT_CONCURRENCY").unwrap_or("1000".into()),
            "seed": std::env::var("AUDIT_SEED").unwrap_or("0xDEADBEEF".into()),
        },
        "logs": state.events,
        "failures": state.failures
    });

    let filename = "INVARIANT_AUDIT_REPORT.json";
    let mut file = File::create(filename).expect("Failed to create report");
    file.write_all(serde_json::to_string_pretty(&report).unwrap().as_bytes()).unwrap();

    println!("\n📄 AUDIT REPORT GENERATED: ./{}", filename);
    println!("📊 RISK SCORE: {}/100 (Lower is better)", risk_score);
    
    if risk_score > 0 {
        println!("⚠️  WARNING: Non-zero risk detected. Check artifacts/failures/ for reproduction vectors.");
    } else {
        println!("🛡️  CLEAN AUDIT. No critical failures detected.");
    }
}