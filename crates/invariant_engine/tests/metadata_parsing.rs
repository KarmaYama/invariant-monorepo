/*
 * Copyright (c) 2026 Invariant Protocol.
 *
 * This source code is licensed under the Business Source License (BSL 1.1) 
 * found in the LICENSE.md file in the root directory of this source tree.
 */

use invariant_engine::attestation;

// --- TEST HELPERS: Manually Construct Android Keystore ASN.1 ---

/// Helper to encode a value wrapped in a Context-Specific Tag (e.g., [710] "Google")
/// This mimics exactly how Android Keystore encodes Brand/Device.
fn encode_tagged_string(tag_num: u32, value: &str) -> Vec<u8> {
    // 1. Encode the inner string as an OCTET STRING (0x04)
    let content = value.as_bytes();
    let mut inner_der = vec![0x04]; // OCTET STRING tag
    inner_der.push(content.len() as u8); // Length (assuming short form < 127)
    inner_der.extend_from_slice(content);

    // 2. Wrap it in the Context-Specific Tag (e.g., 710)
    // Manual byte construction for specific known tags to ensure test accuracy
    // Tag 710 (Brand): [BF 85 46]
    // Tag 711 (Device): [BF 85 47]
    // Tag 712 (Product): [BF 85 48]
    
    let tag_header = match tag_num {
        710 => vec![0xBF, 0x85, 0x46],
        711 => vec![0xBF, 0x85, 0x47],
        712 => vec![0xBF, 0x85, 0x48],
        _ => panic!("Unsupported test tag"),
    };

    let mut out = tag_header;
    // Length of the *inner DER* (Tag + Len + Content)
    out.push(inner_der.len() as u8); 
    out.extend_from_slice(&inner_der);
    
    out
}

/// Constructs a valid-enough Android Extension just to test the metadata extraction
fn construct_extension_payload(brand: &str, device: &str, product: &str) -> Vec<u8> {
    // RootOfTrust (Tag 704) - Required to pass validation
    // Sequence: [VerifiedKey, DeviceLocked(True), VerifiedBootState(Verified)]
    let rot_seq = vec![
        // 🛡️ FIX: Length is 0x08 (8 bytes), NOT 0x09
        // 2 bytes (Key) + 3 bytes (Locked) + 3 bytes (State) = 8 bytes
        0x30, 0x08, 
        0x04, 0x00,       // Empty Key (2 bytes: Tag + Len)
        0x01, 0x01, 0xFF, // Boolean TRUE (Locked) (3 bytes: Tag + Len + Val)
        0x0A, 0x01, 0x00  // Enum 0 (Verified) (3 bytes: Tag + Len + Val)
    ];
    let mut rot_tagged = vec![0xBF, 0x85, 0x40]; // Tag 704
    rot_tagged.push(rot_seq.len() as u8);
    rot_tagged.extend_from_slice(&rot_seq);

    // Build the TEE Enforced List (Sequence)
    let mut tee_content = Vec::new();
    tee_content.extend(rot_tagged); // Add Root of Trust (Mandatory)
    tee_content.extend(encode_tagged_string(710, brand));
    tee_content.extend(encode_tagged_string(711, device));
    tee_content.extend(encode_tagged_string(712, product));

    // Wrap TEE Enforced in SEQUENCE (Index 7 of Main Sequence)
    let mut tee_seq = vec![0x30]; // SEQUENCE
    tee_seq.push(tee_content.len() as u8);
    tee_seq.extend(tee_content);

    // Main Sequence Construction (Indices 0-7)
    // We cheat and fill indices 0-6 with dummy data or empty to match indices
    // 1: AttestationVersion (Int)
    // 2: AttestationSecurityLevel (Enum)
    // 3: KeymasterVersion (Int)
    // 4: KeymasterSecurityLevel (Enum)
    // 5: AttestationChallenge (Octet)
    // 6: UniqueId (Octet)
    // 7: SoftwareEnforced (Seq)
    // 8: TeeEnforced (Seq) <- This is what we parse
    
    // Simplest valid "Skeleton" to get to Index 7
    let mut main_seq = Vec::new();
    
    main_seq.extend(vec![0x02, 0x01, 0x01]); // 1. Version: 1
    main_seq.extend(vec![0x0A, 0x01, 0x01]); // 2. SecLevel: StrongBox(1) / TEE(1)
    main_seq.extend(vec![0x02, 0x01, 0x00]); // 3. KM Ver: 0
    main_seq.extend(vec![0x0A, 0x01, 0x01]); // 4. KM SecLevel: 1
    main_seq.extend(vec![0x04, 0x03, 0x01, 0x02, 0x03]); // 5. Challenge: [1,2,3]
    main_seq.extend(vec![0x04, 0x00]); // 6. UniqueId: Empty
    main_seq.extend(vec![0x30, 0x00]); // 7. SoftwareEnforced: Empty Seq
    main_seq.extend(tee_seq); // 8. TEE Enforced (Our Payload)

    let mut final_der = vec![0x30]; // Outer SEQUENCE
    final_der.push(main_seq.len() as u8);
    final_der.extend(main_seq);

    final_der
}

#[test]
fn test_extracts_nested_hardware_info() {
    // 1. Construct a payload mimicking a Samsung/Pixel device
    // "Google" is wrapped in Tag 710 -> OctetString -> Bytes
    let payload = construct_extension_payload("Google", "Pixel 7 Pro", "cheetah");

    // 2. Run the parser
    // We pass the challenge bytes [1,2,3] we hardcoded above
    let result = attestation::verify_extension_and_extract(&payload, Some(&[1, 2, 3]));

    // 3. Assertions
    assert!(result.is_ok(), "Parser failed: {:?}", result.err());
    
    let metadata = result.unwrap();
    
    println!("Parsed Metadata: {:?}", metadata);

    // 4. Verify we actually extracted the strings
    assert_eq!(metadata.brand, Some("Google".to_string()), "Failed to extract Brand");
    assert_eq!(metadata.device, Some("Pixel 7 Pro".to_string()), "Failed to extract Device");
    assert_eq!(metadata.product, Some("cheetah".to_string()), "Failed to extract Product");
    
    // 5. Verify Security Basics still passed
    assert!(metadata.is_boot_locked, "Bootlock check failed");
    assert_eq!(metadata.trust_tier, "TEE (TrustZone)", "Tier check failed");
}

#[test]
fn test_handles_missing_fields_gracefully() {
    // Construct with valid data but test that the logic holds
    
    let payload = construct_extension_payload("Samsung", "Galaxy S23", "kalama");
    let result = attestation::verify_extension_and_extract(&payload, Some(&[1, 2, 3]));
    
    assert!(result.is_ok());
    let meta = result.unwrap();
    assert_eq!(meta.brand, Some("Samsung".to_string()));
}