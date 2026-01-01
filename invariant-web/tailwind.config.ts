import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['var(--font-sans)'],
        mono: ['var(--font-mono)'],
        serif: ['var(--font-serif)'],
      },
      // Custom typography styles for the "Academic" look
      typography: (theme: any) => ({
        invert: {
          css: {
            '--tw-prose-body': theme('colors.white'),
            '--tw-prose-headings': theme('colors.white'),
            '--tw-prose-links': '#00FFC2',
            '--tw-prose-code': '#00FFC2',
            '--tw-prose-quotes': theme('colors.white'),
          },
        },
      }),
    },
  },
  plugins: [
    require('@tailwindcss/typography'), // <--- CRITICAL FIX
  ],
};
export default config;