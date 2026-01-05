import type { Metadata } from "next";
import { Inter, JetBrains_Mono, Playfair_Display } from "next/font/google";
import "./globals.css";

const sans = Inter({ subsets: ["latin"], variable: "--font-sans" });
const mono = JetBrains_Mono({ subsets: ["latin"], variable: "--font-mono" });
const serif = Playfair_Display({ subsets: ["latin"], variable: "--font-serif" });

export const metadata: Metadata = {
  metadataBase: new URL('https://invariantprotocol.com'),
  title: {
    default: "Invariant | Hardware-Based Identity Protocol",
    template: "%s | Invariant"
  },
  description: "Stop bot traffic at the hardware layer. Invariant uses Android Secure Enclaves to verify physical devices without collecting PII. Integrate the SDK in 15 minutes.",
  openGraph: {
    title: "Invariant Protocol",
    description: "Proof of Device. Validating silicon, not behavior.",
    url: 'https://invariantprotocol.com',
    siteName: 'Invariant Protocol',
    locale: 'en_US',
    type: 'website',
  },
  icons: {
    icon: '/favicon.ico',
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={`${sans.variable} ${mono.variable} ${serif.variable} font-sans antialiased`}>
        {children}
      </body>
    </html>
  );
}