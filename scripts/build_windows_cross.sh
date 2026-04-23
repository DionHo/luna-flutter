#!/usr/bin/env bash
# Windows build — obtains native Windows binaries from GitHub Actions.
#
# Usage:
#   ./scripts/build_windows_cross.sh [--ref BRANCH_OR_TAG]
#
# On Windows hosts (MINGW/MSYS/CYGWIN): builds locally via build_windows.ps1.
# On Linux/macOS: triggers the GitHub Actions Windows workflow, waits for it,
#   then downloads the compiled release bundle to build/windows-artifact/.
#
# Prerequisites (Linux/macOS path):
#   1. gh CLI installed and authenticated:  gh auth login
#   2. The repository must be pushed to GitHub so the workflow can run.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKFLOW="build-windows.yml"
ARTIFACT_NAME="luna-windows-x64"
OUTPUT_DIR="build/windows-artifact"
REF="main"

# Parse optional --ref argument
while [[ $# -gt 0 ]]; do
    case "$1" in
        --ref) REF="$2"; shift 2 ;;
        *)     echo "Unknown argument: $1"; exit 1 ;;
    esac
done

OS="$(uname -s)"

# ── Windows host: build natively ──────────────────────────────────────────

case "$OS" in
    MINGW*|MSYS*|CYGWIN*)
        if command -v pwsh >/dev/null 2>&1; then
            echo "==> Windows host: building natively via pwsh"
            pwsh -File "$SCRIPT_DIR/build_windows.ps1"
            exit 0
        fi
        if command -v powershell.exe >/dev/null 2>&1; then
            echo "==> Windows host: building natively via powershell.exe"
            powershell.exe -ExecutionPolicy Bypass -File "$(cygpath -w "$SCRIPT_DIR/build_windows.ps1")"
            exit 0
        fi
        echo "ERROR: PowerShell not found on PATH." >&2
        exit 1
        ;;
esac

# ── Non-Windows host: trigger GitHub Actions, download artifact ───────────

if ! command -v gh >/dev/null 2>&1; then
    echo "ERROR: gh CLI not found." >&2
    echo "       Install it (https://cli.github.com/) then run: gh auth login" >&2
    exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
    echo "ERROR: gh CLI is not authenticated. Run: gh auth login" >&2
    exit 1
fi

echo "==> Triggering GitHub Actions workflow '$WORKFLOW' on ref '$REF'"
gh workflow run "$WORKFLOW" --ref "$REF"

# Give GitHub a moment to register the new run
sleep 6

echo "==> Waiting for workflow run to complete (this takes ~5–10 min)..."
RUN_ID=$(gh run list --workflow="$WORKFLOW" --limit=1 --json databaseId --jq '.[0].databaseId')
echo "    Run ID: $RUN_ID  (view at: $(gh run view "$RUN_ID" --json url --jq '.url'))"

gh run watch "$RUN_ID" --exit-status

echo "==> Downloading artifact '$ARTIFACT_NAME' to $OUTPUT_DIR/"
mkdir -p "$OUTPUT_DIR"
gh run download "$RUN_ID" --name "$ARTIFACT_NAME" --dir "$OUTPUT_DIR"

echo ""
echo "==> Done! Windows release bundle:"
ls -lh "$OUTPUT_DIR/"
echo ""
echo "    luna_flutter.exe and its DLLs are in $OUTPUT_DIR/"
