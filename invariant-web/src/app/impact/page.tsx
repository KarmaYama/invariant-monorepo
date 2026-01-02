"use client";

import { motion } from "framer-motion";
import Link from "next/link";
import { ArrowLeft, Users, Globe, Bot } from "lucide-react";

export default function Impact() {
  return (
    <div className="min-h-screen bg-[#050505] text-white font-sans selection:bg-[#00FFC2] selection:text-black">
      <nav className="fixed top-0 w-full bg-[#050505]/80 backdrop-blur-md border-b border-white/10 z-50 px-6 h-16 flex items-center">
        <Link href="/" className="flex items-center space-x-2 text-white/60 hover:text-white transition-colors">
          <ArrowLeft size={18} />
          <span className="text-sm font-mono">RETURN</span>
        </Link>
      </nav>

      <main className="max-w-6xl mx-auto pt-32 pb-24 px-6">
        <div className="grid md:grid-cols-2 gap-16 items-center">
          <div>
            <motion.div
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
            >
              <h1 className="text-5xl md:text-7xl font-serif mb-8">Democracy<br/>vs. The Bot.</h1>
              <p className="text-xl text-white/60 font-light mb-8">
                Generative AI creates infinite content. Invariant creates finite identity. Without scarcity, digital democracy is mathematically impossible.
              </p>
            </motion.div>
          </div>
          
          <div className="space-y-6">
            <StatRow 
              icon={<Bot size={24} />}
              stat="1.3 Trillion"
              label="Bot Interactions / Year"
              desc="The noise drowning out human consensus."
            />
            <StatRow 
              icon={<Globe size={24} />}
              stat="3.9 Billion"
              label="Secure Devices"
              desc="Android phones ready to be activated as anchors."
            />
            <StatRow 
              icon={<Users size={24} />}
              stat="Zero"
              label="Barriers to Entry"
              desc="No passport. No bank account. Just a phone."
            />
          </div>
        </div>
      </main>
    </div>
  );
}

function StatRow({ icon, stat, label, desc }: any) {
  return (
    <div className="flex items-start space-x-6 p-6 border border-white/10 bg-white/5 hover:border-[#00FFC2]/30 transition-colors rounded-lg">
      <div className="text-[#00FFC2] mt-1">{icon}</div>
      <div>
        <div className="text-3xl font-mono text-white mb-1">{stat}</div>
        <div className="text-sm font-bold text-white/80 mb-2 uppercase tracking-wide">{label}</div>
        <p className="text-sm text-white/50 font-light">{desc}</p>
      </div>
    </div>
  );
}