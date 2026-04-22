# 8. Concepts

## State Management

Riverpod (`flutter_riverpod`) is the sole state management solution.

- **`Notifier<T>`** — synchronous, non-async state (e.g. `SettingsNotifier`).
- **`AsyncNotifier<T>`** — state with an async `build()` phase (e.g. model
  loading on app start).
- **`StreamNotifier<T>`** — state driven by a continuous stream (e.g.
  `ChatNotifier` accumulating tokens from `LlmService.generate()`).

Providers are declared at the top of their feature `providers/` file and
imported where needed.  Never use `ChangeNotifier` or `setState` for feature
state.

## Error Handling

All domain errors are typed as subclasses of `AppException`
(`lib/core/error/app_exception.dart`):

| Exception | Meaning |
|-----------|---------|
| `ModelLoadException` | GGUF model could not be loaded (file missing, out of memory, etc.) |
| `InferenceException` | llama.cpp returned an error during token generation |
| `TtsException` | kokoro_tts_flutter failed to synthesise or play audio |
| `DatabaseException` | SQLite operation failed |

Providers catch these at the service call site and emit `AsyncValue.error(e, st)`
so the UI can render an error state.  Exceptions must never be swallowed
silently.

## Model Lifecycle

The `LlmService` owns the `nobodywho` model instance.  The lifecycle is:

```
unloaded ──loadModel()──► loaded ──unloadModel()──► unloaded
                            │
                     generate(prompt)
                            │
                     Stream<String> tokens
```

Only one model may be loaded at a time.  Calling `loadModel()` while a model
is resident first calls `unloadModel()` internally.

## Conversation Persistence

`ConversationRepository` maps to a single SQLite table `conversation_turns`:

```sql
CREATE TABLE conversation_turns (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  role      TEXT NOT NULL,   -- 'user' | 'assistant'
  content   TEXT NOT NULL,
  timestamp INTEGER NOT NULL -- Unix milliseconds
);
```

History is loaded once at startup and kept in `ChatNotifier` state.  Writes are
fire-and-forget (`unawaited`) from `ChatNotifier` to avoid blocking the UI.

## Asset and File Path Management

All paths to on-device files (GGUF model, Kokoro weights) must be resolved via
`path_provider` at runtime.  The preferred locations are:

| Asset | path_provider method |
|-------|----------------------|
| User-supplied GGUF model | `getApplicationDocumentsDirectory()` |
| Bundled TTS weights | `getApplicationSupportDirectory()` (extracted on first run) |
| Conversation database | `getApplicationSupportDirectory()` |

Absolute paths must never appear in source code.
