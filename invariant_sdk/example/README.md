# Invariant SDK

**Stop Automated Identity Abuse at the Hardware Layer.**

The Invariant SDK provides a cryptographic interface to the Android Keystore and StrongBox Secure Element. It allows mobile applications to verify that a client is a physical, uncompromised device—not an emulator, server farm, or scripted bot.

## ⚡ Key Features

- **Hardware Attestation:** Deterministic proof that a key lives in the device's Trusted Execution Environment (TEE).
- **Sybil Resistance:** Elevates the marginal cost of fake account creation from $0.00 to the cost of a physical smartphone.
- **Zero PII:** No biometrics, phone numbers, or emails are collected. We verify the *silicon*, not the *user*.
- **Shadow Mode:** Audit your traffic quality silently before enforcing security policies.

## 🚀 Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  invariant_sdk: ^1.0.4

```

## 🛠️ Quick Start

### 1. Initialize the SDK

Initialize the SDK once at the root of your application.

```dart
import 'package:invariant_sdk/invariant_sdk.dart';

void main() {
  // During pilot, use the demo key
  Invariant.initialize(
    apiKey: "sk_test_pilot_demo",
    baseUrl: "[https://api.invariantprotocol.com](https://api.invariantprotocol.com)", 
  );
  
  runApp(MyApp());
}

```

### 2. Verify a Device

Run attestation at critical checkpoints (Sign Up, Login, or High-Value Transactions).

```dart
final result = await Invariant.verifyDevice();

if (result.isVerified) {
  print("Device Trusted: ${result.riskTier}"); 
  // riskTier: STRONGBOX (Highest), TEE (Standard)
} else {
  print("Access Denied: ${result.error}");
  // riskTier: EMULATOR, SOFTWARE_ONLY, or ROOTED
}

```

## 🛡️ Trust Tiers

| Tier | Security Level | Hardware Type |
| --- | --- | --- |
| **STRONGBOX** | Highest | Dedicated Secure Element (e.g. Titan M2) |
| **TEE** | High | ARM TrustZone Isolation |
| **SOFTWARE** | None | Software-backed (Rejected by Engine) |
| **EMULATOR** | Critical Risk | Virtualized Environment Detected |

## ⚖️ License

This SDK is licensed under the **Business Source License 1.1 (BSL)**. Non-production and evaluation use is permitted. For production use exceeding 1,000 MAU, please contact Invariant Protocol.

---

Copyright © 2026 Invariant Protocol. Built with Rust and Cryptography.
