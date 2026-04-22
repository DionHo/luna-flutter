# 1. Introduction and Goals

## Purpose

Luna Flutter is an offline-capable AI voice assistant that runs entirely on the
user's device.  It provides a conversational interface powered by a local large
language model and synthesises responses as speech — with no network dependency
at runtime.

## Requirements Overview

| ID | Requirement |
|----|-------------|
| R1 | The application shall run on Windows, Linux, Android, and iOS from a single Flutter codebase. |
| R2 | All LLM inference shall execute on-device; no cloud API calls are permitted during conversation. |
| R3 | The LLM backend shall use the `nobodywho` Flutter plugin (llama.cpp) with a Gemma 4 E2B GGUF model. |
| R4 | Text-to-speech shall use the `kokoro_tts_flutter` plugin for on-device audio synthesis. |
| R5 | The application shall remain responsive (< 200 ms UI latency) while streaming tokens. |
| R6 | Conversation history shall persist across application restarts. |
| R7 | The build and release pipeline shall be fully automated via GitHub Actions. |

## Quality Goals

| Priority | Quality Attribute | Motivation |
|----------|-------------------|------------|
| 1 | Privacy / Offline-first | User data never leaves the device |
| 2 | Responsiveness | Streaming token display and real-time audio must feel natural |
| 3 | Portability | Single Dart codebase targeting four OS platforms |
| 4 | Maintainability | Clean feature/layer separation; documented architecture |
| 5 | Reliability | App must recover gracefully from model load failures |

## Stakeholders

| Role | Expectation |
|------|-------------|
| End user | Snappy voice assistant that works without internet |
| Developer | Clear architecture, lint-clean code, automated CI |
