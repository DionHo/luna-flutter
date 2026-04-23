#!/usr/bin/env bash
# Downloads the Gemma 4 E2B GGUF models required by Luna Flutter.
# Models are stored in assets/models/ which is git-ignored.
# Run this script once before building the app locally.
# GitHub Actions workflows run this script automatically (with caching).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODELS_DIR="$SCRIPT_DIR/../assets/models"

mkdir -p "$MODELS_DIR"

LLM_FILE="$MODELS_DIR/gemma-4-E2B-it-Q4_K_M.gguf"
MMPROJ_FILE="$MODELS_DIR/mmproj-BF16.gguf"

LLM_URL="https://huggingface.co/unsloth/gemma-4-E2B-it-GGUF/resolve/main/gemma-4-E2B-it-Q4_K_M.gguf?download=true"
MMPROJ_URL="https://huggingface.co/unsloth/gemma-4-E2B-it-GGUF/resolve/main/mmproj-BF16.gguf?download=true"

if [ ! -f "$LLM_FILE" ]; then
  echo "Downloading gemma-4-E2B-it-Q4_K_M.gguf (~3.3 GB)…"
  curl -L --retry 3 --retry-delay 5 -o "$LLM_FILE" "$LLM_URL"
  echo "Downloaded: $LLM_FILE"
else
  echo "Already present: $LLM_FILE"
fi

if [ ! -f "$MMPROJ_FILE" ]; then
  echo "Downloading mmproj-BF16.gguf…"
  curl -L --retry 3 --retry-delay 5 -o "$MMPROJ_FILE" "$MMPROJ_URL"
  echo "Downloaded: $MMPROJ_FILE"
else
  echo "Already present: $MMPROJ_FILE"
fi

echo "All models ready."
