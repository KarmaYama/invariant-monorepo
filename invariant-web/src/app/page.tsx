"use client";

import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import { 
  ShieldCheck, Terminal, Cpu, Activity, ChevronRight, 
  Smartphone, Zap, Lock, Code2, LineChart 
} from "lucide-react";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";
import { fetchNetworkStats } from "@/lib/api";

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
            className="border-b border-white/10 pb-12 mb-12"
          >
            <div className="flex items-center space-x-3 mb-6">
              <span className="relative flex h-3 w-3">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-[#00FFC2] opacity-75"></span>
                <span className="relative inline-flex rounded-full h-3 w-3 bg-[#00FFC2]"></span>
              </span>
              <span className="font-mono text-xs text-[#00FFC2] tracking-[0.2em] font-bold">TESTNET V1 LIVE</span>
            </div>
            
            <h1 className="text-6xl md:text-8xl font-serif tracking-tight mb-8 leading-none">
              Identity, <br/> Anchored to <span className="text-[#00FFC2]">Device.</span>
            </h1>
            
            <div className="flex flex-col md:flex-row md:items-end justify-between gap-8">
              <p className="text-lg md:text-2xl text-white/60 max-w-2xl font-light leading-relaxed">
                Block botnets at source by verifying the Secure Enclave in smartphones. <br/>
                No PII, no biometrics — just deterministic device attestation.
              </p>
              
              {/* --- ACTION LINKS --- */}
              <div className="flex flex-col sm:flex-row gap-6 sm:items-center">
                <a 
                  href="/pilot" 
                  data-analytics-id="hero_cta_pilot"
                  className="group relative flex items-center justify-center space-x-3 bg-[#00FFC2] text-black px-8 py-4 rounded font-mono font-bold text-sm tracking-wide hover:bg-[#00FFC2]/90 hover:scale-105 transition-all shadow-[0_0_20px_rgba(0,255,194,0.3)]"
                >
                  <Smartphone size={18} />
                  <span>Join Pilot</span>
                </a>
                <a 
                  href="/docs" 
                  data-analytics-id="hero_cta_docs"
                  className="group flex items-center justify-center space-x-2 px-6 py-4 border border-white/20 rounded hover:border-white hover:bg-white/5 transition-all"
                >
                  <span className="font-mono text-sm text-white font-bold">Integrate SDK</span>
                  <ChevronRight className="text-white/60 group-hover:text-white group-hover:translate-x-1 transition-transform" size={16} />
                </a>
              </div>
            </div>
          </motion.div>

          {/* TRUST WEDGE */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-24 opacity-80">
            <div className="flex items-center gap-3 text-sm font-mono text-white/80">
              <ShieldCheck size={16} className="text-[#00FFC2]" />
              <span>TESTNET V1 • 20+ ACTIVE NODES</span>
            </div>
            <div className="flex items-center gap-3 text-sm font-mono text-white/80">
              <Lock size={16} className="text-[#00FFC2]" />
              <span>ZERO PII: NO GPS • NO CONTACTS</span>
            </div>
            <div className="flex items-center gap-3 text-sm font-mono text-white/80">
              <Zap size={16} className="text-[#00FFC2]" />
              <span>&lt;200ms VERIFICATION (TYPICAL)</span>
            </div>
          </div>

          {/* DYNAMIC METRICS */}
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
              label="FORGERY COST" 
              value={stats.forgeryCost > 0 ? `$${stats.forgeryCost.toLocaleString()}` : "---"} 
              sub="USD"
            />
            <MetricCard 
              icon={<Terminal size={18} />}
              label="NETWORK STATUS" 
              value={stats.status}
              color={stats.status === 'HEALTHY' ? "text-[#00FFC2]" : "text-amber-500"}
            />
          </div>

          {/* SEGMENTATION: REORDERED FOR IMPACT */}
          <div className="mb-32">
            <h2 className="text-sm font-mono text-[#00FFC2] mb-12 tracking-widest uppercase">Choose Your Interface</h2>
            <div className="grid md:grid-cols-3 gap-8">
              
              {/* 1. ENTERPRISE (Left) */}
              <div className="group p-8 border border-white/10 bg-white/5 rounded-lg hover:border-[#00FFC2]/30 transition-all">
                <LineChart className="text-white/40 mb-6 group-hover:text-[#00FFC2] transition-colors" size={32} />
                <h3 className="text-2xl font-serif text-white mb-4">Enterprise & Security</h3>
                <p className="text-white/60 text-sm leading-relaxed mb-8 h-20">
                  Stop bleeding ad spend to bots. Filter non-hardware-backed traffic before it hits your signup flow.
                </p>
                <ul className="space-y-3 mb-8">
                  <ListItem text="Slash fraud ops costs" />
                  <ListItem text="Protect referral budgets" />
                  <ListItem text="No user friction added" />
                </ul>
                <a 
                  href="/impact" 
                  data-analytics-id="segment_cta_enterprise"
                  className="text-[#00FFC2] font-mono text-xs font-bold border-b border-[#00FFC2]/30 hover:border-[#00FFC2] pb-1 uppercase"
                >
                  View Fraud Models
                </a>
              </div>

              {/* 2. FOUNDING NODES (Center - Highlighted) */}
              <div className="group p-8 border border-[#00FFC2]/20 bg-white/5 rounded-lg hover:border-[#00FFC2] transition-all relative overflow-hidden transform md:-translate-y-4 shadow-[0_0_40px_rgba(0,0,0,0.5)]">
                <div className="absolute top-0 right-0 bg-[#00FFC2] text-black text-[10px] font-bold px-3 py-1 font-mono">RECRUITING</div>
                <div className="absolute top-0 left-0 w-full h-1 bg-linear-to-r from-transparent via-[#00FFC2] to-transparent opacity-50"></div>
                
                <Smartphone className="text-[#00FFC2] mb-6" size={32} />
                <h3 className="text-2xl font-serif text-white mb-4">Founding Nodes</h3>
                <p className="text-white/60 text-sm leading-relaxed mb-8 h-20">
                  Your phone is the anchor. Run the node to secure the graph and earn Genesis status.
                </p>
                <ul className="space-y-3 mb-8">
                  <ListItem text="Zero daily tasks" />
                  <ListItem text="<1% Battery usage" />
                  <ListItem text="Permanent Genesis Badge" />
                </ul>
                <a 
                  href="/pilot" 
                  data-analytics-id="segment_cta_pilot"
                  className="inline-block bg-[#00FFC2] text-black px-6 py-3 rounded font-mono text-xs font-bold hover:bg-[#00FFC2]/90 transition-colors uppercase"
                >
                  Deploy Node
                </a>
              </div>

              {/* 3. DEVELOPER (Right) */}
              <div className="group p-8 border border-white/10 bg-white/5 rounded-lg hover:border-[#00FFC2]/30 transition-all">
                <Code2 className="text-white/40 mb-6 group-hover:text-[#00FFC2] transition-colors" size={32} />
                <h3 className="text-2xl font-serif text-white mb-4">Developers</h3>
                <p className="text-white/60 text-sm leading-relaxed mb-8 h-20">
                  Integrate "Proof of Device" with 3 lines of code. Run in Shadow Mode to audit your traffic quality silently.
                </p>
                <ul className="space-y-3 mb-8">
                  <ListItem text="Flutter & Native SDKs" />
                  <ListItem text="15-minute integration" />
                  <ListItem text="Shadow Mode (Non-blocking)" />
                </ul>
                <a 
                  href="/docs" 
                  data-analytics-id="segment_cta_dev"
                  className="text-[#00FFC2] font-mono text-xs font-bold border-b border-[#00FFC2]/30 hover:border-[#00FFC2] pb-1 uppercase"
                >
                  Read Documentation
                </a>
              </div>

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

function ListItem({ text }: { text: string }) {
  return (
    <li className="flex items-center text-sm text-white/80 font-light">
      <div className="w-1 h-1 bg-[#00FFC2] rounded-full mr-3" />
      {text}
    </li>
  );
}