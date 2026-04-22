# References

External packages, specifications, and standards that the Luna Flutter
codebase depends on.

---

| Name | URL | Version | Rationale |
|------|-----|---------|-----------|
| nobodywho | https://pub.dev/packages/nobodywho | latest | Flutter FFI plugin wrapping llama.cpp for on-device GGUF model inference |
| kokoro_tts_flutter | https://pub.dev/packages/kokoro_tts_flutter | latest | Flutter plugin providing on-device Kokoro TTS synthesis |
| flutter_riverpod | https://pub.dev/packages/flutter_riverpod | ^2.5.0 | Reactive state management with compile-time safe providers (ADR-001) |
| sqflite | https://pub.dev/packages/sqflite | ^2.3.0 | SQLite bindings for Flutter; used by `ConversationRepository` |
| path_provider | https://pub.dev/packages/path_provider | ^2.1.0 | Platform-specific file system path resolution for model and DB files |
| audioplayers | https://pub.dev/packages/audioplayers | ^6.0.0 | Cross-platform audio playback for synthesised TTS output |
| shared_preferences | https://pub.dev/packages/shared_preferences | ^2.2.0 | Lightweight key-value store for user settings persistence |
| Gemma 4 E2B GGUF | https://huggingface.co/lmstudio-community/gemma-2-2b-it-GGUF | Q4_K_M | Target LLM — 2B parameter Gemma 4 instruction-tuned model in GGUF format |
| arc42 | https://arc42.org | 9.0 | Software architecture documentation template used in `docs/s-ad/` |
| llama.cpp | https://github.com/ggerganov/llama.cpp | n/a | Underlying C++ inference engine used by `nobodywho` |
| Kokoro TTS | https://huggingface.co/hexgrad/Kokoro-82M | n/a | Underlying TTS model used by `kokoro_tts_flutter` |
