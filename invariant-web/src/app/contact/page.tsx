"use client";

import { Mail, LifeBuoy, Terminal, ShieldAlert } from "lucide-react";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";

export default function Contact() {
  return (
    <div className="min-h-screen bg-[#050505] text-white font-sans selection:bg-[#00FFC2] selection:text-black flex flex-col">
      
      <Header />

      <main className="grow pt-32 pb-24 px-6 max-w-5xl mx-auto w-full">
        
        {/* HEADER */}
        <div className="mb-16 border-b border-white/10 pb-12">
          <h1 className="text-4xl md:text-5xl font-serif mb-6">Contact the Maintainers.</h1>
          <p className="text-white/60 font-light text-lg max-w-2xl leading-relaxed">
            Invariant is an experimental protocol. We are currently prioritizing technical collaboration with Pilot participants and open-source contributors.
          </p>
        </div>

        {/* DEPARTMENT GRID */}
        <div className="grid md:grid-cols-2 gap-6 mb-24">
          
          {/* 1. TECHNICAL INTEGRATION (Replaces Commercial) */}
          <a href="mailto:partners@invariantprotocol.com" className="group p-8 border border-white/10 bg-white/5 rounded hover:border-[#00FFC2]/50 transition-all">
            <div className="flex justify-between items-start mb-6">
              <Terminal className="text-[#00FFC2]" size={28} />
              <span className="text-xs font-mono text-white/30 uppercase tracking-widest group-hover:text-[#00FFC2] transition-colors">Builders</span>
            </div>
            <h3 className="text-xl font-bold text-white mb-2">Technical Integration</h3>
            <p className="text-sm text-white/50 font-light mb-6">
              For developers and platforms seeking to implement the Invariant SDK or contribute to the codebase.
            </p>
            <span className="text-[#00FFC2] text-sm font-mono border-b border-[#00FFC2]/30 pb-1">partners@invariantprotocol.com</span>
          </a>

          {/* 2. PILOT SUPPORT */}
          <a href="mailto:pilot@invariantprotocol.com" className="group p-8 border border-white/10 bg-white/5 rounded hover:border-white/30 transition-all">
            <div className="flex justify-between items-start mb-6">
              <LifeBuoy className="text-white/60 group-hover:text-white transition-colors" size={28} />
              <span className="text-xs font-mono text-white/30 uppercase tracking-widest">Community</span>
            </div>
            <h3 className="text-xl font-bold text-white mb-2">Pilot Support</h3>
            <p className="text-sm text-white/50 font-light mb-6">
              For Founding Agents participating in the Testnet V1. Report bugs or request technical assistance.
            </p>
            <span className="text-white/80 text-sm font-mono border-b border-white/30 pb-1">pilot@invariantprotocol.com</span>
          </a>

          {/* 3. SECURITY DISCLOSURE */}
          <a href="mailto:security@invariantprotocol.com" className="group p-8 border border-white/10 bg-white/5 rounded hover:border-white/30 transition-all">
            <div className="flex justify-between items-start mb-6">
              <ShieldAlert className="text-amber-500" size={28} />
              <span className="text-xs font-mono text-white/30 uppercase tracking-widest">Security</span>
            </div>
            <h3 className="text-xl font-bold text-white mb-2">Responsible Disclosure</h3>
            <p className="text-sm text-white/50 font-light mb-6">
              Report vulnerabilities regarding the Rust Engine or Android TEE Attestation.
            </p>
            <span className="text-white/80 text-sm font-mono border-b border-white/30 pb-1">security@invariantprotocol.com</span>
          </a>

          {/* 4. GENERAL */}
          <a href="mailto:hello@invariantprotocol.com" className="group p-8 border border-white/10 bg-white/5 rounded hover:border-white/30 transition-all">
            <div className="flex justify-between items-start mb-6">
              <Mail className="text-white/60" size={28} />
              <span className="text-xs font-mono text-white/30 uppercase tracking-widest">General</span>
            </div>
            <h3 className="text-xl font-bold text-white mb-2">General Inquiries</h3>
            <p className="text-sm text-white/50 font-light mb-6">
              General information about the protocol and research goals.
            </p>
            <span className="text-white/80 text-sm font-mono border-b border-white/30 pb-1">hello@invariantprotocol.com</span>
          </a>

        </div>

        {/* FOOTER DETAILS - STRIPPED OF SLA */}
        <div className="border-t border-white/10 pt-12 flex flex-col md:flex-row justify-between gap-8 text-sm text-white/40 font-mono">
          <div>
            <p className="mb-2 text-white/20 uppercase tracking-widest text-xs">Location</p>
            <p>London, United Kingdom</p>
          </div>
          <div>
            <p className="mb-2 text-white/20 uppercase tracking-widest text-xs">Project Status</p>
            <p>Testnet V1 (Alpha)</p>
          </div>
        </div>

      </main>
      <Footer />
    </div>
  );
}