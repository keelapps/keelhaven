import { defineConfig } from 'vitepress'

// Published via .github/workflows/website.yml: built here (private repo),
// static output pushed to the public keelapps/keelhaven-site repo and served
// by GitHub Pages at https://keelapps.github.io/keelhaven-site/.
// When a custom domain is attached to that repo, change `base` to '/'.
export default defineConfig({
  base: '/keelhaven-site/',
  title: 'Keelhaven',
  description:
    'Privacy-first backups for your Mac. A menu bar app powered by restic.',
  lastUpdated: false,

  themeConfig: {
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
