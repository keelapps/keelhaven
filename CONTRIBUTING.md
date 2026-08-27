# Contributing

Bug reports and pull requests are welcome. For anything bigger than a small
fix, open an issue first so nobody builds the same thing twice — and check the
"deliberately not built yet" list in `CLAUDE.md` before proposing features.

## Development setup

Common tasks are wrapped in a thin Makefile — run `make` to list them:

```bash
git clone git@github.com:shenxianpeng/keelhaven.git && cd keelhaven
make bootstrap   # brew install restic xcodegen gh
make test        # KeelhavenCore tests, incl. the real-restic integration suite
make build       # vendor restic + xcodegen generate + Release xcodebuild
make install     # build from source and install to /Applications
make update      # install the latest CI build instead (no local build)
```

The Makefile is a task index only — logic lives in `Scripts/*.sh` and the
standard tools, so `xcodegen generate` + opening `Keelhaven.xcodeproj` in
Xcode works exactly the same.

The app ships with its own copy of restic (universal binary, checksum-verified
against the official release) in `Contents/MacOS/` — end users never install
anything. A user-set path override and Homebrew locations remain as fallbacks.

### Backend integration tests (S3 / SFTP)

`make test` always exercises restic end-to-end against a local-disk repository.
Two further suites do the same against the network backends and self-skip
unless their backend is reachable; CI always runs both (see
`.github/workflows/ci.yml`). To run them locally:

- **S3** (`ResticS3IntegrationTests`) needs an S3-compatible server on
  `127.0.0.1:9000`:

  ```bash
  brew install minio/stable/minio
  MINIO_ROOT_USER=keelhaven-test MINIO_ROOT_PASSWORD=keelhaven-test-secret \
    minio server --address 127.0.0.1:9000 /tmp/minio-data
  ```

- **SFTP** (`ResticSFTPIntegrationTests`) needs non-interactive ssh to
  `$(whoami)@127.0.0.1`: enable *System Settings → General → Sharing → Remote
  Login* with key auth in place, then confirm with
  `ssh -o BatchMode=yes 127.0.0.1 true`.

Both suites honor `KEELHAVEN_TEST_S3_*` / `KEELHAVEN_TEST_SFTP_*` environment
overrides for pointing at real cloud storage or a NAS — see the test file
headers.

### Manual smoke test

1. Run the app — it appears in the menu bar only (no Dock icon).
2. *Add Backup Plan…* → 3-step wizard → use a temp folder as a local destination.
3. *Back Up Now* → progress appears in the menu bar → completion notification.
4. Verify independently: `restic snapshots -r <destination-folder>` (with the password you chose).

## Install from CI (personal use)

**Use the install script** — it downloads the newest successful build for your
Mac's architecture, replaces /Applications/Keelhaven.app, strips quarantine,
quits any running copy, and launches the new one:

```bash
./Scripts/install-latest.sh        # needs: brew install gh (authenticated)
```

<details>
<summary>Manual fallback (what the script automates)</summary>

Builds are made on demand, not on every push — macOS runners bill at 10× and
nobody downloads most of them. Trigger one at [Actions](../../actions) →
Build app → Run workflow (pick your architecture), then download
`Keelhaven-<n>-apple-silicon` (M-series Macs) or `Keelhaven-<n>-intel`. The
script above does exactly this for you, reusing an existing artifact when one
already matches `main`.

GitHub wraps every artifact in its own zip, so the download is a **zip inside a
zip**: `Keelhaven-<n>-<arch>.zip` contains `Keelhaven.app.zip`, which contains
the app. Install with:

```bash
cd ~/Downloads
unzip -o Keelhaven-*-apple-silicon.zip      # unwraps GitHub's layer → Keelhaven.app.zip
ditto -x -k Keelhaven.app.zip /Applications # extracts Keelhaven.app (permissions intact)
xattr -dr com.apple.quarantine /Applications/Keelhaven.app
open /Applications/Keelhaven.app
```

Quit the old copy first (menu bar → Quit Keelhaven); a menu-bar app that is
already running shows nothing when you double-click it again.

</details>

The inner `Keelhaven.app.zip` is deliberate: GitHub's own artifact zip does not
preserve executable permissions, so the app is ditto-zipped first — never skip
the second extraction step.

The `xattr` step is required: downloaded apps get macOS's quarantine flag, and
ad-hoc-signed (un-notarized) apps are blocked by Gatekeeper until it's removed.
This is fine for installing on your own Macs; release DMGs currently ship
un-notarized too, with the same one-time approval — the release notes and the
site FAQ walk through it.

## Project layout

| Path | What it is |
|---|---|
| `KeelhavenCore/` | SwiftPM package: restic process runner, JSON parsing, models, persistence, schedule math. UI-free and fully unit-tested. |
| `KeelhavenCore/Tests/…/Fixtures/` | Unmodified `restic --json` output captured from restic 0.19.1 — parsers are written against real data, not docs. |
| `Keelhaven/` | SwiftUI app: menu bar, wizard, services (scheduler, notifications, login item, Keychain wiring). |
| `project.yml` | XcodeGen spec — the `.xcodeproj` is generated, never committed. |
| `design/` | Icon and brand kit. `icon.mjs` holds the geometry; `build.mjs` renders the asset catalog, `.icns` and favicons. See `design/README.md`. |
| `site/` | Public website + docs (VitePress). Built and published to this repo's `gh-pages` branch by `.github/workflows/website.yml`, served at [keelhaven.app](https://keelhaven.app). See `docs/WEBSITE.md`. |
| `docs/ARCHITECTURE.md` | Module boundaries, data flow, and upgrade paths. |
| `docs/WEBSITE.md` | How the site is built, deployed, and how the keelhaven.app domain is wired. |

## Licensing of contributions

Keelhaven is licensed under GPL-3.0-or-later (see `LICENSE`). The plan that
funds its development is an optional, paid Pro edition built on this same
code. For that to stay legally possible after your code is merged, one grant
beyond the GPL is needed. By submitting a contribution you agree that:

1. Your contribution is licensed under GPL-3.0-or-later, like the project.
2. You additionally grant Xianpeng Shen a perpetual, worldwide, non-exclusive,
   royalty-free right to relicense your contribution as part of Keelhaven,
   including in proprietary versions of it.
3. You have the right to submit the contribution under these terms (in the
   sense of the [Developer Certificate of Origin](https://developercertificate.org)).

You keep the copyright to your contribution. If you can't agree to this —
typically because your employer owns your code — say so in the PR and we'll
figure it out.
