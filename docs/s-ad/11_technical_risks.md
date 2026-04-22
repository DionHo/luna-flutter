# 11. Technical Risks

| ID | Risk | Probability | Impact | Mitigation |
|----|------|-------------|--------|------------|
| R01 | `nobodywho` drops Windows or iOS support | Low | High | Monitor pub.dev changelog; maintain a fallback FFI wrapper branch |
| R02 | `kokoro_tts_flutter` is unmaintained / abandoned | Medium | High | Vendor the plugin or switch to a custom ONNX Runtime wrapper; documented in ADR-003 |
| R03 | Gemma 4 E2B GGUF too large for low-end Android devices (< 4 GB RAM) | High | Medium | Offer a smaller quantisation (Q2_K); document minimum hardware |
| R04 | llama.cpp inference speed too slow on mobile CPU | Medium | Medium | Evaluate GPU Metal delegate on iOS; evaluate Vulkan on Android |
| R05 | iOS App Store rejects app due to bundled ML model size | Low | Medium | Offer model download post-install rather than bundling in the IPA |
| R06 | MSIX packaging fails due to Windows signing certificate costs | Low | Low | Fall back to unsigned ZIP distribution for self-hosted Windows builds |
| R07 | Flutter SDK breaking change in platform channel API used by plugins | Low | Medium | Pin Flutter SDK in `pubspec.yaml` and `ci.yml`; test upgrades in a branch |
| R08 | SQLite concurrent-write corruption during rapid message sends | Low | Low | Serialise DB writes through a single-isolate queue in `ConversationRepository` |
