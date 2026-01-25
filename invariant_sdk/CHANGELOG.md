# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-01-25

### Launched
- **Initial Public Pilot Release**: First release of the Invariant Protocol SDK for Flutter.
- **Hardware Attestation**: Provides access to Android KeyStore Attestation (TEE/StrongBox) for hardware-rooted device verification.

### Capabilities
- **Rich Hardware Manifest**: Returns detailed device provenance including `brand`, `deviceModel`, and `bootLocked` status derived from the secure enclave.
- **Shadow Mode**: Introduced `InvariantMode.shadow` to allow risk signal logging without blocking user flows during integration.
- **Fail-Open Architecture**: Network or infrastructure failures now default to a safe `allow` decision with `UNVERIFIED_TRANSIENT` tiering to prevent application breakage.
- **Operational Dashboard**: Example app now includes a full "Ops Dashboard" with live latency telemetry, risk score visualization, and a manifest inspector.
- **Simulation Mode**: Added offline simulation capabilities (`forceAllow`, `forceShadow`, `forceDeny`) to the example app to facilitate UI testing without backend connectivity.

### Security & Hardening
- **Strict Decision Model**: Replaced boolean verification with explicit `InvariantDecision` enum (`allow`, `allowShadow`, `deny`) to eliminate ambiguous logic states.
- **Pinned Configuration**: SDK initialization now requires explicit API key and optional upstream configuration.
- **Protocol Integrity**: Enforced **Hex encoding** for nonces (replacing Base64) to align strictly with the Rust verification backend.
- **Unified Auth**: Standardized all API endpoints to use `Authorization: Bearer <key>` headers, removing ad-hoc custom headers.

### Integration
- Added `Invariant.verifyDevice()` as the primary stateless entry point.
- Exposed `riskScore` (0.0 - 100.0) for granular policy thresholds.
- Refactored networking layer to a single `ApiClient` to prevent logic drift between verification modes.