<script setup lang="ts">
// Sticky pill nav for the landing page only. Items and CTA copy come from
// index.md frontmatter (fm.landing) so a future zh/index.md localizes them
// without touching this component. When the zh locale lands, add a small
// locale link here — the default navbar (which normally hosts the switcher)
// is hidden on the landing page.
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { useData, withBase } from 'vitepress'

const { frontmatter } = useData()
const landing = computed(() => frontmatter.value.landing ?? {})

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

const mailto = computed(
  () =>
    `mailto:${landing.value.contact}?subject=${encodeURIComponent(
      landing.value.ctaSubject ?? ''
    )}`
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
      </div>
      <a class="kh-btn kh-btn-primary kh-nav-cta" :href="mailto">
        {{ landing.cta }}
      </a>
    </nav>
  </header>
</template>
