import Link from "next/link";

export function Footer() {
  return (
    <footer className="border-t border-white/10 bg-[#050505] pt-16 pb-8">
      <div className="max-w-7xl mx-auto px-6">
        <div className="grid md:grid-cols-4 gap-12 mb-16">
          <div className="col-span-2">
            <h4 className="font-serif text-2xl mb-4">Invariant.</h4>
            <p className="text-white/40 font-light max-w-sm">
              The thermodynamic anchor for digital identity. Built for the age of artificial abundance.
            </p>
          </div>
          
          <div>
            <h5 className="font-mono text-xs text-[#00FFC2] mb-4">PROTOCOL</h5>
            <ul className="space-y-2 text-sm text-white/60">
              <li><Link href="/whitepaper" className="hover:text-white">Whitepaper</Link></li>
              <li><Link href="/inv" className="hover:text-white">Tokenomics</Link></li>
              <li><Link href="/impact" className="hover:text-white">Social Impact</Link></li>
            </ul>
          </div>

          <div>
            <h5 className="font-mono text-xs text-[#00FFC2] mb-4">LEGAL</h5>
            <ul className="space-y-2 text-sm text-white/60">
              <li><Link href="/legal/privacy" className="hover:text-white">Privacy Policy</Link></li>
              <li><Link href="/contact" className="hover:text-white">Contact</Link></li>
            </ul>
          </div>
        </div>

        <div className="flex justify-between items-center pt-8 border-t border-white/5 text-xs font-mono text-white/30">
          <div>© 2025 Invariant Protocol</div>
          <div>Built with ♥ in UK</div>
        </div>
      </div>
    </footer>
  );
}