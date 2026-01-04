/*
 * Copyright (c) 2026 Invariant Protocol.
 *
 * This source code is licensed under the Business Source License (BSL 1.1) 
 * found in the LICENSE.md file in the root directory of this source tree.
 * * You may NOT use this code for active blocking or enforcement without a commercial license.
 */

import 'dart:async';
import 'package:flutter/services.dart';
import 'src/api_client.dart'; // We will create this next

/// The result of a device verification attempt.
class InvariantResult {
  final bool isVerified;
  final String? identityId;
  final String riskTier; // "PHYSICAL_TEE", "EMULATOR", "ROOTED"
  final double? riskScore;

  InvariantResult({
    required this.isVerified,
    this.identityId,
    this.riskTier = "UNKNOWN",
    this.riskScore,
  });
}

class Invariant {
  // Matches the channel name defined in your Kotlin code later
  static const MethodChannel _channel = MethodChannel('com.invariant.protocol/keystore');
  static late final ApiClient _client;
  static bool _initialized = false;

  /// Initialize the SDK with your API Key.
  static void initialize({required String apiKey, String? baseUrl}) {
    _client = ApiClient(apiKey: apiKey, baseUrl: baseUrl);
    _initialized = true;
  }

  /// Verifies the device hardware against the Invariant Network.
  static Future<InvariantResult> verifyDevice() async {
    if (!_initialized) throw Exception("Invariant not initialized. Call Invariant.initialize() first.");

    try {
      // 1. Get Challenge from Server
      final nonce = await _client.getChallenge();
      if (nonce == null) return InvariantResult(isVerified: false, riskTier: "NETWORK_ERROR");

      // 2. Hardware Attestation (Native Layer)
      // This invokes the Kotlin code you wrote yesterday
      final result = await _channel.invokeMethod('generateIdentity', {'nonce': nonce});
      
      final Map<Object?, Object?> data = result;
      // Convert raw bytes to standard Lists
      final pkBytes = (data['publicKey'] as List).cast<int>();
      final chainBytes = (data['attestationChain'] as List).map((e) => (e as List).cast<int>()).toList();

      // 3. Verify on Invariant Cloud
      final verification = await _client.verify(pkBytes, chainBytes, nonce);
      
      if (verification != null) {
        return InvariantResult(
          isVerified: true,
          identityId: verification['id'],
          riskTier: verification['tier'] ?? "PHYSICAL_TEE",
        );
      } else {
         return InvariantResult(isVerified: false, riskTier: "REJECTED_BY_POLICY");
      }

    } on PlatformException {
      // Hardware failure usually means Emulator or Rooted device restricting TEE access
      return InvariantResult(isVerified: false, riskTier: "HARDWARE_FAILURE");
    } catch (_) {
      return InvariantResult(isVerified: false, riskTier: "UNKNOWN_ERROR");
    }
  }
}