<template>
  <!-- Layout is identical whether #price holds a "Free while in beta" badge
       or a real "$N one-time" figure — when pricing lands, only index.md
       changes. Default slot: a markdown checkmark list. -->
  <div class="kh-pricing-card">
    <div class="kh-pricing-top">
      <slot name="price" />
    </div>
    <p class="kh-pricing-note"><slot name="note" /></p>
    <slot />
  </div>
</template>
