# Luna Flutter — Live User Natural Assistant

Luna Flutter is a **portable, offline-capable AI voice assistant** built with
Flutter / Dart.  It runs a Gemma 4 E2B language model entirely on-device via
[nobodywho](https://pub.dev/packages/nobodywho) (llama.cpp backend) and speaks
responses through [kokoro_tts_flutter](https://pub.dev/packages/kokoro_tts_flutter)
— with no internet connection required.

Supported platforms: **Windows · Linux · Android · iOS**

---

## Features

| Feature | Status |
|---------|--------|
| Local LLM inference (Gemma 4 E2B via nobodywho / llama.cpp) | 🔧 Stub |
| On-device TTS (Kokoro via kokoro_tts_flutter) | 🔧 Stub |
| Streaming token display | [ ] Planned |
| Conversation history (SQLite persistence) | [ ] Planned |
| Settings: model path picker | [ ] Planned |
| Voice input (STT) | [ ] Phase 6 |
| Offline-first — no cloud calls | ✅ Design goal |
| GitHub Actions builds (all 4 platforms) | ✅ |

---

## Architecture

```
┌─────────────────────────────────────────┐
│           Flutter UI (Dart)             │
│   ChatScreen · SettingsScreen           │
└──────────────┬──────────────────────────┘
               │ Riverpod providers
┌──────────────▼──────────────────────────┐
│           Feature Layer                 │
│   ChatNotifier · SettingsNotifier       │
└──────┬──────────────────┬───────────────┘
       │                  │
┌──────▼──────┐    ┌──────▼──────────────┐
│ LlmService  │    │      TtsService      │
│ (nobodywho) │    │ (kokoro_tts_flutter) │
└──────┬──────┘    └─────────────────────┘
       │
 Stream<String>  ← llama.cpp inference
```

State management is **Riverpod** (`flutter_riverpod`).  Business logic lives in
`lib/core/services/`.  Feature screens live in `lib/features/<name>/`.

See [`docs/s-ad/`](docs/s-ad/) for the full arc42 architecture documentation.

---

## Getting Started

### Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| Flutter SDK | ≥ 3.22 | `flutter doctor` must pass for your target platform |
| Dart SDK | ≥ 3.4 | Included with Flutter SDK |
| Gemma 4 E2B GGUF model | `Q4_K_M` | Download separately (see below) |

### Download a Model

```sh
# HuggingFace CLI (requires huggingface-cli)
huggingface-cli download lmstudio-community/gemma-2-2b-it-GGUF \
  gemma-2-2b-it-Q4_K_M.gguf --local-dir ~/models/
```

Place the `.gguf` file anywhere accessible on the device and point
the app to it via **Settings → Model Path**.

### Clone and Run

```sh
git clone https://github.com/<your-org>/luna-flutter.git
cd luna-flutter
flutter pub get
flutter run          # add -d linux / -d windows / etc.
```

---

## Building

### Local scripts

```sh
# Linux
./scripts/build_linux.sh

# Android
./scripts/build_android.sh

# iOS (macOS only)
./scripts/build_ios.sh

# Windows (PowerShell)
./scripts/build_windows.ps1
```

### GitHub Actions

Push to `main` or a `release/**` branch to trigger all four platform builds.
Artefacts are uploaded to the workflow run and tagged releases.

CI (analyze + test) runs on every push and pull request via
`.github/workflows/ci.yml`.

---

## Project Structure

```
.github/
  copilot-instructions.md   # Copilot coding guidelines
  workflows/                # CI/CD workflows
docs/
  s-ad/                     # arc42 architecture documentation
  TODO.md                   # Milestone tracker
  references.md             # External dependencies list
lib/
  main.dart
  app.dart
  core/
    error/                  # AppException hierarchy
    models/                 # ConversationTurn, ModelConfig
    services/               # LlmService, TtsService, ConversationRepository
  features/
    chat/                   # ChatScreen, ChatNotifier, widgets
    settings/               # SettingsScreen, SettingsNotifier, widgets
  shared/widgets/           # Reusable UI components
scripts/                    # Local build scripts
```

---

## Contributing

1. Run `flutter analyze --fatal-infos` before every commit.
2. Run `flutter test` and confirm all tests pass.
3. Update `docs/s-ad/` and `README.md` alongside code changes (see
   `.github/copilot-instructions.md` for the full rules).

---

## License

[MIT](LICENSE)
