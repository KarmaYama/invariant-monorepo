"use client";

import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import { ShieldCheck, Terminal, Cpu, Activity, ChevronRight, Lock, Server, Smartphone } from "lucide-react";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";
import { fetchNetworkStats } from "@/lib/api";

// CONSERVATIVE ESTIMATE: Hardware + 14 Days OpEx per Node
const COST_PER_NODE = 150; 

export default function Landing() {
  const [stats, setStats] = useState({
    continuity: 0,
    anchors: 0,
    status: "SYNCING...",
    forgeryCost: 0
  });

  useEffect(() => {
    async function load() {
      const data = await fetchNetworkStats();
      const realAnchors = data.activeAnchors || 0;
      const calculatedCost = realAnchors * COST_PER_NODE;

      setStats({
        continuity: data.continuityHeight,
        anchors: realAnchors,
        status: data.status,
        forgeryCost: calculatedCost
      });
    }
    load();
    const interval = setInterval(load, 10000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="min-h-screen bg-[#050505] text-white selection:bg-[#00FFC2] selection:text-black font-sans overflow-hidden flex flex-col">
      <Header />
      
      <main className="grow pt-32">
        <div className="relative z-10 max-w-7xl mx-auto px-6">
          
          {/* HERO SECTION */}
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
            className="border-b border-white/10 pb-12 mb-16"
          >
            <div className="flex items-center space-x-3 mb-6">
              <span className="relative flex h-3 w-3">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-[#00FFC2] opacity-75"></span>
                <span className="relative inline-flex rounded-full h-3 w-3 bg-[#00FFC2]"></span>
              </span>
              <span className="font-mono text-xs text-[#00FFC2] tracking-[0.2em]">TESTNET V1 LIVE</span>
            </div>
            
            <h1 className="text-6xl md:text-8xl font-serif tracking-tight mb-8 leading-none">
              The Hardware <br/> <span className="text-white">Layer</span><span className="text-[#00FFC2]">.</span>
            </h1>
            
            <div className="flex flex-col md:flex-row md:items-end justify-between gap-8">
              <p className="text-xl md:text-2xl text-white/60 max-w-2xl font-light leading-relaxed">
                Stop validating software. Start validating silicon. <br/>
                Invariant filters 99% of automated traffic by verifying the <span className="text-white font-normal">Trusted Execution Environment (TEE)</span> in user devices.
              </p>
              
              <a href="/whitepaper" className="group flex items-center space-x-4 border-b border-white/30 pb-2 hover:border-[#00FFC2] transition-colors">
                <span className="font-mono text-sm tracking-widest">VIEW ARCHITECTURE</span>
                <ChevronRight className="text-[#00FFC2] group-hover:translate-x-1 transition-transform" size={16} />
              </a>
            </div>
          </motion.div>

          {/* DYNAMIC METRICS GRID */}
          <div className="grid grid-cols-1 md:grid-cols-4 gap-px bg-white/10 border border-white/10 mb-32">
            <MetricCard 
              icon={<Activity size={18} />}
              label="CONTINUITY HEIGHT" 
              value={stats.continuity > 0 ? stats.continuity.toLocaleString() : "---"} 
              font="mono"
            />
            <MetricCard 
              icon={<ShieldCheck size={18} />}
              label="VERIFIED ANCHORS" 
              value={stats.anchors > 0 ? stats.anchors.toString() : "---"} 
              font="mono"
            />
            <MetricCard 
              icon={<Cpu size={18} />}
              label="NETWORK STAKE" 
              value={stats.forgeryCost > 0 ? `$${stats.forgeryCost.toLocaleString()}` : "---"} 
              sub="USD (PHYSICAL)"
            />
            <MetricCard 
              icon={<Terminal size={18} />}
              label="NODE STATUS" 
              value={stats.status}
              color={stats.status === 'HEALTHY' ? "text-[#00FFC2]" : "text-amber-500"}
            />
          </div>

          {/* PROBLEM / SOLUTION (Re-written for B2B) */}
          <div className="grid md:grid-cols-2 gap-24 mb-32">
            <div>
              <h2 className="text-4xl font-serif mb-6">The Zero-Cost Attack.</h2>
              <p className="text-white/60 text-lg leading-relaxed mb-8">
                Generative AI creates infinite fake identities at $0.001 per instance. 
                Traditional checks (IP, Email, CAPTCHA) are software-based and easily spoofed. 
                <span className="text-white block mt-4">If identity is free, trust is impossible.</span>
              </p>
              <a href="/impact" className="text-[#00FFC2] font-mono text-sm border-b border-[#00FFC2]/30 hover:border-[#00FFC2] pb-1">
                SEE THE FRAUD DATA
              </a>
            </div>
            <div>
              <h2 className="text-4xl font-serif mb-6">The CapEx Defense.</h2>
              <p className="text-white/60 text-lg leading-relaxed mb-8">
                We anchor identity to the <span className="text-white">Android Keystore System</span>. 
                To forge an Invariant identity, an attacker must purchase a physical device ($40+) and maintain power.
                <span className="text-white block mt-4">We turn spam from a software problem into a financial problem.</span>
              </p>
              <a href="/inv" className="text-[#00FFC2] font-mono text-sm border-b border-[#00FFC2]/30 hover:border-[#00FFC2] pb-1">
                HOW WE VALIDATE
              </a>
            </div>
          </div>

          {/* NEW SECTION: HOW IT WORKS (Technical Depth) */}
          <div className="border-t border-white/10 pt-24 mb-32">
            <h2 className="text-sm font-mono text-[#00FFC2] mb-12 tracking-widest uppercase">The Verification Standard</h2>
            <div className="grid md:grid-cols-3 gap-12">
              <Feature 
                icon={<Lock />}
                title="1. Challenge"
                desc="The protocol issues a cryptographic nonce to the client. The device must sign this nonce inside its Secure Enclave (StrongBox)."
              />
              <Feature 
                icon={<Smartphone />}
                title="2. Attestation"
                desc="The device returns an X.509 Certificate Chain rooted in the Google Hardware Trust Anchor. Emulators cannot produce this root."
              />
              <Feature 
                icon={<Server />}
                title="3. Verification"
                desc="Our Rust backend parses the ASN.1 chain, verifies the signature, and confirms the device is physical, not virtual."
              />
            </div>
          </div>

        </div>
      </main>

      <Footer />
    </div>
  );
}

function MetricCard({ label, value, sub, color = "text-white", icon, font = "sans" }: any) {
  return (
    <div className="bg-[#050505] p-8 hover:bg-white/5 transition-colors group">
      <div className="flex items-center justify-between mb-6 opacity-40 group-hover:opacity-100 transition-opacity">
        <span className="text-[10px] tracking-[0.2em] font-mono">{label}</span>
        {icon}
      </div>
      <div className={`text-3xl ${color} ${font === 'mono' ? 'font-mono tracking-tighter' : 'font-serif'}`}>
        {value} <span className="text-sm text-white/40 ml-1 font-sans">{sub}</span>
      </div>
    </div>
  );
}

function Feature({ icon, title, desc }: any) {
  return (
    <div>
      <div className="text-[#00FFC2] mb-6 opacity-80">{icon}</div>
      <h3 className="text-xl font-serif mb-4 text-white">{title}</h3>
      <p className="text-sm text-white/50 leading-relaxed font-light">
        {desc}
      </p>
    </div>
  );
}