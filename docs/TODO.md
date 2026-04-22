# Luna Flutter – TODO / Progress Tracker

## Legend
- ✅ Done
- 🔧 In progress / partially done
- [ ] Not started

---

## Phase 0 – Project Setup
- ✅ Repository initialised
- ✅ `docs/s-ad/` arc42 architecture documentation written
- ✅ `docs/references.md` created
- ✅ `README.md` written
- ✅ `.gitignore` created
- ✅ `.github/copilot-instructions.md` created
- ✅ `.devcontainer/` — Ubuntu 24.04 devcontainer with Flutter stable, GTK3 deps, Git Graph, GitHub Copilot extensions

## Phase 1 – Flutter Project Skeleton
- [ ] `flutter create` — generate platform scaffolding for Linux, Windows, Android, iOS
- [ ] `pubspec.yaml` — add `nobodywho`, `kokoro_tts_flutter`, `flutter_riverpod`, `sqflite`, `path_provider`, `audioplayers`
- [ ] `analysis_options.yaml` — strict lints
- [ ] `lib/main.dart` — `ProviderScope` + `runApp`
- [ ] `lib/app.dart` — `MaterialApp.router`, theme
- [ ] `lib/core/error/app_exception.dart` — typed exception hierarchy
- [ ] `lib/core/models/message.dart` — `ConversationTurn` model
- [ ] `lib/core/models/model_config.dart` — `ModelConfig` value object
- [ ] `lib/core/services/llm_service.dart` — `LlmService` (nobodywho wrapper)
- [ ] `lib/core/services/tts_service.dart` — `TtsService` (kokoro wrapper)
- [ ] `lib/core/services/conversation_repository.dart` — SQLite persistence
- [ ] `lib/features/chat/providers/chat_provider.dart` — `ChatNotifier`
- [ ] `lib/features/chat/screens/chat_screen.dart`
- [ ] `lib/features/chat/widgets/message_bubble.dart`
- [ ] `lib/features/chat/widgets/input_bar.dart`
- [ ] `lib/features/settings/providers/settings_provider.dart`
- [ ] `lib/features/settings/screens/settings_screen.dart`
- [ ] `lib/features/settings/widgets/model_path_picker.dart`

## Phase 2 – GitHub Actions CI/CD
- ✅ `.github/workflows/ci.yml` — analyze + test on every push/PR
- ✅ `.github/workflows/build-linux.yml`
- ✅ `.github/workflows/build-windows.yml`
- ✅ `.github/workflows/build-android.yml`
- ✅ `.github/workflows/build-ios.yml`
- [ ] Validate Linux workflow produces a working bundle
- [ ] Validate Windows workflow produces a working MSIX
- [ ] Validate Android workflow produces a signed AAB
- [ ] Validate iOS workflow produces a signed IPA (requires Apple Team ID secret)

## Phase 3 – Local Build Scripts
- ✅ `scripts/build_linux.sh`
- ✅ `scripts/build_android.sh`
- ✅ `scripts/build_ios.sh`
- ✅ `scripts/build_windows.ps1`
- ✅ `scripts/build_all.sh` — runs analyze, tests, and all available platform builds

## Phase 4 – Core Features
- [ ] Streaming token display in chat UI (token-by-token)
- [ ] TTS playback with stop button
- [ ] Conversation persistence (SQLite, survives restart)
- [ ] Settings screen: GGUF model path picker
- [ ] Settings screen: voice / language selection
- [ ] App theme (dark / light toggle)

## Phase 5 – Model Management
- [ ] First-run model download flow (GGUF from HuggingFace)
- [ ] Runtime model switching without app restart
- [ ] Model size / RAM warning for low-memory devices

## Phase 6 – Voice Input
- [ ] Microphone capture (speech-to-text)
- [ ] STT integration (whisper.cpp or on-device API)

## Known Issues / Blockers
- `nobodywho` and `kokoro_tts_flutter` must be available on pub.dev and support
  all four target platforms — verify before Phase 1.
- iOS build requires Apple Developer Team ID (`APPLE_TEAM_ID` secret).
- Android AAB signing requires a keystore; see `docs/s-ad/07_deployment_view.md`.
