#!/bin/bash
# Vendors the pinned restic release into Vendor/restic/restic (gitignored),
# verifying the official SHA256 checksums. The app build copies that binary
# into Keelhaven.app/Contents/MacOS/.
#
# Usage: fetch-restic.sh [universal|arm64|amd64]   (default: universal)
#   universal — lipo-merge of both architectures (local dev default)
#   arm64     — Apple Silicon only (CI per-arch artifact, half the size)
#   amd64     — Intel only
#
# Idempotent: exits fast when the requested variant is already in place.
set -euo pipefail

VERSION="0.19.1"
# From https://github.com/restic/restic/releases/download/v0.19.1/SHA256SUMS
SHA_AMD64="c38d579622cf602f665234c5a8c315030b6cf70656028fe6dc29a786b60e5f35"
SHA_ARM64="7be0a144ccc377880f294204aa271d76e4b79554b42a751151d425ce6ebac143"

MODE="${1:-universal}"
case "$MODE" in
    universal) ARCHES="amd64 arm64" ;;
    arm64)     ARCHES="arm64" ;;
    amd64)     ARCHES="amd64" ;;
    *) echo "Unknown mode: $MODE (expected universal|arm64|amd64)" >&2; exit 1 ;;
esac

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR_DIR="$REPO_ROOT/Vendor/restic"
BINARY="$VENDOR_DIR/restic"
MARKER="$VENDOR_DIR/.variant"

if [ -x "$BINARY" ] \
    && [ "$(cat "$MARKER" 2>/dev/null)" = "$VERSION-$MODE" ] \
    && "$BINARY" version 2>/dev/null | grep -q "restic $VERSION"; then
    echo "restic $VERSION ($MODE) already vendored at $BINARY"
    exit 0
fi

mkdir -p "$VENDOR_DIR"
cd "$VENDOR_DIR"
rm -f restic "$MARKER"

for arch in $ARCHES; do
    file="restic_${VERSION}_darwin_${arch}.bz2"
    echo "Downloading ${file}..."
    curl -fsSL -o "$file" \
        "https://github.com/restic/restic/releases/download/v${VERSION}/${file}"
    case "$arch" in
        amd64) expected="$SHA_AMD64" ;;
        arm64) expected="$SHA_ARM64" ;;
    esac
    echo "$expected  $file" | shasum -a 256 -c
    bunzip2 -kf "$file"
done

if [ "$MODE" = "universal" ]; then
    lipo -create -output restic \
        "restic_${VERSION}_darwin_amd64" \
        "restic_${VERSION}_darwin_arm64"
else
    mv "restic_${VERSION}_darwin_${ARCHES}" restic
fi
chmod +x restic
rm -f restic_${VERSION}_darwin_*
echo "$VERSION-$MODE" > "$MARKER"

echo "Vendored restic ($MODE):"
lipo -info restic
./restic version || true   # fails harmlessly when cross-vendoring for the other arch
