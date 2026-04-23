#!/usr/bin/env bash
# Run all quality checks and build every platform available on the current host.
#
# Always runs:  flutter analyze --fatal-infos
#               flutter test --coverage
#
# Then detects the host OS and available toolchains:
#   Linux   → flutter build linux   (always)
#             flutter build apk     (only when ANDROID_HOME is set)
#             windows via gh CI     (triggers GH Actions, downloads artifact)
#   macOS   → flutter build ios     (only when Xcode is present)
#             flutter build apk     (only when ANDROID_HOME is set)
#   Windows → flutter build windows (always, via PowerShell subscript)
#
# Usage: ./scripts/build_all.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

# ── helpers ────────────────────────────────────────────────────────────────

step() { echo ""; echo "==> $*"; }
skip() { echo "    (skipped) $*"; }

# ── 1. Static analysis ─────────────────────────────────────────────────────

step "flutter analyze --fatal-infos"
flutter analyze --fatal-infos

# ── 2. Tests ───────────────────────────────────────────────────────────────

step "flutter test --coverage"
flutter test --coverage

# ── 3. Platform builds ─────────────────────────────────────────────────────

build_linux() {
    step "Building Linux bundle"
    bash "$SCRIPT_DIR/build_linux.sh"
}

build_android() {
    if [[ -n "${ANDROID_HOME:-}" ]] && command -v java &>/dev/null; then
        step "Building Android AAB"
        bash "$SCRIPT_DIR/build_android.sh"
    else
        skip "Android build (set ANDROID_HOME and ensure Java is on PATH to enable)"
    fi
}

build_ios() {
    if command -v xcodebuild &>/dev/null; then
        step "Building iOS IPA"
        bash "$SCRIPT_DIR/build_ios.sh"
    else
        skip "iOS build (requires macOS + Xcode)"
    fi
}

build_windows() {
    step "Windows cross-build helper"
    bash "$SCRIPT_DIR/build_windows_cross.sh"
}

case "$OS" in
    Linux)
        build_linux
        build_android
        build_windows   # succeeds only when pwsh is installed
        ;;
    Darwin)
        build_ios
        build_android
        ;;
    MINGW*|MSYS*|CYGWIN*)
        # Running inside Git Bash / MSYS2 on Windows
        build_windows
        build_android
        ;;
    *)
        echo "Unknown OS '$OS' — running analyze + test only."
        ;;
esac

step "build_all.sh finished successfully."
