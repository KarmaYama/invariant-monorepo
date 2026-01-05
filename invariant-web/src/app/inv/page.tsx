"use client";

import { motion } from "framer-motion";
import { ArrowLeft, ShieldCheck, Clock, Award, Scale } from "lucide-react";
import Link from "next/link";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";

export default function InvToken() {
  return (
    <div className="min-h-screen bg-[#050505] text-white font-sans selection:bg-[#00FFC2] selection:text-black">
      <Header />

      <main className="max-w-4xl mx-auto pt-32 pb-24 px-6">
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="mb-16"
        >
          <div className="flex items-center space-x-2 font-mono text-[#00FFC2] text-xs mb-4">
            <span className="bg-[#00FFC2]/10 px-2 py-1 rounded">REPUTATION PROTOCOL</span>
            <span className="text-white/40">//</span>
            <span>TESTNET V1</span>
          </div>
          {/* REPLACED: "Universal Basic Share" -> "Proof of Consistency" */}
          <h1 className="text-5xl md:text-6xl font-serif mb-6">Thermodynamic Trust.</h1>
          <p className="text-xl text-white/60 font-light leading-relaxed max-w-2xl">
            Identity is not a badge. It is verifiable work over time. <br/>
            The <strong>Continuity Score</strong> quantifies the physical reliability of a node in the network.
          </p>
        </motion.div>

        <div className="grid md:grid-cols-2 gap-8 mb-16">
          <Card 
            icon={<Clock className="text-[#00FFC2]" />}
            title="Proof of Latency"
            // REPLACED: Token logic with Score logic (Matches your DB)
            desc="Trust is earned in 4-hour epochs. Every successful heartbeat increments your Continuity Score. Missing a window breaks your streak."
          />
          <Card 
            icon={<ShieldCheck className="text-[#00FFC2]" />}
            title="Non-Transferable"
            // REPLACED: "Soulbound" with "Device-Bound" (More technical, less crypto)
            desc="Your score is cryptographically bound to your device's Secure Enclave. It cannot be bought, sold, or transferred. It measures hardware reliability, not wealth."
          />
          <Card 
            icon={<Award className="text-[#00FFC2]" />}
            title="Genesis Eligibility"
            // REPLACED: "5% Money Pot" with "Access Utility"
            desc="Top-scoring nodes in the Testnet will be whitelisted as 'Validator Anchors' for the Mainnet launch. You are mining status, not coins."
          />
          <Card 
            icon={<Scale className="text-[#00FFC2]" />}
            title="Sybil-Resistance"
            desc="To forge a high Continuity Score, an attacker must maintain physical power and network uptime for weeks. The cost of forgery exceeds the value of the attack."
          />
        </div>

        <div className="prose prose-invert prose-p:font-light prose-p:text-white/80 border-t border-white/10 pt-12">
          <h3 className="font-serif text-3xl mb-6">The "Work" of Being Human</h3>
          <p>
            In Proof-of-Work, miners burn electricity to secure a ledger. In Invariant, nodes "burn" <strong>latency and hardware availability</strong> to secure the identity graph.
          </p>
          <p>
            By keeping your node active, you provide a "Heartbeat" to the network. This heartbeat creates a high-trust region in the graph, making it mathematically impossible for botnets to infiltrate without incurring massive physical costs.
          </p>
          <blockquote className="border-l-2 border-[#00FFC2] pl-6 italic text-white/60 my-8">
            "We do not pay you to use the app. We recognize you for anchoring the truth."
          </blockquote>
        </div>
      </main>
      <Footer />
    </div>
  );
}

function Nav() {
  return (
    <nav className="fixed top-0 w-full bg-[#050505]/80 backdrop-blur-md border-b border-white/10 z-50 px-6 h-16 flex items-center">
      <Link href="/" className="flex items-center space-x-2 text-white/60 hover:text-white transition-colors">
        <ArrowLeft size={18} />
        <span className="text-sm font-mono">RETURN</span>
      </Link>
    </nav>
  );
}

function Card({ icon, title, desc }: any) {
  return (
    <div className="bg-white/5 border border-white/10 p-6 rounded-lg hover:border-[#00FFC2]/50 transition-colors">
      <div className="mb-4">{icon}</div>
      <h3 className="text-xl font-serif mb-2">{title}</h3>
      <p className="text-sm text-white/60 font-light">{desc}</p>
    </div>
  );
}