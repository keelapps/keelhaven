<script setup lang="ts">
// One quote from a real post, linked back to where it was said. The link is
// the point: a testimonial you can click through to is evidence, one you
// can't is copy. Default slot: the quote, verbatim.
defineProps<{
  name: string
  handle: string
  source: string
  href: string
}>()
</script>

<template>
  <figure class="kh-voice">
    <blockquote class="kh-voice-quote"><slot /></blockquote>
    <figcaption class="kh-voice-who">
      <span class="kh-voice-name">{{ name }}</span>
      <span class="kh-voice-handle">{{ handle }}</span>
      <a class="kh-voice-source" :href="href" target="_blank" rel="noopener">{{ source }} ↗</a>
    </figcaption>
  </figure>
</template>
