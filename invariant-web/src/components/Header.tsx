"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { motion } from "framer-motion";

const links = [
  { name: "THE MISSION", href: "/impact" },
  { name: "PROTOCOL", href: "/whitepaper" },
  { name: "TOKEN", href: "/inv" },
  { name: "ABOUT", href: "/about" },
];

export function Header() {
  const pathname = usePathname();

  return (
    <nav className="fixed top-0 w-full bg-[#050505]/80 backdrop-blur-md border-b border-white/10 z-50 h-20">
      <div className="max-w-7xl mx-auto px-6 h-full flex items-center justify-between">
        
        {/* LOGO */}
        <Link href="/" className="flex items-center space-x-2 group">
          <div className="h-4 w-4 bg-[#00FFC2] rounded-sm group-hover:rotate-45 transition-transform duration-300" />
          <span className="font-serif text-xl tracking-tight">Invariant<span className="text-[#00FFC2]">.</span></span>
        </Link>

        {/* DESKTOP NAV */}
        <div className="hidden md:flex items-center space-x-8">
          {links.map((link) => (
            <Link 
              key={link.href} 
              href={link.href}
              className={`text-xs font-mono tracking-widest hover:text-[#00FFC2] transition-colors ${
                pathname === link.href ? "text-[#00FFC2]" : "text-white/60"
              }`}
            >
              {link.name}
            </Link>
          ))}
          
          <Link 
            href="/contact"
            className="border border-white/20 px-4 py-2 text-xs font-mono hover:bg-[#00FFC2] hover:text-black hover:border-[#00FFC2] transition-all"
          >
            CONTACT
          </Link>
        </div>
      </div>
    </nav>
  );
}