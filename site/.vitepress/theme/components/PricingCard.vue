<template>
  <!-- Layout is agnostic to what #price holds — today a "Free and open
       source" badge, driven entirely by index.md. Default slot: a markdown
       checkmark list. -->
  <div class="kh-pricing-card">
    <div class="kh-pricing-top">
      <slot name="price" />
    </div>
    <p class="kh-pricing-note"><slot name="note" /></p>
    <slot />
  </div>
</template>
