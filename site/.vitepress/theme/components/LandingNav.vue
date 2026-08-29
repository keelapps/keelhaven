<script setup lang="ts">
// Sticky pill nav for the landing page only. Items and CTA copy come from
// the page's frontmatter (fm.landing) so index.md and zh/index.md localize
// them without touching this component.
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { useData, withBase } from 'vitepress'
import { useLatestRelease } from '../latest'

const { frontmatter, localeIndex } = useData()
const landing = computed(() => frontmatter.value.landing ?? {})

// The default navbar (which normally hosts VitePress's locale switcher) is
// hidden on the landing page, so the nav carries its own link to the other
// language's landing page. Labels are the target language's own name — the
// one string a reader lost in the wrong language can always recognize.
const localeLink = computed(() =>
  localeIndex.value === 'zh'
    ? { text: 'English', href: withBase('/') }
    : { text: '中文', href: withBase('/zh/') }
)

const active = ref('')
const scrolled = ref(false)

let observer: IntersectionObserver | undefined
const onScroll = () => {
  scrolled.value = window.scrollY > 420
}

onMounted(() => {
  onScroll()
  window.addEventListener('scroll', onScroll, { passive: true })
  observer = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (entry.isIntersecting) active.value = entry.target.id
      }
    },
    // A band around the upper-middle of the viewport decides the section.
    { rootMargin: '-40% 0px -55%' }
  )
  document
    .querySelectorAll('.kh-landing section[id]')
    .forEach((section) => observer!.observe(section))
})

onUnmounted(() => {
  observer?.disconnect()
  window.removeEventListener('scroll', onScroll)
})

// Same self-upgrading download link as the hero's DownloadButton: the GitHub
// releases page until /latest.json resolves, the DMG itself afterwards.
const { dmgURL } = useLatestRelease()
const ctaHref = computed(
  () => dmgURL.value || `${landing.value.github}/releases/latest`
)
</script>

<template>
  <header class="kh-nav-wrap">
    <nav class="kh-nav" :class="{ 'is-scrolled': scrolled }">
      <a class="kh-nav-brand" :href="withBase('/')">
        <img :src="withBase('/icon-128.png')" alt="" width="26" height="26" />
        <span>Keelhaven</span>
      </a>
      <div class="kh-nav-links">
        <a
          v-for="item in landing.nav"
          :key="item.text"
          :href="item.anchor ? `#${item.anchor}` : withBase(item.link)"
          :class="{ active: item.anchor && active === item.anchor }"
        >{{ item.text }}</a>
        <a class="kh-nav-locale" :href="localeLink.href">{{ localeLink.text }}</a>
      </div>
      <!-- Always visible, unlike the scroll-gated CTA next to it. -->
      <a
        v-if="landing.github"
        class="kh-nav-github"
        :href="landing.github"
        target="_blank"
        rel="noopener"
        aria-label="Source on GitHub"
      >
        <svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true">
          <path
            fill="currentColor"
            d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0 0 24 12c0-6.63-5.37-12-12-12Z"
          />
        </svg>
      </a>
      <!-- `download` must be empty, not a boolean: its value is the suggested
           filename, so `download="true"` saves the DMG as a file named "true".
           Empty keeps the filename from the URL and still stops VitePress's
           SPA router from intercepting the click. -->
      <a
        class="kh-btn kh-btn-primary kh-nav-cta"
        :href="ctaHref"
        :download="dmgURL ? '' : undefined"
      >
        {{ landing.cta }}
      </a>
    </nav>
  </header>
</template>
