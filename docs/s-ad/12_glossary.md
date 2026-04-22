# 12. Glossary

| Term | Definition |
|------|------------|
| **AppException** | Base class for all typed domain errors in `lib/core/error/app_exception.dart` |
| **AssistantTurn** | A `ConversationTurn` with `role == 'assistant'`; contains the LLM response |
| **ChatNotifier** | The Riverpod `StreamNotifier` that owns the active conversation state and orchestrates the inference pipeline |
| **ConversationRepository** | Service class responsible for reading and writing `ConversationTurn` records to SQLite |
| **ConversationTurn** | A single message unit in the conversation, containing `role`, `content`, and `timestamp` |
| **GGUF** | Binary model format used by llama.cpp; the format of the Gemma 4 E2B model loaded by `nobodywho` |
| **Gemma 4 E2B** | Google's 2-billion-parameter edge LLM in GGUF format (`gemma-4-e2b-it-Q4_K_M.gguf`) |
| **Kokoro** | The open-source TTS model used for on-device voice synthesis, accessed via `kokoro_tts_flutter` |
| **LlmService** | Core service class that wraps the `nobodywho` plugin and exposes `loadModel`, `unloadModel`, and `generate` |
| **ModelConfig** | Value object holding the model file path and inference hyper-parameters (temperature, context length, etc.) |
| **nobodywho** | Flutter FFI plugin wrapping llama.cpp for on-device GGUF model inference |
| **ProviderScope** | Riverpod root widget placed at the top of the widget tree in `main.dart` |
| **SettingsNotifier** | Riverpod `Notifier` that persists user preferences (model path, voice, theme) via `shared_preferences` |
| **StreamNotifier** | Riverpod v2 notifier subclass where `build()` returns a `Stream<T>`; used for token streaming |
| **TtsService** | Core service class that wraps `kokoro_tts_flutter` and exposes `speak` and `stop` |
| **UserTurn** | A `ConversationTurn` with `role == 'user'` |
