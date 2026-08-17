<script setup lang="ts">
// Numbered magazine section: eyebrow ("01 · Features"), serif heading, body.
// Owns the anchor id the nav scrolls to and highlights.
defineProps<{
  id: string
  eyebrow: string
  title: string
}>()
</script>

<template>
  <section :id="id" class="kh-section">
    <p class="kh-eyebrow">{{ eyebrow }}</p>
    <h2 class="kh-h2">{{ title }}</h2>
    <slot />
  </section>
</template>
