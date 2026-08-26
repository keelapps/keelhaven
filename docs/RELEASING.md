# Releasing

`.github/workflows/release.yml` builds a universal `Keelhaven-<version>.dmg`
and attaches it to a GitHub Release. It triggers on pushing a `vX.Y.Z` tag,
or manually via Actions → Release → Run workflow: with **publish** ticked it
cuts the whole release itself, without it just uploads the DMG as a build
artifact — useful for a dry run.

**No Apple Developer membership is required.** With no signing secrets
configured (the current state), the app is ad-hoc signed and not notarized:
the DMG works on both architectures, but macOS asks the user to allow the
app once on first launch. That walkthrough ships in three places so nobody
has to hunt for it — the release body (written by the workflow), the site
FAQ, and this file. If the [optional secrets below](#optional-upgrade-developer-id--notarization)
are ever added, the same tag push produces a signed, notarized, stapled DMG
with zero workflow changes.

This is separate from `build-app.yml`, which produces ad-hoc-signed
per-architecture zips for `Scripts/install-latest.sh` (personal installs
only, not public distribution — see the README). That workflow is manual and
deliberately does *not* fire on `vX.Y.Z` tags: this one already covers tags,
and two macOS builds per tag would pay the 10× premium twice.

## Cutting a release

Whichever path you take, `MARKETING_VERSION` in `project.yml` must match the
new version on `main` — the one-button path commits that bump for you, the
other two need it landed first. Every release path overrides it from the tag
at build time, so the released DMG is always right — but source builds
(contributors, `make install`) report whatever `project.yml` says, and a
stale value makes them nag themselves to "update" to the version they
already have.

### One button, from GitHub (recommended)

Actions → Release → **Run workflow**: enter the version, tick **publish**.
The run bumps `project.yml` on `main` if needed, builds the universal DMG,
creates the `v<version>` tag and the GitHub Release, and bumps the
[Homebrew tap](#homebrew-tap) when its secret is set. Guard rails: publish
runs only from `main`, refuse an existing tag, refuse a malformed version.
Left unticked, a manual run stays the artifact-only dry run.

### From this Mac (no Actions minutes needed)

```bash
make release VERSION=0.2.0
```

`Scripts/release-local.sh` is the manual twin of `release.yml` for when the
Actions quota is exhausted — the same situation `Scripts/deploy-site.sh`
covers for the website. It runs the core tests (the only gate left when PR
CI can't run), builds the universal ad-hoc-signed DMG, tags `v0.2.0` and
pushes the tag, publishes the GitHub Release with the first-launch note
(`Scripts/first-launch-note.md`, shared with the workflow), bumps the
[Homebrew tap](#homebrew-tap), then runs `deploy-site.sh` — which mirrors
the DMG plus `latest.json` to `https://keelhaven.app/downloads/` as part of
the site deploy.

While the quota is out, the tag push and the release event each leave a
not-started failed run behind. Harmless, but they can be silenced until
quota returns:

```bash
gh workflow disable release.yml && gh workflow disable website.yml
# later: gh workflow enable release.yml && gh workflow enable website.yml
```

### Via a tag push

```bash
git tag v0.2.0
git push origin v0.2.0
```

Watch the run under Actions → Release. On success (same for the one-button
path):

1. A GitHub Release for the tag appears with `Keelhaven-0.2.0.dmg` attached
   and first-launch instructions in the body (omitted once builds are
   notarized).
2. Publishing the release triggers `website.yml`, which mirrors the DMG to
   `https://keelhaven.app/downloads/` and writes `latest.json` next to it.
3. `latest.json` lights up the rest on its own: the site's hero button
   switches from the early-access mailto to a real download link, and
   installed apps start showing the in-app update prompt
   (`Keelhaven/Services/UpdateChecker.swift`).
4. With the `HOMEBREW_TAP_TOKEN` secret configured, the workflow also bumps
   the [Homebrew tap](#homebrew-tap); without it that step is skipped.

Every path ends in the same place, and they can be mixed freely: both the
workflow and `deploy-site.sh` mirror whatever the *newest published release*
is, so a later Actions deploy won't clobber a locally cut release or vice
versa.

## What users see (unsigned builds)

First launch of each downloaded version trips Gatekeeper, because the build
is ad-hoc signed and macOS can't verify it online:

- **macOS 15 (Sequoia):** double-click once, dismiss the warning, then
  System Settings › Privacy & Security → **Open Anyway**. (Sequoia removed
  the right-click shortcut.)
- **macOS 14 (Sonoma):** right-click the app → **Open** → **Open**.
- **Terminal:** `xattr -d com.apple.quarantine /Applications/Keelhaven.app`.

This repeats on every update installed by hand, since each newly downloaded
DMG carries a fresh quarantine flag — the one real cost of skipping the
$99/year membership. If that friction ever outweighs the fee, add the
secrets below; nothing else has to change.

## Homebrew tap

[`keelapps/homebrew-tap`](https://github.com/keelapps/homebrew-tap) carries
the cask behind `brew install --cask keelapps/tap/keelhaven`, pointing at the
newest release DMG by version and sha256. `Scripts/update-homebrew-tap.sh`
rewrites those two lines and pushes; it is idempotent, so both release paths
call it freely:

- **`release-local.sh`** runs it with your normal git credentials — nothing
  to configure.
- **`release.yml`** needs a `HOMEBREW_TAP_TOKEN` repo secret: a fine-grained
  PAT with **contents: read and write** on `keelapps/homebrew-tap` only.
  Until the secret exists the workflow skips the step, and the tap catches up
  on the next `release-local.sh` run — or manually:
  `./Scripts/update-homebrew-tap.sh 0.2.0 Keelhaven-0.2.0.dmg`.

Homebrew applies its own quarantine flag on install, so the cask does not
change the first-launch story above — its `caveats` block repeats the
walkthrough. When the repo clears Homebrew's notability bar (roughly 75
stars), the cask can additionally be submitted to the official
`homebrew/homebrew-cask` (dropping the tap prefix from the install command);
the tap keeps working regardless.

## Optional upgrade: Developer ID + notarization

An active [Apple Developer Program](https://developer.apple.com/programs/)
membership ($99/year) buys warning-free first launches. Configure the two
credentials below once and `release.yml` picks them up automatically on the
next tag.

### 1. Developer ID Application certificate

1. Xcode → Settings → Accounts → your team → **Manage Certificates** → **+**
   → **Developer ID Application**. (Or via developer.apple.com → Certificates.)
2. In Keychain Access, find the new certificate under **login**, expand it,
   select **both** the certificate and its private key, right-click →
   **Export 2 items…** → save as a `.p12`, set an export password.
3. Base64-encode it for GitHub Secrets:
   ```bash
   base64 -i DeveloperIDApplication.p12 | pbcopy
   ```
4. Add repo secrets (Settings → Secrets and variables → Actions):
   - `DEVELOPER_ID_CERT_P12_BASE64` — the base64 output above
   - `DEVELOPER_ID_CERT_PASSWORD` — the export password you set
   - `CI_KEYCHAIN_PASSWORD` — any random string; it only protects a
     throwaway keychain that exists for the length of one job
   - `APPLE_TEAM_ID` — your 10-character Team ID, shown next to the
     certificate in Xcode/developer.apple.com

### 2. App Store Connect API key (for notarization)

`notarytool` needs credentials distinct from the signing certificate. An API
key is preferred over an Apple ID + app-specific password: it doesn't expire,
doesn't need 2FA, and can be scoped tightly.

1. [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → Users
   and Access → Integrations → **Keys** → **+**. Role: **Developer** is
   enough for notarization.
2. Download the `.p8` **immediately** — App Store Connect only lets you
   download it once.
3. Add repo secrets:
   - `AC_API_KEY_ID` — the Key ID shown next to it
   - `AC_API_ISSUER_ID` — the Issuer ID at the top of the Keys page
   - `AC_API_KEY_P8_BASE64` — `base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy`

The workflow keys off which secrets exist: `DEVELOPER_ID_CERT_P12_BASE64`
enables Developer ID signing, `AC_API_KEY_ID` enables the two notarization
steps and drops the first-launch note from the release body. Set both
groups together — notarizing an ad-hoc-signed build would just fail at
Apple's end.

## Troubleshooting

- **"Import signing certificate" fails** — one of the four cert-related
  secrets above is missing or the `.p12` password doesn't match. (Without
  any of those secrets the step is skipped entirely; it can only fail once
  you've started adding them.)
- **`notarytool submit` fails with "invalid"** — run
  `xcrun notarytool log <submission-id> --key ... --key-id ... --issuer ...`
  (the workflow log prints the submission ID) to see which binary inside the
  bundle failed Apple's checks — almost always a missing hardened-runtime
  entitlement or a nested executable signed without `--timestamp`.
- **Testing locally without secrets**: `make dmg` still works — it packages
  whatever's in `build/Build/Products/Release/`, which is ad-hoc-signed just
  like an unsigned CI release build. Good enough for checking the DMG
  mechanics (volume name, Applications symlink, layout) end to end.
