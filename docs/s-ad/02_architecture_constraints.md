# 2. Architecture Constraints

## Technology Constraints

| ID | Constraint | Rationale |
|----|------------|-----------|
| C1 | Flutter SDK ≥ 3.22 | Required by `nobodywho` and `kokoro_tts_flutter` native plugin APIs |
| C2 | Dart SDK ≥ 3.4 | Minimum version compatible with the chosen Flutter SDK |
| C3 | LLM inference via `nobodywho` only | Wraps llama.cpp; provides the required GGUF model support |
| C4 | TTS via `kokoro_tts_flutter` only | Only on-device Kokoro TTS binding available for Flutter |
| C5 | State management via Riverpod (`flutter_riverpod`) | Chosen in ADR-001; do not introduce competing state solutions |
| C6 | No `dart:mirrors` | Incompatible with Flutter's tree-shaker and AOT compiler |

## Platform Constraints

| Platform | Min SDK / OS | Notes |
|----------|-------------|-------|
| Android | API 26 (Android 8.0) | Minimum required by `nobodywho` native libs |
| iOS | iOS 16.0 | Minimum required by `kokoro_tts_flutter`; bitcode disabled |
| Linux | Ubuntu 22.04 / glibc 2.35 | CI runner baseline; snap packaging optional |
| Windows | Windows 10 x64 | MSIX packaging via GitHub Actions |

## Organisational Constraints

| ID | Constraint |
|----|------------|
| O1 | All model files (GGUF, TTS weights) are **not** committed to the repository; they are downloaded at runtime or referenced from a user-supplied path |
| O2 | Platform-specific `dart:io` checks must be accompanied by an entry in this document |
| O3 | No third-party analytics or crash-reporting SDKs that phone home |

## Platform-specific `dart:io` Usage

| Location | Platform check | Reason |
|----------|----------------|--------|
| _None yet_ | — | — |
