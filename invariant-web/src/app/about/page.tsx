"use client";

import Link from "next/link";
import { ArrowLeft } from "lucide-react";

export default function About() {
  return (
    <div className="min-h-screen bg-[#050505] text-white font-sans selection:bg-[#00FFC2] selection:text-black">
      <nav className="fixed top-0 w-full bg-[#050505]/80 backdrop-blur-md border-b border-white/10 z-50 px-6 h-16 flex items-center">
        <Link href="/" className="flex items-center space-x-2 text-white/60 hover:text-white transition-colors">
          <ArrowLeft size={18} />
          <span className="text-sm font-mono">RETURN</span>
        </Link>
      </nav>

      <main className="max-w-4xl mx-auto pt-40 px-6">
        <h1 className="text-6xl font-serif mb-12">The Architects.</h1>
        
        <div className="prose prose-invert prose-lg prose-p:font-light prose-p:text-white/80">
          <p>
            We are a collective of engineers, cryptographers, and hardware optimists who believe that 
            <strong> certainty</strong> is the most valuable commodity in the 21st century.
          </p>
          <p>
            The internet was built without an identity layer. For 30 years, corporations patched this hole with centralized databases. 
            Now, those databases are leaking, and AI is rendering them obsolete.
          </p>
          <p>
            We are building the Invariant Protocol not because we want to, but because we have to. 
            There is no future for the digital economy without a way to distinguish a human from a script.
          </p>
        </div>

        <div className="mt-24 grid md:grid-cols-3 gap-8 text-center font-mono text-sm border-t border-white/10 pt-12">
          <div>
            <div className="text-[#00FFC2] mb-2">FOUNDED</div>
            <div>2025</div>
          </div>
          <div>
            <div className="text-[#00FFC2] mb-2">LOCATION</div>
            <div>DISTRIBUTED / GLOBAL</div>
          </div>
          <div>
            <div className="text-[#00FFC2] mb-2">MISSION</div>
            <div>PROOF OF DEVICE</div>
          </div>
        </div>
      </main>
    </div>
  );
}