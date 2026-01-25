// crates/invariant_engine/src/attestation.rs
/*
 * Copyright (c) 2026 Invariant Protocol.
 *
 * This source code is licensed under the Business Source License (BSL 1.1) 
 * found in the LICENSE.md file in the root directory of this source tree.
 */

use x509_parser::prelude::*;
use crate::error::EngineError;
use base64::{Engine as _, engine::general_purpose};
use der_parser::der::*;
use der_parser::ber::BerObjectContent; 
use p256::pkcs8::DecodePublicKey;
use p256::ecdsa::VerifyingKey;
use std::str;

/// OID for Android Key Attestation Extension (1.3.6.1.4.1.11129.2.1.17)
const ANDROID_ATTESTATION_OID: &str = "1.3.6.1.4.1.11129.2.1.17";

// --- TAG CONSTANTS FOR ASN.1 PARSING ---
// Security Tags
const KM_TAG_NO_AUTH_REQUIRED: u32 = 503;
const KM_TAG_ROOT_OF_TRUST: u32 = 704;

// Metadata Tags
const KM_TAG_ATTESTATION_ID_BRAND: u32 = 710;
const KM_TAG_ATTESTATION_ID_DEVICE: u32 = 711;
const KM_TAG_ATTESTATION_ID_PRODUCT: u32 = 712;
const KM_TAG_ATTESTATION_ID_MANUFACTURER: u32 = 716; // Fixed: 716 is Manufacturer
const KM_TAG_ATTESTATION_ID_MODEL: u32 = 717;        // Fixed: 717 is Model

// --- Google Hardware Root (Pinned) ---
const GOOGLE_HARDWARE_ROOT_PEM: &str = r#"
-----BEGIN CERTIFICATE-----
MIIFHDCCAwSgAwIBAgIJAPHBcqaZ6vUdMA0GCSqGSIb3DQEBCwUAMBsxGTAXBgNV
BAUTEGY5MjAwOWU4NTNiNmIwNDUwHhcNMjIwMzIwMTgwNzQ4WhcNNDIwMzE1MTgw
NzQ4WjAbMRkwFwYDVQQFExBmOTIwMDllODUzYjZiMDQ1MIICIjANBgkqhkiG9w0B
AQEFAAOCAg8AMIICCgKCAgEAr7bHgiuxpwHsK7Qui8xUFmOr75gvMsd/dTEDDJdS
Sxtf6An7xyqpRR90PL2abxM1dEqlXnf2tqw1Ne4Xwl5jlRfdnJLmN0pTy/4lj4/7
tv0Sk3iiKkypnEUtR6WfMgH0QZfKHM1+di+y9TFRtv6y//0rb+T+W8a9nsNL/ggj
nar86461qO0rOs2cXjp3kOG1FEJ5MVmFmBGtnrKpa73XpXyTqRxB/M0n1n/W9nGq
C4FSYa04T6N5RIZGBN2z2MT5IKGbFlbC8UrW0DxW7AYImQQcHtGl/m00QLVWutHQ
oVJYnFPlXTcHYvASLu+RhhsbDmxMgJJ0mcDpvsC4PjvB+TxywElgS70vE0XmLD+O
JtvsBslHZvPBKCOdT0MS+tgSOIfga+z1Z1g7+DVagf7quvmag8jfPioyKvxnK/Eg
sTUVi2ghzq8wm27ud/mIM7AY2qEORR8Go3TVB4HzWQgpZrt3i5MIlCaY504LzSRi
igHCzAPlHws+W0rB5N+er5/2pJKnfBSDiCiFAVtCLOZ7gLiMm0jhO2B6tUXHI/+M
RPjy02i59lINMRRev56GKtcd9qO/0kUJWdZTdA2XoS82ixPvZtXQpUpuL12ab+9E
aDK8Z4RHJYYfCT3Q5vNAXaiWQ+8PTWm2QgBR/bkwSWc+NpUFgNPN9PvQi8WEg5Um
AGMCAwEAAaNjMGEwHQYDVR0OBBYEFDZh4QB8iAUJUYtEbEf/GkzJ6k8SMB8GA1Ud
IwQYMBaAFDZh4QB8iAUJUYtEbEf/GkzJ6k8SMA8GA1UdEwEB/wQFMAMBAf8wDgYD
VR0PAQH/BAQDAgIEMA0GCSqGSIb3DQEBCwUAA4ICAQB8cMqTllHc8U+qCrOlg3H7
174lmaCsbo/bJ0C17JEgMLb4kvrqsXZs01U3mB/qABg/1t5Pd5AORHARs1hhqGIC
W/nKMav574f9rZN4PC2ZlufGXb7sIdJpGiO9ctRhiLuYuly10JccUZGEHpHSYM2G
tkgYbZba6lsCPYAAP83cyDV+1aOkTf1RCp/lM0PKvmxYN10RYsK631jrleGdcdkx
oSK//mSQbgcWnmAEZrzHoF1/0gso1HZgIn0YLzVhLSA/iXCX4QT2h3J5z3znluKG
1nv8NQdxei2DIIhASWfu804CA96cQKTTlaae2fweqXjdN1/v2nqOhngNyz1361mF
mr4XmaKH/ItTwOe72NI9ZcwS1lVaCvsIkTDCEXdm9rCNPAY10iTunIHFXRh+7KPz
lHGewCq/8TOohBRn0/NNfh7uRslOSZ/xKbN9tMBtw37Z8d2vvnXq/YWdsm1+JLVw
n6yYD/yacNJBlwpddla8eaVMjsF6nBnIgQOf9zKSe06nSTqvgwUHosgOECZJZ1Eu
zbH4yswbt02tKtKEFhx+v+OTge/06V+jGsqTWLsfrOCNLuA8H++z+pUENmpqnnHo
vaI47gC+TNpkgYGkkBT6B/m/U01BuOBBTzhIlMEZq9qkDWuM2cA5kW5V3FJUcfHn
w1IdYIg2Wxg7yHcQZemFQg==
-----END CERTIFICATE-----
"#;

#[derive(Debug, Default)]
pub struct AttestationMetadata {
    pub brand: Option<String>,
    pub device: Option<String>,
    pub product: Option<String>,
    pub trust_tier: String, 
    pub is_user_presence_required: bool,
    pub is_boot_locked: bool,
}

pub fn validate_attestation_chain(
    chain: &[Vec<u8>], 
    expected_public_key: &[u8],
    expected_challenge: Option<&[u8]>
) -> Result<AttestationMetadata, EngineError> {
    
    // 1. Basic Chain Check
    if chain.len() < 2 {
        return Err(EngineError::InvalidAttestation("Chain length too short".into()));
    }

    // 2. Parse Leaf (The Key Certificate)
    let (_, leaf_cert) = X509Certificate::from_der(&chain[0])
        .map_err(|e| EngineError::InvalidAttestation(format!("Leaf Parse Error: {}", e)))?;

    // 3. Verify Identity Binding
    let cert_spki = leaf_cert.tbs_certificate.subject_pki.raw;
    if !keys_equal(cert_spki, expected_public_key) {
        return Err(EngineError::InvalidAttestation("Public Key mismatch. Certificate does not match the key.".into()));
    }

    // 4. Extract & Verify Extension
    let oid_str = ANDROID_ATTESTATION_OID;
    let extension = leaf_cert.extensions().iter()
        .find(|ext| format!("{}", ext.oid) == oid_str)
        .ok_or(EngineError::InvalidAttestation("Missing Android Attestation Extension".into()))?;

    let metadata = verify_extension_and_extract(extension.value, expected_challenge)?;

    // 5. Verify Signatures up the Chain
    for i in 0..chain.len() - 1 {
        let child_der = &chain[i];
        let parent_der = &chain[i+1];
        
        let (_, child) = X509Certificate::from_der(child_der)
             .map_err(|_| EngineError::InvalidAttestation(format!("Cert Parse Error at {}", i)))?;
        let (_, parent) = X509Certificate::from_der(parent_der)
             .map_err(|_| EngineError::InvalidAttestation(format!("Cert Parse Error at {}", i+1)))?;
        
        child.verify_signature(Some(parent.public_key()))
            .map_err(|_| EngineError::InvalidAttestation(format!("Chain signature broken at depth {}", i)))?;
    }

    // 6. Verify Root against Google Hardware Root
    let root_der = chain.last().ok_or(EngineError::InvalidAttestation("Empty chain".into()))?;
    let (_, root_cert) = X509Certificate::from_der(root_der)
        .map_err(|_| EngineError::InvalidAttestation("Root Parse Error".into()))?;

    verify_google_root(&root_cert)?;
    
    Ok(metadata)
}

pub fn verify_extension_and_extract(
    extension_value: &[u8],
    expected_challenge: Option<&[u8]>
) -> Result<AttestationMetadata, EngineError> {
    
    let (_rem, sequence) = parse_der_sequence(extension_value)
        .map_err(|e| EngineError::InvalidAttestation(format!("ASN.1 Header Error: {:?}", e)))?;

    let items: Vec<DerObject> = sequence.as_sequence()
        .map_err(|_| EngineError::InvalidAttestation("Not a sequence".into()))?
        .iter().cloned().collect();

    if items.len() < 7 {
        return Err(EngineError::InvalidAttestation("Extension sequence too short".into()));
    }

    // A. Verify Security Level (Index 1)
    let att_sec_level = items[1].as_u32().map_err(|_| EngineError::InvalidAttestation("Invalid SecurityLevel".into()))?;
    
    let tier_name = match att_sec_level {
        1 => "TEE (TrustZone)",
        2 => "StrongBox (SE)",
        _ => return Err(EngineError::InvalidAttestation("REJECTED: Software-backed key.".into()))
    };

    // B. Verify Challenge (Index 4)
    let challenge_obj = &items[4];
    let actual_challenge = challenge_obj.as_slice()
        .map_err(|_| EngineError::InvalidAttestation("Challenge is not OctetString".into()))?;

    if let Some(expected) = expected_challenge {
        if actual_challenge != expected {
             return Err(EngineError::InvalidAttestation("Challenge mismatch".into()));
        }
    }

    // C. Verify TEE Enforced Authorization List (Index 7)
    let tee_enforced_obj = &items[7];
    let tee_enforced_list = tee_enforced_obj.as_sequence()
        .map_err(|_| EngineError::InvalidAttestation("teeEnforced is not a sequence".into()))?;

    let mut has_root_of_trust = false;
    let mut is_boot_locked = false;
    let mut is_verified_boot = false;
    let mut no_auth_required = false;
    
    let mut brand: Option<String> = None;
    let mut device: Option<String> = None;
    let mut product: Option<String> = None;

    for item in tee_enforced_list {
        let tag = item.header.tag().0;

        // Security Checks
        if tag == KM_TAG_ROOT_OF_TRUST {
            has_root_of_trust = true;
            if let Ok(content_bytes) = item.as_slice() {
                // Parse inner SEQUENCE
                if let Ok((_, rot_seq_obj)) = parse_der_sequence(content_bytes) {
                    if let Ok(seq) = rot_seq_obj.as_sequence() {
                         // 0: verifiedBootKey, 1: deviceLocked, 2: verifiedBootState
                        if seq.len() >= 3 {
                            if let Ok(locked) = seq[1].as_bool() { is_boot_locked = locked; }
                            if let Ok(state) = seq[2].as_u32() { 
                                // 0 = Verified, 1 = SelfSigned
                                if state == 0 { is_verified_boot = true; } 
                            }
                        }
                    }
                }
            }
        }
        
        if tag == KM_TAG_NO_AUTH_REQUIRED { no_auth_required = true; }

        // Metadata Extraction
        // 🚀 FIXED: Robust extraction logic that handles implicit tagging
        if tag == KM_TAG_ATTESTATION_ID_BRAND { brand = extract_string(item); }
        if tag == KM_TAG_ATTESTATION_ID_DEVICE { device = extract_string(item); }
        if tag == KM_TAG_ATTESTATION_ID_PRODUCT { product = extract_string(item); }
        
        // Fallbacks for Samsung/OEM variations
        if tag == KM_TAG_ATTESTATION_ID_MANUFACTURER && brand.is_none() { brand = extract_string(item); }
        if tag == KM_TAG_ATTESTATION_ID_MODEL && device.is_none() { device = extract_string(item); }
    }

    // Security Enforcements
    if !has_root_of_trust { return Err(EngineError::InvalidAttestation("Missing Root of Trust".into())); }
    if !is_boot_locked { return Err(EngineError::InvalidAttestation("Bootloader Unlocked".into())); }
    if !is_verified_boot { return Err(EngineError::InvalidAttestation("OS Integrity Failed".into())); }
    if no_auth_required { return Err(EngineError::InvalidAttestation("User Presence Check Failed".into())); }

    let metadata = AttestationMetadata {
        brand,
        device,
        product,
        trust_tier: tier_name.to_string(),
        is_user_presence_required: !no_auth_required,
        is_boot_locked,
    };
    
    Ok(metadata)
}

// 🚀 ROBUST STRING EXTRACTOR
// Recursively peels ContextSpecific tags to find the inner OCTET STRING
fn extract_string(item: &DerObject) -> Option<String> {
    // 1. Direct match (e.g. it's already an OctetString)
    if let BerObjectContent::OctetString(bytes) = &item.content {
        return String::from_utf8(bytes.to_vec()).ok();
    }
    
    // 2. Direct match (UTF8String - rare but possible in some HALs)
    if let BerObjectContent::UTF8String(s) = &item.content {
        return Some(s.to_string());
    }

    // 3. Implicitly Tagged (ContextSpecific)
    // The parser wrapper often hides the inner content as raw bytes.
    // We try to re-parse those raw bytes as an OctetString.
    if let BerObjectContent::Unknown(_class, _tag, bytes) = &item.content {
         // Try parsing inner content as OCTET STRING
        if let Ok((_, inner_obj)) = parse_der_octetstring(bytes) {
            if let BerObjectContent::OctetString(inner_bytes) = &inner_obj.content {
                return String::from_utf8(inner_bytes.to_vec()).ok();
            }
        }
        // Try parsing inner content as UTF8 STRING
        if let Ok((_, inner_obj)) = parse_der_utf8string(bytes) {
            if let BerObjectContent::UTF8String(s) = &inner_obj.content {
                return Some(s.to_string());
            }
        }
    }

    // 4. Explicitly Tagged (ContextSpecific)
    // If we have a nested object available
    if let BerObjectContent::ContextSpecific(_tag, opt_inner) = &item.content {
        if let Some(inner) = opt_inner {
            return extract_string(inner); // Recurse
        }
    }
    
    None
}

fn verify_google_root(root: &X509Certificate) -> Result<(), EngineError> {
    let actual_spki = root.tbs_certificate.subject_pki.raw;
    let pem = GOOGLE_HARDWARE_ROOT_PEM.trim();
    let pem_lines: String = pem.lines().filter(|l| !l.starts_with("-----")).collect();
    let expected_der = general_purpose::STANDARD.decode(&pem_lines)
        .map_err(|_| EngineError::InvalidAttestation("PEM Decode Error".into()))?;
    let (_, expected_cert) = X509Certificate::from_der(&expected_der)
        .map_err(|_| EngineError::InvalidAttestation("Google Root Parse Error".into()))?;
    if actual_spki != expected_cert.tbs_certificate.subject_pki.raw {
        return Err(EngineError::InvalidAttestation("Root of Trust Mismatch".into()));
    }
    Ok(())
}

fn keys_equal(a: &[u8], b: &[u8]) -> bool {
    if a == b { return true; }
    let key_a = VerifyingKey::from_public_key_der(a).ok();
    let key_b = VerifyingKey::from_public_key_der(b).or_else(|_| VerifyingKey::from_sec1_bytes(b)).ok();
    match (key_a, key_b) { (Some(ka), Some(kb)) => ka == kb, _ => false }
}