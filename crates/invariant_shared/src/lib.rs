// crates/invariant_shared/src/lib.rs
/*
 * Copyright (c) 2026 Invariant Protocol
 * Use of this software is governed by the MIT License.
 */

pub mod heartbeat;
pub mod identity;
pub mod genesis;
pub mod reattestation; // 👈 NEW

pub use heartbeat::Heartbeat;
pub use identity::{Identity, IdentityStatus, Network};
pub use genesis::GenesisRequest;
pub use reattestation::ReAttestationRequest; // 👈 NEW