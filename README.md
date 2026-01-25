# Invariant Protocol

### The Hardware-Bound Identity Anchor for a Post-AI World

---

## 🏗 System Architecture

Invariant operates as a decentralized infrastructure layer. It bridges the gap between physical silicon and digital identity through high-fidelity hardware attestation.

```mermaid
graph TD
    subgraph "Client Layer (Mobile Device)"
        A[Mobile App] --> B{Secure Enclave}
        B -->|P-256 KeyGen| C[StrongBox / SE]
        B -->|KeyStore| D[Standard TEE]
    end

    subgraph "Invariant Protocol Node (Rust/Axum)"
        E[API Gateway] --> F[Attestation Engine]
        F -->|X.509 Parsing| G[ASN.1 Decoder]
        G -->|Root Validation| H[Hardware Root of Trust]
        F -->|Nonce Verification| I[Anti-Replay Layer]
    end

    subgraph "Persistence & Intelligence"
        J[(PostgreSQL)] -- Identity Ledger --> F
        K[(Redis)] -- Nonce Finality --> I
    end

    A == Attestation Bundle ==> E
    H -.->|Google/OEM Roots| G

```

---

## 🔐 The Genesis Protocol (Remote Attestation)

The "Genesis" event is a cryptographic handshake that proves a user is a unique human with a genuine, untampered device. This process is effectively "un-emulatable."

```mermaid
sequenceDiagram
    participant D as Android Device (TEE)
    participant S as Invariant Node (Rust)
    participant G as Google/OEM Root CA

    Note over D, S: Protocol Phase: Identity Minting
    S->>D: 1. Challenge (32-byte Nonce)
    D->>D: 2. Generate P-256 Keypair in StrongBox
    D->>D: 3. Create Hardware Attestation Statement
    D->>S: 4. GenesisRequest (Public Key + Cert Chain + Nonce)
    
    S->>S: 5. Verify ASN.1 Extension Data
    S->>S: 6. Enforce SecurityLevel == TEE/StrongBox
    S->>S: 7. Validate Bootloader State (Locked)
    S->>G: 8. Verify Signature Chain to Root
    
    alt Verification Success
        S->>S: 9. Mint Identity & Issue Continuity Score
        S-->>D: 201 Created (Identity Registered)
    else Verification Failure
        S-->>D: 403 Rejected (Emulator/Root Detected)
    end

```

---

## ⚡ Why Invariant?

The digital world is currently facing an "Identity Inflation" crisis. Invariant solves this by shifting the cost of Sybil attacks from **software (cheap)** to **silicon (expensive)**.

### 1. Hardware-Backed Verification

Unlike traditional 2FA, Invariant verifies the integrity of the OS. If the bootloader is unlocked or the device is an emulator, the attestation fails at the cryptographic level.

### 2. Trust Decay & Persistence

Trust isn't static. Invariant uses a **Continuity Score** maintained by background heartbeats.

* **Titanium Tier:** Hardware-bound keys stored in a dedicated Secure Element.
* **Steel Tier:** Hardware-bound keys stored in the main TEE.

### 3. Privacy-First Identity

Invariant validates **existence**, not demographics. No iris scans, no passports—just the cryptographic proof that a unique device is in the hands of a human.

---

## 📊 Security Tiers

```mermaid
pie title Identity Tier Distribution
    "Titanium (StrongBox/SE)" : 45
    "Steel (Standard TEE)" : 50
    "Software (Rejected)" : 5

```

---

## 🚀 Developer Integration (B2B SDK)

Integrate Invariant into your application to eliminate bot traffic and Sybil attacks.

### Integration Flow

```mermaid
sequenceDiagram
    participant U as End User
    participant P as Partner App (Game/Social)
    participant S as Invariant SDK
    participant N as Invariant Node

    U->>P: 1. Request High-Trust Action
    P->>S: 2. Request Hardware Proof
    S->>U: 3. Prompt for Device Check (Tap)
    U->>S: 4. Signs with Secure Enclave
    S->>N: 5. Forward Proof for Validation
    N-->>P: 6. Identity Manifest (Trust Tier: Titanium)
    P->>U: 7. Action Permitted

```

### Implementation Example

```rust
// Example: Verifying an Invariant Identity in your Backend
let is_valid = invariant_sdk::verify(
    &user_identity_id,
    &attestation_proof
).await?;

if is_valid.tier == "TITANIUM" {
    // Grant high-trust access (e.g., Ranked Matchmaking, Airdrop)
}

```

---

## 🗺️ Roadmap

* [x] **Phase 1:** Core Rust Engine & Attestation Logic.
* [ ] **Phase 2:** B2B SDK Product Hunt Launch (In Progress).
* [ ] **Phase 3:** Pilot Launch in High-Bot Environments.
* [ ] **Phase 4:** Decentralized Validation Network.

---

## 🛡️ License

Invariant Protocol is licensed under the **Business Source License 1.1 (BSL 1.1)**.

* Non-production use is permitted.
* Production use for more than 1,000 MAU requires a commercial license.
* Converts to **Apache 2.0** on January 1, 2030.

[Download Release](https://invariantprotocol.com/pilot) | [Whitepaper](https://invariantprotocol.com/whitepaper) | [Source](https://www.google.com/search?q=https://github.com/KarmaYama/invariant-monorepo)

*Copyright © 2026 Invariant Protocol. Built with Rust and Iron.*

---