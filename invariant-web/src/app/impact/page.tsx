"use client";

import { motion } from "framer-motion";
import Link from "next/link";
import { ArrowLeft, Server, ShieldAlert, Lock, Zap, ShieldCheck } from "lucide-react";

export default function Impact() {
  return (
    <div className="min-h-screen bg-[#050505] text-white font-sans selection:bg-[#00FFC2] selection:text-black flex flex-col">
      {/* NAV */}
      <nav className="fixed top-0 w-full bg-[#050505]/80 backdrop-blur-md border-b border-white/5 z-50 px-6 h-16 flex items-center justify-between">
        <Link href="/" className="group flex items-center space-x-2 text-white/60 hover:text-white transition-colors">
          <ArrowLeft size={16} className="group-hover:-translate-x-1 transition-transform" />
          <span className="text-xs font-mono tracking-widest">RETURN TO NETWORK</span>
        </Link>
        <div className="hidden md:flex items-center space-x-2">
          <div className="w-2 h-2 rounded-full bg-[#00FFC2] animate-pulse"></div>
          <span className="text-xs font-mono text-[#00FFC2] tracking-widest">LIVE SIGNAL</span>
        </div>
      </nav>

      <main className="grow pt-32 pb-24 px-6 max-w-7xl mx-auto w-full">
        
        {/* HERO SECTION */}
        <div className="mb-24 border-b border-white/10 pb-16">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
          >
            <h1 className="text-4xl md:text-7xl font-serif tracking-tight mb-8 leading-[1.1]">
              Introducing a Cost to <br/>
              <span className="text-[#00FFC2]">Automated Identity Abuse.</span>
            </h1>
            <div className="grid md:grid-cols-2 gap-12">
              <div className="text-lg md:text-xl text-white/60 font-light leading-relaxed">
                <p className="mb-6">
                  Generative automation has reduced the marginal cost of creating fake accounts to near zero.
                </p>
                <p>
                  Invariant introduces a <span className="text-white font-normal">hardware-backed verification step</span> that cannot be reproduced by emulators or scripts, allowing platforms to distinguish physical devices from automated infrastructure before incurring KYC or fraud costs.
                </p>
              </div>
              
              {/* METRICS - DE-RISKED */}
              <div className="flex flex-col justify-end items-start border-l border-white/10 pl-8 space-y-8">
                <div>
                  <div className="text-white font-mono text-lg mb-1">High Automation Risk</div>
                  <div className="text-xs font-mono text-white/40 uppercase tracking-widest leading-relaxed">
                    Significant portions of signup traffic can be automated in unprotected flows.
                  </div>
                </div>
                <div>
                  <div className="text-white font-mono text-lg mb-1">Zero Marginal Cost</div>
                  <div className="text-xs font-mono text-white/40 uppercase tracking-widest leading-relaxed">
                    Software-based identity checks have near-zero marginal attack cost for adversaries.
                  </div>
                </div>
              </div>
            </div>
          </motion.div>
        </div>

        {/* THE THREE OUTCOMES (Replaces "Pillars") */}
        <div className="grid md:grid-cols-3 gap-px bg-white/10 border border-white/10 mb-32">
          <ImpactCard 
            icon={<ShieldAlert size={20} />}
            title="Fraud Cost Externalization"
            body="Automated accounts consume referral budgets, customer support time, and compliance resources. By filtering non-hardware-backed devices upstream, Invariant reduces the volume of low-quality accounts entering downstream systems."
          />
          <ImpactCard 
            icon={<Server size={20} />}
            title="Device-Level Verification"
            body="Invariant relies on cryptographic properties of the device rather than user documents or behavioral inference. This allows platforms to apply a consistent integrity signal across regions without collecting additional personal data."
          />
          <ImpactCard 
            icon={<Lock size={20} />}
            title="Minimal Data Surface"
            body="Invariant does not collect biometric data, identity documents, or behavioral profiles. Verification is based on cryptographic attestations generated inside secure hardware, reducing data retention and breach risk."
          />
        </div>

        {/* COMPARISON TABLE (Technical Accuracy Focus) */}
        <div className="mb-24">
          <h2 className="text-sm font-mono text-[#00FFC2] mb-8 tracking-widest uppercase">Verification Methodology</h2>
          <div className="border-t border-white/10">
            <Row 
              left="Legacy Identity Checks" 
              right="Invariant Device Verification" 
              isHeader 
            />
            <Row 
              left="Document- or behavior-based" 
              right="Hardware-backed cryptographic attestation" 
            />
            <Row 
              left="Susceptible to automation" 
              right="Not reproducible by emulators" 
            />
            <Row 
              left="High user friction (Active)" 
              right="Background verification (Passive)" 
            />
            <Row 
              left="Centralized PII storage" 
              right="No PII collected or stored" 
            />
          </div>
        </div>

        {/* CALL TO ACTION (The Pilot Pitch) */}
        <div className="bg-white/5 border border-white/10 p-12 rounded-lg flex flex-col md:flex-row items-center justify-between gap-8">
          <div>
            <h3 className="text-2xl font-serif mb-2 text-white">Evaluate Device-Level Fraud Signals.</h3>
            <p className="text-white/50 max-w-lg text-sm leading-relaxed">
              Run Invariant in "Shadow Mode" alongside your existing onboarding flow. 
              After 30 days, compare our device classifications against your internal fraud outcomes.
            </p>
          </div>
          <Link href="mailto:partners@invariantprotocol.com" className="px-8 py-4 bg-[#00FFC2] text-black font-mono font-bold text-sm tracking-wide hover:bg-[#00FFC2]/90 transition-colors rounded-sm whitespace-nowrap">
            START SHADOW PILOT
          </Link>
        </div>

      </main>
    </div>
  );
}

function ImpactCard({ icon, title, body }: any) {
  return (
    <div className="bg-[#050505] p-10 hover:bg-white/5 transition-colors group h-full">
      <div className="text-[#00FFC2] mb-6 opacity-60 group-hover:opacity-100 transition-opacity">
        {icon}
      </div>
      <h3 className="text-lg font-serif mb-4 text-white">{title}</h3>
      <p className="text-sm text-white/50 leading-relaxed font-light">
        {body}
      </p>
    </div>
  );
}

function Row({ left, right, isHeader = false }: any) {
  return (
    <div className={`grid grid-cols-2 border-b border-white/10 ${isHeader ? 'py-6' : 'py-6 group hover:bg-white/5 transition-colors'}`}>
      <div className={`px-4 ${isHeader ? 'font-mono text-xs text-white/40 uppercase tracking-widest' : 'text-white/40 font-light font-mono text-sm flex items-center gap-3'}`}>
        {!isHeader && <span className="w-1.5 h-1.5 rounded-full bg-red-500/20"></span>}
        {left}
      </div>
      <div className={`px-4 ${isHeader ? 'font-mono text-xs text-[#00FFC2] uppercase tracking-widest text-right' : 'text-white font-medium text-sm text-right flex items-center justify-end gap-3'}`}>
        {right}
        {!isHeader && <ShieldCheck size={14} className="text-[#00FFC2]"/>}
      </div>
    </div>
  );
}