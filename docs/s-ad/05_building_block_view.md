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
│       ├── llm_service.dart    # LlmService — wraps nobodywho
│       ├── tts_service.dart    # TtsService — wraps kokoro_tts_flutter
│       └── conversation_repository.dart  # Persistence via sqflite
├── features/
│   ├── chat/
│   │   ├── providers/
│   │   │   └── chat_provider.dart   # ChatNotifier (StreamNotifier)
│   │   ├── screens/
│   │   │   └── chat_screen.dart
│   │   └── widgets/
│   │       ├── message_bubble.dart
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
| `loadModel(path)` | `Future<void>` | Initialises the nobodywho model from the given GGUF path |
| `unloadModel()` | `Future<void>` | Releases native model resources |
| `generate(prompt)` | `Stream<String>` | Streams token strings for the given prompt |
| `isModelLoaded` | `bool` | True when a model is resident in memory |

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

## Level 2 — Feature Providers

### ChatNotifier (`lib/features/chat/providers/chat_provider.dart`)

Extends `StreamNotifier<List<ConversationTurn>>`.  Orchestrates the
`LlmService → TtsService` pipeline and exposes the conversation list.

### SettingsNotifier (`lib/features/settings/providers/settings_provider.dart`)

Extends `Notifier<AppSettings>`.  Persists model path, voice, and theme
preferences via `shared_preferences`.
