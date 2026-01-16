// invariant-web/src/app/about/page.tsx
"use client";

import Link from "next/link";
import { Github, Mail } from "lucide-react"; 
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";

export default function About() {
  return (
    <div className="min-h-screen bg-[#050505] text-white font-sans selection:bg-[#00FFC2] selection:text-black">
      <Header />

      <main className="max-w-4xl mx-auto pt-40 px-6 pb-24">
        
        <h1 className="text-5xl font-serif mb-8">The Team.</h1>
        <p className="text-xl text-white/60 font-light max-w-2xl leading-relaxed mb-24">
          Invariant is built by engineers specializing in cryptography and systems architecture. We are funded by a shared belief that the internet needs a public utility for trust.
        </p>

        <div className="grid md:grid-cols-2 gap-16">
          
          {/* ALEX */}
          <div>
            <div className="mb-6 border-b border-white/10 pb-4">
              <h2 className="text-3xl font-serif text-white">Alex Matrino</h2>
              <p className="text-[#00FFC2] text-sm mt-1">Founding Engineer</p>
            </div>
            <p className="text-white/60 leading-relaxed mb-6 font-light">
              Specialist in low-level systems and Trusted Execution Environments (TEE). Alex architected the Rust attestation engine that powers the Invariant core.
            </p>
            <div className="flex gap-4">
              <SocialLink icon={<Github size={18} />} href="https://github.com/KarmaYama" />
              <SocialLink icon={<Mail size={18} />} href="mailto:alex.matarirano@invariantprotocol.com" />
            </div>
          </div>

          {/* CRISTOBAL */}
          <div>
            <div className="mb-6 border-b border-white/10 pb-4">
              <h2 className="text-3xl font-serif text-white">Cristobal Olivares</h2>
              <p className="text-[#00FFC2] text-sm mt-1">Product & Frontend</p>
            </div>
            <p className="text-white/60 leading-relaxed mb-6 font-light">
              Expert in scalable client architecture. Cristobal leads the development of the mobile client and the integration SDKs for partners.
            </p>
            <div className="flex gap-4">
              <SocialLink icon={<Github size={18} />} href="https://github.com/ToTozudo" />
              <SocialLink icon={<Mail size={18} />} href="mailto:cristobal@invariantprotocol.com" />
            </div>
          </div>

        </div>

      </main>
      <Footer />
    </div>
  );
}

function SocialLink({ icon, href }: any) {
  return (
    <Link href={href} className="text-white/40 hover:text-white transition-colors p-2 border border-white/10 rounded-full hover:bg-white/5">
      {icon}
    </Link>
  );
}