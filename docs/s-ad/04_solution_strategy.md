# 4. Solution Strategy

## Key Decisions

### Flutter as UI Framework

Flutter was chosen over native per-platform UIs and Godot to achieve a single
Dart codebase that targets Windows, Linux, Android, and iOS without maintaining
separate UI layers.  Material 3 provides a solid cross-platform design baseline.

### nobodywho for LLM Inference

`nobodywho` (pub.dev) wraps llama.cpp via a Flutter FFI plugin, exposing a
Dart-native streaming API for GGUF model inference.  It avoids the complexity
of writing or maintaining a custom C++ GDExtension / FFI wrapper, and llama.cpp
supports all four target platforms.  The target model is **Gemma 4 E2B** in
GGUF format (`gemma-4-e2b-it-Q4_K_M.gguf`, ~2.5 GB).

### kokoro_tts_flutter for TTS

`kokoro_tts_flutter` provides on-device Kokoro TTS through a Flutter plugin
without requiring a network call or ONNX Runtime integration on the app side.
It is the only production-ready on-device Kokoro binding available for Flutter.

### Riverpod for State Management

Riverpod (`flutter_riverpod`) is used throughout for dependency injection and
reactive state.  `AsyncNotifier` and `StreamNotifier` map cleanly to the async
lifecycle of model loading and token streaming.  See ADR-001.

### SQLite for Conversation Persistence

`sqflite` provides SQLite access on mobile and desktop.  Conversation turns are
stored as rows; the schema is append-only to avoid migration complexity.

### GitHub Actions + Shell Scripts for CI/CD

Four platform-specific workflow files handle build and release artefacts.
Local shell scripts (`scripts/`) mirror the CI steps so developers can build
and test release artefacts without pushing to remote.

## Technology Stack Summary

| Concern | Technology | Package |
|---------|------------|---------|
| UI framework | Flutter 3.22+ | sdk |
| LLM inference | llama.cpp via nobodywho | `nobodywho` |
| TTS | Kokoro | `kokoro_tts_flutter` |
| State management | Riverpod | `flutter_riverpod` |
| Local DB | SQLite | `sqflite` |
| File paths | path_provider | `path_provider` |
| Audio playback | audioplayers | `audioplayers` |
