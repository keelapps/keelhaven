<script setup lang="ts">
// One accordion row: question left, plus icon right, answer expands inline.
// Native <details> keeps it keyboard-accessible with zero JS; the plus
// rotates into a close mark via CSS when open.
defineProps<{ question: string }>()
</script>

<template>
  <details class="kh-faq-item">
    <summary>
      <span class="kh-faq-q">{{ question }}</span>
      <span class="kh-faq-plus" aria-hidden="true"></span>
    </summary>
    <div class="kh-faq-a">
      <slot />
    </div>
  </details>
</template>
