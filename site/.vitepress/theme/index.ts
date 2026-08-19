// Extends the default theme with the landing-page components used by
// site/index.md. Standalone pages (/licenses, /privacy) are untouched —
// every landing style in landing.css is scoped under .kh-landing.
import DefaultTheme from 'vitepress/theme'
import type { Theme } from 'vitepress'
import LandingNav from './components/LandingNav.vue'
import LandingSection from './components/LandingSection.vue'
import LandingFooter from './components/LandingFooter.vue'
import ShotFrame from './components/ShotFrame.vue'
import MenuBarDemo from './components/MenuBarDemo.vue'
import PricingCard from './components/PricingCard.vue'
import FaqItem from './components/FaqItem.vue'
import './landing.css'

export default {
  extends: DefaultTheme,
  enhanceApp({ app }) {
    app.component('LandingNav', LandingNav)
    app.component('LandingSection', LandingSection)
    app.component('LandingFooter', LandingFooter)
    app.component('ShotFrame', ShotFrame)
    app.component('MenuBarDemo', MenuBarDemo)
    app.component('PricingCard', PricingCard)
    app.component('FaqItem', FaqItem)
  },
} satisfies Theme
