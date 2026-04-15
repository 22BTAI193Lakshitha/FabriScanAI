import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'
import { Toaster } from 'react-hot-toast'

const inter = Inter({ subsets: ['latin'], variable: '--font-inter' })

export const metadata: Metadata = {
  title: 'FabriScan AI – Intelligent Fabric Recognition',
  description: 'AI-powered fabric identification and analysis platform. Upload a fabric image to get instant classification, properties, and smart shopping recommendations.',
  keywords: 'fabric scanner, AI fabric analysis, textile identification, cotton linen wool silk viscose',
  openGraph: {
    title: 'FabriScan AI',
    description: 'AI-powered fabric analysis platform',
    type: 'website',
  },
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={inter.variable} suppressHydrationWarning data-scroll-behavior="smooth">
      <body className="bg-slate-950 text-slate-100 antialiased" suppressHydrationWarning>
        {children}
        <Toaster
          position="top-right"
          toastOptions={{
            style: { background: '#1e293b', color: '#f1f5f9', border: '1px solid #334155' },
            success: { iconTheme: { primary: '#10b981', secondary: '#f1f5f9' } },
            error: { iconTheme: { primary: '#ef4444', secondary: '#f1f5f9' } },
          }}
        />
      </body>
    </html>
  )
}
