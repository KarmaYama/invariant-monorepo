// invariant_sdk/lib/invariant_sdk.dart
library invariant_sdk;

import 'package:flutter/services.dart';
import 'package:invariant_sdk/src/api_client.dart';

/// The operational mode of the Invariant SDK.
enum InvariantMode {
  /// The SDK will return [InvariantDecision.deny] when verification fails.
  enforce,
  /// The SDK will return [InvariantDecision.allowShadow] when verification fails,
  /// allowing the user to proceed while logging the risk signal.
  shadow,
}

/// The authoritative decision from the Invariant Policy Engine.
enum InvariantDecision {
  /// The device is verified and trusted. Proceed with the protected action.
  allow,
  /// The device failed verification, but the SDK is in [InvariantMode.shadow].
  /// Proceed with the action but flag the transaction/session for review.
  allowShadow,
  /// The device failed verification and the SDK is in [InvariantMode.enforce].
  /// Block the action.
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

  /// Constructs the result from the Server API response.
  /// 
  /// [fallbackBrand], [fallbackModel], and [fallbackProduct] are populated from 
  /// the Android OS (Build.MODEL) if the TEE signature omits them.
  factory InvariantResult.fromServer(
    Map<String, dynamic> json, 
    InvariantMode mode,
    {String? fallbackBrand, String? fallbackModel, String? fallbackProduct}
  ) {
    // 1. Extract Core Signals
    final bool isVerified = json['verified'] ?? false;
    final String tier = json['tier'] ?? 'UNKNOWN';
    final double score = (json['risk_score'] as num?)?.toDouble() ?? 100.0;
    
    // 2. Extract Rich Hardware Manifest with Hybrid Fallback
    // If the server saw Hardware Attestation IDs, use them.
    // Otherwise, use the software metadata we grabbed from the OS.
    final String? brand = json['brand'] ?? fallbackBrand;
    final String? deviceModel = json['device_model'] ?? fallbackModel; 
    final String? product = json['product'] ?? fallbackProduct;
    
    final bool bootLocked = json['boot_locked'] ?? false;
    final String? error = json['error'];

    // 3. Derive Decision
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

  /// Initialize the Invariant SDK.
  static void initialize({
    required String apiKey,
    InvariantMode mode = InvariantMode.shadow,
    String? baseUrl,
  }) {
    _mode = mode;
    _client = ApiClient(apiKey: apiKey, baseUrl: baseUrl);
  }

  /// Performs a hardware-backed device verification ("Secure Tap").
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
        // Invokes Kotlin: generateIdentity(nonce)
        hardwareResult = await _channel.invokeMethod('generateIdentity', {'nonce': nonce});
      } on PlatformException catch (e) {
        return InvariantResult(
          decision: (_mode == InvariantMode.shadow) ? InvariantDecision.allowShadow : InvariantDecision.deny,
          tier: "SOFTWARE_ERROR",
          score: 100.0,
          reason: "Hardware Failure: ${e.message}",
        );
      }

      // 3. Construct Payload with REAL Hardware Data
      final payload = {
        "public_key": hardwareResult['publicKey'],         // List<int>
        "attestation_chain": hardwareResult['attestationChain'], // List<List<int>>
        "nonce": client.hexToBytes(nonce),
      };

      // 4. Verify with Node
      final resultData = await client.verify(payload);

      if (resultData != null) {
        // 🚀 HYBRID TRUST: Pass the software fallbacks to the factory
        return InvariantResult.fromServer(
          resultData, 
          _mode,
          fallbackBrand: hardwareResult['softwareBrand'],
          fallbackModel: hardwareResult['softwareModel'],
          fallbackProduct: hardwareResult['softwareProduct'],
        );
      } else {
        return InvariantResult.failOpen("Verification Service Error");
      }
    } catch (e) {
      return InvariantResult.failOpen("Client Error: ${e.toString()}");
    }
  }
}