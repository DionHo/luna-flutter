#!/usr/bin/env bash
# Build a release Android AAB.
# Usage: ./scripts/build_android.sh
#
# Requires:
#   ANDROID_KEYSTORE_PATH   — path to the .jks keystore
#   ANDROID_KEY_ALIAS       — key alias
#   ANDROID_KEY_PASSWORD    — key password
#   ANDROID_STORE_PASSWORD  — keystore password
set -euo pipefail

echo "==> flutter build appbundle --release"
flutter build appbundle \
  --release \
  --obfuscate \
  --split-debug-info=build/symbols

echo "==> Done: build/app/outputs/bundle/release/app-release.aab"
