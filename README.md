# Keelhaven

Privacy-first Mac backup to your own storage. One-time purchase, no subscription, no telemetry.

Keelhaven wraps the battle-tested [restic](https://restic.net) engine in a native SwiftUI menu bar app: pick folders, pick a destination you own (external drive, any S3-compatible bucket, or SFTP/NAS), set a schedule — your files are encrypted on your Mac before they leave it.

**Status: early development.** The engine, wizard, and scheduled backups work; restore and snapshot browsing are next.

## Install from CI (personal use)

Every CI run on `main` uploads an ad-hoc-signed build as a workflow artifact:
[Actions](../../actions) → latest CI run → download `Keelhaven-<n>` → then:

```bash
unzip ~/Downloads/Keelhaven-*.zip -d /Applications   # or drag Keelhaven.app over
xattr -dr com.apple.quarantine /Applications/Keelhaven.app
open /Applications/Keelhaven.app
```

The `xattr` step is required: downloaded apps get macOS's quarantine flag, and
ad-hoc-signed (un-notarized) apps are blocked by Gatekeeper until it's removed.
This is fine for installing on your own Macs; public releases will be
Developer-ID-signed and notarized instead.

## Development setup

```bash
brew install restic xcodegen        # restic ≥ 0.19 required
git clone git@github.com:keelapps/keelhaven.git && cd keelhaven

# Core engine: compiles + 34 tests against real restic fixtures
cd KeelhavenCore && swift test && cd ..

# App: generate the Xcode project (never committed), then build
xcodegen generate
xcodebuild -project Keelhaven.xcodeproj -scheme Keelhaven build
# …or: open Keelhaven.xcodeproj and hit Run
```

### Manual smoke test

1. Run the app — it appears in the menu bar only (no Dock icon).
2. *Add Backup Plan…* → 3-step wizard → use a temp folder as a local destination.
3. *Back Up Now* → progress appears in the menu bar → completion notification.
4. Verify independently: `restic snapshots -r <destination-folder>` (with the password you chose).

## Project layout

| Path | What it is |
|---|---|
| `KeelhavenCore/` | SwiftPM package: restic process runner, JSON parsing, models, persistence, schedule math. UI-free and fully unit-tested. |
| `KeelhavenCore/Tests/…/Fixtures/` | Unmodified `restic --json` output captured from restic 0.19.1 — parsers are written against real data, not docs. |
| `Keelhaven/` | SwiftUI app: menu bar, wizard, services (scheduler, notifications, login item, Keychain wiring). |
| `project.yml` | XcodeGen spec — the `.xcodeproj` is generated, never committed. |
| `docs/ARCHITECTURE.md` | Module boundaries, data flow, and upgrade paths. |

## Security model (v1)

- Repository password and S3 secret key live in the macOS Keychain, one entry per plan.
- Secrets reach restic only through the child process environment — never argv, never disk.
- The restic child gets a minimal clean environment (`PATH`, `HOME`, `TMPDIR`, `SSH_AUTH_SOCK` + credentials), not the app's.
- Zero telemetry. Nothing leaves your machine except your encrypted backups, to the destination you chose.
