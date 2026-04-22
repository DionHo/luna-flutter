# 10. Quality Requirements

## Quality Scenarios

| ID | Quality Attribute | Stimulus | Response | Threshold |
|----|-------------------|----------|----------|-----------|
| Q1 | Responsiveness | User submits a prompt | First token appears in chat UI | ≤ 3 s on reference hardware (8 GB RAM, mid-range CPU) |
| Q2 | Responsiveness | Token stream in progress | UI frame rate | ≥ 60 fps (no jank from token appends) |
| Q3 | Responsiveness | User taps Stop | TTS and inference halt | ≤ 200 ms |
| Q4 | Reliability | GGUF model file missing on startup | App shows actionable error, does not crash | 100 % of occurrences |
| Q5 | Reliability | TTS synthesis fails mid-sentence | Error surfaced via `AsyncValue.error`; chat UI remains usable | 100 % of occurrences |
| Q6 | Portability | Fresh install on any target platform | App builds and runs without platform-specific manual steps | All four platforms |
| Q7 | Privacy | App is running | No outbound network requests during inference or TTS | Zero requests (verifiable with network monitor) |
| Q8 | Maintainability | Adding a new feature screen | New screen fits into `lib/features/<name>/` without touching unrelated code | Dev time < 2 h for a simple screen |

## Reference Hardware

Tests and thresholds are evaluated on:
- **Desktop:** 8-core CPU, 16 GB RAM, no discrete GPU (represents integrated-graphics laptop)
- **Mobile:** Mid-range Android, 6 GB RAM (e.g. Pixel 6a class)
