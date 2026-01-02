"use client";

import Link from "next/link";
import { ArrowLeft, Mail, MessageSquare } from "lucide-react";

export default function Contact() {
  return (
    <div className="min-h-screen bg-[#050505] text-white font-sans selection:bg-[#00FFC2] selection:text-black flex flex-col">
      <nav className="fixed top-0 w-full bg-[#050505]/80 backdrop-blur-md border-b border-white/10 z-50 px-6 h-16 flex items-center">
        <Link href="/" className="flex items-center space-x-2 text-white/60 hover:text-white transition-colors">
          <ArrowLeft size={18} />
          <span className="text-sm font-mono">RETURN</span>
        </Link>
      </nav>

      <main className="grow flex items-center justify-center p-6">
        <div className="max-w-2xl w-full text-center">
          <h1 className="text-5xl font-serif mb-6">Signal over Noise.</h1>
          <p className="text-white/60 font-light mb-12">
            We are currently in Stealth / Genesis Mode. We prioritize encrypted channels and high-signal communication.
          </p>

          <div className="grid md:grid-cols-2 gap-4">
            <a href="mailto:genesis@invariant.tech" className="flex items-center justify-center space-x-3 p-8 border border-white/10 bg-white/5 hover:border-[#00FFC2] hover:text-[#00FFC2] transition-all group">
              <Mail size={24} />
              <span className="font-mono text-sm">GENESIS@INVARIANT.TECH</span>
            </a>
            <a href="https://discord.gg/invariant" className="flex items-center justify-center space-x-3 p-8 border border-white/10 bg-white/5 hover:border-[#00FFC2] hover:text-[#00FFC2] transition-all group">
              <MessageSquare size={24} />
              <span className="font-mono text-sm">ENCRYPTED COMMS</span>
            </a>
          </div>
        </div>
      </main>
    </div>
  );
}