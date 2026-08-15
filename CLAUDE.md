# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Keelhaven is a privacy-first macOS menu-bar backup app (SwiftUI, macOS 14+) that wraps the [restic](https://restic.net) CLI. See `docs/ARCHITECTURE.md` for module boundaries, data flow, key v1 decisions and their upgrade paths — read it before structural changes.

## Commands

```bash
# Prerequisites (once)
brew install restic xcodegen        # restic ≥ 0.19 required

# Core package: build + all tests (fast, no Xcode needed)
swift test --package-path KeelhavenCore

# Run a single test class or method
swift test --package-path KeelhavenCore --filter SchedulePolicyTests
swift test --package-path KeelhavenCore --filter ResticCommandTests/testBackupCommand

# App: regenerate the Xcode project (required after editing project.yml,
# and on fresh clones — the .xcodeproj is generated, never committed)
xcodegen generate
xcodebuild -project Keelhaven.xcodeproj -scheme Keelhaven build
```

There is no linter configured. CI (`.github/workflows/ci.yml`) runs the core tests with restic installed, **enforces 100% line coverage on KeelhavenCore** (llvm-cov gate), and uploads ad-hoc-signed Release builds. When adding core code, add the tests that cover it in the same PR or CI goes red. Check locally with:

```bash
swift test --package-path KeelhavenCore --enable-code-coverage
BIN=$(swift build --package-path KeelhavenCore --show-bin-path)
xcrun llvm-cov report "$BIN/KeelhavenCorePackageTests.xctest/Contents/MacOS/KeelhavenCorePackageTests" \
  -instr-profile="$BIN/codecov/default.profdata" -ignore-filename-regex="Tests|\.build"
```

## Architecture in one paragraph

Two layers with a hard boundary: **`KeelhavenCore/`** is a UI-free SwiftPM package holding everything unit-testable (models, restic process runner + JSON parsing, JSON-file persistence, Keychain protocol + impls, pure schedule math); **`Keelhaven/`** is the SwiftUI app target holding only views (`MenuBar/`, `Wizard/`) and thin service wrappers around system frameworks (`Services/`: scheduler timer, notifications, login item; `Support/`: restic discovery). All state flows through a single `@MainActor @Observable` root, `Keelhaven/AppState.swift`, which owns the services and serializes backups (one at a time, app-wide). Anything that can be tested without a UI belongs in KeelhavenCore, not the app target.

## Non-obvious rules

- **restic parsing is fixture-driven.** All JSON parsing is written against real captured restic 0.19.1 output in `KeelhavenCore/Tests/KeelhavenCoreTests/Fixtures/` — not restic docs. When changing parsers or bumping the supported restic version, re-capture fixtures from the real binary and keep them unmodified. `ResticRunnerIntegrationTests` additionally runs the real restic binary end-to-end and self-skips when restic isn't installed.
- **Secrets never touch argv or disk.** Repository passwords / S3 keys live in the macOS Keychain (one entry per plan UUID) and reach restic only via the child process environment, which is a minimal clean environment — not the app's. Don't add code that logs, persists, or passes secrets as arguments.
- **`Keelhaven.xcodeproj` and `Keelhaven/Info.plist` are generated** (gitignored). Edit `project.yml` instead, then run `xcodegen generate`. `project.yml` also has a post-build script that stamps the git commit into Info.plist for the About window — it must keep running after ProcessInfoPlistFile and before signing.
- **Menu-bar-only app** (`LSUIElement: true`): no Dock icon. App Sandbox is deliberately OFF (hardened runtime ON) because the restic child needs arbitrary folder/network/ssh access — see ARCHITECTURE.md before "fixing" this.
- **Deliberately not built yet** (don't add speculatively): restore/snapshot browsing, retention/prune, extra backends, bundled restic, launchd scheduling, sandboxing.
