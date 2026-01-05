"use client";

import Link from "next/link";
import { Github, Mail } from "lucide-react"; // Removed Linkedin (Too corporate)
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";

export default function About() {
  return (
    <div className="min-h-screen bg-[#050505] text-white font-sans selection:bg-[#00FFC2] selection:text-black">
      <Header />

      <main className="max-w-5xl mx-auto pt-40 px-6 pb-24">
        
        {/* HEADER */}
        <div className="mb-24 border-b border-white/10 pb-16">
          <h1 className="text-5xl md:text-7xl font-serif mb-8">The Maintainers.</h1>
          <p className="text-xl text-white/60 font-light max-w-2xl leading-relaxed">
            Invariant is an open-source research initiative. <br/>
            It is a protocol built by two engineers obsessed with solving the Sybil problem via hardware constraints.
          </p>
        </div>

        {/* FOUNDER GRID */}
        <div className="grid md:grid-cols-2 gap-12 mb-32">
          
          {/* ALEX - The Engine */}
          <div className="group">
            <div className="border-l-2 border-white/20 pl-6 py-2 mb-6 group-hover:border-[#00FFC2] transition-colors">
              <h2 className="text-3xl font-serif text-white mb-1">Alex Matrino</h2>
              {/* VISA SAFE TITLE: Technical Role Only */}
              <div className="text-xs font-mono text-white/40 group-hover:text-[#00FFC2] tracking-widest uppercase transition-colors">Protocol Architect</div>
            </div>
            <p className="text-white/60 leading-relaxed mb-8 h-24">
              Focuses on the <strong>Rust Attestation Engine</strong> and low-level hardware constraints. Responsible for the backend architecture, TEE integration logic, and the "Proof of Latency" mechanism.
            </p>
            <div className="flex space-x-6">
              <SocialLink icon={<Github size={20} />} label="GITHUB" href="https://github.com/KarmaYama" />
              <SocialLink icon={<Mail size={20} />} label="EMAIL" href="mailto:alex.matarirano@invariantprotocol.com" />
            </div>
          </div>

          {/* CRISTOBAL - The Interface */}
          <div className="group">
            <div className="border-l-2 border-white/20 pl-6 py-2 mb-6 group-hover:border-[#00FFC2] transition-colors">
              <h2 className="text-3xl font-serif text-white mb-1">Cristobal Olivares</h2>
              {/* VISA SAFE TITLE: Technical Role Only */}
              <div className="text-xs font-mono text-white/40 group-hover:text-[#00FFC2] tracking-widest uppercase transition-colors">Frontend Lead</div>
            </div>
            <p className="text-white/60 leading-relaxed mb-8 h-24">
              Manages the <strong>Web Infrastructure</strong> and client-side architecture. Responsible for the frontend experience, developer documentation, and ensuring the protocol remains accessible.
            </p>
            <div className="flex space-x-6">
              <SocialLink icon={<Github size={20} />} label="GITHUB" href="https://github.com/ToTozudo" />
              <SocialLink icon={<Mail size={20} />} label="EMAIL" href="mailto:cristobal@invariantprotocol.com" />
            </div>
          </div>

        </div>

        {/* MISSION STATEMENT */}
        <div className="bg-white/5 border border-white/10 p-12 rounded-lg">
          <h3 className="text-sm font-mono text-white/40 mb-6 uppercase tracking-widest">Our Thesis</h3>
          <p className="text-2xl md:text-3xl font-serif leading-tight text-white/90">
            "We believe the internet was built without an identity layer. We are building the hardware primitives to fix it as a public good."
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