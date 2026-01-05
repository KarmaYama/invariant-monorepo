// invariant-web/src/app/pilot/page.tsx
"use client";

import { 
  Download, ShieldCheck, BatteryWarning, Signal, 
  Bot, Fingerprint, Hash, Globe, CheckCircle2 
} from "lucide-react";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";

export default function PilotGuide() {
  return (
    <div className="min-h-screen bg-[#050505] text-white font-sans selection:bg-[#00FFC2] selection:text-black">
      
      <Header />

      <main className="max-w-4xl mx-auto pt-32 pb-24 px-6">
        
        {/* HERO */}
        <div className="mb-20 text-center">
          <div className="inline-flex items-center gap-2 bg-[#00FFC2]/10 px-3 py-1 rounded-full border border-[#00FFC2]/20 mb-8">
            <span className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-[#00FFC2] opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2 w-2 bg-[#00FFC2]"></span>
            </span>
            <span className="text-[#00FFC2] font-mono text-xs tracking-widest font-bold">COHORT 1: OPEN</span>
          </div>
          
          <h1 className="text-5xl md:text-6xl font-serif mb-4 leading-tight">
            Anchor trust to your phone. <br />
            <span className="text-[#00FFC2]">Become a Founding Node.</span>
          </h1>
          
          <p className="text-lg md:text-xl text-white/60 font-light leading-relaxed max-w-2xl mx-auto mb-6">
            Run a tiny background node on your Android device for 14 days. We verify hardware (not people) and give early contributors a permanent Genesis badge.
          </p>

          {/* TRUST SIGNALS */}
          <div className="flex flex-wrap justify-center gap-4 text-xs font-mono text-white/40 uppercase tracking-wider">
            <span className="flex items-center gap-1"><ShieldCheck size={12}/> ZERO PII</span>
            <span className="flex items-center gap-1"><BatteryWarning size={12}/> {"<1%"} Battery Impact</span>
            <span className="flex items-center gap-1"><Signal size={12}/> Passive Heartbeats</span>
          </div>
        </div>

        {/* DOWNLOAD CARD */}
        <div id="download" className="bg-[#00FFC2]/5 border border-[#00FFC2]/20 p-12 rounded-lg mb-24 text-center relative overflow-hidden">
          <div className="absolute top-0 left-0 w-full h-1 bg-linear-to-r from-transparent via-[#00FFC2] to-transparent opacity-50" />

          <h2 className="text-3xl font-serif text-white mb-4">Install the Pilot Node</h2>
          <p className="text-white/60 mb-8 max-w-lg mx-auto">
            Quick setup: install the APK, authenticate once, and leave it installed for 14 days. We only collect attestation certificates — no names or contacts.
          </p>
          
          <div className="flex flex-col items-center gap-6">
            <a 
              href="/invariant.apk" 
              download 
              className="flex items-center gap-3 bg-[#00FFC2] text-black px-10 py-5 rounded font-mono font-bold text-lg hover:bg-[#00FFC2]/90 hover:scale-105 transition-all shadow-[0_0_30px_rgba(0,255,194,0.4)]"
              aria-label="Download Invariant Pilot APK"
            >
              <Download size={24} />
              INSTALL PILOT NODE
            </a>
            
            <div className="bg-black/40 border border-white/10 px-4 py-2 rounded text-left">
              <div className="text-[10px] font-mono text-[#00FFC2]/60 uppercase mb-1">SHA-256 FINGERPRINT</div>
              <div className="text-xs font-mono text-white/50 select-all">
                e13c52adc3babb6a4f4edfcc1f660cdbe478cb012a37c90af526995558fbe444
              </div>
            </div>

            <a href="#activation" className="text-sm text-white/60 underline mt-2">How it works →</a>
          </div>
        </div>

        {/* INSTRUCTIONS */}
        <div id="activation" className="space-y-12 mb-24 max-w-2xl mx-auto">
          <h2 className="text-xl font-mono text-white/40 uppercase tracking-widest border-b border-white/10 pb-4 mb-8">Activation Sequence</h2>

          <InstructionStep 
            number="1" 
            title="Handshake" 
            desc="Open the app and authenticate once. This generates a device-bound key inside the Secure Enclave."
            icon={<ShieldCheck size={18} className="text-[#00FFC2]"/>}
          />

          <InstructionStep 
            number="2" 
            title="Allow Background" 
            desc="Settings → Apps → Invariant → Battery → Unrestricted. This prevents the OS from stopping the heartbeat."
            sub="Required to ensure your node completes 14 days of heartbeats."
            icon={<BatteryWarning size={18} className="text-amber-500"/>}
            isWarning
          />

          <InstructionStep 
            number="3" 
            title="Passive Operation" 
            desc="Leave the app installed. It uses negligible battery and no personal data — check the public Leaderboard to see your status."
            icon={<Signal size={18} className="text-[#00FFC2]"/>}
          />
        </div>

        {/* DISCLAIMER */}
        <div className="border border-white/10 bg-white/5 p-6 rounded text-sm text-white/50 font-light text-center leading-relaxed">
          <strong className="text-white block mb-2 font-mono uppercase text-xs tracking-widest">Research Disclosure</strong>
          This is an experimental infrastructure pilot. We only process cryptographic attestations — no names, contacts, GPS, or biometrics are collected.
        </div>

      </main>
      <Footer />
    </div>
  );
}

function InstructionStep({ number, title, desc, sub, icon, isWarning }: any) {
  return (
    <div className="flex gap-6 group">
      <div className={`flex-none w-10 h-10 rounded flex items-center justify-center font-mono font-bold text-lg border ${
        isWarning ? 'bg-amber-500/10 text-amber-500 border-amber-500/20' : 'bg-white/5 text-[#00FFC2] border-white/10'
      }`}>
        {number}
      </div>
      <div>
        <h3 className="text-xl font-bold text-white mb-2 flex items-center gap-3">
          {title} {icon}
        </h3>
        <p className="text-white/70 font-light leading-relaxed mb-2">
          {desc}
        </p>
        {sub && (
          <p className="text-amber-500/80 text-sm font-mono bg-amber-500/10 px-2 py-1 inline-block rounded">
            {sub}
          </p>
        )}
      </div>
    </div>
  );
}
