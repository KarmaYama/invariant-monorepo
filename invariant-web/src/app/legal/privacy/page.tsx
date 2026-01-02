"use client";

import Link from "next/link";
import { ArrowLeft, ShieldAlert } from "lucide-react";

export default function Privacy() {
  return (
    <div className="min-h-screen bg-[#050505] text-white font-sans selection:bg-[#00FFC2] selection:text-black">
      <nav className="fixed top-0 w-full bg-[#050505]/80 backdrop-blur-md border-b border-white/10 z-50 px-6 h-16 flex items-center">
        <Link href="/" className="flex items-center space-x-2 text-white/60 hover:text-white transition-colors">
          <ArrowLeft size={18} />
          <span className="text-sm font-mono">RETURN</span>
        </Link>
      </nav>

      <main className="max-w-3xl mx-auto pt-32 pb-24 px-6">
        <h1 className="text-4xl font-serif mb-2">Data Minimization Policy</h1>
        <p className="text-white/40 font-mono text-xs mb-12">LAST UPDATED: GENESIS EPOCH (2025)</p>

        <div className="space-y-12 prose prose-invert">
          <section>
            <h2 className="text-2xl font-serif text-white mb-4">1. The Anti-Data Thesis</h2>
            <p className="text-white/70 font-light">
              Invariant is built on a simple premise: <strong>Data is a liability, not an asset.</strong> We do not want to know who you are. We mathematically cannot know who you are.
            </p>
          </section>

          <section>
            <h2 className="text-2xl font-serif text-white mb-4">2. What We Collect (The Signal)</h2>
            <ul className="list-disc pl-4 space-y-2 text-white/70 font-light">
              <li><strong>Attestation Chains:</strong> The X.509 certificate chain provided by your device's Secure Element (StrongBox/TEE). This proves the device model and boot state.</li>
              <li><strong>Public Keys:</strong> The P-256 public key generated inside your hardware. This allows the network to verify your signatures.</li>
              <li><strong>Heartbeats:</strong> Cryptographic proofs that your device was online at a specific timestamp.</li>
            </ul>
          </section>

          <section>
            <h2 className="text-2xl font-serif text-white mb-4">3. What We Do Not Collect (The Noise)</h2>
            <div className="bg-red-500/10 border border-red-500/30 p-6 rounded-lg">
              <ul className="list-disc pl-4 space-y-2 text-red-200/80 font-light">
                <li><span className="font-bold text-red-400">NO</span> Biometrics (FaceID/Fingerprint data stays in your Secure Enclave).</li>
                <li><span className="font-bold text-red-400">NO</span> GPS Location History.</li>
                <li><span className="font-bold text-red-400">NO</span> Real Names or Government IDs.</li>
                <li><span className="font-bold text-red-400">NO</span> Phone Numbers or SIM data.</li>
              </ul>
            </div>
          </section>

          <section>
            <h2 className="text-2xl font-serif text-white mb-4">4. Hardware Hashing</h2>
            <p className="text-white/70 font-light">
              To prevent device fingerprinting, raw hardware identifiers (like Serial Numbers) are salted and hashed using SHA-256 before storage. The raw identifiers are discarded immediately after the initial verification handshake.
            </p>
          </section>
        </div>
      </main>
    </div>
  );
}