<script setup lang="ts">
// Hero CTA that upgrades itself: links to the GitHub releases page from the
// first paint, then swaps to a direct DMG download (with a version chip) once
// /latest.json resolves. The label never changes, so nothing flashes while
// the manifest loads.
import { useLatestRelease } from '../latest'

defineProps<{
  label: string
  fallbackHref: string
}>()

const { dmgURL, version } = useLatestRelease()
</script>

<template>
  <!-- `download` keeps VitePress's SPA router from intercepting the click:
       .dmg is not in its known-extensions list, so without it the router
       rewrites the href to …dmg.html and lands on the 404 page. -->
  <a v-if="dmgURL" class="kh-btn kh-btn-primary" :href="dmgURL" download>
    {{ label }}<span v-if="version" class="kh-btn-version">v{{ version }}</span>
  </a>
  <a
    v-else
    class="kh-btn kh-btn-primary"
    :href="fallbackHref"
    target="_blank"
    rel="noopener"
  >{{ label }}</a>
</template>
