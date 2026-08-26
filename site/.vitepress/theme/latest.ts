// Shared release lookup for every download CTA on the landing page.
//
// /latest.json is written next to the mirrored DMG by website.yml on each
// release. Consumers render a link to the GitHub releases page immediately —
// so no placeholder copy ever flashes — and swap to the direct DMG download
// once the manifest turns out to exist. The fetch happens once per page load,
// however many CTAs are on it.
import { ref } from 'vue'

const dmgURL = ref('')
const version = ref('')
let requested = false

export function useLatestRelease() {
  if (!requested && typeof window !== 'undefined') {
    requested = true
    fetch('/latest.json')
      .then(async (res) => {
        if (!res.ok) return
        const latest = await res.json()
        if (typeof latest.dmgURL === 'string' && latest.dmgURL) {
          dmgURL.value = latest.dmgURL
          version.value = typeof latest.version === 'string' ? latest.version : ''
        }
      })
      .catch(() => {
        // Offline or a malformed manifest — the releases-page link stays up.
      })
  }
  return { dmgURL, version }
}
