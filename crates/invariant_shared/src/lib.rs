/*
 * Copyright (c) 2025 Invariant Protocol
 * * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 */

/// The data model for the Proof of Persistence signal.
pub mod heartbeat;

/// The data model for the Identity invariant and its state.
pub mod identity;

pub mod genesis;

// Re-exports for cleaner access
pub use heartbeat::Heartbeat;
pub use identity::{Identity, IdentityStatus, Network};
pub use genesis::GenesisRequest;