<template>
  <!-- Dark rounded frame for a product screenshot. Until the real capture
       ships (added via design/build.mjs into site/public/), index.md places
       a branded placeholder in the slot. -->
  <figure class="kh-shot">
    <div class="kh-shot-frame">
      <slot />
    </div>
  </figure>
</template>
