// crates/invariant_engine/tests/attestation_tests.rs
/*
 * Copyright (c) 2026 Invariant Protocol.
 */

#[cfg(test)]
mod tests {
    use async_trait::async_trait;
    use chrono::{Utc, Duration};
    use std::collections::{HashMap, HashSet};
    use tokio::sync::RwLock;
    use uuid::Uuid;
    use p256::ecdsa::{SigningKey, signature::Signer};
    use rand_core::OsRng; 
    use p256::pkcs8::EncodePublicKey;

    use invariant_engine::{InvariantEngine, IdentityStorage, EngineError, attestation, core::EngineConfig};
    use invariant_engine::ports::NonceStorage; // 👈 NEW TRAIT IMPORT
    use invariant_shared::{Identity, IdentityStatus, Heartbeat, GenesisRequest, Network};

    // --- MOCK STORAGE IMPLEMENTATION (Postgres) ---
    #[derive(Default)]
    struct MockStorage {
        identities: RwLock<HashMap<Uuid, Identity>>,
        heartbeats: RwLock<Vec<Heartbeat>>,
    }

    #[async_trait]
    impl IdentityStorage for MockStorage {
        async fn get_identity(&self, id: &Uuid) -> Result<Option<Identity>, EngineError> {
            Ok(self.identities.read().await.get(id).cloned())
        }

        async fn get_identity_by_public_key(&self, pk: &[u8]) -> Result<Option<Identity>, EngineError> {
            let map = self.identities.read().await;
            for identity in map.values() {
                if identity.public_key == pk {
                    return Ok(Some(identity.clone()));
                }
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
        
        async fn set_username(&self, id: &Uuid, username: &str) -> Result<bool, EngineError> {
            let mut map = self.identities.write().await;
            // Check uniqueness
            for identity in map.values() {
                if let Some(existing) = &identity.username {
                    if existing == username { return Ok(false); }
                }
            }
            if let Some(id_ref) = map.get_mut(id) {
                if id_ref.username.is_some() { return Ok(false); }
                id_ref.username = Some(username.to_string());
                return Ok(true);
            }
            Ok(false)
        }

        async fn get_leaderboard(&self, limit: i64) -> Result<Vec<Identity>, EngineError> {
            let map = self.identities.read().await;
            let mut list: Vec<Identity> = map.values().cloned().collect();
            list.sort_by(|a, b| b.continuity_score.cmp(&a.continuity_score));
            Ok(list.into_iter().take(limit as usize).collect())
        }

        async fn update_fcm_token(&self, id: &Uuid, token: &str) -> Result<(), EngineError> {
            let mut map = self.identities.write().await;
            if let Some(id_ref) = map.get_mut(id) {
                id_ref.fcm_token = Some(token.to_string());
            }
            Ok(())
        }

        async fn get_late_fcm_tokens(&self, _minutes: i64) -> Result<Vec<String>, EngineError> {
            Ok(vec![])
        }
    }

    // --- MOCK NONCE STORAGE (Redis) ---
    #[derive(Default)]
    struct MockNonceStorage {
        used_nonces: RwLock<HashSet<Vec<u8>>>,
    }

    #[async_trait]
    impl NonceStorage for MockNonceStorage {
        async fn consume_nonce(&self, nonce: &[u8], _ttl: u64) -> Result<bool, EngineError> {
            let mut set = self.used_nonces.write().await;
            if set.contains(nonce) {
                return Ok(false); // Already used -> Replay Detected
            }
            set.insert(nonce.to_vec());
            Ok(true) // Fresh -> Consumed
        }
    }

    // --- HELPER: Manual DER Construction for Attestation Tests ---
    fn encode_test_extension(is_software: bool, challenge_bytes: &[u8]) -> Vec<u8> {
        fn tag(t: u8, content: &[u8]) -> Vec<u8> {
            let mut v = vec![t];
            if content.len() < 128 {
                v.push(content.len() as u8);
            } else {
                v.push(0x81);
                v.push(content.len() as u8);
            }
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

        // Tag 704 (RootOfTrust)
        let mut rot_content = Vec::new();
        rot_content.extend(octet(b"key"));
        rot_content.extend(bool_true()); // deviceLocked = true
        rot_content.extend(enum_val(0)); // verifiedBootState = Verified (0)
        rot_content.extend(octet(b"hash"));
        let rot_seq = seq(&rot_content);
        
        tee_items.push(0xBF); tee_items.push(0x85); tee_items.push(0x40);
        tee_items.push(rot_seq.len() as u8);
        tee_items.extend_from_slice(&rot_seq);

        // Tag 710: Brand
        let brand_oct = octet(b"Google");
        tee_items.push(0xBF); tee_items.push(0x85); tee_items.push(0x46);
        tee_items.push(brand_oct.len() as u8);
        tee_items.extend_from_slice(&brand_oct);

        // Tag 711: Device
        let dev_oct = octet(b"Pixel 7");
        tee_items.push(0xBF); tee_items.push(0x85); tee_items.push(0x47);
        tee_items.push(dev_oct.len() as u8);
        tee_items.extend_from_slice(&dev_oct);

        root_content.extend(seq(&tee_items));
        seq(&root_content)
    }

    // --- TESTS ---

    #[test]
    fn test_attestation_nonce_success() {
        let nonce = b"valid_nonce_123";
        let der_bytes = encode_test_extension(false, nonce);
        let result = attestation::verify_extension_and_extract(&der_bytes, Some(nonce));
        
        assert!(result.is_ok(), "Attestation failed: {:?}", result.err());
        let meta = result.unwrap();
        assert_eq!(meta.brand.as_deref(), Some("Google"));
        assert_eq!(meta.device.as_deref(), Some("Pixel 7"));
        assert!(meta.is_boot_locked);
    }

    #[test]
    fn test_attestation_nonce_mismatch() {
        let real_nonce = b"real_nonce";
        let fake_nonce = b"fake_nonce";
        let der_bytes = encode_test_extension(false, real_nonce);
        let result = attestation::verify_extension_and_extract(&der_bytes, Some(fake_nonce));
        assert!(result.is_err());
        match result {
            Err(EngineError::InvalidAttestation(msg)) => { assert!(msg.contains("Challenge mismatch"), "Error was: {}", msg); },
            _ => panic!("Expected Nonce Mismatch Error"),
        }
    }

    #[test]
    fn test_attestation_rejects_software_keys() {
        let nonce = b"nonce";
        let der_bytes = encode_test_extension(true, nonce);
        let result = attestation::verify_extension_and_extract(&der_bytes, Some(nonce));
        assert!(result.is_err());
        match result {
            Err(EngineError::InvalidAttestation(msg)) => { assert!(msg.contains("Software-backed"), "Error was: {}", msg); },
            _ => panic!("Expected Software Rejection Error"),
        }
    }

    #[tokio::test]
    async fn test_genesis_idempotency() {
        let storage = MockStorage::default();
        let nonce_storage = MockNonceStorage::default();
        let config = EngineConfig { network: Network::Testnet, genesis_version: 1 };
        let engine = InvariantEngine::new(storage, nonce_storage, config);
        
        let pk = vec![0xAA, 0xBB, 0xCC];
        let existing_id = Uuid::new_v4();

        let identity = Identity {
            id: existing_id,
            public_key: pk.clone(),
            continuity_score: 100,
            created_at: Utc::now(),
            last_heartbeat: Utc::now(),
            last_attestation: Utc::now(), // Fresh
            status: IdentityStatus::Active,
            username: None, streak: 10, is_genesis_eligible: true, fcm_token: None,
            hardware_brand: None, hardware_device: None, hardware_product: None,
            genesis_version: 1, network: Network::Testnet,
        };
        engine.get_storage().save_identity(&identity).await.unwrap();

        let request = GenesisRequest {
            public_key: pk,
            attestation_chain: vec![],
            nonce: vec![0x01, 0x02, 0x03], 
        };

        // Should return existing without checking chain
        let result = engine.process_genesis(request).await.expect("Should return existing");
        assert_eq!(result.id, existing_id);
    }

    #[tokio::test]
    async fn test_heartbeat_success() {
        let storage = MockStorage::default();
        let nonce_storage = MockNonceStorage::default();
        let config = EngineConfig { network: Network::Testnet, genesis_version: 1 };
        let engine = InvariantEngine::new(storage, nonce_storage, config);

        let id = Uuid::new_v4();
        let signing_key = SigningKey::random(&mut OsRng);
        let verifying_key = signing_key.verifying_key();
        let public_key_der = verifying_key.to_public_key_der().unwrap().as_bytes().to_vec();

        // Setup: Last heartbeat > 24h ago, Attestation fresh
        let identity = Identity {
            id,
            public_key: public_key_der,
            continuity_score: 1,
            created_at: Utc::now() - Duration::days(2),
            last_heartbeat: Utc::now() - Duration::hours(25),
            last_attestation: Utc::now(), 
            status: IdentityStatus::Active,
            username: None, is_genesis_eligible: true, fcm_token: None, streak: 0,
            hardware_brand: None, hardware_device: None, hardware_product: None,
            genesis_version: 1, network: Network::Testnet,
        };
        engine.get_storage().save_identity(&identity).await.unwrap();

        let hb_time = Utc::now();
        let nonce = vec![0xDE, 0xAD, 0xBE, 0xEF];
        
        // Format: ID | NONCE_HEX | TIMESTAMP_ISO
        let payload_str = format!("{}|{}|{}", id, hex::encode(&nonce), hb_time.to_rfc3339());
        let signature: p256::ecdsa::Signature = signing_key.sign(payload_str.as_bytes());
        
        let hb = Heartbeat {
            identity_id: id,
            device_signature: signature.to_der().as_bytes().to_vec(),
            nonce: nonce.clone(),
            timestamp: hb_time,
        };

        let score = engine.process_heartbeat(hb).await.expect("Valid heartbeat failed");
        assert_eq!(score, 2);
    }

    #[tokio::test]
    async fn test_heartbeat_rate_limit() {
        let storage = MockStorage::default();
        let nonce_storage = MockNonceStorage::default();
        let config = EngineConfig { network: Network::Testnet, genesis_version: 1 };
        let engine = InvariantEngine::new(storage, nonce_storage, config);

        let id = Uuid::new_v4();
        let now = Utc::now();

        // Setup: Heartbeat only 10 mins ago
        let identity = Identity {
            id,
            public_key: vec![],
            continuity_score: 1,
            created_at: now,
            last_heartbeat: now - chrono::Duration::minutes(10), 
            last_attestation: now, // Fresh attestation
            status: IdentityStatus::Active,
            username: None, is_genesis_eligible: true, fcm_token: None, streak: 0,
            hardware_brand: None, hardware_device: None, hardware_product: None,
            genesis_version: 1, network: Network::Testnet,
        };
        engine.get_storage().save_identity(&identity).await.unwrap();

        let hb = Heartbeat {
            identity_id: id,
            device_signature: vec![],
            nonce: vec![0x00],
            timestamp: now,
        };

        match engine.process_heartbeat(hb).await {
            Err(EngineError::RateLimitExceeded) => (),
            _ => panic!("Expected Rate Limit Error"),
        }
    }

    #[tokio::test]
    async fn test_heartbeat_revoked_identity() {
        let storage = MockStorage::default();
        let nonce_storage = MockNonceStorage::default();
        let config = EngineConfig { network: Network::Testnet, genesis_version: 1 };
        let engine = InvariantEngine::new(storage, nonce_storage, config);

        let id = Uuid::new_v4();

        let identity = Identity {
            id,
            public_key: vec![],
            continuity_score: 10,
            created_at: Utc::now(),
            last_heartbeat: Utc::now() - chrono::Duration::hours(6),
            last_attestation: Utc::now(),
            status: IdentityStatus::Revoked, // Revoked
            username: None, is_genesis_eligible: true, fcm_token: None, streak: 0, 
            hardware_brand: None, hardware_device: None, hardware_product: None,
            genesis_version: 1, network: Network::Testnet,
        };
        engine.get_storage().save_identity(&identity).await.unwrap();

        let hb = Heartbeat {
            identity_id: id,
            device_signature: vec![],
            nonce: vec![0x00],
            timestamp: Utc::now(),
        };

        let result = engine.process_heartbeat(hb).await;
        match result {
            Err(EngineError::Storage(msg)) => assert_eq!(msg, "Identity is Revoked"),
            _ => panic!("Expected Revoked Error, got {:?}", result),
        }
    }

    #[tokio::test]
    async fn test_heartbeat_trust_decay() {
        let storage = MockStorage::default();
        let nonce_storage = MockNonceStorage::default();
        let config = EngineConfig { network: Network::Testnet, genesis_version: 1 };
        let engine = InvariantEngine::new(storage, nonce_storage, config);

        let id = Uuid::new_v4();
        let now = Utc::now();

        // 🛡️ Setup: Identity attested 8 days ago (> 7 Day TTL)
        let identity = Identity {
            id,
            public_key: vec![],
            continuity_score: 10,
            created_at: now - Duration::days(10),
            last_heartbeat: now - Duration::days(1),
            last_attestation: now - Duration::days(8), // EXPIRED
            status: IdentityStatus::Active,
            username: None, is_genesis_eligible: true, fcm_token: None, streak: 5,
            hardware_brand: None, hardware_device: None, hardware_product: None,
            genesis_version: 1, network: Network::Testnet,
        };
        engine.get_storage().save_identity(&identity).await.unwrap();

        let hb = Heartbeat {
            identity_id: id,
            device_signature: vec![],
            nonce: vec![0x99], // Fresh nonce
            timestamp: now,
        };

        // Expect Rejection: AttestationRequired (before Crypto Check)
        match engine.process_heartbeat(hb).await {
            Err(EngineError::AttestationRequired) => (),
            res => panic!("Expected Trust Decay Error, got {:?}", res),
        }
    }

    #[tokio::test]
    async fn test_heartbeat_replay_protection() {
        let storage = MockStorage::default();
        let nonce_storage = MockNonceStorage::default();
        let config = EngineConfig { network: Network::Testnet, genesis_version: 1 };
        let engine = InvariantEngine::new(storage, nonce_storage, config);

        let id = Uuid::new_v4();
        let now = Utc::now();

        let identity = Identity {
            id,
            public_key: vec![],
            continuity_score: 1,
            created_at: now,
            last_heartbeat: now - Duration::days(2),
            last_attestation: now,
            status: IdentityStatus::Active,
            username: None, is_genesis_eligible: true, fcm_token: None, streak: 0,
            hardware_brand: None, hardware_device: None, hardware_product: None,
            genesis_version: 1, network: Network::Testnet,
        };
        engine.get_storage().save_identity(&identity).await.unwrap();

        let nonce = vec![0x12, 0x34];
        let hb = Heartbeat {
            identity_id: id,
            device_signature: vec![],
            nonce: nonce.clone(),
            timestamp: now,
        };

        // 1. First attempt: Consumes nonce.
        // Fails at Crypto (InvalidSignature) because we didn't sign it.
        // BUT the nonce should be marked used.
        let _ = engine.process_heartbeat(hb.clone()).await; 

        // 2. Second attempt: SAME NONCE
        // Should fail at Nonce Check immediately (ReplayDetected).
        match engine.process_heartbeat(hb).await {
            Err(EngineError::ReplayDetected) => (),
            res => panic!("Expected ReplayDetected, got {:?}", res),
        }
    }

    #[tokio::test]
    async fn test_heartbeat_invalid_signature() {
        let storage = MockStorage::default();
        let nonce_storage = MockNonceStorage::default();
        let config = EngineConfig { network: Network::Testnet, genesis_version: 1 };
        let engine = InvariantEngine::new(storage, nonce_storage, config);

        let id = Uuid::new_v4();
        let signing_key = SigningKey::random(&mut OsRng); 
        let verifying_key = signing_key.verifying_key();
        let public_key_der = verifying_key.to_public_key_der().unwrap().as_bytes().to_vec();

        let wrong_key = SigningKey::random(&mut OsRng); 

        // Setup: Fresh attestation, Old heartbeat (so rate limit passes)
        let identity = Identity {
            id,
            public_key: public_key_der,
            continuity_score: 1,
            created_at: Utc::now(),
            last_heartbeat: Utc::now() - chrono::Duration::hours(25), 
            last_attestation: Utc::now(), 
            status: IdentityStatus::Active,
            username: None, is_genesis_eligible: true, fcm_token: None, streak: 0,
            hardware_brand: None, hardware_device: None, hardware_product: None,
            genesis_version: 1, network: Network::Testnet,
        };
        engine.get_storage().save_identity(&identity).await.unwrap();

        let hb_time = Utc::now();
        let nonce = vec![0x01];
        let payload_str = format!("{}|{}|{}", id, hex::encode(&nonce), hb_time.to_rfc3339());
        let signature: p256::ecdsa::Signature = wrong_key.sign(payload_str.as_bytes());

        let hb = Heartbeat {
            identity_id: id,
            device_signature: signature.to_der().as_bytes().to_vec(),
            nonce: nonce,
            timestamp: hb_time,
        };

        let result = engine.process_heartbeat(hb).await;
        assert!(matches!(result, Err(EngineError::InvalidSignature)));
    }
}