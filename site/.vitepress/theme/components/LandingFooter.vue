<script setup lang="ts">
// Dark landing footer. Link groups, tagline, and legal copy come from
// index.md frontmatter (localizable); the version comes from themeConfig
// (read out of project.yml at build time in config.mts, locale-independent).
// TODO when pricing lands: add Terms + Refund policy pages to the legal group.
import { computed } from 'vue'
import { useData, withBase } from 'vitepress'

const { frontmatter, theme } = useData()
const landing = computed(() => frontmatter.value.landing ?? {})
const footer = computed(() => landing.value.footer ?? {})
const version = computed(() => (theme.value as any).appVersion ?? '')

const href = (link: {
  link?: string
  href?: string
  anchor?: string
  mailto?: boolean
  github?: boolean
}) => {
  if (link.mailto) return `mailto:${landing.value.contact}`
  if (link.github) return landing.value.github
  if (link.anchor) return `#${link.anchor}`
  if (link.href) return link.href
  return withBase(link.link ?? '/')
}

// Off-site links open in a new tab — VitePress does this for markdown links,
// but these anchors are rendered by hand.
const external = (link: { href?: string; github?: boolean }) =>
  Boolean(link.href || link.github)
</script>

<template>
  <footer class="kh-footer">
    <div class="kh-footer-inner">
      <div class="kh-footer-cols">
        <div>
          <a class="kh-footer-brand-name" :href="withBase('/')">
            <img :src="withBase('/icon-128.png')" alt="" width="24" height="24" />
            <span>Keelhaven</span>
          </a>
          <p class="kh-footer-tagline">{{ footer.tagline }}</p>
          <p class="kh-footer-version">v{{ version }} · {{ footer.versionNote }}</p>
        </div>
        <div v-for="group in footer.groups" :key="group.title">
          <h4>{{ group.title }}</h4>
          <ul>
            <li v-for="link in group.links" :key="link.text">
              <a
                :href="href(link)"
                :target="external(link) ? '_blank' : undefined"
                :rel="external(link) ? 'noopener' : undefined"
              >{{ link.text }}</a>
            </li>
          </ul>
        </div>
      </div>
      <div class="kh-footer-bottom">
        <span>{{ footer.copyright }}</span>
      </div>
    </div>
  </footer>
</template>
