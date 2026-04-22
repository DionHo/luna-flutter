# 3. Context and Scope

## Business Context

```
┌────────────────────────────────────────────────────────┐
│                     End User                           │
│  speaks / types a query                                │
└──────────────────────────┬─────────────────────────────┘
                           │ touch / keyboard / microphone
┌──────────────────────────▼─────────────────────────────┐
│                  Luna Flutter App                      │
│  (Flutter / Dart; Windows, Linux, Android, iOS)        │
│                                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │            LLM Inference (nobodywho)             │  │
│  │          Gemma 4 E2B GGUF — on-device            │  │
│  └──────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────┐  │
│  │          TTS Synthesis (kokoro_tts_flutter)      │  │
│  │            Kokoro model — on-device              │  │
│  └──────────────────────────────────────────────────┘  │
└──────────────────────────┬─────────────────────────────┘
                           │ audio output
                    Speaker / headphones
```

## Scope

**Inside the system boundary:**
- Conversational UI (chat history, text input)
- Streaming LLM inference via `nobodywho`
- On-device TTS via `kokoro_tts_flutter`
- Conversation persistence (local storage)
- Model lifecycle management (load, unload, swap)
- Build and release pipeline (GitHub Actions + shell scripts)

**Outside the system boundary:**
- Speech-to-text / microphone input (planned, not in initial scope)
- Cloud-based inference or external APIs
- Model fine-tuning or training
- 3D avatar rendering
- Tool / function calling (planned future feature)

## External Interfaces

| Interface | Direction | Technology | Notes |
|-----------|-----------|------------|-------|
| GGUF model file | In (read-only) | File system via `path_provider` | User downloads separately |
| Kokoro TTS model | In (read-only) | Bundled asset or user-provided path | |
| Audio output | Out | Flutter `audioplayers` or platform audio | PCM from kokoro |
| Conversation DB | In/Out | SQLite via `sqflite` | Local persistence |
