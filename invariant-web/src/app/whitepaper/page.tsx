"use client";

import React, { isValidElement } from 'react';
import { useRouter } from 'next/navigation';
import ReactMarkdown from 'react-markdown';
import remarkMath from 'remark-math';
import remarkGfm from 'remark-gfm'; 
import rehypeKatex from 'rehype-katex';
import rehypeSlug from 'rehype-slug';
import 'katex/dist/katex.min.css';
import { motion } from "framer-motion";
import { ArrowLeft, Share2, ShieldCheck, Cpu, Globe } from "lucide-react";

/* -------------------------------------------------------------------------- */
/* DIAGRAM COMPONENTS                                                         */
/* -------------------------------------------------------------------------- */

function RegistrationFlowDiagram() {
  return (
    <div className="my-12 p-8 border border-white/10 bg-white/5 rounded-lg max-w-2xl mx-auto font-mono text-sm not-prose">
      <div className="text-center text-[#00FFC2] mb-8 uppercase tracking-widest text-xs">Figure 1: Device Registration Sequence</div>
      <div className="relative space-y-8 before:absolute before:inset-0 before:ml-6 before:w-0.5 before:-translate-x-px before:bg-linear-to-b before:from-white/20 before:via-[#00FFC2]/50 before:to-white/20 before:h-full">
        <FlowStep number="1" title="USER CLIENT → TEE" desc="Request Key Generation" />
        <FlowStep number="2" title="TEE → USER CLIENT" desc="Generate Key Pair & Attestation Cert" />
        <FlowStep number="3" title="USER CLIENT → RUST BACKEND" desc="Submit Certificate Chain" />
        <FlowStep number="4" title="BACKEND INTERNAL" desc="Verify Google Root & Parse OID" />
        <FlowStep number="5" title="BACKEND → BLOCKCHAIN" desc="Mint Identity NFT / Register Account" />
      </div>
    </div>
  );
}

function AttestationFlowDiagram() {
  return (
    <div className="my-12 p-8 border border-white/10 bg-white/5 rounded-lg max-w-2xl mx-auto font-mono text-sm not-prose">
      <div className="text-center text-[#00FFC2] mb-8 uppercase tracking-widest text-xs">Figure 2: Heartbeat & Attestation</div>
      <div className="relative space-y-8 before:absolute before:inset-0 before:ml-6 before:w-0.5 before:-translate-x-px before:bg-linear-to-b before:from-white/20 before:via-[#00FFC2]/50 before:to-white/20 before:h-full">
        <FlowStep number="1" title="DEVICE → TRUSTED TIME" desc="Request Signed Timestamp (NTP)" />
        <FlowStep number="2" title="SECURE ELEMENT" desc="Sign(Timestamp + Nonce)" />
        <FlowStep number="3" title="DEVICE → NETWORK" desc="Submit Proof of Liveness" />
        <FlowStep number="4" title="NETWORK CONSENSUS" desc="Update Trust Score (Ts)" />
      </div>
    </div>
  );
}

function FlowStep({ number, title, desc }: { number: string, title: string, desc: string }) {
  return (
    <div className="relative flex items-center group">
      <div className="absolute left-0 h-12 w-12 flex items-center justify-center rounded-full bg-[#050505] border border-white/20 group-hover:border-[#00FFC2] transition-colors z-10">
        <span className="text-white/60 group-hover:text-[#00FFC2] font-bold">{number}</span>
      </div>
      <div className="ml-16 bg-black/40 border border-white/10 p-4 rounded w-full group-hover:border-white/30 transition-colors">
        <div className="text-[#00FFC2] text-xs mb-1 font-bold">{title}</div>
        <div className="text-white/80">{desc}</div>
      </div>
    </div>
  )
}

/* -------------------------------------------------------------------------- */
/* CONTENT                                                                    */
/* -------------------------------------------------------------------------- */

const WHITEPAPER_CONTENT = `
# The Invariant Protocol
### A Hardware-Entangled Sybil-Resistance Mechanism Utilizing Trusted Execution Environments and Economic Disincentives

## Abstract
The digital economy currently faces an existential crisis of trust, precipitated by the collision of three distinct technological trajectories: the democratization of generative artificial intelligence (AI), the obsolescence of centralized custodial identity models, and the hyper-inflation of digital fraud costs. As Large Language Models (LLMs) shatter the Turing barrier, the historic "Proof of Personhood" (PoP) primitives—CAPTCHAs, email verification, and behavioral heuristics—have collapsed, rendering the "one account equals one human" assumption invalid.

This paper introduces the **Invariant Protocol**, a decentralized identity infrastructure that decouples the user interface of identity from its cryptographic roots to establish a "Proof of Device" (PoD) network. By leveraging the ubiquity of Trusted Execution Environments (TEEs) and Secure Elements (SE) within the global smartphone ecosystem, specifically the Android Keystore System and ARM TrustZone architectures, Invariant establishes a quantifiable, hardware-bound proxy for human uniqueness.

We present a formal analysis of the protocol’s architecture, integrating the LATTE layered attestation framework to ensure portability across heterogeneous TEEs (ARM TrustZone, Intel SGX, RISC-V Penglai). We further provide a rigorous economic stress test, modeling the "Cost of Forgery" (CoF) against the "Profit from Corruption" (PfC) to demonstrate the thermodynamic and financial barriers imposed on adversarial actors. Through the synthesis of hardware-backed trust anchors, Account Abstraction (ERC-4337), and a novel "Trust Score" governance model derived from graph-theoretic Sybil defense literature, Invariant proposes a sustainable path toward a privacy-preserving, Sybil-resistant digital commons.

---

## 1. Introduction
The architecture of the internet was not designed with a native identity layer. For the past three decades, this deficiency has been patched by a feudalistic model of digital existence, where users "rent" their identities from an oligopoly of centralized authorities—technology conglomerates, financial institutions, and government agencies. While this model facilitated the rapid onboarding of the global population, it created systemic vulnerabilities characterized by surveillance capitalism, catastrophic data breaches (1.35 trillion victim notices in 2024 alone), and the inherent fragility of custodial access.

The emergence of generative AI has fundamentally altered this threat landscape. We have transitioned from an era where Sybil attacks—the creation of multiple fake identities by a single adversary—were constrained by human attention and labor, to an era of automated, zero-marginal-cost identity forgery. Automated agents can now simulate human behavior with fidelity sufficient to bypass traditional Turing tests, threatening the integrity of digital advertising markets, democratic governance systems, and equitable resource distribution networks. The identity verification market, projected to reach **\\$33.93 billion by 2030**, is symptomatic of this collapse in digital trust.

The Invariant Protocol addresses this crisis not by attempting to solve the philosophical problem of "personhood," but by solving the physical problem of "uniqueness" via hardware entanglement. We posit that the only scalable solution for global Sybil resistance is to transition from a model of **"managing keys"** to one of **"managing hardware-bound relationships"**.

### 1.1 The Sybil Attack and the Impossibility of Digital Distinctions
Douceur’s seminal work on the Sybil attack established that without a centralized certification authority, a distinct identity cannot be proven in a distributed system unless there is a parity of resources. In a purely digital realm, resources (computation, storage) are fungible and elastic. An attacker with sufficient computational power can simulate thousands of entities.

Unlike proof-of-work (PoW) systems that rely on computational expenditure, or proof-of-stake (PoS) systems that rely on capital lock-up, Invariant introduces **non-fungible physical hardware** as the distinct resource. By anchoring identity to the unique, tamper-resistant cryptographic coprocessors found in modern smartphones—specifically devices compliant with Android 9+ and equipped with StrongBox or TEEs—the protocol imposes a hard physical constraint on the generation of identities. To forge $N$ identities, an adversary must acquire, power, and maintain $N$ physical devices, effectively translating the security of the network from the digital domain to the thermodynamic domain.

### 1.2 Motivation: The Failure of "One CPU, One Vote"
Satoshi Nakamoto initially envisioned Bitcoin as a "one-CPU-one-vote" system. However, the advent of ASICs led to centralization, where voting power became a function of capital rather than participation. Similarly, standard Proof-of-Stake systems often devolve into plutocracies where the rich get richer.

The Invariant Protocol revisits the democratic ideal by shifting the atomic unit of the network from the CPU (which is scalable via capital) to the **personal device** (which is constrained by supply chains and physical utility). While "Proof-of-Personhood" schemes like Worldcoin utilize specialized biometric hardware (the Orb), Invariant leverages the roughly **3.9 billion Android devices** already in circulation. This approach avoids the distribution bottlenecks of specialized hardware while utilizing the robust security primitives of ARM TrustZone and Intel SGX already embedded in consumer electronics.

---

## 2. Hardware Trust Anchors: The Physical Layer
The security of the Invariant Protocol is not derived from blockchain consensus mechanisms, which are ultimately software-layer constructs, but from the physical properties of the silicon powering user devices. We rely on the Trusted Execution Environment (TEE) and the Secure Element (SE) as the roots of trust.

### 2.1 ARM TrustZone Architecture
The vast majority of mobile devices utilized in the Invariant network are powered by ARM-based System-on-Chip (SoC) architectures. The security of these devices relies on ARM TrustZone technology, which provides a hardware-enforced isolation between the "Secure World" and the "Normal World" (Rich Execution Environment or REE).

#### 2.1.1 System Architecture and the NS-Bit
TrustZone partitions all SoC hardware and software resources. This partition is enforced by the AMBA3 AXI system bus, which includes an additional control signal known as the **Non-Secure (NS) bit**.
* **Read Transaction (ARPROT):** Low is Secure; High is Non-Secure.
* **Write Transaction (AWPROT):** Low is Secure; High is Non-Secure.

The bus fabric ensures that no Secure World resources (memory, peripherals, cryptographic engines) can be accessed by Normal World components. This isolation is critical for Invariant. Even if the Android OS (Normal World) is compromised by malware or rooted by the user, the cryptographic keys generated and stored within the Secure World remain inaccessible. The NS-bit essentially creates a 33rd address bit, splitting the physical address space into two distinct, hardware-separated regions.

#### 2.1.2 The Secure Monitor and World Switching
The processor transitions between the Secure and Normal worlds via a dedicated mode called **Monitor Mode**. Entry into Monitor Mode is tightly controlled and can be triggered by the Secure Monitor Call (SMC) instruction or specific hardware exceptions (IRQ, FIQ). The software executing in Monitor Mode is responsible for context switching—saving the state of the current world and restoring the state of the target world. This ensures that register contents and pipeline instructions from the Secure World are never leaked to the Normal World. For Invariant, this guarantees that the private keys used to sign identity assertions never reside in registers accessible to a compromised Android kernel.

#### 2.1.3 Peripheral Security and the "Trusted Path"
Invariant leverages TrustZone to secure not just computation, but input/output peripherals. By securing the interrupt controller and user I/O devices (touchscreen, fingerprint sensor), TrustZone enables a "Trusted Path" for user authentication. This prevents "shack attacks" (low-budget hardware attacks) or software-based overlays from spoofing user biometric consent, a crucial component of the protocol’s "Proof of Liveness" checks.

### 2.2 Intel Software Guard Extensions (SGX)
While mobile utilizes TrustZone, Invariant’s server-side attestation and potential future desktop clients rely on Intel SGX. SGX enables the creation of **enclaves**, isolated memory regions protected from processes running at higher privilege levels, including the OS and Hypervisor.

#### 2.2.1 Enclave Page Cache (EPC) and Access Control
The SGX architecture protects enclave memory via the Enclave Page Cache (EPC), a subset of the Processor Reserved Memory (PRM). The CPU performs access control checks on every memory access. If a non-enclave instruction attempts to read or write to an address within the EPC, the processor generates an abort page semantics or a #GP(0) exception. This ensures that even a malicious cloud provider with physical access to the server DRAM cannot inspect the memory of an Invariant verification node.

#### 2.2.2 MRENCLAVE and Remote Attestation
SGX provides a cryptographic measurement of the enclave’s initial state, known as MRENCLAVE. This 256-bit hash (SHA-256) reflects the enclave's code, data, and stack initialization.
* **EINIT Instruction:** Finalizes the enclave identity. It verifies that the SIGSTRUCT (signature structure) is valid and that the MRENCLAVE matches the expected value.
* **Local and Remote Attestation:** Enclaves can prove their identity to other enclaves (EREPORT) or remote parties.

This allows the Invariant Network to verify that a verification node is running the exact, unmodified, open-source verification code before trusting its output.

### 2.3 Android Keystore and StrongBox
While TrustZone provides logical isolation, it often shares the main CPU die. For higher-assurance identity signals, Invariant prioritizes devices equipped with **StrongBox**, a discrete Secure Element introduced in Android 9.

#### 2.3.1 Hierarchies of Hardware Security
The Android ecosystem offers three tiers of security, which Invariant maps to a quantitative "Trust Score" ($T_s$):

| Mechanism | Hardware Isolation | Tamper Resistance | Market Availability | Invariant Trust Tier |
| :--- | :--- | :--- | :--- | :--- |
| **StrongBox** | Dedicated Chip (SE) | High (Voltage/Glitch protection) | Flagship/Premium | **Tier 1 (High)** |
| **TEE** | ARM TrustZone | Medium | >95% of modern Androids | **Tier 2 (Standard)** |
| **Software** | None (OS-level) | Low | Legacy/Budget | **Tier 3 (Rejected)** |

StrongBox implementations must have their own CPU, secure storage, and True Random Number Generator (TRNG). They are designed to resist physical penetration, side-channel analysis, and fault injection attacks that might compromise a standard TEE.

#### 2.3.2 Key Attestation and the X.509 Chain
To prevent "emulator farming"—where an attacker simulates thousands of Android instances on a server—Invariant relies on Android Key Attestation. When a device generates a key pair, it produces an X.509 certificate chain signed by the **Google Hardware Attestation Root**.

The Invariant backend parses the certificate extension (OID 1.3.6.1.4.1.11129.2.1.17) to verify:
* **attestationSecurityLevel:** Must be \`TrustedEnvironment\` or \`StrongBox\`. If it reads \`Software\`, the device is rejected.
* **bootState:** Must indicate \`Verified\` or \`Locked\` to ensure the bootloader has not been tampered with.

---

## 3. The Invariant Protocol Architecture
The Invariant Protocol stack is designed to facilitate secure, portable, and privacy-preserving verification. It utilizes a Rust-based backend for memory safety and cryptographic correctness, coupled with a Flutter client for cross-platform mobile deployment.

### 3.1 LATTE: Layered Attestation for Portable Enclaves
A significant challenge in hardware-backed identity is **portability**. TEE implementations are heterogeneous (Intel SGX, ARM TrustZone, RISC-V Penglai), and binding an identity strictly to a platform-specific measurement ($M$) creates lock-in and upgrade friction. Invariant adopts the **LATTE (Layered Attestation)** framework to solve this.

#### 3.1.1 The Challenge of Nested Attestation
Traditional "nested attestation" relies on the TEE runtime to measure the application payload via software. If the TEE runtime has a bug (e.g., sandbox escape), a malicious payload can compromise the runtime. Since the hardware measurement $M$ only reflects the initial state of the runtime, the compromise is undetectable.

#### 3.1.2 The LATTE Solution: Portable Identity ($I$)
LATTE introduces the concept of a **Portable Identity** ($I$), which is the cryptographic hash of the portable payload (the Invariant verification logic/WASM module). The protocol splits the attestation into two layers:
1. **Restricted Payload Loading:** The enclave is built such that it only loads payloads matching a specific hardcoded portable identity ($I$).
2. **Layered Reference-Value Derivation:** The verifier independently derives the reference measurement ($M_{ref}$) for the underlying runtime and the reference identity ($I_{ref}$) for the payload.

This enables the protocol to run securely on an ARM TrustZone device today and migrate to a RISC-V Keystone device tomorrow, maintaining the "Invariant" of the identity across hardware architectures.

#### 3.1.3 Formal Definition of Identity-Measurement Binding
Let $P$ be the portable code. Let $R_i$ be the TEE runtime on platform $i$. Let $\\mathcal{B}_i$ be the build function. The enclave content $E_i^P$ is formally defined as the build of the runtime constrained by the identity of the payload. The verifier function $\\mathcal{V}$ confirms that the measurement $M$ corresponds to the binding of $I$ and $R_i$.

### 3.2 Trusted Time and Proof of Latency
Identity is not just a static key; it is existence over time. Invariant implements **Proof of Latency (PoL)**, requiring devices to sign "Heartbeat" tasks periodically. This mimics the concept of Time-Lock Puzzles, but rather than proving CPU cycles were spent, it proves **temporal existence** was maintained.

#### 3.2.1 The Time-Lock Parallel
Invariant adapts the concept of time-lock puzzles by using the **TrustedTime API** as the "squaring function". The device cannot "skip ahead" in time because the timestamp $T$ is cryptographically signed by Google's secure NTP servers.

#### 3.2.2 The Liveness Proof
To prevent attackers from manipulating the system clock to "speed run" reputation accumulation, the Invariant Client requests a timestamp from the TrustedTime API. The device then signs the tuple $(K_{priv}, T_{trusted}, Nonce)$ inside the TEE. This creates a "Signed Proof of Liveness" asserting that "Device X was active and functional at Verified Time T". This imposes an **Operational Expenditure (OpEx)** on attackers: they must keep thousands of devices powered on and connected to the internet for months to build reputation.

### 3.3 Zero-Knowledge Privacy Preservation
To adhere to the principle of "Invisible Identity," Invariant must prove uniqueness without revealing the underlying hardware identifiers (IMEI, Serial Number) or user data. We employ Zero-Knowledge Proofs (ZKPs) utilizing modern mobile ZK frameworks. The client generates a proof $\\pi$ such that the protocol uses a deterministic **Nullifier** derived from the hardware key and the context to prevent double-signaling while maintaining unlinkability between different contexts.

---

## 4. Mathematical Models of Sybil Resistance
The core innovation of Invariant is the translation of hardware constraints into a graph-theoretic security guarantee. We adapt the principles of **SybilLimit** and **SybilGuard** to a hardware-latency graph.

### 4.1 Graph Topology: The Heartbeat Network
In standard SybilLimit, edges represent social trust relationships. In Invariant, edges represent **verified latency relationships** or "Heartbeats" over time. Let $G = (V, E)$ be the graph where $V$ is the set of devices. An edge $e_{ij}$ exists if Device $i$ and Device $j$ have historically attested to each other's presence (e.g., via Bluetooth Low Energy proximity checks).

### 4.2 The Mixing Time and Attack Edges
The security of the network relies on the "Fast Mixing" property of the honest region of the graph. Sybils (attackers) can create infinite nodes $S$ but limited "Attack Edges" $g$ connecting to the honest component $H$. SybilLimit proves that a random walk of length $w = \\Theta(\\log n)$ stays within the honest region with high probability if $g$ is small relative to $n$. By enforcing hardware costs, Invariant effectively bounds $g$.

### 4.3 Trust Scoring Function ($T_s$)
The Trust Score $T_s$ of an identity is a scalar value $T_s \\in [0, 1]$, calculated via a weighted function of hardware security and temporal consistency.

$$
T_s = \\alpha \\cdot H(d) + \\beta \\cdot \\log(L(d)) + \\gamma \\cdot P(d)
$$

Where:
* $H(d)$: Hardware Tier Score ($1.0$ for StrongBox, $0.6$ for TEE, $0$ for Software).
* $L(d)$: Liveness Score. A logarithmic function of the contiguous "Heartbeat" duration $t$.
* $P(d)$: Proximity Score. Derived from ZK-proofs of proximity to other high-trust devices.
* $\\alpha, \\beta, \\gamma$: Weighting coefficients.

---

## 5. Economic Stress Test: The Cost of Forgery
The Invariant Protocol replaces the thermodynamic energy cost of Proof-of-Work with the **Cost of Forgery (CoF)**. For the network to be secure, the cost to attack must exceed the Profit from Corruption (PfC).

$$
CoF > PfC
$$

### 5.1 Attacker Capital Expenditure (CapEx)
Unlike digital-only identities, Invariant requires physical hardware. We model the cost based on the 2025 refurbished smartphone market.

**Table 1: Fleet Acquisition Costs (2025 Benchmarks)**

| Fleet Size | Device Tier | Unit Cost (Refurb) | Total CapEx |
| :--- | :--- | :--- | :--- |
| 1,000 | TEE (Standard) | \\$100 | \\$100,000 |
| 10,000 | TEE (Standard) | \\$100 | \\$1,000,000 |
| 1,000 | StrongBox (High) | \\$345 | \\$345,000 |
| 10,000 | StrongBox (High) | \\$345 | **\\$3,450,000** |

The CapEx creates a significant floor. To control 10,000 high-trust votes, an attacker must deploy **\\$3.45 million** in upfront capital.

### 5.2 Operational Expenditure (OpEx): The Proxy Bottleneck
Owning the devices is insufficient; they must appear distinct on the network layer. The attacker must procure residential mobile proxies to simulate disparate human locations.

* **Mobile Proxy Cost:** $\\approx$ \\$50 per month per IP.
* **Annual OpEx (10k Fleet):** \\$50 $\\times$ 10,000 $\\times$ 12 = \\$6,000,000.
* **Total Year 1 Cost:** To maintain a 10,000-device standard fleet is approximately **\\$7.15 million**.

### 5.3 Profit from Corruption (PfC) Analysis
We compare the CoF against potential extraction vectors:

* **Ad Fraud:** A botnet generating fake impressions. Revenue $\\approx$ \\$72M/year. Margin $\\approx$ \\$64.85M. **Conclusion:** High Risk. Invariant must implement strict behavioral heuristics and Proximity Scoring to devalue static farming bots.
* **Governance Attacks:** Swinging a DAO vote. For larger treasuries, **Quadratic Voting (QV)** powered by Invariant IDs makes the cost of influence quadratic rather than linear. The cost to buy 10,000 votes scales exponentially, causing the attack cost to explode beyond the fleet cost.

### 5.4 Tokenomics: Universal Basic Share (UBS)
To incentivize legitimate adoption, the protocol emits INV tokens as a "Universal Basic Share" (UBS).
* **Legitimate User ROI:** Infinite. They already own the phone. Marginal cost $\\approx$ 0.
* **Attacker ROI:** Negative, unless the token value exceeds the hardware depreciation + proxy costs.

---

## 6. Implementation and User Experience
To succeed, Invariant must be invisible, avoiding the friction and complexity often associated with cryptographic protocols. We achieve this through **Account Abstraction** and **Passkeys**, creating a UX that rivals centralized Web2 login flows.

### 6.1 Account Abstraction (ERC-4337)
Invariant utilizes ERC-4337 to implement **Paymasters**. The Invariant DAO or third-party issuers act as Paymasters, sponsoring the gas fees for identity creation, making the app feel "free". The identity is not a key, but a smart contract, enabling "Session Keys" for seamless interaction.

### 6.2 Passkeys and Biometric Integration
We eliminate the seed phrase entirely. The user authenticates via FaceID/Fingerprint, and the device generates a P-256 key pair inside the Secure Enclave. On-chain verification utilizes the **RIP-7212 precompile**, allowing the smart account to directly verify the biometric signature.

### 6.3 Recovery Flows
"Lost phone" scenarios are handled via **Social Recovery**. Users can designate friends or use **ZK-Email Recovery**, where a Zero-Knowledge circuit verifies the DKIM signature of an email off-chain to rotate the key.

---

## 7. Security Analysis and Risk Mitigation
While the "Sieve" of hardware attestation is robust, it is not impervious.

### 7.1 TEE Fragility and Zero-Day Exploits
**Risk:** A specific chipset is compromised via a side-channel attack.
**Mitigation: Chip De-ranking Registry.** The protocol maintains a dynamic "Chipset Registry." If a vulnerability is disclosed, the governance DAO votes to downgrade the Trust Score $H(d)$ of all devices using that chipset.

### 7.2 Side-Channel Attacks and ORAM
**Risk:** An attacker observes memory access patterns to infer key bits.
**Mitigation: Oblivious RAM (ORAM).** Future iterations will implement ORAM primitives to obfuscate memory access patterns, ensuring that the sequence of reads/writes reveals no information about the data being accessed.

### 7.3 Governance Plutocracy
**Risk:** Whales accumulating tokens to sway protocol parameters.
**Mitigation: Sybil-Resistant Quadratic Voting.** By binding voting power to the unique hardware ID (Trust Score) rather than token holdings, Invariant implements true Quadratic Voting, protecting the governance layer from financial capture.

---

## 8. Protocol Flow Diagrams

### 8.1 Device Registration Flow
The following diagram illustrates the flow of device registration, highlighting the interaction between the User, the TEE, the Rust Backend, and the Blockchain.

\`\`\`registration-flow
DIAGRAM_PLACEHOLDER
\`\`\`

### 8.2 Attestation & Heartbeat Flow
This diagram details the "Heartbeat" mechanism involving TrustedTime and the calculation of the Trust Score ($T_s$).

\`\`\`attestation-flow
DIAGRAM_PLACEHOLDER
\`\`\`

---

## 9. Conclusion
The deceptive simplicity of early crypto-identity projects disguises a sophisticated response to a profound civilizational threat: the loss of digital personhood. The analysis presented in this whitepaper demonstrates that "Just using Android" is insufficient without a decentralized protocol to prevent censorship and honeypot risks. However, leveraging Android hardware as a decentralized root of trust is the only viable path to scalability.

By anchoring identity in the thermodynamic cost of hardware, utilizing the LATTE framework for portability, and abstracting complexity via ERC-4337, Invariant builds a "Normal ID" for the post-AI internet. It creates a scarcity of identity that is economically defensible, technically robust, and user-centric. The data suggests that building this infrastructure is not only "worth it" but structurally necessary for the continuity of the digital economy.

---

## Bibliography
1. Borge, M., et al. "Proof-of-Personhood: Redemocratizing Permissionless Cryptocurrencies." *Proceedings of IEEE*.
2. Rebello, G. A. F., et al. "A Security and Performance Analysis of Proof-based Consensus Protocols."
3. Corso, A. "Performance Analysis of Proof-of-Elapsed-Time (POET) Consensus in the Sawtooth Blockchain Framework." *University of Oregon Thesis*.
4. Yu, H., Kaminsky, M., Gibbons, P. B., & Xiao, F. "SybilLimit: A Near-Optimal Social Network Defense against Sybil Attacks." *Proceedings of IEEE S&P*.
5. Yu, H., Kaminsky, M., Gibbons, P. B., & Flaxman, A. "SybilGuard: Defending Against Sybil Attacks via Social Networks." *SIGCOMM*.
6. Douceur, J. R. "The Sybil Attack." *Microsoft Research*.
7. Rivest, R. L., Shamir, A., & Wagner, D. A. "Time-lock puzzles and timed-release Crypto."
8. Xu, H., et al. "LATTE: Layered Attestation for Portable Enclaves." *EuroS&P 2025*.
9. ARM Limited. "ARM Security Technology: Building a Secure System using TrustZone Technology." *Whitepaper*.
10. Intel Corporation. "Intel Software Guard Extensions Programming Reference."
11. Internal Audit. "Code Review: TEE Fragility & Zero-Days, Governance Risk."
12. Internal Economic Report. "Stress Test: Sybil Attack Simulation & Cost of Forgery."
`;

/* -------------------------------------------------------------------------- */
/* MAIN COMPONENT                                                             */
/* -------------------------------------------------------------------------- */

export default function Whitepaper() {
  const router = useRouter();
  
  // Custom components to override default unstyled HTML
  const MarkdownComponents: any = {
    // Override Header 1
    h1: (props: any) => (
      <h1 className="text-4xl md:text-5xl font-serif text-white mt-16 mb-8 border-b border-white/10 pb-4" {...props} />
    ),
    // Override Header 2
    h2: (props: any) => (
      <h2 className="text-3xl font-serif text-white mt-12 mb-6" id={props.id} {...props} />
    ),
    // Override Header 3
    h3: (props: any) => (
      <h3 className="text-xl font-mono text-[#00FFC2] mt-8 mb-4 uppercase tracking-wide" {...props} />
    ),
    // Override Header 4
    h4: (props: any) => (
      <h4 className="text-lg font-bold text-white mt-6 mb-3" {...props} />
    ),
    // Override Paragraphs
    p: (props: any) => (
      <p className="text-lg text-white/80 font-light leading-relaxed mb-6" {...props} />
    ),
    // Override Lists
    ul: (props: any) => (
      <ul className="list-disc list-inside mb-6 space-y-2 text-white/80" {...props} />
    ),
    li: (props: any) => (
      <li className="ml-4" {...props} />
    ),
    // Override Blockquotes
    blockquote: (props: any) => (
      <blockquote className="border-l-2 border-[#00FFC2] pl-6 py-2 my-8 text-white/60 italic bg-white/5 rounded-r-lg" {...props} />
    ),
    // Override Links
    a: (props: any) => (
      <a className="text-[#00FFC2] hover:underline underline-offset-4" {...props} />
    ),
    // Override Horizontal Rules
    hr: (props: any) => (
      <hr className="border-white/10 my-12" {...props} />
    ),
    // Override Tables
    table: (props: any) => (
      <div className="overflow-x-auto my-8 border border-white/10 rounded-lg">
        <table className="w-full text-left border-collapse bg-white/5" {...props} />
      </div>
    ),
    th: (props: any) => (
      <th className="border-b border-white/10 bg-white/5 p-4 text-[#00FFC2] font-mono text-sm uppercase whitespace-nowrap" {...props} />
    ),
    td: (props: any) => (
      <td className="border-b border-white/5 p-4 text-white/70 font-light" {...props} />
    ),
    tr: (props: any) => (
      <tr className="hover:bg-white/5 transition-colors" {...props} />
    ),
    
    // CUSTOM PRE BLOCK HANDLER (Intercepts code blocks at the source)
    pre: ({ children }: any) => {
      // 1. Extract the 'code' element (which is the child of <pre>)
      const childArray = React.Children.toArray(children);
      const codeElement = childArray[0] as React.ReactElement<any>;
      
      // 2. Check if it's a valid React element before accessing props
      if (!isValidElement(codeElement)) {
         return <pre className="bg-white/5 p-4 rounded-lg overflow-x-auto border border-white/10 my-6">{children}</pre>;
      }

      // 3. Extract the class name (e.g., "language-registration-flow")
      // FIX: Explicitly cast props to known shape to silence TS "Property does not exist on type {}" error
      const className = (codeElement.props as { className?: string }).className || '';
      
      // 4. Check for our special flowcharts
      if (className.includes('language-registration-flow')) {
         return <RegistrationFlowDiagram />;
      }
      
      if (className.includes('language-attestation-flow')) {
         return <AttestationFlowDiagram />;
      }

      // 5. Fallback: Render standard code block
      return (
        <pre className="bg-white/5 p-4 rounded-lg overflow-x-auto border border-white/10 my-6">
          {children}
        </pre>
      );
    },
  };

  return (
    <div className="min-h-screen bg-[#050505] text-white font-sans selection:bg-[#00FFC2] selection:text-black">
      
      {/* NAVIGATION HEADER */}
      <nav className="fixed top-0 w-full bg-[#050505]/80 backdrop-blur-md border-b border-white/10 z-50 px-6 h-16 flex items-center justify-between">
        <button 
          onClick={() => router.push('/')}
          className="flex items-center space-x-2 text-white/60 hover:text-white transition-colors cursor-pointer z-50"
        >
          <ArrowLeft size={18} />
          <span className="text-sm font-mono">RETURN TO DASHBOARD</span>
        </button>
        <div className="flex items-center space-x-4">
           <button className="p-2 hover:bg-white/10 rounded-full transition-colors">
             <Share2 size={18} className="text-white/60" />
           </button>
        </div>
      </nav>

      <main className="max-w-4xl mx-auto pt-32 pb-24 px-6">
        
        {/* TITLE SECTION */}
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="mb-16 border-b border-white/10 pb-8"
        >
          <div className="flex items-center space-x-2 font-mono text-[#00FFC2] text-xs mb-4">
            <span className="bg-[#00FFC2]/10 px-2 py-1 rounded">PROTOCOL SPECIFICATION</span>
            <span className="text-white/40">//</span>
            <span>V1.0</span>
          </div>
          <h1 className="text-5xl md:text-6xl font-serif mb-6 leading-tight">Invariant Whitepaper</h1>
          
          <div className="grid grid-cols-2 md:grid-cols-4 gap-6 text-sm text-white/40 font-mono mt-8">
            <div>
              <div className="text-white/20 text-xs mb-1">PUBLISHED</div>
              <div className="text-white">DECEMBER 2025</div>
            </div>
            <div>
              <div className="text-white/20 text-xs mb-1">VERSION</div>
              <div className="text-white">1.0.4 (DRAFT)</div>
            </div>
             <div>
              <div className="text-white/20 text-xs mb-1">SHA-256</div>
              <div className="text-white">A7F...92C</div>
            </div>
            <div>
              <div className="text-white/20 text-xs mb-1">STATUS</div>
              <div className="text-[#00FFC2]">AUDIT PENDING</div>
            </div>
          </div>
        </motion.div>

        {/* TABLE OF CONTENTS */}
        <div className="mb-16 p-6 border border-white/5 rounded-lg bg-white/5">
            <h3 className="text-sm font-mono text-[#00FFC2] mb-4">CONTENTS</h3>
            <div className="grid md:grid-cols-2 gap-y-2 gap-x-8 text-sm text-white/60 font-light">
                <a href="#abstract" className="hover:text-white transition-colors">Abstract</a>
                <a href="#1-introduction" className="hover:text-white transition-colors">1. Introduction</a>
                <a href="#2-hardware-trust-anchors-the-physical-layer" className="hover:text-white transition-colors">2. Hardware Trust Anchors</a>
                <a href="#3-the-invariant-protocol-architecture" className="hover:text-white transition-colors">3. Protocol Architecture</a>
                <a href="#4-mathematical-models-of-sybil-resistance" className="hover:text-white transition-colors">4. Sybil Resistance Models</a>
                <a href="#5-economic-stress-test-the-cost-of-forgery" className="hover:text-white transition-colors">5. Economic Stress Test</a>
                <a href="#6-implementation-and-user-experience" className="hover:text-white transition-colors">6. Implementation & UX</a>
                <a href="#bibliography" className="hover:text-white transition-colors">Bibliography</a>
            </div>
        </div>

        {/* MARKDOWN RENDERER */}
        <article className="pb-24">
          <ReactMarkdown 
            remarkPlugins={[remarkMath, remarkGfm]} 
            rehypePlugins={[rehypeKatex, rehypeSlug]}
            components={MarkdownComponents}
          >
            {WHITEPAPER_CONTENT}
          </ReactMarkdown>
        </article>

        {/* FOOTER CITATION */}
        <div className="mt-12 pt-8 border-t border-white/10 text-white/30 text-sm font-mono flex justify-between items-center">
          <p>INVARIANT PROTOCOL // 2025</p>
          <div className="flex space-x-4">
             <ShieldCheck size={16} />
             <Cpu size={16} />
             <Globe size={16} />
          </div>
        </div>

      </main>
    </div>
  );
}