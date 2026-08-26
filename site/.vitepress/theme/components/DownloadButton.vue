<script setup lang="ts">
// Hero CTA that upgrades itself: renders the fallback link (early-access
// mailto) immediately, then swaps to a real DMG download once /latest.json —
// written next to the mirrored DMG by website.yml on each release — turns
// out to exist. Before the first public release the fetch 404s and the
// fallback simply stays, so launch day needs no site edit at all.
import { ref, onMounted } from 'vue'

defineProps<{
  label: string
  fallbackLabel: string
  fallbackHref: string
}>()

const dmgURL = ref('')
const version = ref('')

onMounted(async () => {
  try {
    const res = await fetch('/latest.json')
    if (!res.ok) return
    const latest = await res.json()
    if (typeof latest.dmgURL === 'string' && latest.dmgURL) {
      dmgURL.value = latest.dmgURL
      version.value = typeof latest.version === 'string' ? latest.version : ''
    }
  } catch {
    // Offline or a malformed manifest — the fallback CTA stays up.
  }
})
</script>

<template>
  <!-- `download` keeps VitePress's SPA router from intercepting the click:
       .dmg is not in its known-extensions list, so without it the router
       rewrites the href to …dmg.html and lands on the 404 page. -->
  <a v-if="dmgURL" class="kh-btn kh-btn-primary" :href="dmgURL" download>
    {{ label }}<span v-if="version" class="kh-btn-version">v{{ version }}</span>
  </a>
  <a v-else class="kh-btn kh-btn-primary" :href="fallbackHref">{{ fallbackLabel }}</a>
</template>
