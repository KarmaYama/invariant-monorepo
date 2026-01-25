// invariant-web/src/app/docs/page.tsx
"use client";

import { useState, useEffect } from "react";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";
import { Copy, CheckCircle2, AlertTriangle, Shield, Server, Terminal, Activity } from "lucide-react";

const SECTIONS = [
  { id: "quickstart", label: "Quickstart" },
  { id: "simulation", label: "Simulation & Testing" }, // New Section
  { id: "architecture", label: "Architecture" },
  { id: "api-reference", label: "API Reference" },
  { id: "errors", label: "Error Handling" },
  { id: "compliance", label: "Privacy & Compliance" },
];

export default function Docs() {
  const [active, setActive] = useState("quickstart");

  useEffect(() => {
    const handleScroll = () => {
      const sections = document.querySelectorAll("section[id]");
      let current = "quickstart";
      sections.forEach((s) => {
        const top = (s as HTMLElement).offsetTop - 200;
        if (window.scrollY >= top) current = s.getAttribute("id") || "quickstart";
      });
      setActive(current);
    };
    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  return (
    <div className="bg-[#050505] text-white selection:bg-[#00FFC2] selection:text-black font-sans min-h-screen flex flex-col">
      <Header />

      <div className="flex-1 w-full max-w-7xl mx-auto flex pt-24 px-6 relative">
        
        {/* --- SIDEBAR NAV --- */}
        <aside className="hidden lg:block w-64 shrink-0 sticky top-24 self-start h-[calc(100vh-8rem)] overflow-y-auto border-r border-white/10 pt-4 pb-12 no-scrollbar">
          <div className="pr-6">
            <h4 className="font-serif text-white mb-6 text-lg">Invariant SDK</h4>
            <nav className="space-y-1">
              {SECTIONS.map((item) => (
                <button
                  key={item.id}
                  onClick={() => document.getElementById(item.id)?.scrollIntoView({ behavior: 'smooth' })}
                  className={`block w-full text-left text-sm py-2.5 px-4 rounded transition-all duration-200 ${
                    active === item.id 
                      ? "bg-[#00FFC2]/10 text-[#00FFC2] font-medium border-l-2 border-[#00FFC2]" 
                      : "text-white/50 hover:text-white hover:bg-white/5 border-l-2 border-transparent"
                  }`}
                >
                  {item.label}
                </button>
              ))}
            </nav>
            
            <div className="mt-12 px-4 pt-8 border-t border-white/10">
              <div className="text-xs font-mono text-white/40 mb-2">SDK VERSION</div>
              <div className="text-sm font-mono text-white">v0.1.0 (Pilot)</div>
            </div>
          </div>
        </aside>

        {/* --- MAIN CONTENT --- */}
        <main className="flex-1 min-w-0 lg:pl-16 pb-32">
          
          <div className="mb-20 pb-8 border-b border-white/10">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded bg-[#00FFC2]/10 text-[#00FFC2] font-mono text-xs font-bold tracking-wider mb-6">
              ANDROID • FLUTTER • RUST
            </div>
            <h1 className="text-5xl font-serif mb-6">Hardware Verification</h1>
            <p className="text-xl text-white/60 font-light leading-relaxed max-w-3xl">
              The Invariant SDK allows you to verify that a client device is a physical Android handset with a secure hardware keystore. It detects emulators, server farms, and rooted environments using the Secure Enclave (TEE).
            </p>
          </div>

          {/* 1. QUICKSTART */}
          <Section id="quickstart" title="Quickstart">
            <p className="text-white/70 mb-6">
              The SDK handles the cryptographic handshake. You receive a structured `InvariantResult` containing a definitive <strong>Decision</strong> and a granular <strong>Risk Score</strong>.
            </p>
            
            <div className="space-y-8">
              <div>
                <h4 className="text-white font-bold mb-2 text-sm font-mono">1. INSTALLATION</h4>
                <CodeBlock label="pubspec.yaml" code={`dependencies:
  invariant_sdk: ^0.1.0`} />
              </div>

              <div>
                <h4 className="text-white font-bold mb-2 text-sm font-mono">2. USAGE</h4>
                <CodeBlock label="main.dart" code={`import 'package:invariant_sdk/invariant_sdk.dart';

void main() {
  // Initialize with your Publishable Key
  Invariant.initialize(
    apiKey: "pk_live_...",
    mode: InvariantMode.shadow // Use 'enforce' to block bots
  );
  runApp(MyApp());
}

Future<void> onLogin() async {
  // 1. Run Hardware Attestation
  final result = await Invariant.verifyDevice();

  // 2. Handle Decision
  switch (result.decision) {
    case InvariantDecision.allow:
      // ✅ Device Verified (Hardware TEE Confirmed)
      completeLogin();
      break;

    case InvariantDecision.allowShadow:
      // ⚠️ Risk Detected but Allowed (Shadow Mode)
      // Log this event to your analytics
      logRisk(result.riskScore, result.reason);
      completeLogin();
      break;

    case InvariantDecision.deny:
      // ⛔ Blocked (Emulator / Rooted / Clone)
      showBlockScreen(reason: result.reason);
      break;
  }
}`} />
              </div>
            </div>
          </Section>

          {/* 2. SIMULATION & TESTING */}
          <Section id="simulation" title="Simulation & Testing">
            <p className="text-white/70 mb-6">
              You don't need a physical device farm to test your UI. The SDK includes a simulation mode for development.
            </p>
            <div className="grid md:grid-cols-2 gap-6">
              <div className="bg-white/5 p-6 rounded border border-white/10">
                <Terminal className="text-[#00FFC2] mb-4" size={24} />
                <h4 className="text-white font-bold mb-2">Simulated Scenarios</h4>
                <p className="text-sm text-white/60 mb-4">
                  The Example App allows you to toggle between network modes to verify your UI's reaction to different threat levels.
                </p>
                <ul className="text-sm text-white/50 space-y-2 list-disc pl-4">
                  <li><strong>Real Network:</strong> Actual TEE Handshake.</li>
                  <li><strong>Force Allow:</strong> Simulates a clean Pixel 8.</li>
                  <li><strong>Force Shadow:</strong> Simulates a risk event in audit mode.</li>
                  <li><strong>Force Deny:</strong> Simulates an emulator block.</li>
                </ul>
              </div>
              <div className="bg-white/5 p-6 rounded border border-white/10">
                <Activity className="text-[#00FFC2] mb-4" size={24} />
                <h4 className="text-white font-bold mb-2">Fail-Open Design</h4>
                <p className="text-sm text-white/60 mb-4">
                  If the Invariant Cloud is unreachable, the SDK defaults to <code>allow</code> with the tier <code>UNVERIFIED_TRANSIENT</code>.
                </p>
                <p className="text-sm text-white/60">
                  This ensures legitimate users are never blocked due to network outages or server maintenance.
                </p>
              </div>
            </div>
          </Section>

          {/* 3. ARCHITECTURE */}
          <Section id="architecture" title="Architecture">
            <div className="mb-8">
              <h4 className="text-lg font-bold text-white mb-4">Hybrid Trust Model</h4>
              <p className="text-white/70 leading-relaxed mb-6">
                Invariant prioritizes <strong>Security</strong> first, then <strong>User Experience</strong>. 
                Some devices (e.g., budget Samsungs) have a secure TEE but refuse to sign metadata like "Model Name".
              </p>
              <div className="bg-black/50 p-6 rounded border border-white/10 space-y-4">
                <div className="flex gap-4">
                  <div className="w-8 h-8 rounded-full bg-[#00FFC2] flex items-center justify-center text-black font-bold shrink-0">1</div>
                  <div>
                    <h5 className="text-white font-bold">Hardware Handshake</h5>
                    <p className="text-sm text-white/60">The TEE generates a key pair and signs a nonce. If this fails (Emulator), we block.</p>
                  </div>
                </div>
                <div className="flex gap-4">
                  <div className="w-8 h-8 rounded-full bg-[#00FFC2]/20 text-[#00FFC2] flex items-center justify-center font-bold shrink-0">2</div>
                  <div>
                    <h5 className="text-white font-bold">Metadata Enrichment</h5>
                    <p className="text-sm text-white/60">If the TEE signature includes the Model Name, we use it. If not, we fallback to the OS-reported name.</p>
                  </div>
                </div>
                <div className="flex gap-4">
                  <div className="w-8 h-8 rounded-full bg-[#00FFC2]/20 text-[#00FFC2] flex items-center justify-center font-bold shrink-0">3</div>
                  <div>
                    <h5 className="text-white font-bold">Policy Decision</h5>
                    <p className="text-sm text-white/60">The server validates the chain against the Google Root CA and issues a decision (Allow/Deny).</p>
                  </div>
                </div>
              </div>
            </div>
          </Section>

          {/* 4. API REFERENCE */}
          <Section id="api-reference" title="API Reference">
            <p className="text-white/60 mb-6">The `InvariantResult` object.</p>
            
            <div className="border border-white/10 rounded overflow-hidden">
              <table className="w-full text-left text-sm">
                <thead className="bg-white/5 font-mono text-[#00FFC2]">
                  <tr>
                    <th className="p-4 border-b border-white/10">Field</th>
                    <th className="p-4 border-b border-white/10">Type</th>
                    <th className="p-4 border-b border-white/10">Description</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-white/5 text-white/80 font-mono">
                  <tr>
                    <td className="p-4 text-white">decision</td>
                    <td className="p-4 text-white/50">enum</td>
                    <td className="p-4 font-sans text-white/60">
                      <code>allow</code>, <code>allowShadow</code>, or <code>deny</code>. Use this for control flow.
                    </td>
                  </tr>
                  <tr>
                    <td className="p-4 text-white">score</td>
                    <td className="p-4 text-white/50">double</td>
                    <td className="p-4 font-sans text-white/60">Risk Score (0.0 = Safe, 100.0 = Bot).</td>
                  </tr>
                  <tr>
                    <td className="p-4 text-white">tier</td>
                    <td className="p-4 text-white/50">string</td>
                    <td className="p-4 font-sans text-white/60">The hardware classification (see below).</td>
                  </tr>
                  <tr>
                    <td className="p-4 text-white">reason</td>
                    <td className="p-4 text-white/50">string?</td>
                    <td className="p-4 font-sans text-white/60">Diagnostic reason for denial or shadow flag.</td>
                  </tr>
                </tbody>
              </table>
            </div>

            <h4 className="text-lg font-serif text-white mt-12 mb-6">Trust Tiers</h4>
            <div className="space-y-3">
              <RiskTier 
                code="TITANIUM" 
                color="text-[#00FFC2]" 
                desc="StrongBox. Dedicated Secure Element (Titan M2, Knox Vault). Highest security." 
              />
              <RiskTier 
                code="STEEL" 
                color="text-white" 
                desc="TEE. Standard ARM TrustZone execution. Safe for most use cases." 
              />
              <RiskTier 
                code="SOFTWARE" 
                color="text-amber-500" 
                desc="Weak. Key generated in Android OS software. Not hardware-backed." 
              />
              <RiskTier 
                code="EMULATOR" 
                color="text-red-500" 
                desc="Critical. Virtualization detected. Immediate block." 
              />
            </div>
          </Section>

          {/* 5. PRIVACY */}
          <Section id="compliance" title="Privacy & Compliance">
            <div className="bg-white/5 p-8 rounded border border-white/10 italic text-white/60 leading-relaxed text-sm">
              "Invariant uses the Android Keystore System to verify device integrity. This process creates a cryptographic proof of hardware backing. It does NOT collect biometrics, phone numbers, or persistent identifiers (IMEI/AdID) that could track users across apps. The verification is stateless and privacy-preserving."
            </div>
          </Section>

        </main>
      </div>
      <Footer />
    </div>
  );
}

// --- SUB-COMPONENTS ---

function Section({ id, title, children }: any) {
  return (
    <section id={id} className="mb-24 scroll-mt-32">
      <h2 className="text-3xl font-serif text-white mb-8 border-l-4 border-[#00FFC2] pl-6">{title}</h2>
      {children}
    </section>
  );
}

function Pattern({ title, desc, code }: any) {
  return (
    <div className="border border-white/10 rounded bg-white/5 p-6">
      <h4 className="text-[#00FFC2] font-mono text-sm font-bold mb-2 uppercase tracking-wide">{title}</h4>
      <p className="text-sm text-white/60 mb-4">{desc}</p>
      <div className="bg-black/50 p-3 rounded font-mono text-xs text-white/80 overflow-x-auto">
        {code}
      </div>
    </div>
  );
}

function RiskTier({ code, desc, color }: any) {
  return (
    <div className="flex flex-col md:flex-row md:items-center justify-between p-4 border border-white/5 bg-white/5 rounded hover:border-white/20 transition-colors">
      <span className={`font-mono font-bold ${color} mb-2 md:mb-0`}>{code}</span>
      <span className="text-sm text-white/60 md:text-right max-w-lg">{desc}</span>
    </div>
  );
}

function ErrorItem({ code, desc }: any) {
  return (
    <div className="flex flex-col md:flex-row gap-2">
      <span className="text-white font-bold w-48 shrink-0">{code}</span>
      <span className="text-white/50">{desc}</span>
    </div>
  );
}

function Callout({ children }: any) {
  return (
    <div className="mt-6 p-4 border border-amber-500/30 bg-amber-500/5 rounded flex gap-4 text-amber-200 text-sm leading-relaxed">
      <AlertTriangle className="shrink-0" size={20} />
      <div>{children}</div>
    </div>
  );
}

function CodeBlock({ label, code }: any) {
  const [copied, setCopied] = useState(false);
  const copy = () => {
    navigator.clipboard.writeText(code);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="rounded bg-[#0A0A0A] border border-white/10 overflow-hidden my-4 group">
      <div className="flex justify-between items-center px-4 py-2 bg-white/5 border-b border-white/5">
        <span className="text-xs text-white/30 font-mono">{label}</span>
        <button onClick={copy} className="text-white/40 hover:text-white transition-colors flex items-center gap-2">
          <span className="text-[10px] uppercase font-mono">{copied ? "COPIED" : "COPY"}</span>
          {copied ? <CheckCircle2 size={14} className="text-[#00FFC2]" /> : <Copy size={14} />}
        </button>
      </div>
      <pre className="p-4 text-sm text-white/80 font-mono overflow-x-auto">
        {code}
      </pre>
    </div>
  );
}