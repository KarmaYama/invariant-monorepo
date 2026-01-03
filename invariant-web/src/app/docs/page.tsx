"use client";

import Link from "next/link";
import { useState, useEffect } from "react";
import { 
  ArrowLeft, Copy, Terminal, Shield, Code2, CheckCircle2, 
  Cpu, Smartphone, Server, AlertTriangle, Info, BookOpen 
} from "lucide-react";

// --- NAVIGATION CONFIGURATION ---
const SECTIONS = {
  getting_started: [
    { id: "overview", label: "Overview" },
    { id: "architecture", label: "System Architecture" },
    { id: "security-model", label: "Security Model" },
    { id: "installation", label: "Installation" },
  ],
  integration: [
    { id: "initialization", label: "Initialization" },
    { id: "verify-device", label: "Verify Device" },
    { id: "response-object", label: "Response Reference" },
    { id: "error-handling", label: "Error Handling" },
  ],
  patterns: [
    { id: "shadow-mode", label: "Shadow Mode Pattern" },
    { id: "enforcement", label: "Enforcement Strategies" },
  ],
  operational: [
    { id: "privacy", label: "Privacy & Data" },
    { id: "performance", label: "Performance & Latency" },
  ]
};

export default function Docs() {
  const [activeSection, setActiveSection] = useState("overview");

  // Scroll spy to update active section
  useEffect(() => {
    const handleScroll = () => {
      const sections = document.querySelectorAll("section[id]");
      let current = "overview";
      sections.forEach((section) => {
        const top = (section as HTMLElement).offsetTop - 150;
        if (window.scrollY >= top) {
          current = section.getAttribute("id") || "overview";
        }
      });
      setActiveSection(current);
    };
    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  const scrollTo = (id: string) => {
    const element = document.getElementById(id);
    if (element) {
      window.scrollTo({ top: element.offsetTop - 100, behavior: "smooth" });
    }
  };

  return (
    <div className="min-h-screen bg-[#050505] text-white font-sans selection:bg-[#00FFC2] selection:text-black">
      {/* NAV */}
      <nav className="fixed top-0 w-full bg-[#050505]/95 backdrop-blur-md border-b border-white/10 z-50 px-6 h-16 flex items-center justify-between">
        <Link href="/" className="flex items-center space-x-2 text-white/60 hover:text-white transition-colors">
          <ArrowLeft size={18} />
          <span className="text-sm font-mono tracking-widest">RETURN TO DASHBOARD</span>
        </Link>
        <div className="flex items-center space-x-3">
          <div className="flex items-center space-x-2 px-3 py-1 bg-white/5 rounded border border-white/10">
            <div className="w-1.5 h-1.5 rounded-full bg-[#00FFC2]"></div>
            <span className="text-xs font-mono text-[#00FFC2] tracking-widest">API v1</span>
          </div>
          <span className="text-xs font-mono text-white/40 tracking-widest">SDK v1.0.4</span>
        </div>
      </nav>

      <main className="flex pt-16 min-h-screen max-w-7xl mx-auto">
        
        {/* SIDEBAR NAVIGATION */}
        <aside className="w-64 hidden md:block border-r border-white/10 fixed h-full pt-8 pb-24 overflow-y-auto no-scrollbar">
          <div className="px-6 space-y-8">
            <NavGroup title="Getting Started" items={SECTIONS.getting_started} active={activeSection} onSelect={scrollTo} />
            <NavGroup title="Integration" items={SECTIONS.integration} active={activeSection} onSelect={scrollTo} />
            <NavGroup title="Implementation Patterns" items={SECTIONS.patterns} active={activeSection} onSelect={scrollTo} />
            <NavGroup title="Operational" items={SECTIONS.operational} active={activeSection} onSelect={scrollTo} />
          </div>
        </aside>

        {/* MAIN CONTENT AREA */}
        <div className="md:ml-64 w-full pt-12 px-6 md:px-16 pb-32">
          
          {/* HEADER */}
          <div className="mb-16 border-b border-white/10 pb-8">
            <h1 className="text-4xl font-serif mb-4">Invariant SDK Documentation</h1>
            <p className="text-white/60 text-lg font-light leading-relaxed max-w-3xl">
              Technical reference for the Invariant Hardware Attestation SDK. 
              This library provides a cryptographic interface to the Android Keystore System and StrongBox Security Element.
            </p>
          </div>

          {/* --- SECTION: OVERVIEW --- */}
          <Section id="overview" title="Overview">
            <p>
              The Invariant SDK enables mobile applications to cryptographically verify that a client device is a physical Android handset, ensuring it is not an emulator, a server-farmed instance, or a rooted environment running instrumentation tools.
            </p>
            <p className="mt-4">
              Unlike behavioral analysis or fingerprinting (which are probabilistic), Invariant uses <strong>deterministic hardware attestation</strong>. It generates a non-exportable key pair inside the device's Trusted Execution Environment (TEE) and validates the chain of trust against the Google Hardware Root.
            </p>
          </Section>

          {/* --- SECTION: ARCHITECTURE --- */}
          <Section id="architecture" title="System Architecture">
            
            <p className="mb-6">
              The verification process follows a challenge-response protocol designed to prevent replay attacks and ensure freshness.
            </p>
            <div className="space-y-4">
              <Step number="1" title="Challenge Acquisition" desc="The SDK requests a cryptographic nonce from the Invariant API. This nonce is valid for 5 minutes." />
              <Step number="2" title="Hardware Signing" desc="The SDK invokes the Android Keystore to generate a temporary, non-exportable key pair (EC P-256). The nonce is embedded into the key's Attestation Certificate extension." />
              <Step number="3" title="Attestation" desc="The device returns an X.509 Certificate Chain signed by the hardware root (Google/Titan M)." />
              <Step number="4" title="Verification" desc="The SDK transmits the chain and signature to Invariant's Rust backend. The backend parses the ASN.1 structure, verifies the signature against the nonce, and validates the Root of Trust." />
            </div>
          </Section>

          {/* --- SECTION: SECURITY MODEL --- */}
          <Section id="security-model" title="Security Model & Threat Assumptions">
            <div className="grid md:grid-cols-2 gap-6 mb-8">
              <div className="p-6 bg-white/5 border border-white/10 rounded-lg">
                <h4 className="text-[#00FFC2] font-mono text-sm mb-4 flex items-center gap-2">
                  <Shield size={16} /> THREATS MITIGATED
                </h4>
                <ul className="space-y-2 text-sm text-white/70 font-light list-disc list-inside">
                  <li><strong>Emulator Farming:</strong> Detection of virtualized environments (Bluestacks, AWS Device Farm).</li>
                  <li><strong>Instrumentation:</strong> Detection of hooked environments (Frida, Xposed) via integrity checks.</li>
                  <li><strong>Man-in-the-Middle:</strong> Prevented via TLS pinning and signature verification.</li>
                  <li><strong>Replay Attacks:</strong> Prevented via server-issued nonces.</li>
                </ul>
              </div>
              <div className="p-6 bg-white/5 border border-white/10 rounded-lg">
                <h4 className="text-amber-500 font-mono text-sm mb-4 flex items-center gap-2">
                  <AlertTriangle size={16} /> OUT OF SCOPE
                </h4>
                <ul className="space-y-2 text-sm text-white/70 font-light list-disc list-inside">
                  <li><strong>Device Theft:</strong> We certify the device is genuine, not that the user holding it is the owner.</li>
                  <li><strong>Analog Gap:</strong> We cannot prevent a human from physically operating a device farm (though cost makes this prohibitive).</li>
                </ul>
              </div>
            </div>
          </Section>

          {/* --- SECTION: INSTALLATION --- */}
          <Section id="installation" title="Installation">
            <p className="mb-4">
              Add the SDK to your project's dependencies. The SDK requires <strong>Android SDK 21+</strong> (Android 5.0), though hardware attestation guarantees are strongest on <strong>Android 9+</strong> (API 28).
            </p>
            <CodeBlock 
              label="pubspec.yaml" 
              lang="yaml" 
              code={`dependencies:
  invariant_sdk: ^1.0.4
  http: ^1.2.0`} 
            />
          </Section>

          {/* --- SECTION: INITIALIZATION --- */}
          <Section id="initialization" title="Initialization">
            <p className="mb-4">
              Initialize the SDK once at the root of your application, typically in `main.dart` or your dependency injection setup.
            </p>
            <CodeBlock 
              label="main.dart" 
              lang="dart" 
              code={`import 'package:invariant_sdk/invariant_sdk.dart';

void main() {
  // Initialize with your Project API Key
  Invariant.initialize(
    apiKey: "sk_live_51M...", 
    // Optional: Override base URL for enterprise on-premise deployments
    // baseUrl: "https://invariant.internal.bank.com"
  );
  
  runApp(MyApp());
}`} 
            />
          </Section>

          {/* --- SECTION: VERIFY DEVICE --- */}
          <Section id="verify-device" title="Verify Device">
            <p className="mb-4">
              Call `verifyDevice()` at critical checkpoints (Sign Up, Login, or High-Value Transaction). 
              This method is asynchronous and performs network IO.
            </p>
            <Callout type="info">
              <strong>Latency Warning:</strong> Hardware key generation is computationally expensive on the Secure Element. 
              Expect latency between <strong>200ms - 800ms</strong> depending on the device chipset. Show a loading state.
            </Callout>
            <CodeBlock 
              label="auth_service.dart" 
              lang="dart" 
              code={`try {
  final result = await Invariant.verifyDevice();

  if (result.isVerified) {
    print("Device Trusted: \${result.riskTier}");
    // Proceed with transaction
  } else {
    print("Device Rejected: \${result.riskTier}");
    // Block or require Step-Up Auth
  }
} catch (e) {
  // Handle network or system errors (Fail Open or Closed based on policy)
}`} 
            />
          </Section>

          {/* --- SECTION: RESPONSE OBJECT --- */}
          <Section id="response-object" title="Response Reference">
            <p className="mb-6">
              The `InvariantResult` object contains the deterministic assessment of the device's hardware security posture.
            </p>
            
            <div className="overflow-x-auto border border-white/10 rounded-lg mb-8">
              <table className="w-full text-left text-sm">
                <thead className="bg-white/5 font-mono text-[#00FFC2]">
                  <tr>
                    <th className="p-4 border-b border-white/10">Field</th>
                    <th className="p-4 border-b border-white/10">Type</th>
                    <th className="p-4 border-b border-white/10">Description</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-white/5 text-white/70">
                  <tr>
                    <td className="p-4 font-mono text-white">isVerified</td>
                    <td className="p-4 font-mono text-xs">boolean</td>
                    <td className="p-4">True if the attestation chain is valid, rooted, and matches the nonce.</td>
                  </tr>
                  <tr>
                    <td className="p-4 font-mono text-white">riskTier</td>
                    <td className="p-4 font-mono text-xs">string</td>
                    <td className="p-4">The classification of the environment (see table below).</td>
                  </tr>
                  <tr>
                    <td className="p-4 font-mono text-white">riskScore</td>
                    <td className="p-4 font-mono text-xs">double</td>
                    <td className="p-4">0.0 (Safe) to 100.0 (Compromised). Derived from OS integrity signals.</td>
                  </tr>
                  <tr>
                    <td className="p-4 font-mono text-white">identityId</td>
                    <td className="p-4 font-mono text-xs">string?</td>
                    <td className="p-4">Ephemeral session ID useful for server-side audit logs.</td>
                  </tr>
                </tbody>
              </table>
            </div>

            <h4 className="text-white font-serif text-lg mb-4">Risk Tiers</h4>
            <div className="grid gap-4">
              <TierCard 
                tier="STRONGBOX" 
                desc="Highest Security. Key generated in a dedicated Secure Element (e.g., Titan M, Samsung Knox). Virtually impossible to extract or clone." 
                color="text-[#00FFC2]"
              />
              <TierCard 
                tier="PHYSICAL_TEE" 
                desc="Standard Security. Key generated in the main processor's TrustZone. Valid physical device." 
                color="text-white"
              />
              <TierCard 
                tier="SOFTWARE_ONLY" 
                desc="Low Security. Device lacks hardware keystore or is an older Android version. Keys generated in OS user space." 
                color="text-amber-500"
              />
              <TierCard 
                tier="EMULATOR" 
                desc="High Risk. The environment failed to provide a hardware root of trust. Likely a bot, script, or virtual machine." 
                color="text-red-500"
              />
              <TierCard 
                tier="ROOTED_COMPROMISED" 
                desc="High Risk. Physical device verified, but OS integrity checks (Bootloader state) failed." 
                color="text-red-500"
              />
            </div>
          </Section>

          {/* --- SECTION: SHADOW MODE --- */}
          <Section id="shadow-mode" title="Pattern: Shadow Mode">
            <p className="mb-4">
              For initial integration, we strongly recommend the <strong>Shadow Mode</strong> pattern. This involves calling the SDK and logging the result <em>without</em> blocking the user.
            </p>
            <p className="mb-6">
              This allows you to establish a baseline of your traffic quality (e.g., "What % of my users are actually on Emulators?") before turning on active blocking.
            </p>
            <CodeBlock 
              label="analytics_middleware.dart" 
              lang="dart" 
              code={`// 1. Perform check silently
final result = await Invariant.verifyDevice();

// 2. Attach risk data to your existing analytics event
Analytics.logEvent("user_signup_attempt", parameters: {
  "user_id": "12345",
  "inv_tier": result.riskTier,  // e.g. "PHYSICAL_TEE"
  "inv_verified": result.isVerified
});

// 3. Allow user to proceed regardless of result (for now)`} 
            />
          </Section>

          {/* --- SECTION: ENFORCEMENT --- */}
          <Section id="enforcement" title="Pattern: Active Enforcement">
            <p className="mb-4">
              Once baselines are established, you can enforce policies based on the `riskTier`.
            </p>
            <div className="space-y-4">
              <div className="border-l-2 border-white/20 pl-4">
                <h5 className="text-white font-bold mb-1">Strict Policy (Fintech / Crypto)</h5>
                <p className="text-sm text-white/60">Block all `EMULATOR` and `SOFTWARE_ONLY`. Require `PHYSICAL_TEE` or `STRONGBOX` for money movement.</p>
              </div>
              <div className="border-l-2 border-white/20 pl-4">
                <h5 className="text-white font-bold mb-1">Permissive Policy (Social / Gaming)</h5>
                <p className="text-sm text-white/60">Allow `PHYSICAL_TEE`. Flag `EMULATOR` for manual review or CAPTCHA challenge.</p>
              </div>
            </div>
          </Section>

          {/* --- SECTION: ERROR HANDLING --- */}
          <Section id="error-handling" title="Error Handling">
            <p className="mb-4">
              The SDK may throw exceptions during the hardware handshake or network call. Robust applications should implement a <strong>Fail-Open</strong> or <strong>Fail-Closed</strong> strategy depending on risk appetite.
            </p>
            <div className="overflow-x-auto border border-white/10 rounded-lg mb-6">
              <table className="w-full text-left text-sm">
                <thead className="bg-white/5 font-mono text-[#00FFC2]">
                  <tr>
                    <th className="p-4 border-b border-white/10">Error Type</th>
                    <th className="p-4 border-b border-white/10">Cause</th>
                    <th className="p-4 border-b border-white/10">Recommended Action</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-white/5 text-white/70">
                  <tr>
                    <td className="p-4 font-mono text-white">HARDWARE_FAILURE</td>
                    <td className="p-4">Device Keystore is broken or busy. Common on low-end devices.</td>
                    <td className="p-4">Retry once. If fails, Fallback to SMS auth.</td>
                  </tr>
                  <tr>
                    <td className="p-4 font-mono text-white">NETWORK_ERROR</td>
                    <td className="p-4">Unable to reach Invariant API to verify nonce.</td>
                    <td className="p-4">Fail Open (Allow user) or Queue for later verification.</td>
                  </tr>
                  <tr>
                    <td className="p-4 font-mono text-white">REJECTED_BY_POLICY</td>
                    <td className="p-4">Device is valid but blocked by server-side blacklists (e.g. known farm ID).</td>
                    <td className="p-4">Block immediately.</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </Section>

          {/* --- SECTION: PRIVACY --- */}
          <Section id="privacy" title="Privacy & Data Minimization">
            <p className="mb-4">
              Invariant is a <strong>Zero-PII</strong> (Personally Identifiable Information) system. We verify the <em>device</em>, not the <em>user</em>.
            </p>
            <ul className="list-disc list-inside space-y-2 text-white/70 text-sm font-light">
              <li><strong>No Biometrics:</strong> We do not access FaceID or Fingerprint data.</li>
              <li><strong>No Hardware IDs:</strong> We do not collect IMEI, MAC Addresses, or Phone Numbers.</li>
              <li><strong>Key Isolation:</strong> The private key generated for attestation never leaves the device's Secure Enclave.</li>
              <li><strong>Data Transmission:</strong> Only the X.509 Certificate Chain and the signed Nonce are sent to the server.</li>
            </ul>
          </Section>

        </div>
      </main>
    </div>
  );
}

// --- SUB-COMPONENTS ---

function NavGroup({ title, items, active, onSelect }: any) {
  return (
    <div className="mb-8">
      <h4 className="font-mono text-xs text-[#00FFC2] mb-4 uppercase tracking-widest">{title}</h4>
      <ul className="space-y-3">
        {items.map((item: any) => (
          <li 
            key={item.id}
            onClick={() => onSelect(item.id)}
            className={`cursor-pointer text-sm transition-colors duration-200 border-l-2 pl-3 -ml-3 ${
              active === item.id 
                ? "text-white border-[#00FFC2] font-medium" 
                : "text-white/50 border-transparent hover:text-white hover:border-white/20"
            }`}
          >
            {item.label}
          </li>
        ))}
      </ul>
    </div>
  );
}

function Section({ id, title, children }: any) {
  return (
    <section id={id} className="mb-24 scroll-mt-32">
      <h2 className="text-2xl font-serif text-white mb-6 flex items-center gap-3">
        {title}
      </h2>
      <div className="text-white/80 font-light leading-relaxed space-y-6">
        {children}
      </div>
    </section>
  );
}

function Step({ number, title, desc }: any) {
  return (
    <div className="flex gap-4">
      <div className="flex-none flex items-center justify-center w-8 h-8 rounded bg-white/5 text-[#00FFC2] font-mono text-sm font-bold border border-white/10">
        {number}
      </div>
      <div>
        <h5 className="font-bold text-white text-sm mb-1">{title}</h5>
        <p className="text-sm text-white/60">{desc}</p>
      </div>
    </div>
  );
}

function TierCard({ tier, desc, color }: any) {
  return (
    <div className="flex items-start gap-4 p-4 border border-white/5 bg-white/5 rounded">
      <div className={`font-mono text-sm font-bold w-40 shrink-0 ${color}`}>{tier}</div>
      <div className="text-sm text-white/60 font-light">{desc}</div>
    </div>
  );
}

function Callout({ type, children }: any) {
  const isInfo = type === 'info';
  return (
    <div className={`my-6 p-4 rounded border flex gap-3 ${
      isInfo ? 'bg-blue-500/10 border-blue-500/20 text-blue-200' : 'bg-amber-500/10 border-amber-500/20 text-amber-200'
    }`}>
      <div className="mt-0.5 shrink-0">
        {isInfo ? <Info size={18} /> : <AlertTriangle size={18} />}
      </div>
      <div className="text-sm font-light leading-relaxed">
        {children}
      </div>
    </div>
  );
}

function CodeBlock({ label, lang, code }: any) {
  const [copied, setCopied] = useState(false);
  const copy = () => {
    navigator.clipboard.writeText(code);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="rounded border border-white/10 bg-[#0A0A0A] font-mono text-sm my-6">
      <div className="flex items-center justify-between px-4 py-2 bg-white/5 border-b border-white/5">
        <span className="text-white/30 text-xs font-bold">{label}</span>
        <button onClick={copy} className="flex items-center gap-2 text-white/40 hover:text-white transition-colors">
          {copied ? <CheckCircle2 size={12} className="text-[#00FFC2]" /> : <Copy size={12} />}
          <span className="text-[10px] uppercase">{copied ? "COPIED" : "COPY"}</span>
        </button>
      </div>
      <div className="p-4 overflow-x-auto text-white/80">
        <pre>{code}</pre>
      </div>
    </div>
  );
}