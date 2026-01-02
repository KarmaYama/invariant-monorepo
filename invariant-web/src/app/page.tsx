"use client";

import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import { ShieldCheck, Terminal, Cpu, Activity, ChevronRight } from "lucide-react";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";
import { fetchNetworkStats } from "@/lib/api"; // This import will work now

export default function Landing() {
  // Initial state (Skeleton / Loading state)
  const [stats, setStats] = useState({
    continuity: 0,
    anchors: 0,
    status: "SYNCING..."
  });

  // Fetch Real Data on Mount
  useEffect(() => {
    async function load() {
      const data = await fetchNetworkStats();
      setStats({
        continuity: data.continuityHeight,
        anchors: data.activeAnchors,
        status: data.status
      });
    }
    load();
    // Poll every 10 seconds for "Live" feel
    const interval = setInterval(load, 10000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="min-h-screen bg-[#050505] text-white selection:bg-[#00FFC2] selection:text-black font-sans overflow-hidden flex flex-col">
      <Header />
      
      {/* HERO SECTION */}
      <main className="grow pt-32"> {/* Fixed: flex-grow -> grow */}
        <div className="relative z-10 max-w-7xl mx-auto px-6">
          
          {/* HEADER */}
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
            
            <h1 className="text-6xl md:text-9xl font-serif tracking-tight mb-8 leading-none">
              Proof of <br/> <span className="text-white">Device</span><span className="text-[#00FFC2]">.</span>
            </h1>
            
            <div className="flex flex-col md:flex-row md:items-end justify-between gap-8">
              <p className="text-xl md:text-2xl text-white/60 max-w-2xl font-light leading-relaxed">
                The Anchor for the Artificial Age. <br/>
                We convert hardware entropy into a <span className="text-white font-normal">machine-readable scarcity signal</span> to defeat Sybil attacks.
              </p>
              
              <a href="/whitepaper" className="group flex items-center space-x-4 border-b border-white/30 pb-2 hover:border-[#00FFC2] transition-colors">
                <span className="font-mono text-sm tracking-widest">READ MANIFESTO</span>
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
              label="ACTIVE ANCHORS" 
              value={stats.anchors > 0 ? stats.anchors.toString() : "---"} 
              font="mono"
            />
            <MetricCard 
              icon={<Cpu size={18} />}
              label="COST OF FORGERY" 
              value="$3,450" 
              sub="$ / 10k Fleet"
            />
            <MetricCard 
              icon={<Terminal size={18} />}
              label="NETWORK STATE" 
              value={stats.status}
              color={stats.status === 'HEALTHY' ? "text-[#00FFC2]" : "text-amber-500"}
            />
          </div>

          {/* PREVIEW SECTIONS */}
          <div className="grid md:grid-cols-2 gap-24 mb-32">
            <div>
              <h2 className="text-4xl font-serif mb-6">The Problem.</h2>
              <p className="text-white/60 text-lg leading-relaxed mb-8">
                Generative AI creates infinite content. But a digital economy requires finite identity. 
                Without a physical anchor, "Proof of Personhood" is just a Turing test waiting to be failed.
              </p>
              <a href="/impact" className="text-[#00FFC2] font-mono text-sm border-b border-[#00FFC2]/30 hover:border-[#00FFC2] pb-1">
                SEE THE SOCIAL IMPACT
              </a>
            </div>
            <div>
              <h2 className="text-4xl font-serif mb-6">The Solution.</h2>
              <p className="text-white/60 text-lg leading-relaxed mb-8">
                We don't scan your eyes. We verify your silicon. Using the Trusted Execution Environment (TEE) 
                in 3.9 billion smartphones, Invariant builds a graph of "Proof of Latency" that bots cannot forge.
              </p>
              <a href="/inv" className="text-[#00FFC2] font-mono text-sm border-b border-[#00FFC2]/30 hover:border-[#00FFC2] pb-1">
                EXPLORE TOKENOMICS
              </a>
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
    <div className="bg-[#050505] p-8 hover:bg-white/2 transition-colors group"> {/* Fixed: hover:bg-white/2 */}
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