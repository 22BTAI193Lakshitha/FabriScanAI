'use client'

import Link from 'next/link'
import { useEffect, useState } from 'react'
import { ArrowRight, BarChart3, ScanLine, ShieldCheck, ShoppingBag, Sparkles } from 'lucide-react'
import styles from './page.module.css'

const HERO_WORDS = ['Cotton', 'Linen', 'Wool', 'Silk', 'Viscose']

const FEATURES = [
  {
    title: 'Instant Fabric Detection',
    description: 'Upload a photo and get fast AI-backed fabric classification in seconds.',
    icon: ScanLine,
  },
  {
    title: 'Confidence & Property Insights',
    description: 'See confidence scores, care tips, and useful material characteristics.',
    icon: BarChart3,
  },
  {
    title: 'Smart Shopping Suggestions',
    description: 'Discover product ideas and direct links tailored to identified materials.',
    icon: ShoppingBag,
  },
]

export default function HomePage() {
  const [wordIndex, setWordIndex] = useState(0)

  useEffect(() => {
    const timer = window.setInterval(() => {
      setWordIndex((prev) => (prev + 1) % HERO_WORDS.length)
    }, 1800)

    return () => window.clearInterval(timer)
  }, [])

  const scrollToFeatures = () => {
    document.getElementById('features')?.scrollIntoView({ behavior: 'smooth' })
  }

  return (
    <main className={styles.page}>
      <div className={styles.orbOne} aria-hidden="true" />
      <div className={styles.orbTwo} aria-hidden="true" />

      <div className={styles.shell}>
        <header className={styles.navbar}>
          <div className={styles.brandWrap}>
            <span className={styles.brandIcon}>🧵</span>
            <span className={styles.brandText}>FabriScan AI</span>
          </div>

          <nav className={styles.navActions}>
            <Link href="/auth?mode=login" className={styles.loginBtn}>
              Login
            </Link>
            <Link href="/auth?mode=register" className={styles.registerBtn}>
              Register
            </Link>
          </nav>
        </header>

        <section className={styles.hero}>
          <div>
            <p className={styles.eyebrow}>
              <Sparkles size={16} />
              AI-Powered Fabric Intelligence
            </p>

            <h1 className={styles.title}>
              Read your fabric before you buy.
              <span className={styles.breakLine}>From </span>
              <span className={styles.rotatingWord} key={HERO_WORDS[wordIndex]}>
                {HERO_WORDS[wordIndex]}
              </span>
              <span className={styles.breakLine}> to high-performance blends.</span>
            </h1>

            <p className={styles.subtitle}>
              FabriScan helps you identify textiles, compare material properties, and choose better products with confidence.
            </p>

            <div className={styles.ctaRow}>
              <Link href="/auth?mode=register" className={styles.primaryCta}>
                Start Free <ArrowRight size={16} />
              </Link>

              <button type="button" onClick={scrollToFeatures} className={styles.secondaryCta}>
                Explore Features
              </button>
            </div>
          </div>

          <aside className={styles.heroCard}>
            <p className={styles.cardLabel}>What you can do</p>
            <ul className={styles.bulletList}>
              <li>
                <ShieldCheck size={16} />
                Detect materials from an image upload
              </li>
              <li>
                <ShieldCheck size={16} />
                View confidence metrics and analytics
              </li>
              <li>
                <ShieldCheck size={16} />
                Get use-case and care recommendations
              </li>
            </ul>

            <div className={styles.metrics}>
              <div>
                <p>50+</p>
                <span>Supported Labels</span>
              </div>
              <div>
                <p>Live</p>
                <span>Image Analysis</span>
              </div>
              <div>
                <p>Fast</p>
                <span>Scan Responses</span>
              </div>
            </div>
          </aside>
        </section>

        <section id="features" className={styles.featuresSection}>
          <h2>Built for practical textile decisions</h2>
          <p>
            Every scan combines recognition, properties, and shopping intelligence so you can move from curiosity to action.
          </p>

          <div className={styles.featureGrid}>
            {FEATURES.map((feature) => {
              const Icon = feature.icon
              return (
                <article key={feature.title} className={styles.featureCard}>
                  <div className={styles.featureIcon}>
                    <Icon size={20} />
                  </div>
                  <h3>{feature.title}</h3>
                  <p>{feature.description}</p>
                </article>
              )
            })}
          </div>
        </section>

        <section className={styles.bottomCta}>
          <h2>Ready to scan your first fabric?</h2>
          <p>Create an account or jump back in to your dashboard.</p>
          <div className={styles.bottomActions}>
            <Link href="/auth?mode=login" className={styles.loginBtn}>
              Login
            </Link>
            <Link href="/auth?mode=register" className={styles.registerBtn}>
              Register
            </Link>
          </div>
        </section>
      </div>
    </main>
  )
}
