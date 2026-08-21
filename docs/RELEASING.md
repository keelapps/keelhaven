# Releasing

`.github/workflows/release.yml` builds a universal, Developer-ID-signed,
notarized `Keelhaven-<version>.dmg` and attaches it to a GitHub Release. It
triggers on pushing a `vX.Y.Z` tag, or manually via
Actions → Release → Run workflow (give it a version, it uploads the DMG as a
build artifact instead of creating a release — useful for a dry run).

This is separate from `build-app.yml`, which produces ad-hoc-signed
per-architecture zips for `Scripts/install-latest.sh` (personal installs
only, not public distribution — see the README). That workflow is manual and
deliberately does *not* fire on `vX.Y.Z` tags: this one already covers tags,
and two macOS builds per tag would pay the 10× premium twice.

## One-time setup

You need an active [Apple Developer Program](https://developer.apple.com/programs/)
membership ($99/year) for the two credentials below. Do this once per Apple
Developer team.

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

## Cutting a release

```bash
git tag v1.0.0
git push origin v1.0.0
```

Watch the run under Actions → Release. On success, a GitHub Release for the
tag appears with `Keelhaven-1.0.0.dmg` attached, already signed, notarized,
and stapled — Gatekeeper accepts it offline with no "unidentified developer"
prompt.

## Troubleshooting

- **"Import signing certificate" fails** — one of the four cert-related
  secrets above is missing or the `.p12` password doesn't match.
- **`notarytool submit` fails with "invalid"** — run
  `xcrun notarytool log <submission-id> --key ... --key-id ... --issuer ...`
  (the workflow log prints the submission ID) to see which binary inside the
  bundle failed Apple's checks — almost always a missing hardened-runtime
  entitlement or a nested executable signed without `--timestamp`.
- **Testing locally without secrets**: `make dmg` still works — it packages
  whatever's in `build/Build/Products/Release/`, which is ad-hoc-signed
  unless you've manually set up local Developer ID signing. Good enough for
  checking the DMG mechanics (volume name, Applications symlink, layout)
  without touching notarization at all.
