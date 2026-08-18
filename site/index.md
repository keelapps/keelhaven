---
layout: page
navbar: false
footer: false

# All landing copy that components render lives here (not inside the
# components) so a future zh/index.md can localize everything in one file.
landing:
  # The one place the support address is written. It is a Cloudflare Email
  # Routing alias on keelhaven.app that forwards to a real inbox, so it can be
  # re-pointed without touching the site.
  contact: support@keelhaven.app
  cta: Get early access
  ctaSubject: Keelhaven early access
  nav:
    - { text: Features, anchor: features }
    - { text: Guide, anchor: guide }
    - { text: Pricing, anchor: pricing }
    - { text: FAQ, anchor: faq }
  footer:
    tagline: Privacy-first backups for your Mac.
    versionNote: pre-release
    copyright: © Keelapps. All rights reserved.
    groups:
      - title: Support
        links:
          - { text: Email support, mailto: true }
          - { text: FAQ, anchor: faq }
      - title: Product
        links:
          - { text: Features, anchor: features }
          - { text: Getting started, anchor: guide }
          - { text: Pricing, anchor: pricing }
      - title: Legal
        links:
          - { text: Privacy, link: /privacy }
          - { text: Open source licenses, link: /licenses }
---

<script setup>
import { computed } from 'vue'
import { useData } from 'vitepress'

const { frontmatter } = useData()
const mailto = computed(() => {
  const landing = frontmatter.value.landing
  return `mailto:${landing.contact}?subject=${encodeURIComponent(landing.ctaSubject)}`
})
</script>

<!-- TODO before launch: a real download link replacing the mailto CTA, and
     the 1.0 price in the Pricing section.

     A product tour section belongs between the hero and Features, but only
     once there is a real screenshot to put in it — design/build.mjs writes
     into site/public/, and ShotFrame is still registered and ready:

       <LandingSection id="tour" eyebrow="00 · See it"
                       title="One menu bar item. That's the whole app.">
         <ShotFrame><img … /></ShotFrame>
       </LandingSection>

     An empty frame apologising for itself is worse than no section at all. -->

<div class="kh-landing">

<LandingNav />

<section id="top" class="kh-hero">
  <h1 class="kh-hero-title">Privacy-first backups for your&nbsp;Mac</h1>
  <p class="kh-hero-tagline">A quiet menu bar app that backs up the folders you care about — encrypted on your Mac, on your schedule, to storage you own.</p>
  <p class="kh-hero-facts">
    <span>macOS 14+</span>
    <span>No subscription</span>
    <span>No telemetry</span>
    <span>Restores with open tools</span>
  </p>
  <p class="kh-hero-actions">
    <a class="kh-btn kh-btn-primary" :href="mailto">Get early access</a>
    <a class="kh-btn kh-btn-ghost" href="#guide">Read the guide</a>
  </p>
</section>

<LandingSection id="features" eyebrow="01 · Features" title="Built to be forgotten">

<div class="kh-feature-grid">
<div class="kh-feature">

### Private by design

Your data is encrypted before it leaves your Mac. Passwords live in the macOS Keychain and are never written to disk or logs.

</div>
<div class="kh-feature">

### Out of your way

Lives in the menu bar — no Dock icon, no windows to manage. Set a schedule once and forget it.

</div>
<div class="kh-feature">

### No lock-in

Backups are written in a standard, open format — restorable with free open-source tools on any machine, with or without Keelhaven.

</div>
<div class="kh-feature">

### Real schedules

Hourly, daily, or weekly — pick a weekday and a time, and Keelhaven keeps your backups current.

</div>
</div>

</LandingSection>

<LandingSection id="guide" eyebrow="02 · Guide" title="Three decisions, then silence">

<ol class="kh-steps">
<li>

### Pick your folders

Choose the folders you can't lose — documents, photos, projects.

</li>
<li>

### Choose a destination you own

An external drive, a NAS, or any S3-compatible bucket. There is no Keelhaven server in the path.

</li>
<li>

### Set the schedule

Hourly, daily, or weekly. Keelhaven runs in the background and only speaks up when something needs attention.

</li>
</ol>

<div class="kh-guide-note">

Runs on macOS 14 or later, Apple silicon and Intel, with everything it needs bundled. Download links will land here with the first public beta — beta builds aren't notarised yet, so macOS will ask you to allow the app once in **System Settings › Privacy & Security**.

</div>

</LandingSection>

<LandingSection id="pricing" eyebrow="03 · Pricing" title="Pay once. That's the entire model.">

<PricingCard>
<template #price><span class="kh-badge">Free while in beta</span></template>
<template #note>One-time purchase at 1.0 — bought once, updates forever, never a subscription.</template>

- Unlimited backup plans and destinations
- Universal build — Apple silicon and Intel
- Backup engine built in — nothing else to install
- No account, no telemetry, no server of ours in the path

</PricingCard>

</LandingSection>

<LandingSection id="faq" eyebrow="04 · Questions" title="Straight answers">

<FaqItem question="Does this replace Time Machine?">

No — run both. Time Machine is excellent at putting a whole Mac back the way it was, from a drive on your desk. Keelhaven is for the second copy: the folders you can't lose, encrypted, somewhere that isn't your desk.

</FaqItem>
<FaqItem question="Why pay for this when open-source tools are free?">

Because the engine isn't the part that's missing. Keelhaven's backup engine is [restic](https://restic.net) — free, open source, and excellent; you are not paying us for it. The price covers everything a command-line tool deliberately leaves to you: a schedule that actually runs, passwords held in the macOS Keychain and never written to disk or logs, a menu bar that stays quiet until something needs you, and setup that doesn't start with reading documentation. Our lock-in is zero by design, so we have to be worth paying for — that's the intended trade.

</FaqItem>
<FaqItem question="Am I locked into Keelhaven?">

No. Every plan writes an ordinary restic repository, so you can list, verify, and restore your backups with the open-source restic CLI on any Mac or Linux box — with or without Keelhaven installed. If Keelhaven disappears tomorrow, your backups don't.

</FaqItem>
<FaqItem question="Is Keelhaven open source?">

The app itself is a paid, closed-source product. Its backup engine is not: Keelhaven bundles and redistributes restic, which is open source under the BSD 2-Clause License — see [Open source licenses](/licenses) for the full notice. So while you can't read Keelhaven's source, you are never dependent on it to reach your data.

</FaqItem>
<FaqItem question="Is my data readable by anyone else?">

No. Backups are encrypted on your Mac before anything is uploaded, and the repository password is stored only in your macOS Keychain. There is no Keelhaven server, no account system, and no telemetry — the app has nowhere else to send anything.

</FaqItem>
<FaqItem question="Which destinations are supported?">

An external or network drive mounted on your Mac, any S3-compatible bucket (AWS, Backblaze B2, Wasabi, Cloudflare R2, MinIO), and SFTP to your own server or NAS.

</FaqItem>
<FaqItem question="Do I need to install anything else?">

No. Everything Keelhaven needs ships inside the app bundle, including its backup engine — no separate install step, no Homebrew requirement, nothing to keep up to date.

</FaqItem>
<FaqItem question="What happens if I forget the repository password?">

The backup is unrecoverable, by design — repositories are encrypted end to end, and nobody, not us and not your storage provider, holds a spare key. Keelhaven keeps the password in your macOS Keychain and can copy it back out after a Touch ID check; put it in your password manager too.

</FaqItem>
<FaqItem question="Why isn't it on the Mac App Store?">

App Store apps must run in the sandbox, and the backup engine needs to read the folders you point it at and open network and SSH connections. Keelhaven ships with the hardened runtime enabled and signed builds, just not through the store.

</FaqItem>

</LandingSection>

<LandingFooter />

</div>
