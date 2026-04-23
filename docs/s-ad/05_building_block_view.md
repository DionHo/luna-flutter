# 5. Building Block View

## Level 1 — Top-Level Structure

```
lib/
├── main.dart                   # Entry point; ProviderScope wraps the app
├── app.dart                    # MaterialApp, router, theme
├── core/
│   ├── error/
│   │   └── app_exception.dart  # Typed domain error hierarchy
│   ├── models/
│   │   ├── message.dart        # ConversationTurn model
│   │   └── model_config.dart   # LLM / TTS configuration value objects
│   └── services/
│       ├── llm_service.dart    # LlmService — wraps nobodywho Chat + Model
│       ├── embedding_service.dart  # EmbeddingService — wraps nobodywho Encoder
│       ├── rag_service.dart    # RagService — two-stage RAG pipeline
│       ├── tts_service.dart    # TtsService — wraps kokoro_tts_flutter
│       └── conversation_repository.dart  # Persistence via sqflite
├── features/
│   ├── chat/
│   │   ├── providers/
│   │   │   └── chat_provider.dart   # ChatNotifier (AsyncNotifier)
│   │   ├── screens/
│   │   │   └── chat_screen.dart
│   │   └── widgets/
│   │       ├── message_bubble.dart  # Uses gpt_markdown for assistant responses
│   │       └── input_bar.dart
│   └── settings/
│       ├── providers/
│       │   └── settings_provider.dart
│       ├── screens/
│       │   └── settings_screen.dart
│       └── widgets/
│           └── model_path_picker.dart
└── shared/
    └── widgets/
        └── loading_indicator.dart
```

## Level 2 — Core Services

### LlmService (`lib/core/services/llm_service.dart`)

| Member | Type | Description |
|--------|------|-------------|
| `loadModel(config)` | `Future<void>` | Loads a GGUF chat model (+ optional mmproj) into nobodywho |
| `unloadModel()` | `Future<void>` | Releases native model resources |
| `generate(prompt)` | `Stream<String>` | Streams token strings for a text prompt |
| `generateFromAudio(path)` | `Stream<String>` | Streams tokens for a WAV audio file (multimodal) |
| `stopGeneration()` | `void` | Cancels in-progress token generation |
| `isModelLoaded` | `bool` | True when a model is resident in memory |
| `skipThinkingTags(stream)` | `Stream<String>` | Free function: strips `<think>…</think>` blocks from output |

### TtsService (`lib/core/services/tts_service.dart`)

| Member | Type | Description |
|--------|------|-------------|
| `speak(text)` | `Future<void>` | Synthesises and plays audio for the given text |
| `stop()` | `Future<void>` | Cancels active synthesis and playback |
| `isSpeaking` | `bool` | True while audio is being played |

### ConversationRepository (`lib/core/services/conversation_repository.dart`)

| Member | Type | Description |
|--------|------|-------------|
| `loadHistory()` | `Future<List<ConversationTurn>>` | Retrieves all stored turns from SQLite |
| `addTurn(turn)` | `Future<void>` | Appends a turn to the database |
| `clearHistory()` | `Future<void>` | Deletes all stored turns |

### EmbeddingService (`lib/core/services/embedding_service.dart`)

Wraps `nobodywho.Encoder` for computing dense semantic embedding vectors.
Used as Stage 1 of the RAG pipeline.

| Member | Type | Description |
|--------|------|-------------|
| `loadModel(path)` | `Future<void>` | Loads a GGUF embedding model |
| `encode(text)` | `Future<List<double>>` | Returns a dense float embedding vector |
| `unloadModel()` | `void` | Releases native model resources |
| `isLoaded` | `bool` | True when an embedding model is resident |

### RagService (`lib/core/services/rag_service.dart`)

Two-stage retrieval pipeline: cosine-similarity filtering (Stage 1) followed
by cross-encoder reranking (Stage 2).  Mirrors the pattern from the
[nobodywho flutter-starter-example](https://github.com/nobodywho-ooo/flutter-starter-example).

| Member | Type | Description |
|--------|------|-------------|
| `loadModels(embeddingPath, rerankerPath)` | `Future<void>` | Loads both GGUF models |
| `search(query, documents, topK, candidateCount)` | `Future<List<String>>` | Returns top-K relevant documents |
| `unloadModels()` | `void` | Releases native model resources |
| `isLoaded` | `bool` | True when both models are resident |

## Level 2 — Feature Providers

### ChatNotifier (`lib/features/chat/providers/chat_provider.dart`)

Extends `AsyncNotifier<ChatState>`.  Orchestrates the
`LlmService → TtsService` pipeline and exposes the conversation list.
Key actions: `sendMessage`, `startListening`, `stopListening`, `stopGeneration`,
`newSession`, `switchSession`, `deleteActiveSession`.

Riverpod providers in the same file:
- `llmServiceProvider` — singleton `LlmService`
- `ttsServiceProvider` — singleton `TtsService`
- `audioRecorderProvider` — singleton `AudioRecorderService`
- `embeddingServiceProvider` — singleton `EmbeddingService`
- `ragServiceProvider` — singleton `RagService`
- `conversationRepositoryProvider` — singleton `ConversationRepository`
- `modelBootstrapProvider` — overridden at startup with a pre-initialised `ModelBootstrapService`

### SettingsNotifier (`lib/features/settings/providers/settings_provider.dart`)

Extends `Notifier<AppSettings>`.  Persists model path, voice, and theme
preferences via `shared_preferences`.
