"use client";

import { 
  Download, ShieldCheck, BatteryWarning, Signal, 
  Bot, Fingerprint, Hash, Globe 
} from "lucide-react";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";

export default function PilotGuide() {
  return (
    <div className="min-h-screen bg-[#050505] text-white font-sans selection:bg-[#00FFC2] selection:text-black">
      
      <Header />

      <main className="max-w-4xl mx-auto pt-32 pb-24 px-6">
        
        {/* HERO: THE CALL TO ACTION */}
        <div className="mb-20 text-center">
          <div className="inline-flex items-center gap-2 bg-[#00FFC2]/10 px-3 py-1 rounded-full border border-[#00FFC2]/20 mb-8">
            <span className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-[#00FFC2] opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2 w-2 bg-[#00FFC2]"></span>
            </span>
            <span className="text-[#00FFC2] font-mono text-xs tracking-widest font-bold">COHORT 1: RECRUITING</span>
          </div>
          
          <h1 className="text-5xl md:text-7xl font-serif mb-6 leading-tight">
            The Internet is drowning. <br/>
            <span className="text-[#00FFC2]">Be the Anchor.</span>
          </h1>
          
          <p className="text-xl text-white/60 font-light leading-relaxed max-w-2xl mx-auto">
            We are building a network to distinguish humans from AI without invading privacy. 
            We need 20 Founding Agents to prove the cost model works.
          </p>
        </div>

        {/* THE MANIFESTO: THE "WHY" */}
        <div className="grid md:grid-cols-3 gap-8 mb-24">
          <div className="bg-white/5 p-8 rounded border border-white/10">
            <Bot className="text-white/40 mb-6" size={32} />
            <h3 className="text-lg font-bold text-white mb-3">The Problem</h3>
            <p className="text-sm text-white/60 leading-relaxed">
              AI-generated traffic is rapidly overtaking human activity online. As this accelerates, the trust required for digital society is collapsing.
            </p>
          </div>
          <div className="bg-white/5 p-8 rounded border border-white/10">
            <Fingerprint className="text-[#00FFC2] mb-6" size={32} />
            <h3 className="text-lg font-bold text-white mb-3">The Solution</h3>
            <p className="text-sm text-white/60 leading-relaxed">
              AI has infinite software power, but zero physical presence. By anchoring identity to physical hardware, we dramatically raise the cost of large-scale impersonation.
            </p>
          </div>
          <div className="bg-white/5 p-8 rounded border border-white/10">
            <Globe className="text-white/40 mb-6" size={32} />
            <h3 className="text-lg font-bold text-white mb-3">Your Role</h3>
            <p className="text-sm text-white/60 leading-relaxed">
              You aren't just a user. You are a <strong>Network Node</strong>. Your phone provides the "Heartbeat" that secures the network for everyone else.
            </p>
          </div>
        </div>

        {/* ⚠️ THE NO-HYPE DISCLAIMER */}
        <div className="border-l-4 border-amber-500 bg-amber-500/5 p-8 mb-24 rounded-r">
          <div className="flex items-start gap-4">
            <Hash className="text-amber-500 shrink-0 mt-1" size={24} />
            <div>
              <h3 className="text-amber-500 font-mono text-sm font-bold tracking-widest uppercase mb-2">Read Before Joining</h3>
              <p className="text-white/80 font-serif text-xl mb-4">
                This is not a financial product.
              </p>
              <p className="text-white/60 text-sm leading-relaxed max-w-2xl">
                Invariant is an experimental cryptographic infrastructure. We do not promise token airdrops, financial returns, or "passive income." 
                <br/><br/>
                We are asking for your help to build a public good: a bot-proof layer for the internet. Your reward is the <strong>Genesis Status</strong>—a permanent, cryptographic badge proving you were here when the lights were turned on.
                <br/><br/>
                <span className="text-white/80 font-medium">Genesis Status is non-transferable, non-tradable, and carries no monetary value.</span>
              </p>
            </div>
          </div>
        </div>

        {/* DOWNLOAD SECTION */}
        <div id="download" className="bg-[#00FFC2]/5 border border-[#00FFC2]/20 p-12 rounded-lg mb-24 text-center">
          <h2 className="text-3xl font-serif text-white mb-4">Ready to Anchor?</h2>
          <p className="text-white/60 mb-8 max-w-lg mx-auto">
            Your mission: Keep the app installed for 14 days. <br/>
            The system will test if a decentralized network can survive purely on mobile hardware.
          </p>
          
          <div className="flex flex-col items-center gap-4">
            {/* LINK UPDATED TO LOCAL ASSET */}
            <a href="/invariant.apk" download className="flex items-center gap-3 bg-[#00FFC2] text-black px-8 py-4 rounded font-mono font-bold text-base hover:bg-[#00FFC2]/90 hover:scale-105 transition-all shadow-[0_0_20px_rgba(0,255,194,0.3)]">
              <Download size={20} />
              DOWNLOAD PILOT NODE .APK
            </a>
            
            {/* HASH UPDATED FROM YOUR LOGS */}
            <div className="flex flex-col items-center gap-1 mt-2">
              <span className="text-[10px] font-mono text-[#00FFC2]/60 uppercase tracking-widest">SHA-256 CHECKSUM</span>
              <span className="text-[10px] font-mono text-white/30 bg-white/5 px-2 py-1 rounded select-all">
                6DD7913EF6CA77B5D4B636D8BEE1D79860B03250ED265D1A54ECE36FFF0085E4
              </span>
            </div>
          </div>
        </div>

        {/* THE SURVIVAL GUIDE */}
        <div className="space-y-12 mb-24 max-w-2xl mx-auto">
          <h2 className="text-xl font-mono text-white/40 uppercase tracking-widest border-b border-white/10 pb-4 mb-8">Operational Instructions</h2>

          <div className="flex gap-6 opacity-80 hover:opacity-100 transition-opacity">
            <div className="flex-none w-8 h-8 rounded bg-white/10 flex items-center justify-center font-mono font-bold text-[#00FFC2]">1</div>
            <div>
              <h3 className="text-lg font-bold text-white mb-2 flex items-center gap-2">
                Genesis Handshake <ShieldCheck size={16} className="text-[#00FFC2]"/>
              </h3>
              <p className="text-white/60 font-light leading-relaxed">
                Open the app. Authenticate with Biometrics. This generates your key inside the Secure Enclave.
              </p>
            </div>
          </div>

          <div className="flex gap-6 opacity-80 hover:opacity-100 transition-opacity">
            <div className="flex-none w-8 h-8 rounded bg-white/10 flex items-center justify-center font-mono font-bold text-amber-500">2</div>
            <div>
              <h3 className="text-lg font-bold text-white mb-2 flex items-center gap-2">
                Override Battery Saver <BatteryWarning size={16} className="text-amber-500"/>
              </h3>
              <p className="text-white/60 font-light leading-relaxed mb-3">
                Crucial Step: You must allow Invariant to run in the background, or the OS will kill your node.
              </p>
              <div className="bg-amber-500/10 border border-amber-500/20 p-3 rounded text-xs text-amber-200 font-mono inline-block">
                Settings &gt; Apps &gt; Invariant &gt; Battery &gt; Unrestricted
              </div>
              <p className="text-white/40 text-xs mt-3 italic">
                * Battery settings vary by manufacturer (Samsung, Xiaomi, etc.). If the app stops pulsing, search your device model + 'background battery settings'.
              </p>
            </div>
          </div>

          <div className="flex gap-6 opacity-80 hover:opacity-100 transition-opacity">
            <div className="flex-none w-8 h-8 rounded bg-white/10 flex items-center justify-center font-mono font-bold text-[#00FFC2]">3</div>
            <div>
              <h3 className="text-lg font-bold text-white mb-2 flex items-center gap-2">
                Hold the Line <Signal size={16} className="text-[#00FFC2]"/>
              </h3>
              <p className="text-white/60 font-light leading-relaxed">
                The app pulses every 4 hours. You don't need to open it constantly. Just ensure your phone stays on.
              </p>
            </div>
          </div>
        </div>

        {/* FOOTER */}
        <div className="mt-24 text-center border-t border-white/10 pt-12">
          <p className="text-white/30 font-mono text-xs mb-4">ISSUES? DIRECT LINE TO THE ARCHITECT</p>
          <a href="mailto:alex.matarirano@invariantprotocol.com" className="text-[#00FFC2] border-b border-[#00FFC2]/30 hover:border-[#00FFC2] pb-1 transition-all">
            alex.matarirano@invariantprotocol.com
          </a>
        </div>

      </main>
      <Footer />
    </div>
  );
}