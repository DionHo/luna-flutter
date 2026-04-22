# 6. Runtime View

## Scenario 1 — Application Start / Model Load

```
App start
  └─► main.dart: runApp(ProviderScope(child: LunaApp()))
        └─► SettingsNotifier.build()
              └─► shared_preferences: read saved model path
        └─► ChatNotifier.build()
              └─► ConversationRepository.loadHistory()
                    └─► SQLite: SELECT * FROM turns ORDER BY id
              └─► LlmService.loadModel(path)
                    └─► nobodywho: NobodywhoModel(modelPath).load()
                          ── success ──► LlmService.isModelLoaded = true
                          ── failure ──► AppException.modelLoadFailed
                                          └─► ChatNotifier emits AsyncError
```

## Scenario 2 — User Sends a Message (Token Streaming)

```
User taps Send (InputBar)
  └─► ChatNotifier.sendMessage(userText)
        1. Append UserTurn to state list
        2. ConversationRepository.addTurn(UserTurn)
        3. LlmService.generate(prompt)  ← returns Stream<String>
              └─► nobodywho: session.getCompletion(prompt)
                    ── token ──► ChatNotifier appends token to AssistantTurn
                                   └─► UI rebuilds via Riverpod (streaming)
                    ── done  ──► ChatNotifier finalises AssistantTurn
                                   └─► ConversationRepository.addTurn(AssistantTurn)
                                   └─► TtsService.speak(fullResponse)
                                         └─► kokoro_tts_flutter: synthesise + play
```

## Scenario 3 — Settings: Change Model Path

```
User selects new GGUF via ModelPathPicker
  └─► SettingsNotifier.setModelPath(newPath)
        └─► shared_preferences: write model path
        └─► LlmService.unloadModel()
              └─► nobodywho: dispose current model
        └─► LlmService.loadModel(newPath)
              (see Scenario 1 from LlmService.loadModel)
```

## Async / Threading Model

- `LlmService.generate()` runs llama.cpp inference on a background isolate
  managed internally by `nobodywho`; token `Stream<String>` is delivered on
  the main isolate via Flutter's platform channel message loop.
- `TtsService.speak()` dispatches synthesis to the `kokoro_tts_flutter` plugin,
  which runs synthesis on a background thread and streams PCM to the audio
  output device.
- `ChatNotifier` never blocks the UI thread; it only awaits `Future`s and
  listens to `Stream`s in its `build` / `sendMessage` methods.
