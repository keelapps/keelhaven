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

// Published via .github/workflows/website.yml: built here (private repo),
// static output pushed to the public keelapps/keelhaven-site repo and served
// by GitHub Pages at https://keelapps.github.io/keelhaven-site/.
// When a custom domain is attached to that repo, change `base` to '/'.
// Raw HTML in `footer.message` below does not get `base` prepended the way
// markdown links do, so the two share this constant. Changing it here is
// enough when a custom domain lands.
const base = '/keelhaven-site/'
// og:image must be an absolute URL — relative paths are ignored by every
// scraper. Split from `base` so a custom domain is a two-line change.
const origin = 'https://keelapps.github.io'
const siteUrl = origin + base

const description =
  'Privacy-first backups for your Mac. A quiet menu bar app.'

export default defineConfig({
  base,
  title: 'Keelhaven',
  description,
  lastUpdated: false,

  // Assets live in site/public/ and are written there by design/build.mjs and
  // design/materials.mjs — don't hand-copy them, they will go stale.
  //
  // Unlike markdown links and themeConfig.logo, nothing here is passed through
  // withBase(): these are raw attributes, so every local path needs `base`
  // spelled out or it 404s under the /keelhaven-site/ prefix.
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
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Guide', link: '/guide/getting-started' },
    ],
    sidebar: {
      '/guide/': [
        {
          text: 'Guide',
          items: [
            { text: 'Getting Started', link: '/guide/getting-started' },
            { text: 'Installation', link: '/guide/installation' },
            { text: 'FAQ', link: '/guide/faq' },
          ],
        },
      ],
    },
    footer: {
      // The BSD-2-Clause notice travels with the app bundle (restic-LICENSE.txt
      // + the About window) — the website distributes nothing, so a discreet
      // licenses link is plenty here. Full credit lives on /licenses and in
      // the FAQ.
      message: `<a href="${base}privacy">Privacy</a> · <a href="${base}licenses">Open source licenses</a>`,
      copyright: '© Keelapps. All rights reserved.',
    },
  },

  // English is the default locale at the site root. Chinese is planned but
  // not written yet — when it is, uncomment and add pages under site/zh/.
  // locales: {
  //   root: { label: 'English', lang: 'en' },
  //   zh: { label: '简体中文', lang: 'zh-Hans', link: '/zh/' },
  // },
})
