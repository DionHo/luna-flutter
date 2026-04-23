#!/usr/bin/env bash
# Build a release Android AAB.
# Usage: ./scripts/build_android.sh
set -euo pipefail

if [[ -z "${ANDROID_HOME:-}" && -d "/opt/android-sdk" ]]; then
  export ANDROID_HOME="/opt/android-sdk"
fi
if [[ -z "${ANDROID_SDK_ROOT:-}" && -n "${ANDROID_HOME:-}" ]]; then
  export ANDROID_SDK_ROOT="$ANDROID_HOME"
fi
if [[ -n "${ANDROID_HOME:-}" ]]; then
  export PATH="$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin"
fi

# Ensure an old Gradle daemon does not keep stale JVM settings.
if [[ -d android ]]; then
  (cd android && ./gradlew --stop >/dev/null 2>&1) || true
fi

echo "==> flutter build appbundle --release"
flutter build appbundle \
  --release \
  --obfuscate \
  --split-debug-info=build/symbols

echo "==> Done: build/app/outputs/bundle/release/app-release.aab"
