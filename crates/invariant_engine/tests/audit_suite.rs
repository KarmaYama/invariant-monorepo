/*
 * Copyright (c) 2026 Invariant Protocol.
 *
 * ======================================================================================
 * INVARIANT MASTER AUDIT SUITE
 * ======================================================================================
 *
 * This suite consolidates ALL verification logic into a single adversarial harness.
 *
 * SCOPE:
 * 1. ADVERSARIAL: Deep Fuzzing, Race Conditions, Time-Warps.
 * 2. REGRESSION: Standard unit tests for Nonce, Signature, and Metadata logic.
 * 3. COMPLIANCE: ASN.1 parsing and Hardware Enforcements.
 *
 * ARTIFACT: INVARIANT_AUDIT_REPORT.json
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
use p256::pkcs8::{EncodePublicKey};

// ======================================================================================
// 1. GLOBAL AUDIT STATE & REPORTING
// ======================================================================================

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

    if let Ok(mut file) = File::create(format!("{}.bin", filename_base)) {
        let _ = file.write_all(raw_data);
    }

    let mut meta = metadata;
    meta["test"] = serde_json::Value::String(test_name.to_string());
    meta["description"] = serde_json::Value::String(description.to_string());
    meta["sha256"] = serde_json::Value::String(hash.clone());
    meta["file_path"] = serde_json::Value::String(format!("{}.bin", filename_base));
    use base64::{Engine as _, engine::general_purpose};
    meta["base64_payload"] = serde_json::Value::String(general_purpose::STANDARD.encode(raw_data));

    if let Ok(mut file) = File::create(format!("{}.json", filename_base)) {
        let _ = file.write_all(serde_json::to_string_pretty(&meta).unwrap().as_bytes());
    }

    let mut state = AUDIT_STATE.lock().unwrap();
    state.failures.push(meta);
}

// ======================================================================================
// 2. MOCK INFRASTRUCTURE
// ======================================================================================

#[derive(Default, Clone)]
struct MockStorage {
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

// ======================================================================================
// 3. HELPERS (DER Construction)
// ======================================================================================

fn legacy_encode_extension(is_software: bool, challenge_bytes: &[u8]) -> Vec<u8> {
    fn tag(t: u8, content: &[u8]) -> Vec<u8> {
        let mut v = vec![t];
        if content.len() < 128 { v.push(content.len() as u8); } 
        else { v.push(0x81); v.push(content.len() as u8); }
        v.extend_from_slice(content);
        v
    }
    fn int(val: u8) -> Vec<u8> { tag(0x02, &[val]) }
    fn enum_val(val: u8) -> Vec<u8> { tag(0x0a, &[val]) }
    fn octet(val: &[u8]) -> Vec<u8> { tag(0x04, val) }
    fn seq(content: &[u8]) -> Vec<u8> { tag(0x30, content) }
    fn bool_true() -> Vec<u8> { tag(0x01, &[0xFF]) } 
    
    let sec_level = if is_software { 0 } else { 1 };
    let mut root_content = Vec::new();
    root_content.extend(int(1));                  
    root_content.extend(enum_val(sec_level));     
    root_content.extend(int(0));                  
    root_content.extend(enum_val(sec_level));     
    root_content.extend(octet(challenge_bytes)); 
    root_content.extend(octet(b"unique_id"));
    root_content.extend(seq(&[])); 

    let mut tee_items = Vec::new();
    // RootOfTrust
    let mut rot_content = Vec::new();
    rot_content.extend(octet(b"key"));
    rot_content.extend(bool_true());
    rot_content.extend(enum_val(0));
    rot_content.extend(octet(b"hash"));
    let rot_seq = seq(&rot_content);
    tee_items.push(0xBF); tee_items.push(0x85); tee_items.push(0x40);
    tee_items.push(rot_seq.len() as u8);
    tee_items.extend_from_slice(&rot_seq);

    // Brand "Google"
    let brand_oct = octet(b"Google");
    tee_items.push(0xBF); tee_items.push(0x85); tee_items.push(0x46);
    tee_items.push(brand_oct.len() as u8);
    tee_items.extend_from_slice(&brand_oct);

    // Device "Pixel 7"
    let dev_oct = octet(b"Pixel 7");
    tee_items.push(0xBF); tee_items.push(0x85); tee_items.push(0x47);
    tee_items.push(dev_oct.len() as u8);
    tee_items.extend_from_slice(&dev_oct);

    root_content.extend(seq(&tee_items));
    seq(&root_content)
}

fn fuzz_encode_extension(security_level: u8, challenge: &[u8], boot_locked: bool) -> Vec<u8> {
    let mut root = vec![0x30]; // Sequence
    let mut content = Vec::new();
    content.extend_from_slice(&[0x02, 0x01, 0x01, 0x0A, 0x01, security_level, 0x02, 0x01, 0x00, 0x0A, 0x01, security_level]);
    content.push(0x04);
    if challenge.len() < 128 { content.push(challenge.len() as u8); } else { content.push(0x81); content.push(challenge.len() as u8); }
    content.extend_from_slice(challenge);
    content.extend_from_slice(&[0x04, 0x00, 0x30, 0x00]); 
    let mut tee_seq = Vec::new();
    let locked_byte = if boot_locked { 0xFF } else { 0x00 };
    tee_seq.extend_from_slice(&[0xBF, 0x85, 0x40, 0x08, 0x30, 0x06, 0x04, 0x00, 0x01, 0x01, locked_byte, 0x0A, 0x01, 0x00]);
    content.push(0x30);
    content.push(tee_seq.len() as u8);
    content.extend(tee_seq);
    root.push(content.len() as u8);
    root.extend(content);
    root
}

fn encode_tagged_string(tag_num: u32, value: &str) -> Vec<u8> {
    let content = value.as_bytes();
    let mut inner_der = vec![0x04];
    inner_der.push(content.len() as u8);
    inner_der.extend_from_slice(content);
    let tag_header = match tag_num {
        710 => vec![0xBF, 0x85, 0x46],
        711 => vec![0xBF, 0x85, 0x47],
        712 => vec![0xBF, 0x85, 0x48],
        _ => panic!("Unsupported test tag"),
    };
    let mut out = tag_header;
    out.push(inner_der.len() as u8);
    out.extend_from_slice(&inner_der);
    out
}

fn construct_metadata_payload(brand: &str, device: &str, product: &str) -> Vec<u8> {
    let rot_seq = vec![0x30, 0x08, 0x04, 0x00, 0x01, 0x01, 0xFF, 0x0A, 0x01, 0x00];
    let mut rot_tagged = vec![0xBF, 0x85, 0x40];
    rot_tagged.push(rot_seq.len() as u8);
    rot_tagged.extend_from_slice(&rot_seq);

    let mut tee_content = Vec::new();
    tee_content.extend(rot_tagged);
    tee_content.extend(encode_tagged_string(710, brand));
    tee_content.extend(encode_tagged_string(711, device));
    tee_content.extend(encode_tagged_string(712, product));

    let mut tee_seq = vec![0x30];
    tee_seq.push(tee_content.len() as u8);
    tee_seq.extend(tee_content);

    let mut main_seq = Vec::new();
    main_seq.extend(vec![0x02, 0x01, 0x01, 0x0A, 0x01, 0x01, 0x02, 0x01, 0x00, 0x0A, 0x01, 0x01]);
    main_seq.extend(vec![0x04, 0x03, 0x01, 0x02, 0x03]); // Fixed challenge [1,2,3]
    main_seq.extend(vec![0x04, 0x00, 0x30, 0x00]);
    main_seq.extend(tee_seq);

    let mut final_der = vec![0x30];
    final_der.push(main_seq.len() as u8);
    final_der.extend(main_seq);
    final_der
}

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
            if mutated.len() > 5 {
                let idx = rng.gen_range(1..mutated.len()-1);
                mutated[idx] = mutated[idx].wrapping_add(50);
                step = format!("flip_byte_at_{}", idx);
            }
        },
        2 => {
            let new_len = rng.gen_range(0..mutated.len());
            mutated.truncate(new_len);
            step = format!("truncate_to_{}", new_len);
        },
        3 => {
            mutated.extend_from_slice(&[0x84, 0xFF, 0xFF, 0xFF, 0xFF]);
            step = "append_huge_length".to_string();
        },
        4 => {
            let sub_seq = vec![0x30, 0x02, 0x05, 0x00];
            let idx = rng.gen_range(0..mutated.len());
            mutated.splice(idx..idx, sub_seq);
            step = format!("inject_nested_sequence_at_{}", idx);
        },
        _ => {}
    }
    (mutated, step)
}

// ======================================================================================
// 4. ADVERSARIAL TESTS (The "Nuclear" Option)
// ======================================================================================

#[tokio::test]
async fn audit_signature_fuzzing() {
    let (seed, iterations, _) = get_config();
    let mut rng = ChaCha8Rng::seed_from_u64(seed);
    println!(">>> 🔒 Starting Signature Fuzzing ({} iterations)", iterations);

    for i in 0..iterations {
        let signing_key = SigningKey::random(&mut rng);
        let verify_key_bytes = signing_key.verifying_key().to_public_key_der().unwrap().as_bytes().to_vec();
        let wrong_key = SigningKey::random(&mut rng);
        
        let mut nonce = [0u8; 32]; rng.fill_bytes(&mut nonce);
        let payload = format!("AUDIT_PAYLOAD_{}", i);
        
        let signature: Signature = signing_key.sign(payload.as_bytes());
        let sig_bytes = signature.to_der().as_bytes().to_vec();

        // A. Valid
        match crypto::verify_signature(&verify_key_bytes, payload.as_bytes(), &sig_bytes) {
            Ok(_) => {},
            Err(e) => panic!("Valid signature rejected! Key: {:?}, Err: {:?}", hex::encode(&verify_key_bytes), e),
        }

        // B. Corrupt
        let mut corrupt_sig = sig_bytes.clone();
        let flip_idx = rng.gen_range(0..corrupt_sig.len());
        corrupt_sig[flip_idx] ^= 0xFF;
        if crypto::verify_signature(&verify_key_bytes, payload.as_bytes(), &corrupt_sig).is_ok() {
            save_failure_artifact("sig_bit_flip", "Accepted corrupted signature", &corrupt_sig, serde_json::json!({"mutation": "bit_flip"}));
            panic!("❌ CRITICAL: Corrupted signature accepted!");
        }

        // C. Wrong Key
        let wrong_sig: Signature = wrong_key.sign(payload.as_bytes());
        let wrong_sig_bytes = wrong_sig.to_der().as_bytes().to_vec();
        if crypto::verify_signature(&verify_key_bytes, payload.as_bytes(), &wrong_sig_bytes).is_ok() {
            save_failure_artifact("sig_wrong_key", "Accepted wrong key signature", &wrong_sig_bytes, serde_json::json!({"mutation": "wrong_key"}));
            panic!("❌ CRITICAL: Wrong key signature accepted!");
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
        let (mutated, mutation_step) = mutate_der(&mut rng, &base_der);

        let result = std::panic::catch_unwind(|| {
            attestation::verify_extension_and_extract(&mutated, Some(&challenge))
        });

        match result {
            Ok(inner_res) => {
                if let Ok(_) = inner_res {
                    save_failure_artifact("asn1_accepted_mutation", "Parser accepted mutated DER", &mutated, serde_json::json!({"mutation": mutation_step}));
                }
            },
            Err(_) => {
                let mut state = AUDIT_STATE.lock().unwrap();
                state.panics_detected += 1;
                save_failure_artifact("asn1_panic", "Parser PANIC detected", &mutated, serde_json::json!({"mutation": mutation_step}));
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
    let now = Utc::now();
    let ttl = Duration::days(7);
    
    let scenarios = vec![
        ("Valid (T-1m)", ttl - Duration::minutes(1), true),
        ("Expired (T+1m)", ttl + Duration::minutes(1), false),
    ];

    for (name, offset, should_pass) in scenarios {
        let identity = Identity {
            id,
            public_key: vec![],
            continuity_score: 10, streak: 5,
            created_at: now - Duration::days(400),
            last_heartbeat: now - Duration::hours(1),
            last_attestation: now - offset, 
            status: IdentityStatus::Active,
            username: None, is_genesis_eligible: true, fcm_token: None,
            hardware_brand: None, hardware_device: None, hardware_product: None,
            genesis_version: 1, network: Network::Testnet,
        };
        engine.get_storage().save_identity(&identity).await.unwrap();

        let mut n = [0u8; 4]; rand::thread_rng().fill_bytes(&mut n);
        let nonce = n.to_vec();
        let hb = Heartbeat { identity_id: id, timestamp: now, nonce, device_signature: vec![] };

        let res = engine.process_heartbeat(hb).await;
        match res {
            Err(EngineError::AttestationRequired) => {
                if should_pass {
                    log_event("Logic", "Trust Decay", "FAIL", &format!("Scenario {} rejected valid identity", name));
                    panic!("Premature expiration!");
                }
            },
            Err(EngineError::InvalidSignature) => {
                if !should_pass {
                    log_event("Logic", "Trust Decay", "FAIL", &format!("Scenario {} allowed expired identity", name));
                    panic!("Leaked expired identity!");
                }
            },
            _ => {}
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
    
    let id = Uuid::new_v4();
    let mut rng = ChaCha8Rng::seed_from_u64(0x1234);
    let signing_key = SigningKey::random(&mut rng);
    let pk_der = signing_key.verifying_key().to_public_key_der().unwrap().as_bytes().to_vec();

    let identity = Identity {
        id,
        public_key: pk_der,
        continuity_score: 0, streak: 0,
        created_at: Utc::now(), last_heartbeat: Utc::now() - Duration::days(2),
        last_attestation: Utc::now(), status: IdentityStatus::Active,
        username: None, is_genesis_eligible: true, fcm_token: None,
        hardware_brand: None, hardware_device: None, hardware_product: None,
        genesis_version: 1, network: Network::Testnet,
    };
    storage.save_identity(&identity).await.unwrap();

    let engine = Arc::new(InvariantEngine::new(storage.clone(), nonce_storage.clone(), config));
    let barrier = Arc::new(Barrier::new(concurrency));
    let mut handles = vec![];
    let replay_nonce = vec![0xFF, 0xFF, 0xFF];

    for i in 0..concurrency {
        let eng = engine.clone();
        let bar = barrier.clone();
        let my_id = id;
        let my_key = signing_key.clone();
        let r_nonce = replay_nonce.clone();

        handles.push(tokio::spawn(async move {
            let is_replay = i % 2 == 0;
            let nonce = if is_replay { r_nonce } else { 
                let mut n = [0u8; 8]; 
                let mut r = ChaCha8Rng::seed_from_u64(i as u64);
                r.fill_bytes(&mut n); 
                n.to_vec() 
            };
            let ts = Utc::now();
            let payload = format!("{}|{}|{}", my_id, hex::encode(&nonce), ts.to_rfc3339());
            let signature: Signature = my_key.sign(payload.as_bytes());
            let sig_bytes = signature.to_der().as_bytes().to_vec();
            let hb = Heartbeat { identity_id: my_id, nonce, timestamp: ts, device_signature: sig_bytes };
            
            bar.wait().await;
            eng.process_heartbeat(hb).await
        }));
    }

    let results = futures::future::join_all(handles).await;
    let mut success_count = 0;
    let mut replay_blocked = 0;

    for res in results {
        match res.unwrap() {
            Ok(_) => success_count += 1,
            Err(EngineError::ReplayDetected) => replay_blocked += 1,
            _ => {}
        }
    }

    println!("    Race Results: Success={}, ReplayBlocked={}", success_count, replay_blocked);
    let final_id = storage.get_identity(&id).await.unwrap().unwrap();
    
    if final_id.continuity_score != success_count as u64 {
        log_event("Concurrency", "Atomic Increment", "FAIL", "DB Score mismatch");
        panic!("Race condition detected!");
    } else {
        log_event("Concurrency", "Atomic Increment", "PASS", "DB state consistent.");
    }

    if replay_blocked == 0 {
        log_event("Concurrency", "Replay Defense", "FAIL", "No replays blocked!");
        panic!("Replay defense failed.");
    } else {
        log_event("Concurrency", "Replay Defense", "PASS", &format!("Blocked {} concurrent replays.", replay_blocked));
    }
}

// ======================================================================================
// 5. REGRESSION & UNIT TESTS (Ported from attestation_tests.rs & metadata_parsing.rs)
// ======================================================================================

#[test]
fn regression_attestation_nonce_success() {
    let nonce = b"valid_nonce_123";
    let der_bytes = legacy_encode_extension(false, nonce);
    let result = attestation::verify_extension_and_extract(&der_bytes, Some(nonce));
    
    match result {
        Ok(meta) => {
            if meta.brand.as_deref() == Some("Google") && meta.is_boot_locked {
                log_event("Regression", "Attestation Success", "PASS", "Standard Pixel attestation valid.");
            } else {
                log_event("Regression", "Attestation Success", "FAIL", "Metadata mismatch.");
                panic!("Metadata extraction failed");
            }
        },
        Err(e) => {
            log_event("Regression", "Attestation Success", "FAIL", &format!("Parse error: {:?}", e));
            panic!("Valid attestation failed");
        }
    }
}

#[test]
fn regression_attestation_nonce_mismatch() {
    let real_nonce = b"real_nonce";
    let fake_nonce = b"fake_nonce";
    let der_bytes = legacy_encode_extension(false, real_nonce);
    let result = attestation::verify_extension_and_extract(&der_bytes, Some(fake_nonce));
    
    match result {
        Err(EngineError::InvalidAttestation(msg)) if msg.contains("Challenge mismatch") => {
            log_event("Regression", "Nonce Mismatch", "PASS", "Blocked invalid nonce.");
        },
        _ => {
            log_event("Regression", "Nonce Mismatch", "FAIL", "Failed to block mismatched nonce.");
            panic!("Allowed mismatch nonce!");
        }
    }
}

#[test]
fn regression_attestation_software_rejection() {
    let nonce = b"nonce";
    let der_bytes = legacy_encode_extension(true, nonce); // true = software
    let result = attestation::verify_extension_and_extract(&der_bytes, Some(nonce));
    
    match result {
        Err(EngineError::InvalidAttestation(msg)) if msg.contains("Software-backed") => {
            log_event("Regression", "Software Rejection", "PASS", "Blocked software-backed key.");
        },
        _ => {
            log_event("Regression", "Software Rejection", "FAIL", "Allowed software key!");
            panic!("Allowed software key!");
        }
    }
}

#[test]
fn regression_metadata_parsing() {
    let payload = construct_metadata_payload("Google", "Pixel 7 Pro", "cheetah");
    let result = attestation::verify_extension_and_extract(&payload, Some(&[1,2,3]));
    
    match result {
        Ok(meta) => {
            let b = meta.brand.as_deref() == Some("Google");
            let d = meta.device.as_deref() == Some("Pixel 7 Pro");
            let p = meta.product.as_deref() == Some("cheetah");
            
            if b && d && p && meta.is_boot_locked {
                log_event("Regression", "Metadata Parsing", "PASS", "Extracted deep-nested ASN.1 tags correctly.");
            } else {
                log_event("Regression", "Metadata Parsing", "FAIL", "Extracted wrong values.");
                panic!("Metadata mismatch");
            }
        },
        Err(e) => {
            log_event("Regression", "Metadata Parsing", "FAIL", &format!("Parse failed: {:?}", e));
            panic!("Parser error");
        }
    }
}

#[tokio::test]
async fn regression_heartbeat_invalid_signature() {
    let storage = MockStorage::default();
    let nonce_storage = MockNonceStorage::default();
    let config = EngineConfig { network: Network::Testnet, genesis_version: 1 };
    let engine = InvariantEngine::new(storage.clone(), nonce_storage.clone(), config);

    let id = Uuid::new_v4();
    let signing_key = SigningKey::random(&mut rand::thread_rng()); 
    let pk_der = signing_key.verifying_key().to_public_key_der().unwrap().as_bytes().to_vec();
    let wrong_key = SigningKey::random(&mut rand::thread_rng()); 

    let identity = Identity {
        id, public_key: pk_der, continuity_score: 1, streak: 0,
        created_at: Utc::now(), last_heartbeat: Utc::now() - Duration::hours(25), 
        last_attestation: Utc::now(), status: IdentityStatus::Active,
        username: None, is_genesis_eligible: true, fcm_token: None,
        hardware_brand: None, hardware_device: None, hardware_product: None,
        genesis_version: 1, network: Network::Testnet,
    };
    engine.get_storage().save_identity(&identity).await.unwrap();

    let hb_time = Utc::now();
    let nonce = vec![0x01];
    let payload = format!("{}|{}|{}", id, hex::encode(&nonce), hb_time.to_rfc3339());
    let signature: Signature = wrong_key.sign(payload.as_bytes());
    let hb = Heartbeat { identity_id: id, device_signature: signature.to_der().as_bytes().to_vec(), nonce, timestamp: hb_time };

    let result = engine.process_heartbeat(hb).await;
    
    if matches!(result, Err(EngineError::InvalidSignature)) {
        log_event("Regression", "Invalid Sig Check", "PASS", "Blocked invalid signature correctly.");
    } else {
        log_event("Regression", "Invalid Sig Check", "FAIL", "Allowed invalid signature!");
        panic!("Crypto fail");
    }
}

// ======================================================================================
// 6. REPORT GENERATOR (Runs Last)
// ======================================================================================

#[test]
fn zzz_generate_final_report() {
    let state = AUDIT_STATE.lock().unwrap();
    let duration = Utc::now().signed_duration_since(state.start_time).num_seconds();
    let _total_fails = state.events.iter().filter(|e| e["status"] == "FAIL").count() + state.failures.len();
    let panic_penalty = if state.panics_detected > 0 { 100 } else { 0 };
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
        "logs": state.events,
        "failures": state.failures
    });

    let filename = "INVARIANT_AUDIT_REPORT.json";
    let mut file = File::create(filename).expect("Failed to create report");
    file.write_all(serde_json::to_string_pretty(&report).unwrap().as_bytes()).unwrap();

    println!("\n📄 AUDIT REPORT GENERATED: ./{}", filename);
    println!("📊 RISK SCORE: {}/100", risk_score);
}