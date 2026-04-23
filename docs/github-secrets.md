# GitHub Actions — Required Secrets

Add secrets at **Settings → Secrets and variables → Actions → New repository secret**
for the repository: https://github.com/DionHo/luna-flutter/settings/secrets/actions

---

## Public repositories and secrets safety

GitHub Actions secrets are **safe to use in public repositories**. GitHub guarantees:

- Secret values are **never printed** in workflow logs, even if you accidentally `echo` them — they are masked with `***`.
- Secrets are **not passed to workflows triggered by pull requests from forks** by default. A fork-triggered PR workflow runs with read-only permissions and sees empty strings for all secrets, so no secret can be exfiltrated by a contributor submitting a malicious PR.
- Secrets are only accessible to workflows in your repository and to repository/organization owners.

**What this means for Luna Flutter:** the signing certificates and passwords stored as secrets cannot be read by the public, cannot be leaked in logs, and cannot be stolen via a fork PR.

> ⚠️ If you ever push a workflow change that *explicitly* prints a secret (e.g. `echo "$MY_SECRET"`), GitHub redacts the output to `***` in the logs. Never use `set -x` (shell trace mode) in a step that handles secrets, as it may log intermediate variable values before masking kicks in.

---

## iOS signing (`build-ios.yml`)

All four secrets are required to produce a signed `.ipa`. Until they are set the
workflow still runs and compiles the app with `--no-codesign` (no `.ipa` uploaded).

| Secret name | Value |
|---|---|
| `IOS_CERTIFICATE_BASE64` | Base64-encoded Apple **Distribution** certificate (`.p12`). Export from Xcode → Settings → Accounts → Manage Certificates, then: `base64 -i cert.p12 \| pbcopy` |
| `IOS_CERTIFICATE_PASSWORD` | Password chosen when exporting the `.p12` file |
| `IOS_PROVISIONING_PROFILE_BASE64` | Base64-encoded **App Store Distribution** provisioning profile. Download from [developer.apple.com](https://developer.apple.com/account/resources/profiles/list), then: `base64 -i profile.mobileprovision \| pbcopy` |
| `APPLE_TEAM_ID` | Your 10-character Apple Developer Team ID, e.g. `AB12CD34EF`. Visible at [developer.apple.com/account](https://developer.apple.com/account) under **Membership Details**. |

---

## Android signing (`build-android.yml`)

All three secrets are required to produce a signed release `.aab`.
Without them the `Decode keystore` step will write an empty file and
`flutter build appbundle --release` will fail at signing.

| Secret name | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded Java keystore (`.jks`) file. Generate with: `keytool -genkey -v -keystore keystore.jks -alias key -keyalg RSA -keysize 2048 -validity 10000`, then `base64 -i keystore.jks \| pbcopy` |
| `ANDROID_KEY_ALIAS` | Alias used when generating the keystore (e.g. `key`) |
| `ANDROID_KEY_PASSWORD` | Key password set during keystore generation |
| `ANDROID_STORE_PASSWORD` | Store password set during keystore generation |

---

## Windows signing (optional, `build-windows.yml`)

By default MSIX creation uses `sign_msix: false` (unsigned) so no secrets are
required. To produce a signed MSIX for distribution:

| Secret name | Value |
|---|---|
| `WINDOWS_PFX_BASE64` | Base64-encoded `.pfx` code-signing certificate |
| `WINDOWS_PFX_PASSWORD` | Password for the `.pfx` file |

To enable signing, set `sign_msix: true` in `pubspec.yaml` under `msix_config`
and update the `Create MSIX` step in `.github/workflows/build-windows.yml` to
pass `--certificate-path` and `--certificate-password` from those secrets.

---

## Summary — which workflows need which secrets

| Workflow | Optional secrets (builds without them) | Required secrets (fails without them) |
|---|---|---|
| `build-ios.yml` | `IOS_CERTIFICATE_BASE64`, `IOS_CERTIFICATE_PASSWORD`, `IOS_PROVISIONING_PROFILE_BASE64`, `APPLE_TEAM_ID` | — (builds `--no-codesign`) |
| `build-android.yml` | — | `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `ANDROID_STORE_PASSWORD` |
| `build-windows.yml` | `WINDOWS_PFX_BASE64`, `WINDOWS_PFX_PASSWORD` | — (unsigned MSIX + exe always built) |
| `build-linux.yml` | — | — (no secrets needed) |
| `ci.yml` | — | — (no secrets needed) |
