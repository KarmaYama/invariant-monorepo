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