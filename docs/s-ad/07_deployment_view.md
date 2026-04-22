# 7. Deployment View

## Development Environment

A ready-to-use devcontainer is provided under `.devcontainer/`.

| File | Purpose |
|------|---------|
| `.devcontainer/Dockerfile` | Ubuntu 24.04 (noble) base with Flutter stable, clang, cmake, ninja, GTK3 |
| `.devcontainer/devcontainer.json` | VS Code extensions (Flutter, Dart, Git Graph, GitHub Copilot), `postCreateCommand` |

The container supports **Linux builds and tests** out of the box.  Android,
Windows, and iOS builds are handled by CI runners with the appropriate
toolchains.

To pin a specific Flutter release, set the `FLUTTER_CHANNEL` build arg in
`devcontainer.json` (e.g. `"3.29.3"`).

## Platform Build Matrix

| Platform | Runner (CI) | Output artefact | Script |
|----------|-------------|-----------------|--------|
| Linux x64 | `ubuntu-22.04` | `.tar.gz` bundle | `scripts/build_linux.sh` |
| Windows x64 | `windows-2022` | MSIX package | `scripts/build_windows.ps1` |
| Android | `ubuntu-22.04` | `.aab` (release) | `scripts/build_android.sh` |
| iOS | `macos-14` | `.ipa` (signed) | `scripts/build_ios.sh` |
| All (local) | host OS | per-platform artefacts | `scripts/build_all.sh` |

## GitHub Actions Workflows

| File | Trigger | Purpose |
|------|---------|---------|
| `.github/workflows/ci.yml` | Push / PR (all branches) | `flutter analyze` + `flutter test` |
| `.github/workflows/build-linux.yml` | Push to `main`, `release/**` | Build Linux bundle artefact |
| `.github/workflows/build-windows.yml` | Push to `main`, `release/**` | Build Windows MSIX artefact |
| `.github/workflows/build-android.yml` | Push to `main`, `release/**` | Build Android AAB artefact |
| `.github/workflows/build-ios.yml` | Push to `main`, `release/**` | Build signed iOS IPA artefact |

## Release Process

1. Create a `release/x.y.z` branch and bump the version in `pubspec.yaml`.
2. CI runs all four build workflows; artefacts are uploaded to GitHub Releases.
3. Android AAB is promoted manually in Google Play Console.
4. iOS IPA is uploaded via Fastlane / Transporter to App Store Connect.

## Required Secrets

| Secret | Used by | Purpose |
|--------|---------|---------|
| `ANDROID_KEYSTORE_BASE64` | `build-android.yml` | Release signing keystore (Base64) |
| `ANDROID_KEY_ALIAS` | `build-android.yml` | Key alias within the keystore |
| `ANDROID_KEY_PASSWORD` | `build-android.yml` | Key password |
| `ANDROID_STORE_PASSWORD` | `build-android.yml` | Keystore password |
| `APPLE_TEAM_ID` | `build-ios.yml` | Apple Developer Team ID |
| `IOS_CERTIFICATE_BASE64` | `build-ios.yml` | Distribution certificate (p12, Base64) |
| `IOS_CERTIFICATE_PASSWORD` | `build-ios.yml` | Certificate password |
| `IOS_PROVISIONING_PROFILE_BASE64` | `build-ios.yml` | Provisioning profile (Base64) |
