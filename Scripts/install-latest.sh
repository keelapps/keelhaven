#!/bin/bash
# One-command install/update of the latest CI build from main:
#   ./Scripts/install-latest.sh
# Downloads the newest successful artifact for this Mac's architecture,
# replaces /Applications/Keelhaven.app, strips the quarantine flag, quits any
# running instance, and launches the new one. Replaces the error-prone manual
# unzip-twice + xattr + reinstall dance.
set -euo pipefail

REPO="keelapps/keelhaven"

if ! command -v gh >/dev/null; then
    echo "This script needs the GitHub CLI. Install it with: brew install gh" >&2
    exit 1
fi

case "$(uname -m)" in
    arm64) VARIANT="apple-silicon" ;;
    *)     VARIANT="intel" ;;
esac

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

RUN=$(gh run list --repo "$REPO" --branch main --status success --limit 1 \
    --json databaseId --jq '.[0].databaseId')
if [ -z "$RUN" ]; then
    echo "No successful CI run found on main." >&2
    exit 1
fi

echo "Downloading the $VARIANT build from run $RUN..."
gh run download "$RUN" --repo "$REPO" --pattern "Keelhaven-*-$VARIANT" --dir "$TMP"

INNER=$(find "$TMP" -name 'Keelhaven.app.zip' | head -1)
if [ -z "$INNER" ]; then
    echo "Artifact did not contain Keelhaven.app.zip." >&2
    exit 1
fi
ditto -x -k "$INNER" "$TMP/out"

echo "Installing to /Applications..."
pkill -x Keelhaven 2>/dev/null && sleep 1 || true
rm -rf /Applications/Keelhaven.app
ditto "$TMP/out/Keelhaven.app" /Applications/Keelhaven.app
xattr -dr com.apple.quarantine /Applications/Keelhaven.app 2>/dev/null || true

open /Applications/Keelhaven.app

PLIST=/Applications/Keelhaven.app/Contents/Info.plist
COMMIT=$(/usr/libexec/PlistBuddy -c 'Print :GitCommit' "$PLIST" 2>/dev/null || echo "?")
BUILD=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$PLIST" 2>/dev/null || echo "?")
echo "Done: Keelhaven build $BUILD ($COMMIT) is running in your menu bar."
