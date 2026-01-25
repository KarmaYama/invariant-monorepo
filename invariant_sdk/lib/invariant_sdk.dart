// invariant_sdk/lib/invariant_sdk.dart
library invariant_sdk;

import 'package:flutter/services.dart'; // Required for MethodChannel
import 'package:invariant_sdk/src/api_client.dart';

/// The operational mode of the Invariant SDK.
enum InvariantMode {
  enforce,
  shadow,
}

/// The authoritative decision from the Invariant Policy Engine.
enum InvariantDecision {
  allow,
  allowShadow,
  deny,
}

/// The result of a hardware attestation check.
class InvariantResult {
  final InvariantDecision decision;
  final String tier;
  final double score;
  final String? brand;
  final String? deviceModel;
  final String? product;
  final bool bootLocked;
  final String? reason;

  const InvariantResult({
    required this.decision,
    required this.tier,
    required this.score,
    this.brand,
    this.deviceModel,
    this.product,
    this.bootLocked = false,
    this.reason,
  });

  bool get isVerified => decision == InvariantDecision.allow;

  factory InvariantResult.fromJson(Map<String, dynamic> json, InvariantMode mode) {
    final bool isVerified = json['verified'] ?? false;
    final String tier = json['tier'] ?? 'UNKNOWN';
    final double score = (json['risk_score'] as num?)?.toDouble() ?? 100.0;
    
    final String? brand = json['brand'];
    final String? deviceModel = json['device_model']; 
    final String? product = json['product'];
    final bool bootLocked = json['boot_locked'] ?? false;
    final String? error = json['error'];

    InvariantDecision decision;
    if (isVerified) {
      decision = InvariantDecision.allow;
    } else {
      decision = (mode == InvariantMode.shadow) 
          ? InvariantDecision.allowShadow 
          : InvariantDecision.deny;
    }

    return InvariantResult(
      decision: decision,
      tier: tier,
      score: score,
      brand: brand,
      deviceModel: deviceModel,
      product: product,
      bootLocked: bootLocked,
      reason: error,
    );
  }

  factory InvariantResult.failOpen(String reason) {
    return InvariantResult(
      decision: InvariantDecision.allow,
      tier: "UNVERIFIED_TRANSIENT",
      score: 0.0, 
      reason: reason,
    );
  }
}

class Invariant {
  static ApiClient? _client;
  static InvariantMode _mode = InvariantMode.shadow;
  
  // ⚡ REAL HARDWARE CHANNEL
  static const MethodChannel _channel = MethodChannel('com.invariant.protocol/keystore');

  static void initialize({
    required String apiKey,
    InvariantMode mode = InvariantMode.shadow,
    String? baseUrl,
  }) {
    _mode = mode;
    _client = ApiClient(apiKey: apiKey, baseUrl: baseUrl);
  }

  static Future<InvariantResult> verifyDevice() async {
    try {
      final client = _client;
      if (client == null) {
        return const InvariantResult(
          decision: InvariantDecision.deny, 
          tier: "SDK_INTERNAL_ERROR", 
          score: 100.0,
          reason: "SDK not initialized. Call Invariant.initialize() first.",
        );
      }

      // 1. Get Challenge (Nonce)
      final nonce = await client.getChallenge();
      if (nonce == null) {
        return InvariantResult.failOpen("Upstream Unavailable: Challenge Failed");
      }

      // 2. Hardware Signature (Native Call)
      Map<dynamic, dynamic> hardwareResult;
      try {
        // 🚀 CRITICAL: Invoking the Kotlin code here
        hardwareResult = await _channel.invokeMethod('generateIdentity', {'nonce': nonce});
      } on PlatformException catch (e) {
        // Handle specific hardware errors (e.g. Device not secure)
        return InvariantResult(
          decision: (_mode == InvariantMode.shadow) ? InvariantDecision.allowShadow : InvariantDecision.deny,
          tier: "SOFTWARE_ERROR",
          score: 100.0,
          reason: "Hardware Failure: ${e.message}",
        );
      }

      // 3. Construct Payload with REAL Hardware Data
      final payload = {
        "public_key": hardwareResult['publicKey'],         // List<int> from Kotlin
        "attestation_chain": hardwareResult['attestationChain'], // List<List<int>> from Kotlin
        "nonce": client.hexToBytes(nonce),
      };

      // 4. Verify with Node
      final resultData = await client.verify(payload);

      if (resultData != null) {
        return InvariantResult.fromJson(resultData, _mode);
      } else {
        return InvariantResult.failOpen("Verification Service Error");
      }
    } catch (e) {
      return InvariantResult.failOpen("Client Error: ${e.toString()}");
    }
  }
}