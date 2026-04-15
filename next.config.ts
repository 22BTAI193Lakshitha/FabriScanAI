import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
  turbopack: {
    root: process.cwd(),
  },
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'xawyxdnmulprygajeigx.supabase.co',
        port: '',
        pathname: '/storage/v1/object/public/**',
      },
    ],
  },
  // Transpile Three.js ecosystem
  transpilePackages: ['three', '@react-three/fiber', '@react-three/drei'],
}

export default nextConfig
