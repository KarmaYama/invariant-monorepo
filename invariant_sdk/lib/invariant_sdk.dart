// invariant_sdk/lib/invariant_sdk.dart
/*
 * Copyright (c) 2026 Invariant Protocol.
 *
 * This source code is licensed under the Business Source License (BSL 1.1) 
 * found in the LICENSE.md file in the root directory of this source tree.
 */

import 'dart:async';
import 'package:flutter/services.dart';
import 'src/api_client.dart';

/// The result of a device verification attempt.
class InvariantResult {
  final bool isVerified;
  final String? identityId;
  final String riskTier; // "PHYSICAL_TEE", "EMULATOR", "ROOTED", "SHADOW_PASS"
  final double? riskScore;

  InvariantResult({
    required this.isVerified,
    this.identityId,
    this.riskTier = "UNKNOWN",
    this.riskScore,
  });
}

class Invariant {
  static const MethodChannel _channel = MethodChannel('com.invariant.protocol/keystore');
  static late final ApiClient _client;
  static bool _initialized = false;
  
  // ⚡ SHADOW MODE TOGGLE
  static bool _isBlocking = true;

  /// Initialize the SDK.
  /// 
  /// [isBlocking]: If false, failed checks will still return `isVerified: true` (Shadow Mode).
  /// This allows you to audit traffic without breaking user flow.
  static void initialize({
    required String apiKey, 
    String? baseUrl,
    bool isBlocking = true, 
  }) {
    _client = ApiClient(apiKey: apiKey, baseUrl: baseUrl);
    _isBlocking = isBlocking;
    _initialized = true;
  }

  /// Verifies the device hardware against the Invariant Network.
  static Future<InvariantResult> verifyDevice() async {
    if (!_initialized) throw Exception("Invariant not initialized. Call Invariant.initialize() first.");

    try {
      // 1. Get Challenge (Fail-Open safe)
      final nonce = await _client.getChallenge();
      
      // ⚡ FAIL-OPEN LOGIC: Network Down?
      if (nonce == null) {
        return InvariantResult(
          isVerified: true, // Allow user proceed
          riskTier: "NETWORK_FAIL_OPEN"
        );
      }

      // 2. Hardware Attestation (Native Layer)
      final result = await _channel.invokeMethod('generateIdentity', {'nonce': nonce});
      
      final Map<Object?, Object?> data = result;
      final pkBytes = (data['publicKey'] as List).cast<int>();
      final chainBytes = (data['attestationChain'] as List).map((e) => (e as List).cast<int>()).toList();

      // 3. Verify on Server
      final verification = await _client.verify(pkBytes, chainBytes, nonce);
      
      // ⚡ FAIL-OPEN LOGIC: Server Error?
      if (verification == null) {
        return InvariantResult(
          isVerified: true, // Allow user proceed
          riskTier: "SERVER_FAIL_OPEN"
        );
      }

      // 4. SHADOW MODE LOGIC
      // If server rejected it, but we are in Shadow Mode, we return TRUE (Verified)
      // but mark the tier as Shadow so the backend logs it (handled by server-side analytics)
      if (verification['verified'] == true) {
        return InvariantResult(
          isVerified: true,
          identityId: verification['id'],
          riskTier: verification['tier'] ?? "PHYSICAL_TEE",
        );
      } else {
        // Device is Bad (Emulator/Rooted)
        if (!_isBlocking) {
          // SHADOW MODE: Allow it, but tag it.
          return InvariantResult(
            isVerified: true, 
            riskTier: "SHADOW_FLAGGED_${verification['tier']}"
          );
        }
        
        // BLOCKING MODE: Reject it.
        return InvariantResult(isVerified: false, riskTier: "REJECTED_BY_POLICY");
      }

    } on PlatformException {
      // Hardware failure (Emulator often throws here)
      if (!_isBlocking) return InvariantResult(isVerified: true, riskTier: "SHADOW_HARDWARE_FAIL");
      return InvariantResult(isVerified: false, riskTier: "HARDWARE_FAILURE");
    } catch (_) {
      // Unknown Error -> Fail Open
      return InvariantResult(isVerified: true, riskTier: "UNKNOWN_FAIL_OPEN");
    }
  }
}