// invariant-web/src/app/pilot/page.tsx
"use client";

import Link from "next/link";
import { 
  Download, ShieldCheck, BatteryWarning, Signal, CheckCircle2, 
  Smartphone, AlertTriangle, ArrowRight 
} from "lucide-react";

export default function PilotGuide() {
  return (
    <div className="min-h-screen bg-[#050505] text-white font-sans selection:bg-[#00FFC2] selection:text-black">
      
      {/* NAV */}
      <nav className="fixed top-0 w-full bg-[#050505]/95 backdrop-blur-md border-b border-white/10 z-50 px-6 h-16 flex items-center justify-between">
        <Link href="/" className="flex items-center space-x-2 text-white/60 hover:text-white transition-colors">
          <span className="font-mono text-sm tracking-widest">INVARIANT GENESIS</span>
        </Link>
        <div className="flex items-center space-x-2">
          <div className="w-2 h-2 rounded-full bg-[#00FFC2] animate-pulse"></div>
          <span className="text-xs font-mono text-[#00FFC2] tracking-widest">TESTNET ACTIVE</span>
        </div>
      </nav>

      <main className="max-w-3xl mx-auto pt-32 pb-24 px-6">
        
        {/* HERO */}
        <div className="mb-16">
          <div className="inline-block bg-[#00FFC2]/10 px-3 py-1 rounded border border-[#00FFC2]/20 mb-6">
            <span className="text-[#00FFC2] font-mono text-xs tracking-widest font-bold">FOUNDING COHORT ONLY</span>
          </div>
          <h1 className="text-5xl md:text-6xl font-serif mb-6 leading-tight">
            Your Mission: <br/> Survive 14 Days.
          </h1>
          <p className="text-xl text-white/60 font-light leading-relaxed">
            You are 1 of 20 "Founding Agents." Your goal is to keep the Invariant Node alive on your phone for two weeks without the operating system killing it.
          </p>
        </div>

        {/* DOWNLOAD CARD */}
        <div className="bg-white/5 border border-white/10 p-8 rounded-lg mb-16 flex flex-col md:flex-row items-center gap-8">
          <div className="bg-[#00FFC2]/10 p-6 rounded-full">
            <Smartphone size={40} className="text-[#00FFC2]" />
          </div>
          <div className="grow">
            <h3 className="text-2xl font-serif mb-2">Step 1: Install the Node</h3>
            <p className="text-white/60 font-light text-sm mb-4">
              Download the APK directly to your Android device. You may need to allow "Install from Unknown Sources."
            </p>
            <div className="flex gap-4">
              <a href="#" className="flex items-center gap-2 bg-[#00FFC2] text-black px-6 py-3 rounded font-mono font-bold text-sm hover:bg-[#00FFC2]/90 transition-colors">
                <Download size={16} />
                DOWNLOAD .APK
              </a>
              <span className="text-xs font-mono text-white/30 self-center">v1.0.4 (15MB)</span>
            </div>
          </div>
        </div>

        {/* THE SURVIVAL GUIDE */}
        <div className="space-y-12 mb-24">
          <h2 className="text-2xl font-serif border-b border-white/10 pb-4 mb-8">The Survival Guide</h2>

          {/* STEP 1 */}
          <div className="flex gap-6">
            <div className="flex-none w-8 h-8 rounded bg-white/10 flex items-center justify-center font-mono font-bold text-[#00FFC2]">1</div>
            <div>
              <h3 className="text-lg font-bold text-white mb-2 flex items-center gap-2">
                Genesis Handshake <ShieldCheck size={16} className="text-[#00FFC2]"/>
              </h3>
              <p className="text-white/60 font-light leading-relaxed">
                Open the app. It will ask for Biometric Auth (Fingerprint/FaceID). This generates your <strong>Hardware Key</strong> inside the secure chip. If successful, you will see your "Identity Card."
              </p>
            </div>
          </div>

          {/* STEP 2 */}
          <div className="flex gap-6">
            <div className="flex-none w-8 h-8 rounded bg-white/10 flex items-center justify-center font-mono font-bold text-amber-500">2</div>
            <div>
              <h3 className="text-lg font-bold text-white mb-2 flex items-center gap-2">
                Kill the Battery Saver <BatteryWarning size={16} className="text-amber-500"/>
              </h3>
              <p className="text-white/60 font-light leading-relaxed mb-4">
                Android hates background apps. You <strong>MUST</strong> disable battery optimization for Invariant, or the OS will kill your node within 4 hours.
              </p>
              <div className="bg-amber-500/10 border border-amber-500/20 p-4 rounded text-sm text-amber-200 font-mono">
                Settings &gt; Apps &gt; Invariant &gt; Battery &gt; Unrestricted
              </div>
            </div>
          </div>

          {/* STEP 3 */}
          <div className="flex gap-6">
            <div className="flex-none w-8 h-8 rounded bg-white/10 flex items-center justify-center font-mono font-bold text-[#00FFC2]">3</div>
            <div>
              <h3 className="text-lg font-bold text-white mb-2 flex items-center gap-2">
                Maintain the Pulse <Signal size={16} className="text-[#00FFC2]"/>
              </h3>
              <p className="text-white/60 font-light leading-relaxed">
                The app sends a "Heartbeat" every 4 hours. You don't need to open it constantly, but check it once a day to ensure the ring is still spinning.
              </p>
              <ul className="mt-4 space-y-2 text-sm text-white/50">
                <li className="flex items-center gap-2"><CheckCircle2 size={12} className="text-[#00FFC2]"/> Streak &gt; 3 Days: <strong>PIONEER</strong></li>
                <li className="flex items-center gap-2"><CheckCircle2 size={12} className="text-[#00FFC2]"/> Streak &gt; 7 Days: <strong>STABILITY</strong></li>
                <li className="flex items-center gap-2"><CheckCircle2 size={12} className="text-[#00FFC2]"/> Streak &gt; 14 Days: <strong>GENESIS ANCHOR</strong></li>
              </ul>
            </div>
          </div>
        </div>

        {/* FAQ / TROUBLESHOOTING */}
        <div className="border-t border-white/10 pt-12">
          <h3 className="font-mono text-sm text-white/40 mb-8 uppercase tracking-widest">Troubleshooting</h3>
          
          <div className="space-y-6">
            <details className="group">
              <summary className="flex items-center justify-between cursor-pointer list-none text-white/80 hover:text-[#00FFC2] transition-colors font-medium">
                <span>The app says "Hardware Failure"</span>
                <ArrowRight size={16} className="group-open:rotate-90 transition-transform"/>
              </summary>
              <p className="text-white/50 font-light text-sm mt-2 leading-relaxed pl-4 border-l border-white/10 ml-1">
                This means your device's Secure Chip is busy or unsupported. Try restarting your phone. If it persists, your device might not support TEE Attestation (common on very old phones).
              </p>
            </details>

            <details className="group">
              <summary className="flex items-center justify-between cursor-pointer list-none text-white/80 hover:text-[#00FFC2] transition-colors font-medium">
                <span>My streak reset to 0</span>
                <ArrowRight size={16} className="group-open:rotate-90 transition-transform"/>
              </summary>
              <p className="text-white/50 font-light text-sm mt-2 leading-relaxed pl-4 border-l border-white/10 ml-1">
                You missed a 4-hour window. Likely, Android put the app to sleep. Double-check your Battery Settings and make sure "Background Data" is allowed.
              </p>
            </details>

            <details className="group">
              <summary className="flex items-center justify-between cursor-pointer list-none text-white/80 hover:text-[#00FFC2] transition-colors font-medium">
                <span>Is this draining my battery?</span>
                <ArrowRight size={16} className="group-open:rotate-90 transition-transform"/>
              </summary>
              <p className="text-white/50 font-light text-sm mt-2 leading-relaxed pl-4 border-l border-white/10 ml-1">
                Negligible. The app wakes up for about 3 seconds every 4 hours. It uses less energy than receiving a single WhatsApp message.
              </p>
            </details>
          </div>
        </div>

        {/* FOOTER */}
        <div className="mt-24 text-center">
          <p className="text-white/30 font-mono text-xs mb-4">NEED HELP? CONTACT THE OPERATOR</p>
          <a href="mailto:alex@invariant.tech" className="text-[#00FFC2] border-b border-[#00FFC2]/30 hover:border-[#00FFC2] pb-1 transition-all">
            alex@invariantprotocol.com
          </a>
        </div>

      </main>
    </div>
  );
}