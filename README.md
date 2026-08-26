<p align="center">
  <img src="docs/assets/banner.png" alt="Keelhaven — privacy-first Mac backup to storage you own" width="820">
</p>

# Keelhaven

**[keelhaven.app](https://keelhaven.app)**

Privacy-first Mac backup to your own storage. Free and open source (GPLv3) — no subscription, no telemetry.

Keelhaven wraps the battle-tested [restic](https://restic.net) engine in a native SwiftUI menu bar app: pick folders, pick a destination you own (external drive, any S3-compatible bucket, or SFTP/NAS), set a schedule — your files are encrypted on your Mac before they leave it.

**Status: public beta.** The engine, wizard, scheduled backups, and whole-snapshot restore all work; file-level browsing inside snapshots is next.

## Install

```bash
brew install --cask keelapps/tap/keelhaven
```

Without Homebrew, one command installs (or updates to) the latest release:

```bash
curl -fsSL https://keelhaven.app/install.sh | bash
```

Or download `Keelhaven-<version>.dmg` from [keelhaven.app](https://keelhaven.app)
or the [latest release](../../releases/latest) and drag the app into
Applications. Either way, beta builds aren't notarized yet, so the very first
launch needs a one-time approval — the [site FAQ](https://keelhaven.app/#faq)
walks through it.

## Contributing and development

Keelhaven is developed in the open. Development setup, the CI install path
for personal builds, and the project layout live in
[CONTRIBUTING.md](CONTRIBUTING.md); module boundaries and design decisions in
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Security model (v1)

- Repository password and S3 secret key live in the macOS Keychain, one entry per plan.
- Secrets reach restic only through the child process environment — never argv, never disk.
- The restic child gets a minimal clean environment (`PATH`, `HOME`, `TMPDIR`, `SSH_AUTH_SOCK` + credentials), not the app's.
- Zero telemetry. Nothing leaves your machine except your encrypted backups, to the destination you chose.

## License

Keelhaven is free software under the [GNU General Public License, version 3 or later](LICENSE) (GPL-3.0-or-later): use it, study it, build it, fork it. The app itself stays free; the plan for funding it is an optional paid Pro edition later, built on this code — which is why contributions come with a relicensing grant, see [CONTRIBUTING.md](CONTRIBUTING.md). The "Keelhaven" name and icon are not covered by the code license: a fork should ship under its own name. The bundled [restic](https://restic.net) engine is redistributed under its own BSD-2-Clause license, shipped in the app bundle and surfaced in the About window.
