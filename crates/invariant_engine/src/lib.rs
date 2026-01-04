/*
 * Copyright (c) 2026 Invariant Protocol.
 *
 * This source code is licensed under the Business Source License (BSL 1.1) 
 * found in the LICENSE.md file in the root directory of this source tree.
 * * You may NOT use this code for active blocking or enforcement without a commercial license.
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