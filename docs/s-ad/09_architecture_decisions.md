# 9. Architecture Decisions

## ADR-001 — Riverpod as State Management Solution

**Date:** 2026-04-22  
**Status:** Accepted

**Context:**  
Flutter offers several competing state management approaches (Provider,
Riverpod, Bloc, GetX, etc.).  The application has significant async state
(model loading, token streaming) that benefits from first-class `AsyncValue`
and `Stream` support.

**Decision:**  
Use `flutter_riverpod` with `AsyncNotifier` and `StreamNotifier`.

**Rationale:**
- Compile-time safe provider access; no `BuildContext` required in services.
- `AsyncValue<T>` cleanly unifies loading / data / error states.
- `StreamNotifier` maps directly to the token-streaming use case.
- No competing state solution introduces less complexity than unifying on one.

**Consequences:**
- All feature state lives in Riverpod providers; `setState` and
  `ChangeNotifier` are forbidden in feature code.
- New contributors must be familiar with Riverpod v2 (code-gen optional).

---

## ADR-002 — nobodywho for LLM Inference

**Date:** 2026-04-22  
**Status:** Accepted

**Context:**  
A Flutter app cannot link native C++ inference libraries directly without an
FFI plugin.  Options evaluated: custom llama.cpp FFI wrapper, LiteRT-LM FFI
wrapper, `nobodywho` (pub.dev).

**Decision:**  
Use `nobodywho` as the LLM inference plugin.

**Rationale:**
- Maintained Flutter plugin; no custom native build required.
- llama.cpp backend supports GGUF models on all four target platforms.
- Streaming `Stream<String>` API aligns with `StreamNotifier` architecture.

**Consequences:**
- Model format is GGUF (not `.litertlm`).
- GPU acceleration depends on llama.cpp delegate support per platform.

---

## ADR-003 — kokoro_tts_flutter for Text-to-Speech

**Date:** 2026-04-22  
**Status:** Accepted

**Context:**  
Kokoro TTS must run on-device.  Options: custom ONNX Runtime FFI plugin,
`kokoro_tts_flutter` (pub.dev).

**Decision:**  
Use `kokoro_tts_flutter`.

**Rationale:**
- Avoids maintaining a custom ONNX Runtime wrapper for four platforms.
- Provides the same Kokoro voice quality as a custom integration.

**Consequences:**
- Dependency on a third-party pub.dev package for a core feature.
- Must track `kokoro_tts_flutter` for breaking updates.
