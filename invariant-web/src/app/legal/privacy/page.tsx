"use client";

import Link from "next/link";
import { ArrowLeft, ShieldCheck, Lock, FileX, Server } from "lucide-react";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";

export default function Privacy() {
  return (
    <div className="min-h-screen bg-[#050505] text-white font-sans selection:bg-[#00FFC2] selection:text-black">
      <Header />

      <main className="max-w-3xl mx-auto pt-32 pb-24 px-6">
        <div className="mb-12 border-b border-white/10 pb-8">
          <h1 className="text-4xl font-serif mb-4">Privacy Architecture</h1>
          <p className="text-white/60 font-light text-lg">
            Invariant is designed as a <span className="text-white">Zero-Knowledge-Inspired Infrastructure</span>. 
            We verify hardware-backed execution, not user identity.
          </p>
        </div>

        <div className="space-y-16">
          
          {/* SECTION 1: PHILOSOPHY */}
          <section>
            <div className="flex items-center gap-3 mb-4">
              <ShieldCheck className="text-[#00FFC2]" size={24} />
              <h2 className="text-2xl font-serif text-white">1. Structural Privacy</h2>
            </div>
            <p className="text-white/70 font-light leading-relaxed">
              We do not rely on "policies" to protect user data; we rely on <strong>cryptographic constraints</strong>. 
              Our architecture is decoupled: the Attestation Engine verifies hardware integrity without ever requesting access to user identity layers (PII).
            </p>
          </section>

          {/* SECTION 2: DATA COLLECTION */}
          <section>
            <div className="flex items-center gap-3 mb-4">
              <Server className="text-[#00FFC2]" size={24} />
              <h2 className="text-2xl font-serif text-white">2. Data Ingress (The Signal)</h2>
            </div>
            <p className="text-white/70 font-light mb-6">
              The Protocol processes strictly non-identifiable metadata required to validate the Trusted Execution Environment (TEE):
            </p>
            <div className="grid gap-4">
              <DataPoint 
                title="X.509 Attestation Chain"
                desc="The certificate chain provided by the Android Keystore to verify the hardware root of trust."
              />
              <DataPoint 
                title="Ephemeral Public Keys"
                desc="A P-256 public key generated inside hardware-backed secure execution (TEE / Secure Element). This key is mathematically unrelated to the user's identity."
              />
              <DataPoint 
                title="Cryptographic Heartbeats"
                desc="Signed timestamps proving device uptime. These contain no location or behavioral data."
              />
            </div>
          </section>

          {/* SECTION 3: EXCLUSIONS */}
          <section>
            <div className="flex items-center gap-3 mb-4">
              <FileX className="text-red-400" size={24} />
              <h2 className="text-2xl font-serif text-white">3. Data Exclusions</h2>
            </div>
            <div className="bg-white/5 border border-white/10 p-6 rounded-lg">
              <p className="text-white/70 font-light mb-4">
                The Invariant SDK operates sandbox-isolated and does not request the following permissions:
              </p>
              <ul className="grid md:grid-cols-2 gap-y-3 gap-x-8 mb-6">
                <ExclusionItem label="Biometric Data (FaceID/Fingerprint)" />
                <ExclusionItem label="GPS / Geolocation History" />
                <ExclusionItem label="Phone Numbers / SMS Logs" />
                <ExclusionItem label="Contact Lists / Social Graph" />
                <ExclusionItem label="Advertising ID (GAID/IDFA)" />
                <ExclusionItem label="App Usage History" />
              </ul>
              <p className="text-white/40 text-xs italic border-t border-white/10 pt-4">
                Invariant remains fully functional without access to any of the above.
              </p>
            </div>
          </section>

          {/* SECTION 4: HASHING */}
          <section>
            <div className="flex items-center gap-3 mb-4">
              <Lock className="text-[#00FFC2]" size={24} />
              <h2 className="text-2xl font-serif text-white">4. Identifier Hashing</h2>
            </div>
            <p className="text-white/70 font-light leading-relaxed">
              To prevent device fingerprinting across different applications, any hardware identifiers are strictly <strong>Salted and Hashed (SHA-256 with per-context salts)</strong> before persistence. 
              <br/><br/>
              Raw hardware serial numbers are processed in-memory during the handshake and discarded immediately. They are never written to disk.
            </p>
          </section>

        </div>
      </main>
      <Footer />
    </div>
  );
}

function DataPoint({ title, desc }: any) {
  return (
    <div className="border-l-2 border-[#00FFC2]/30 pl-4 py-1">
      <h4 className="font-mono text-[#00FFC2] text-sm mb-1">{title}</h4>
      <p className="text-white/60 text-sm font-light">{desc}</p>
    </div>
  );
}

function ExclusionItem({ label }: any) {
  return (
    <li className="flex items-center gap-3 text-white/50 font-mono text-xs">
      <div className="w-1.5 h-1.5 bg-red-500/50 rounded-full"></div>
      {label}
    </li>
  );
}