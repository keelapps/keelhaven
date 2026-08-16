# Keelhaven brand kit

Everything visual in this repo comes out of `icon.mjs`. Change the geometry
there and every surface — app icon, menu bar, favicons, social cards — moves
with it. Nothing is drawn twice.

## The idea

Backup software looks like plumbing. Grey shields, spinning arrows, disk
platters, padlocks: the category signals *utility*, and none of it signals the
thing people actually want from a backup, which is **not having to worry**.

Keelhaven's name already contains the better idea. A keel is the backbone of a
ship; a haven is where it ends up safe. So the icon draws exactly that — a
lighthouse over dark water, one warm light in a cold sea. It says *watched over*
rather than *encrypted with AES-256*, and it is the only lighthouse in a Dock
full of shields.

Two consequences worth keeping:

- **One warm accent, everything else cold.** The amber lantern is the only warm
  colour in the system. Spend it on the thing that matters on any given surface
  (the light, a primary button, a highlighted word) and nowhere else. The moment
  amber appears twice on a screen, it stops meaning anything.
- **Deep navy, not black.** Backup apps trend toward grey/black chrome. A
  saturated night-blue stands out against both a light and a dark Dock, and it
  gives the amber something to glow against.

## Palette

| Token | Hex | Where it goes |
|---|---|---|
| `abyss` | `#05141F` | Deepest water, page background at the bottom of the hero |
| `hull` | `#0B2540` | Body text on light, favicon field |
| `deep` | `#0D3055` | Sky at the top of the icon, dark surfaces |
| `sea` | `#14507E` | Mid tones, borders on dark |
| `tide` | `#22608F` | Lightest sky |
| `foam` | `#7FB6DC` | Waterline, faint ripples, secondary text on dark |
| `mist` | `#EAF2FB` | Text on dark, the lighthouse tower |
| `beam` | `#FFDDA8` | Light rays, hover glow |
| `lantern` | `#FFBB52` | **The accent.** Lantern glass, primary buttons |
| `ember` | `#EE8C2C` | Bottom of the amber gradient, small warm text |

## The marks

| File | Use |
|---|---|
| `svg/icon.svg` | Full app icon, 1024. Everything ≥128 px |
| `svg/icon-small.svg` | Same icon with the blurred beam and ripples dropped. Everything ≤64 px |
| `svg/mark.svg` | Lighthouse alone, with glow. Lockups on dark |
| `svg/mark-flat.svg` | Lighthouse alone, no glow. Lockups on light |
| `svg/menubar.svg` | 18 pt template glyph, `currentColor` |
| `svg/mono-navy.svg`, `svg/mono-lantern.svg` | Flat one-colour mark with light rays |
| `svg/wordmark-{light,dark}.svg` | Name + tagline, system font stack |

Three rules that are easy to get wrong:

1. **Small sizes get different art, not smaller art.** Below 64 px the blurred
   beam and the water ripples turn into grey noise, so `icon-small.svg` drops
   them and scales the tower up ~10 % to keep its silhouette. `build.mjs` picks
   the right source per size automatically.
2. **The flat mark needs its rays.** A bare tower silhouette reads as a fire
   hydrant — this was tested, it really does. `monoMark()` adds three detached
   strokes per side. Solid wedges were tried first and read as ears; keep the
   rays thin and keep the gap.
3. **The menu bar glyph is drawn separately.** At 18 pt the dome, gallery and
   taper have to be exaggerated or they disappear. Don't substitute a scaled-down
   `icon.svg`.

## Type

The system stack, everywhere: `-apple-system` first, so it resolves to SF Pro on
a Mac. A native app's site should be set in the OS's own face.

Headlines are tight — `font-weight: 640`, `letter-spacing: -.035em`. Body text
is not: default tracking, `line-height: 1.55`.

Inter is vendored in `fonts/` (SIL OFL 1.1) purely so `materials.mjs` renders the
same PNGs on any machine. It is not used by the site.

## Regenerating

```bash
cd design
npm install
npm run build       # icon, asset catalog, .icns, favicons
npm run materials   # banner, og:image, social preview, wordmark  (needs Chromium)
```

`build.mjs` writes into `Keelhaven/Assets.xcassets/`, `docs/assets/` and
`site/public/`; `materials.mjs` writes into `docs/assets/` and `site/public/`.
Those PNGs are committed on purpose: CI's macOS runner has no image toolchain,
so the build must not depend on this script having run.

`site/public/` holds a small duplicate of `docs/assets/` — the favicons, nav
logo and `og.png` — because VitePress serves static files only from there. It is
written by these scripts rather than copied by hand: the hand-copied version
(`site/assets/`) drifted out of use and was left behind. Anything the website
needs should be added to the `SITE` writes, not copied across.

After adding the asset catalog for the first time, run `xcodegen generate` so
the new resource lands in the project.

## Not done yet

**macOS 26 layered icons.** Tahoe wants a `.icon` bundle authored in Icon
Composer, with separate foreground/mid/background layers and light, dark, clear
and tinted variants. Keelhaven deploys to macOS 14, where a static squircle is
correct and works everywhere, so that is what ships today — macOS 26 masks it to
the system shape and it looks fine.

When it's time: the layers are already separated in `icon.mjs`
(`light()` / `water()` / `lighthouse()`), so exporting three PNGs to feed Icon
Composer is a small job, not a redraw.
