"use client";

import { motion } from "framer-motion";
import { Shield, Fingerprint, Lock, ChevronRight, CheckCircle2, Smartphone, Terminal, Code2 } from "lucide-react";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";
import Link from "next/link";

export default function Landing() {
  return (
    <div className="min-h-screen bg-[#050505] text-white selection:bg-[#00FFC2] selection:text-black font-sans overflow-hidden flex flex-col">
      <Header />
      
      <main className="grow">
        
        {/* --- HERO SECTION: The Proposition --- */}
        <section className="relative pt-40 pb-32 px-6 max-w-7xl mx-auto">
          {/* Background Glow */}
          <div className="absolute top-0 right-0 w-125 h-125 bg-[#00FFC2] opacity-[0.03] blur-[120px] rounded-full pointer-events-none" />

          <motion.div 
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
          >
            <div className="inline-flex items-center gap-2 border border-white/10 bg-white/5 px-4 py-1.5 rounded-full mb-8">
              <span className="w-2 h-2 bg-[#00FFC2] rounded-full shadow-[0_0_10px_#00FFC2]" />
              <span className="text-xs font-medium tracking-wide text-white/80">Public Pilot Live</span>
            </div>

            <h1 className="text-5xl md:text-8xl font-serif tracking-tight mb-8 leading-[1.1] text-white">
              The End of <br />
              <span className="text-transparent bg-clip-text bg-linear-to-r from-white to-white/50">Impersonation.</span>
            </h1>
            
            <p className="text-xl md:text-2xl text-white/50 max-w-2xl font-light leading-relaxed mb-12">
              Software identity is broken. Invariant binds digital accounts to <span className="text-white">physical devices</span>, making mass-scale fraud mathematically impossible.
            </p>
            
            <div className="flex flex-col sm:flex-row gap-6">
              <Link 
                href="/pilot" 
                className="bg-[#00FFC2] text-black px-8 py-4 rounded-sm font-semibold text-lg hover:bg-[#00FFC2]/90 transition-all flex items-center justify-center gap-3"
              >
                <Smartphone size={20} />
                Get Verified
              </Link>
              <Link 
                href="/impact" 
                className="border border-white/20 text-white px-8 py-4 rounded-sm font-medium text-lg hover:bg-white/5 transition-all flex items-center justify-center gap-3"
              >
                Why It Matters
                <ChevronRight size={18} className="opacity-60" />
              </Link>
            </div>
          </motion.div>
        </section>

        {/* --- TRUST SIGNALS: The "Why" --- */}
        <section className="border-y border-white/5 bg-white/2">
          <div className="max-w-7xl mx-auto px-6 py-16 grid md:grid-cols-3 gap-12">
            <Feature 
              icon={<Shield size={24} className="text-[#00FFC2]" />}
              title="Hardware Locked"
              desc="We don't check passwords. We check the Secure Enclave chip inside the phone. It cannot be faked by AI."
            />
            <Feature 
              icon={<Fingerprint size={24} className="text-[#00FFC2]" />}
              title="Zero Personal Data"
              desc="No names. No biometrics. No phone numbers. We verify the device hardware, never the user's private life."
            />
            <Feature 
              icon={<Lock size={24} className="text-[#00FFC2]" />}
              title="Instant Killswitch"
              desc="If a device is stolen, its identity is revoked instantly. The physical thief gets a brick, not your access."
            />
          </div>
        </section>

        {/* --- PROBLEM/SOLUTION: The Story --- */}
        <section className="py-32 px-6 max-w-7xl mx-auto">
          <div className="grid md:grid-cols-2 gap-20 items-center">
            <div>
              <h2 className="text-4xl md:text-5xl font-serif mb-8 leading-tight">
                The internet was built <br/> without a <span className="text-[#00FFC2]">Body.</span>
              </h2>
              <div className="space-y-6 text-lg text-white/60 font-light">
                <p>
                  Today, a scammer can create 10,000 fake accounts for $5 using AI tools. They can impersonate your CEO, your bank, or your hiring manager.
                </p>
                <p>
                  Old defenses (SMS, Email, CAPTCHA) are failing.
                </p>
                <p className="text-white border-l-2 border-[#00FFC2] pl-6 py-2">
                  Invariant changes the rules. To create a fake identity on our network, an attacker must buy a physical smartphone. 
                  <br/><br/>
                  <strong>We raised the cost of fraud from $0.00 to $150.00 per attempt.</strong>
                </p>
              </div>
            </div>
            
            {/* Visual Abstract: The Shield */}
            <div className="relative h-125 w-full bg-white/5 rounded-2xl border border-white/10 overflow-hidden flex items-center justify-center">
              <div className="absolute inset-0 bg-linear-to-tr from-[#00FFC2]/10 to-transparent opacity-50" />
              <div className="text-center space-y-6 relative z-10">
                <div className="w-24 h-24 bg-[#00FFC2]/10 rounded-full flex items-center justify-center mx-auto border border-[#00FFC2]/30 backdrop-blur-md">
                  <Shield size={48} className="text-[#00FFC2]" />
                </div>
                <div>
                  <div className="text-2xl font-serif text-white">Status: Secure</div>
                  <div className="text-white/40 font-mono text-sm mt-2">DEVICE ID: 8A2...99F</div>
                </div>
                <div className="flex gap-2 justify-center mt-4">
                  <Badge text="TITANIUM TIER" />
                  <Badge text="HARDWARE BOUND" />
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* --- NEW SECTION: FOR DEVELOPERS --- */}
        <section className="py-32 px-6 border-t border-white/10 bg-[#0A0A0A]">
          <div className="max-w-7xl mx-auto grid md:grid-cols-2 gap-16 items-center">
            
            {/* Left: Pitch */}
            <div>
              <div className="flex items-center gap-2 mb-6">
                <Terminal size={20} className="text-[#00FFC2]" />
                <span className="font-mono text-xs text-[#00FFC2] tracking-widest uppercase">For Builders</span>
              </div>
              <h2 className="text-4xl font-serif mb-6 text-white">
                Integration takes <br/> less than 15 minutes.
              </h2>
              <p className="text-white/50 text-lg font-light leading-relaxed mb-8">
                Don't build your own fraud detection. Invariant provides a simple SDK that returns a deterministic <code>riskTier</code> for every device.
              </p>
              
              <ul className="space-y-4 mb-10">
                <DevFeature text="Flutter & Native Android SDKs" />
                <DevFeature text="Shadow Mode (Non-blocking analytics)" />
                <DevFeature text="Zero PII (GDPR Compliant by default)" />
              </ul>

              <Link 
                href="/docs" 
                className="group inline-flex items-center text-white border-b border-white/30 pb-1 hover:border-[#00FFC2] hover:text-[#00FFC2] transition-colors"
              >
                <span className="font-mono text-sm mr-2">READ DOCUMENTATION</span>
                <ChevronRight size={16} className="group-hover:translate-x-1 transition-transform" />
              </Link>
            </div>

            {/* Right: Code Snippet Visual */}
            <div className="bg-[#050505] border border-white/10 rounded-lg p-6 font-mono text-sm relative group hover:border-white/20 transition-colors shadow-2xl">
              <div className="absolute top-4 right-4 flex gap-2">
                <div className="w-3 h-3 rounded-full bg-red-500/20" />
                <div className="w-3 h-3 rounded-full bg-yellow-500/20" />
                <div className="w-3 h-3 rounded-full bg-green-500/20" />
              </div>
              <div className="text-white/30 mb-4 select-none">// auth_controller.dart</div>
              <div className="space-y-2">
                <div className="text-purple-400">final<span className="text-white"> result = </span><span className="text-blue-400">await</span><span className="text-white"> Invariant.verify();</span></div>
                <div className="text-white">&nbsp;</div>
                <div className="text-purple-400">if<span className="text-white"> (result.riskTier == </span><span className="text-green-400">'STRONGBOX'</span><span className="text-white">) {'{'}</span></div>
                <div className="text-white pl-4"><span className="text-white/50">// Hardware-backed. Allow transaction.</span></div>
                <div className="text-white pl-4">processPayment();</div>
                <div className="text-white">{'}'} <span className="text-purple-400">else</span> {'{'}</div>
                <div className="text-white pl-4"><span className="text-white/50">// Emulator or Rooted. Block.</span></div>
                <div className="text-white pl-4">throw <span className="text-yellow-400">SecurityException</span>();</div>
                <div className="text-white">{'}'}</div>
              </div>
            </div>

          </div>
        </section>

        {/* --- CTA: The Invite --- */}
        <section className="py-24 px-6 text-center border-t border-white/10">
          <h2 className="text-4xl font-serif mb-6">Secure your digital existence.</h2>
          <p className="text-white/50 max-w-lg mx-auto mb-10 text-lg">
            Join the Pilot. Establish your hardware anchor today.
          </p>
          <Link 
            href="/pilot" 
            className="inline-block border-b border-[#00FFC2] text-[#00FFC2] pb-1 text-xl hover:text-white hover:border-white transition-colors"
          >
            Start Verification Process →
          </Link>
        </section>

      </main>
      <Footer />
    </div>
  );
}

function Feature({ icon, title, desc }: any) {
  return (
    <div className="group">
      <div className="mb-6 p-4 bg-white/5 w-fit rounded-lg border border-white/10 group-hover:border-[#00FFC2]/50 transition-colors">
        {icon}
      </div>
      <h3 className="text-xl font-serif text-white mb-3">{title}</h3>
      <p className="text-white/50 leading-relaxed font-light">
        {desc}
      </p>
    </div>
  );
}

function Badge({ text }: { text: string }) {
  return (
    <span className="px-3 py-1 rounded bg-[#00FFC2]/10 border border-[#00FFC2]/20 text-[#00FFC2] text-[10px] font-bold tracking-wider">
      {text}
    </span>
  );
}

function DevFeature({ text }: { text: string }) {
  return (
    <li className="flex items-center gap-3 text-white/70 font-light text-sm">
      <CheckCircle2 size={16} className="text-[#00FFC2] shrink-0" />
      {text}
    </li>
  );
}