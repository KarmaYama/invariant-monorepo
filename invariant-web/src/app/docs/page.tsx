// invariant-web/src/app/docs/page.tsx
"use client";

import { useState, useEffect } from "react";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";
import { Copy, CheckCircle2, AlertTriangle, Shield, Server } from "lucide-react";

// --- NAVIGATION STRUCTURE ---
const SECTIONS = [
  { id: "quickstart", label: "Quickstart" },
  { id: "architecture", label: "Architecture" },
  { id: "integration", label: "Integration Patterns" },
  { id: "api-reference", label: "API Reference" },
  { id: "errors", label: "Error Handling" },
  { id: "testing", label: "Testing & QA" },
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

      {/* WRAPPER: Flex container handling the sidebar/main layout */}
      <div className="flex-1 w-full max-w-7xl mx-auto flex pt-24 px-6 relative">
        
        {/* --- SIDEBAR NAV (STICKY FIX) --- */}
        {/* Changed 'fixed' to 'sticky' so it respects the footer boundary */}
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
              <div className="text-sm font-mono text-white">v1.0.4 (Stable)</div>
            </div>
          </div>
        </aside>

        {/* --- MAIN CONTENT --- */}
        <main className="flex-1 min-w-0 lg:pl-16 pb-32">
          
          <div className="mb-20 pb-8 border-b border-white/10">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded bg-[#00FFC2]/10 text-[#00FFC2] font-mono text-xs font-bold tracking-wider mb-6">
              ANDROID NATIVE • FLUTTER
            </div>
            <h1 className="text-5xl font-serif mb-6">Hardware Verification</h1>
            <p className="text-xl text-white/60 font-light leading-relaxed max-w-3xl">
              The Invariant SDK allows you to verify that a client device is a physical Android handset with a secure hardware keystore. It detects emulators, server farms, and rooted environments deterministically.
            </p>
          </div>

          {/* 1. QUICKSTART */}
          <Section id="quickstart" title="Quickstart">
            <p className="text-white/70 mb-6">
              The SDK handles the cryptographic handshake with the device's Secure Enclave (TEE). You receive a single `InvariantResult` object containing the risk assessment.
            </p>
            
            <div className="space-y-8">
              <div>
                <h4 className="text-white font-bold mb-2 text-sm font-mono">1. INSTALLATION</h4>
                <CodeBlock label="pubspec.yaml" code={`dependencies:
  invariant_sdk: ^1.0.4`} />
              </div>

              <div>
                <h4 className="text-white font-bold mb-2 text-sm font-mono">2. USAGE</h4>
                <CodeBlock label="main.dart" code={`import 'package:invariant_sdk/invariant_sdk.dart';

// Initialize once (usually in main)
void main() {
  Invariant.initialize(apiKey: "sk_live_...");
  runApp(MyApp());
}

// Call verify() at critical checkpoints
Future<void> onLogin() async {
  try {
    final result = await Invariant.verifyDevice();
    
    if (result.isVerified) {
      print("Safe: \${result.riskTier}"); 
    } else {
      // Handle Risk: Block or Challenge
      print("Blocked: \${result.riskTier}");
    }
  } catch (e) {
    // Fail Open recommended for network errors
    proceedWithLogin();
  }
}`} />
              </div>
            </div>
          </Section>

          {/* 2. ARCHITECTURE */}
          <Section id="architecture" title="Architecture">
            <div className="grid md:grid-cols-2 gap-8 mb-8">
              <div className="bg-white/5 p-6 rounded border border-white/10">
                <Shield className="text-[#00FFC2] mb-4" size={24} />
                <h4 className="text-lg font-bold text-white mb-2">The Handshake</h4>
                <p className="text-sm text-white/60 leading-relaxed">
                  1. SDK requests a cryptographic nonce from Invariant.<br/>
                  2. Device generates a P-256 KeyPair inside the TEE.<br/>
                  3. TEE signs the nonce + timestamp.<br/>
                  4. Invariant backend validates the Google Root of Trust chain.
                </p>
              </div>
              <div className="bg-white/5 p-6 rounded border border-white/10">
                <Server className="text-[#00FFC2] mb-4" size={24} />
                <h4 className="text-lg font-bold text-white mb-2">Performance</h4>
                <p className="text-sm text-white/60 leading-relaxed">
                  Hardware key generation is computationally expensive.
                  <br/><br/>
                  <span className="text-white">• Pixel 6+ (Titan M2):</span> ~200ms<br/>
                  <span className="text-white">• Samsung S23 (Knox):</span> ~300ms<br/>
                  <span className="text-white">• Low-end Devices:</span> up to 800ms
                </p>
              </div>
            </div>
            <Callout type="warning">
              This is a network-bound operation. Always show a loading state (e.g. spinner) while awaiting the result. Do not block the UI thread.
            </Callout>
          </Section>

          {/* 3. INTEGRATION PATTERNS */}
          <Section id="integration" title="Integration Patterns">
            <h3 className="text-xl text-white mb-4 font-serif">When to Verify</h3>
            <div className="space-y-6">
              <Pattern 
                title="On Signup (Recommended)" 
                desc="Prevent bot accounts from ever being created. High impact, low friction."
                code="await Invariant.verifyDevice(); // Before creating user DB entry"
              />
              <Pattern 
                title="On High-Value Transaction" 
                desc="Verify hardware presence before withdrawals or sensitive data access."
                code="if (amount > 1000) await Invariant.verifyDevice();"
              />
              <Pattern 
                title="Shadow Mode (Audit)" 
                desc="Call verify() but ignore the result. Log the data to Analytics to measure fraud levels before enforcing blocks."
                code="Analytics.log('verification_result', result.riskTier);"
              />
            </div>
          </Section>

          {/* 4. API REFERENCE */}
          <Section id="api-reference" title="API Reference">
            <p className="text-white/60 mb-6">The `InvariantResult` object is the single source of truth.</p>
            
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
                    <td className="p-4 text-white">isVerified</td>
                    <td className="p-4 text-white/50">bool</td>
                    <td className="p-4 font-sans text-white/60">True ONLY if the device is a valid physical Android with TEE.</td>
                  </tr>
                  <tr>
                    <td className="p-4 text-white">riskTier</td>
                    <td className="p-4 text-white/50">string</td>
                    <td className="p-4 font-sans text-white/60">The specific classification (see below).</td>
                  </tr>
                  <tr>
                    <td className="p-4 text-white">identityId</td>
                    <td className="p-4 text-white/50">string?</td>
                    <td className="p-4 font-sans text-white/60">Ephemeral session ID for server-side audit logs.</td>
                  </tr>
                </tbody>
              </table>
            </div>

            <h4 className="text-lg font-serif text-white mt-12 mb-6">Risk Tiers (Enum)</h4>
            <div className="space-y-3">
              <RiskTier 
                code="STRONGBOX" 
                color="text-[#00FFC2]" 
                desc="Gold Standard. Key generated in a discrete Secure Element (Titan M, Knox Vault). Cannot be cloned or extracted." 
              />
              <RiskTier 
                code="PHYSICAL_TEE" 
                color="text-white" 
                desc="Standard. Valid physical device using ARM TrustZone. Safe for 99% of use cases." 
              />
              <RiskTier 
                code="SOFTWARE_ONLY" 
                color="text-amber-500" 
                desc="Weak. Device lacks hardware attestation or is running an old OS. Keys stored in software." 
              />
              <RiskTier 
                code="EMULATOR" 
                color="text-red-500" 
                desc="Critical. Environment is virtualized (Bluestacks, AWS Device Farm). Block immediately." 
              />
              <RiskTier 
                code="ROOTED" 
                color="text-red-500" 
                desc="Critical. Bootloader is unlocked or OS integrity check failed." 
              />
            </div>
          </Section>

          {/* 5. ERROR HANDLING */}
          <Section id="errors" title="Error Handling">
            <p className="text-white/60 mb-6">
              The SDK separates <strong>Verification Failures</strong> (Bot detected) from <strong>System Errors</strong> (Network down).
            </p>
            <div className="bg-[#0A0A0A] border border-white/10 rounded p-6 font-mono text-sm space-y-4">
              <ErrorItem 
                code="HARDWARE_FAILURE" 
                desc="The device Keystore is crashing or busy. Retry once." 
              />
              <ErrorItem 
                code="NETWORK_ERROR" 
                desc="Invariant API unreachable. Recommend Fail-Open (Allow user)." 
              />
              <ErrorItem 
                code="REJECTED_BY_POLICY" 
                desc="Valid device, but blocked by server blacklist (e.g. known fraud farm)." 
              />
            </div>
          </Section>

          {/* 6. TESTING */}
          <Section id="testing" title="Testing & QA">
            <p className="text-white/70 mb-6">
              How to verify your integration without buying 50 phones.
            </p>
            
            <div className="space-y-6">
              <div className="p-6 border border-white/10 rounded bg-white/5">
                <h4 className="text-white font-bold mb-2">Simulating Emulators</h4>
                <p className="text-sm text-white/60 mb-4">
                  Run your app on the standard <strong>Android Studio Emulator</strong>. 
                  Invariant will automatically detect the lack of TEE and return:
                </p>
                <code className="block bg-black/50 p-2 rounded text-red-400 font-mono text-sm">
                  riskTier: "EMULATOR", isVerified: false
                </code>
              </div>

              <div className="p-6 border border-white/10 rounded bg-white/5">
                <h4 className="text-white font-bold mb-2">Simulating Success</h4>
                <p className="text-sm text-white/60 mb-4">
                  You must use a <strong>Physical Device</strong> (Pixel, Samsung, etc.) to get a <code>PHYSICAL_TEE</code> result.
                  The Android Emulator <i>cannot</i> simulate a Secure Element cryptographically.
                </p>
              </div>
            </div>
          </Section>

          {/* 7. COMPLIANCE */}
          <Section id="compliance" title="Privacy & Compliance">
            <p className="text-white/70 mb-6">
              Copy this text for your Legal/Compliance team.
            </p>
            <div className="bg-white/5 p-8 rounded border border-white/10 italic text-white/60 leading-relaxed text-sm">
              "Our application uses the Invariant Protocol for fraud prevention. This system verifies the integrity of the device hardware using the Android Keystore System. The process generates a cryptographic attestation chain which is sent to Invariant servers for validation. No personally identifiable information (PII) such as biometric data, names, phone numbers, or persistent hardware identifiers (IMEI/Serial) is collected, stored, or transmitted during this process."
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