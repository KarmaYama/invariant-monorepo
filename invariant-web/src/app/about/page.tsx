"use client";

import Link from "next/link";
import { ArrowLeft, Github, Linkedin, Mail } from "lucide-react";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";

export default function About() {
  return (
    <div className="min-h-screen bg-[#050505] text-white font-sans selection:bg-[#00FFC2] selection:text-black">
      <Header />

      <main className="max-w-5xl mx-auto pt-40 px-6 pb-24">
        
        {/* HEADER */}
        <div className="mb-24 border-b border-white/10 pb-16">
          <h1 className="text-5xl md:text-7xl font-serif mb-8">The Builders.</h1>
          <p className="text-xl text-white/60 font-light max-w-2xl leading-relaxed">
            Invariant is not a DAO, a foundation, or a "collective." <br/>
            It is a protocol built by two technical founders obsessed with solving the Sybil problem.
          </p>
        </div>

        {/* FOUNDER GRID */}
        <div className="grid md:grid-cols-2 gap-12 mb-32">
          
          {/* ALEX - The Engine */}
          <div className="group">
            <div className="border-l-2 border-white/20 pl-6 py-2 mb-6 group-hover:border-[#00FFC2] transition-colors">
              <h2 className="text-3xl font-serif text-white mb-1">Alex Matrino</h2>
              <div className="text-xs font-mono text-white/40 group-hover:text-[#00FFC2] tracking-widest uppercase transition-colors">Co-Founder / Protocol Architect</div>
            </div>
            <p className="text-white/60 leading-relaxed mb-8 h-24">
              Focuses on the <strong>Rust Attestation Engine</strong> and hardware constraints. Responsible for the backend architecture, TEE integration logic, and the "Proof of Latency" mechanism.
            </p>
            <div className="flex space-x-6">
              <SocialLink icon={<Github size={20} />} label="GITHUB" href="https://github.com/KarmaYama" />
              <SocialLink icon={<Mail size={20} />} label="CONTACT" href="mailto:alex.matarirano@invariantprotocol.com" />
            </div>
          </div>

          {/* CRISTOBAL - The Interface */}
          <div className="group">
            <div className="border-l-2 border-white/20 pl-6 py-2 mb-6 group-hover:border-[#00FFC2] transition-colors">
              <h2 className="text-3xl font-serif text-white mb-1">Cristobal Olivares</h2>
              <div className="text-xs font-mono text-white/40 group-hover:text-[#00FFC2] tracking-widest uppercase transition-colors">Co-Founder / Product Lead</div>
            </div>
            <p className="text-white/60 leading-relaxed mb-8 h-24">
              Manages the <strong>Web Infrastructure</strong> and operational strategy. Responsible for the frontend experience, partner integrations, and ensuring the protocol is usable by humans.
            </p>
            <div className="flex space-x-6">
              <SocialLink icon={<Github size={20} />} label="GITHUB" href="https://github.com/ToTozudo" />
              <SocialLink icon={<Mail size={20} />} label="CONTACT" href="mailto:cristobal@invariantprotocol.com" />
            </div>
          </div>

        </div>

        {/* MISSION STATEMENT */}
        <div className="bg-white/5 border border-white/10 p-12 rounded-lg">
          <h3 className="text-sm font-mono text-white/40 mb-6 uppercase tracking-widest">Our Thesis</h3>
          <p className="text-2xl md:text-3xl font-serif leading-tight text-white/90">
            "We believe the internet was built without an identity layer. For 30 years, centralized databases patched this hole. Now, AI is tearing those patches apart. We are building the hardware layer to fix it."
          </p>
        </div>

      </main>
      <Footer />
    </div>
  );
}

function SocialLink({ icon, label, href }: any) {
  return (
    <Link href={href} className="flex items-center space-x-2 text-white/40 hover:text-[#00FFC2] transition-colors">
      {icon}
      <span className="text-xs font-mono font-bold tracking-wider">{label}</span>
    </Link>
  );
}