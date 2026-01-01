/*
 * Copyright (c) 2025 Invariant Protocol
 * Use of this software is governed by the Business Source License
 * included in the LICENSE file.
 *
 * As of the Change Date specified in that file, in accordance with
 * the Business Source License, use of this software will be governed
 * by the Apache License, Version 2.0.
 */

/// The logic core for mining "Proof of Persistence".
pub mod core;

/// Centralized error handling for the engine.
pub mod error;

/// The abstract "Ports" (Interfaces) for storage.
/// This enforces Dependency Inversion.
pub mod ports;

/// Cryptographic Utilities (P-256 Signature Verification).
pub mod crypto;

/// Hardware Attestation Validation Logic.
pub mod attestation;

// Re-exports
pub use core::InvariantEngine;
pub use error::EngineError;
pub use ports::IdentityStorage;
pub use crypto::verify_signature;
pub use attestation::validate_attestation_chain;