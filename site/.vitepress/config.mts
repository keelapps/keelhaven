import { defineConfig } from 'vitepress'
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

// The app's marketing version, read from the single source of truth so the
// landing-page footer can never go stale. project.yml sits at the repo root,
// two levels up from this file.
const appVersion =
  readFileSync(
    fileURLToPath(new URL('../../project.yml', import.meta.url)),
    'utf8'
  ).match(/MARKETING_VERSION:\s*"?([\d.]+)/)?.[1] ?? '0.0.0'

// Published via .github/workflows/website.yml: built here,
// static output pushed to this repo's gh-pages branch and served
// by GitHub Pages at https://keelhaven.app/ — the custom domain lives in
// site/public/CNAME, which is the only thing keeping it attached (the deploy
// force-pushes an orphan branch, so a CNAME added anywhere else is wiped on
// the next run). Cloudflare only answers DNS for the domain; traffic goes
// straight to GitHub Pages. See docs/WEBSITE.md.
//
// Raw HTML in `footer.message` below does not get `base` prepended the way
// markdown links do, so the two share this constant.
const base = '/'
// og:image must be an absolute URL — relative paths are ignored by every
// scraper. Split from `base` so the host and the path prefix stay separable.
const origin = 'https://keelhaven.app'
const siteUrl = origin + base

const description =
  'Privacy-first backups for your Mac. A quiet menu bar app.'

export default defineConfig({
  base,
  title: 'Keelhaven',
  description,
  lastUpdated: false,

  // Needs an absolute origin to emit useful <loc>s, which is why it only
  // arrived with the custom domain. site/public/robots.txt points at it.
  sitemap: { hostname: siteUrl },

  // Assets live in site/public/ and are written there by design/build.mjs and
  // design/materials.mjs — don't hand-copy them, they will go stale.
  //
  // Unlike markdown links and themeConfig.logo, nothing here is passed through
  // withBase(): these are raw attributes, so every local path needs `base`
  // spelled out, or they break the day the site moves under a path prefix
  // again.
  head: [
    ['link', { rel: 'icon', type: 'image/svg+xml', href: `${base}favicon.svg` }],
    ['link', { rel: 'icon', type: 'image/png', sizes: '32x32', href: `${base}favicon-32.png` }],
    ['link', { rel: 'apple-touch-icon', sizes: '180x180', href: `${base}favicon-180.png` }],
    // `hull` from the brand palette — see design/README.md.
    ['meta', { name: 'theme-color', content: '#0B2540' }],

    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:site_name', content: 'Keelhaven' }],
    ['meta', { property: 'og:title', content: 'Keelhaven — privacy-first Mac backup' }],
    ['meta', { property: 'og:description', content: description }],
    ['meta', { property: 'og:url', content: siteUrl }],
    ['meta', { property: 'og:image', content: `${siteUrl}og.png` }],
    ['meta', { property: 'og:image:width', content: '1200' }],
    ['meta', { property: 'og:image:height', content: '630' }],

    ['meta', { name: 'twitter:card', content: 'summary_large_image' }],
    ['meta', { name: 'twitter:title', content: 'Keelhaven — privacy-first Mac backup' }],
    ['meta', { name: 'twitter:description', content: description }],
    ['meta', { name: 'twitter:image', content: `${siteUrl}og.png` }],
  ],

  themeConfig: {
    // Custom field, read by LandingFooter via useData().theme.
    appVersion,
    // Passed through withBase() by the default theme, so no `base` here.
    logo: '/icon-128.png',
    // The site is a single landing page; only /privacy and /licenses use
    // this default-theme chrome.
    nav: [{ text: 'Home', link: '/' }],
    // GitHub icon in that default-theme navbar. The landing page's own nav
    // and footer carry the same link, driven by index.md frontmatter.
    socialLinks: [
      { icon: 'github', link: 'https://github.com/keelapps/keelhaven' },
    ],
    footer: {
      // The BSD-2-Clause notice travels with the app bundle (restic-LICENSE.txt
      // + the About window) — the website distributes nothing, so a discreet
      // licenses link is plenty here. Full credit lives on /licenses and in
      // the FAQ.
      message: `<a href="${base}privacy">Privacy</a> · <a href="${base}licenses">Licenses</a>`,
      copyright: '© Keelapps.',
    },
  },

  // English is the default locale at the site root. Chinese is planned but
  // not written yet — when it is, uncomment and add pages under site/zh/.
  // locales: {
  //   root: { label: 'English', lang: 'en' },
  //   zh: { label: '简体中文', lang: 'zh-Hans', link: '/zh/' },
  // },
})
