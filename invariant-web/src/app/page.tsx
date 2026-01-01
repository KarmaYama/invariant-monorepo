"use client";

import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import { ShieldCheck, Terminal, Cpu, Activity } from "lucide-react";

export default function Landing() {
  // Simulate live connection to your Rust Server
  const [blockHeight, setBlockHeight] = useState(104592);
  
  useEffect(() => {
    const interval = setInterval(() => setBlockHeight(h => h + 1), 4000);
    return () => clearInterval(interval);
  }, []);

  return (
    <main className="min-h-screen bg-[#050505] text-white selection:bg-[#00FFC2] selection:text-black font-sans overflow-hidden relative">
      
      {/* BACKGROUND GRID (Subtle Engineering Paper look) */}
      <div className="absolute inset-0 z-0 opacity-[0.03]" 
           style={{ backgroundImage: 'linear-gradient(#fff 1px, transparent 1px), linear-gradient(90deg, #fff 1px, transparent 1px)', backgroundSize: '40px 40px' }} 
      />

      <div className="relative z-10 max-w-7xl mx-auto px-6 pt-32">
        
        {/* HEADER: ACADEMIC STYLE */}
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          className="border-b border-white/10 pb-8 mb-12"
        >
          <div className="flex items-center space-x-2 mb-4">
            <div className="h-2 w-2 bg-[#00FFC2] animate-pulse rounded-full" />
            <span className="font-mono text-xs text-[#00FFC2] tracking-widest">SYSTEM ONLINE // TESTNET V1</span>
          </div>
          
          <h1 className="text-6xl md:text-8xl font-serif tracking-tight mb-4">
            Invariant<span className="text-[#00FFC2]">.</span>
          </h1>
          <p className="text-xl md:text-2xl text-white/60 max-w-2xl font-light">
            The Anchor for the Artificial Age. <br/>
            A hardware-bound Sybil-resistance mechanism utilizing <span className="font-mono text-white">Trusted Execution Environments</span>.
          </p>
        </motion.div>

        {/* LIVE METRICS GRID */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-24">
          <MetricCard 
            icon={<Activity size={18} />}
            label="CONTINUITY HEIGHT" 
            value={blockHeight.toLocaleString()} 
            font="mono"
          />
          <MetricCard 
            icon={<ShieldCheck size={18} />}
            label="ACTIVE ANCHORS" 
            value="142" 
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
            value="HEALTHY" 
            color="text-[#00FFC2]"
          />
        </div>

        {/* THE WHITEPAPER PREVIEW (LaTeX Rendering) */}
        <div className="grid md:grid-cols-2 gap-16 border-t border-white/10 pt-16">
          <div>
            <h2 className="text-3xl font-serif mb-6">The Thesis</h2>
            <div className="prose prose-invert prose-p:font-light prose-p:text-white/80">
              <p>
                The digital economy faces an existential crisis of trust. Generative AI has shattered the 
                Turing barrier, rendering heuristic "Proof of Personhood" obsolete.
              </p>
              <p>
                Invariant introduces <strong>Proof of Device (PoD)</strong>. By leveraging the 
                Android Keystore and ARM TrustZone, we establish a cost-function for identity forgery 
                that scales with hardware reality, not computational power.
              </p>
              <div className="mt-8">
                <a href="/whitepaper" className="group inline-flex items-center space-x-2 border border-white/20 px-6 py-3 hover:border-[#00FFC2] hover:text-[#00FFC2] transition-colors">
                  <span>READ PROTOCOL SPECIFICATION</span>
                  <span className="group-hover:translate-x-1 transition-transform">→</span>
                </a>
              </div>
            </div>
          </div>

          {/* CODE / MATH PREVIEW */}
          <div className="bg-white/5 p-6 rounded-sm border border-white/10 font-mono text-sm overflow-hidden relative">
            <div className="absolute top-0 right-0 p-2 text-xs text-white/30">src/attestation.rs</div>
            <pre className="text-white/70">
{`// STRICT HARDWARE ENFORCEMENT
pub fn validate_chain(
    chain: &[Vec<u8>], 
    nonce: &[u8]
) -> Result<Tier, Error> {

    // 1. Verify Google Root
    let root = parse(chain.last())?;
    if root.spki != GOOGLE_ROOT {
        return Err(Error::FakeDevice);
    }

    // 2. Check Isolation Level
    let iso = extract_isolation(chain[0])?;
    if iso != Isolation::TrustedEnvironment {
        return Err(Error::SoftwareEmulator);
    }

    Ok(Tier::Hardware)
}`}
            </pre>
          </div>
        </div>

      </div>
    </main>
  );
}

function MetricCard({ label, value, sub, color = "text-white", icon, font = "sans" }: any) {
  return (
    <div className="border border-white/10 p-6 hover:bg-white/5 transition-colors group">
      <div className="flex items-center justify-between mb-4 opacity-50 group-hover:opacity-100 transition-opacity">
        <span className="text-xs tracking-widest">{label}</span>
        {icon}
      </div>
      <div className={`text-3xl ${color} ${font === 'mono' ? 'font-mono' : 'font-serif'}`}>
        {value} <span className="text-sm text-white/40">{sub}</span>
      </div>
    </div>
  );
}