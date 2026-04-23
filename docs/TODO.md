# Luna Flutter – TODO / Progress Tracker

## Legend
- ✅ Done
- 🔧 In progress / partially done
- [ ] Not started

---

## Phase 0 – Project Setup & Infrastructure
- ✅ Repository initialised
- ✅ `docs/s-ad/` arc42 architecture documentation written
- ✅ `docs/references.md` created
- ✅ `README.md` written
- ✅ `.gitignore` created
- ✅ `.github/copilot-instructions.md` created
- ✅ `.devcontainer/` — Ubuntu 24.04 devcontainer with Flutter stable, GTK3 deps, Git Graph, GitHub Copilot extensions
- ✅ `.github/workflows/ci.yml` — analyze + test on every push/PR
- ✅ `.github/workflows/build-linux.yml`
- ✅ `.github/workflows/build-windows.yml`
- ✅ `.github/workflows/build-android.yml`
- ✅ `.github/workflows/build-ios.yml`
- ✅ `scripts/build_linux.sh`
- ✅ `scripts/build_android.sh`
- ✅ `scripts/build_ios.sh`
- ✅ `scripts/build_windows.ps1`
- ✅ `scripts/build_all.sh` — runs analyze, tests, and all available platform builds
- [ ] Validate Linux workflow produces a working bundle
- [ ] Validate Windows workflow produces a working MSIX
- [ ] Validate Android workflow produces a signed AAB
- [ ] Validate iOS workflow produces a signed IPA (requires Apple Team ID secret)

## Phase 1 – Flutter Project Skeleton
- ✅ `flutter create` — generate platform scaffolding for Linux, Windows, Android, iOS
- ✅ `pubspec.yaml` — add `nobodywho`, `kokoro_tts_flutter`, `flutter_riverpod`, `sqflite`, `path_provider`, `audioplayers`
- ✅ `analysis_options.yaml` — strict lints
- ✅ `lib/main.dart` — `ProviderScope` + `runApp`; `NobodyWho.init()` wrapped in try-catch for stub mode
- ✅ `lib/app.dart` — `MaterialApp`, dark theme (Material 3)
- ✅ `lib/core/error/app_exception.dart` — typed exception hierarchy
- ✅ `lib/core/models/message.dart` — `ConversationTurn` model
- ✅ `lib/core/models/session.dart` — `Session` model (multi-session support)
- ✅ `lib/core/models/model_config.dart` — `ModelConfig` value object
- ✅ `lib/core/services/llm_service.dart` — `LlmService` (nobodywho wrapper)
- ✅ `lib/core/services/tts_service.dart` — `TtsService` (kokoro wrapper)
- ✅ `lib/core/services/conversation_repository.dart` — multi-session SQLite persistence
- ✅ `lib/features/chat/providers/chat_provider.dart` — `ChatNotifier` with session CRUD + PTT stubs
- ✅ `lib/features/chat/screens/chat_screen.dart` — session bar + chat list + push-to-talk layout
- ✅ `lib/features/chat/widgets/message_bubble.dart`
- ✅ `lib/features/chat/widgets/session_bar.dart` — new/delete/switch sessions
- ✅ `lib/features/chat/widgets/push_to_talk_button.dart` — hold-to-talk button (STT stub)
- ✅ `lib/features/settings/providers/settings_provider.dart`
- ✅ `lib/features/settings/screens/settings_screen.dart`
- ✅ `lib/features/settings/widgets/model_path_picker.dart`
- [ ] `lib/features/chat/widgets/input_bar.dart` — kept as fallback; not used in main UI yet

## Phase 2 – AI Voice Assistant (Multimodal)
- ✅ `scripts/download_models.sh` — downloads Gemma 4 E2B + BF16 mmproj to `assets/models/`
- ✅ CI workflows updated — model download with `actions/cache` before flutter build
- ✅ `lib/core/services/model_bootstrap_service.dart` — locates bundled model files at runtime
- ✅ `lib/core/services/audio_recorder_service.dart` — microphone capture via `record` package
- ✅ `lib/core/services/llm_service.dart` — multimodal `Model.load` + `askWithPrompt(AudioPart)`
- ✅ `lib/core/services/startup_logger.dart` — appending startup diagnostics log written next to exe
- ✅ `lib/features/chat/providers/chat_provider.dart` — PTT starts/stops recorder, sends audio to model
- ✅ `test/audio_inference_test.dart` — no-UI integration test; confirms Gemma 4 audio path works on Linux
- ✅ `test/text_inference_test.dart` — no-UI integration test; confirms Gemma 4 text path + `NobodyWho.init()` on Linux
- ✅ `test/model_bootstrap_path_test.dart` — path construction unit tests; confirms bundle layout is correct
- ✅ CI (`ci.yml`) runs all three model tests with cached model download (ubuntu-24.04 required for GLIBC 2.38)
- ✅ `lib/core/services/embedding_service.dart` — `EmbeddingService` wrapping `nobodywho.Encoder` (semantic embeddings for RAG)
- ✅ `lib/core/services/rag_service.dart` — `RagService` two-stage RAG pipeline (cosine-sim + cross-encoder reranking)
- ✅ `LlmService.stopGeneration()` — cancels active token generation
- ✅ `skipThinkingTags()` — stream helper stripping `<think>…</think>` blocks from LLM output
- ✅ `MessageBubble` uses `gpt_markdown` for streaming-aware Markdown rendering of assistant responses
- ✅ Windows CI bundles `vcomp140.dll` (OpenMP) and `vulkan-1.dll` (Vulkan Loader) from pre-installed SDK
- 🔧 Test on Windows desktop end-to-end (awaiting re-test)
- [ ] Android microphone permission + mobile model extraction
- [ ] iOS microphone permission + mobile model extraction

## Phase 3 – Core Features
- [ ] Streaming token display in chat UI (token-by-token) — stop button wired to `ChatNotifier.stopGeneration()`
- [ ] TTS playback with stop button
- [ ] Conversation persistence (SQLite, survives restart)
- [ ] Settings screen: GGUF model path picker
- [ ] Settings screen: voice / language selection
- [ ] App theme (dark / light toggle)

## Phase 4 – RAG & Knowledge Base
- [ ] Download embedding model (`nomic-embed-text-v1.5` or similar) via `scripts/download_embedding_rerank.sh`
- [ ] Download reranker model (`cross-encoder/ms-marco-MiniLM-L-6-v2` or similar)
- [ ] Wire `EmbeddingService` + `RagService` into a `RagNotifier` provider
- [ ] RAG screen: paste/type a knowledge base, ask questions with semantic retrieval
- [ ] Integrate retrieved context into `LlmService.generate()` via system prompt injection

## Phase 5 – Model Management
- [ ] First-run model download flow (GGUF from HuggingFace via `hf://` URL support in nobodywho)
- [ ] Runtime model switching without app restart
- [ ] Model size / RAM warning for low-memory devices

## Known Issues / Blockers
- `nobodywho` and `kokoro_tts_flutter` must be available on pub.dev and support
  all four target platforms — verify before Phase 1.
- iOS build requires Apple Developer Team ID (`APPLE_TEAM_ID` secret).
- Android AAB signing requires a keystore; see `docs/s-ad/07_deployment_view.md`.
- Gemma 4 E2B models are large (~4 GB total); first build requires running
  `scripts/download_models.sh` or relying on CI cache.
