#!/usr/bin/env bash
# Build a release Linux bundle.
# Usage: ./scripts/build_linux.sh [output_dir]
set -euo pipefail

OUTPUT_DIR="${1:-build/linux-release}"

echo "==> flutter build linux --release"
flutter build linux --release

BUNDLE_SRC="build/linux/x64/release/bundle"
mkdir -p "$OUTPUT_DIR"
cp -r "$BUNDLE_SRC/." "$OUTPUT_DIR/"

echo "==> Packaging archive"
ARCHIVE="luna-linux-x64.tar.gz"
tar -czf "$ARCHIVE" -C "$(dirname "$OUTPUT_DIR")" "$(basename "$OUTPUT_DIR")"

echo "==> Done: $ARCHIVE"
