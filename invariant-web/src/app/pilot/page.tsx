// invariant-web/src/app/pilot/page.tsx
"use client";

import { Download, CheckCircle2, Shield } from "lucide-react";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";

export default function Pilot() {
  return (
    <div className="min-h-screen bg-[#050505] text-white font-sans selection:bg-[#00FFC2] selection:text-black">
      <Header />

      <main className="pt-40 pb-24 px-6 max-w-3xl mx-auto text-center">
        
        <div className="inline-block bg-white/5 border border-white/10 px-4 py-1.5 rounded-full mb-8">
          <span className="text-[#00FFC2] text-xs font-bold tracking-widest uppercase">Open Beta Access</span>
        </div>

        <h1 className="text-5xl md:text-6xl font-serif mb-6 leading-tight">
          Verify Your Device.
        </h1>
        
        <p className="text-xl text-white/50 font-light leading-relaxed mb-12 max-w-xl mx-auto">
          Download the Invariant Pilot app to generate your secure hardware key. 
          No account creation required.
        </p>

        {/* THE DOWNLOAD CARD - CLEANER */}
        <div className="bg-white/5 border border-white/10 p-10 rounded-2xl mb-16 relative overflow-hidden group hover:border-white/20 transition-all">
          <div className="absolute top-0 left-0 w-full h-1 bg-[#00FFC2] opacity-80" />
          
          <div className="flex flex-col items-center">
            <div className="w-16 h-16 bg-[#00FFC2]/20 rounded-full flex items-center justify-center mb-6 text-[#00FFC2]">
              <Download size={32} />
            </div>
            
            <h3 className="text-2xl font-serif text-white mb-2">Android Pilot Client</h3>
            <p className="text-white/40 text-sm mb-8">Version 1.3.0 • 50MB • Safe & Signed</p>
            
            <a 
              href="/invariant.apk" 
              download 
              className="w-full sm:w-auto bg-[#00FFC2] text-black px-12 py-4 rounded font-bold tracking-wide hover:scale-105 transition-transform"
            >
              DOWNLOAD APK
            </a>
            
            <div className="mt-6 flex items-center gap-2 text-white/30 text-xs">
              <Shield size={12} />
              <span>Cryptographically Signed by Invariant Protocol</span>
            </div>
          </div>
        </div>

        {/* SIMPLE STEPS */}
        <div className="text-left max-w-md mx-auto space-y-8">
          <Step 
            num="01" 
            text="Install the App" 
            sub="Accept the security prompt. We do not track location." 
          />
          <Step 
            num="02" 
            text="Tap to Initialize" 
            sub="The app will communicate with your phone's Secure Enclave." 
          />
          <Step 
            num="03" 
            text="Confirm Daily" 
            sub="Open the app once a day to prove you still possess the device." 
          />
        </div>

      </main>
      <Footer />
    </div>
  );
}

function Step({ num, text, sub }: any) {
  return (
    <div className="flex gap-6">
      <span className="text-[#00FFC2] font-serif text-xl italic opacity-50">{num}</span>
      <div>
        <h4 className="text-lg text-white font-medium mb-1">{text}</h4>
        <p className="text-white/50 text-sm font-light leading-relaxed">{sub}</p>
      </div>
    </div>
  );
}