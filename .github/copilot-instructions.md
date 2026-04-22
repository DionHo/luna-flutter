# GitHub Copilot Instructions — Luna Flutter

## Project overview

Luna Flutter is an **offline-capable AI voice assistant** built with Flutter /
Dart.  It runs a Gemma 4 E2B language model on-device via the
[nobodywho](https://pub.dev/packages/nobodywho) plugin (llama.cpp backend) and
speaks responses through on-device TTS via
[kokoro_tts_flutter](https://pub.dev/packages/kokoro_tts_flutter).  The app
targets **Windows, Linux, Android, and iOS** from a single codebase and is
built and released via GitHub Actions and local shell scripts.

There is no cloud inference — all AI processing happens on the user's device.

---

## Architecture documentation — read before acting

The `docs/s-ad/` directory contains the full arc42 software-architecture
description for this project.  **Before implementing or proposing any
non-trivial change, read the relevant sections:**

| Section | When to consult |
|---------|-----------------|
| `01_introduction_and_goals.md` | Validating that a change aligns with project requirements and quality goals |
| `02_architecture_constraints.md` | Changes touching Flutter version, platform support, or third-party packages |
| `03_context_and_scope.md` | Understanding what is inside / outside the system boundary |
| `04_solution_strategy.md` | High-level technology decisions and rationale |
| `05_building_block_view.md` | Flutter layer / feature structure; where new Dart code belongs |
| `06_runtime_view.md` | Async stream and inference flow; how tokens and audio are produced |
| `07_deployment_view.md` | Platform targets, CI/CD pipeline, and release packaging |
| `08_concepts.md` | Cross-cutting concerns: state management, error handling, model lifecycle |
| `09_architecture_decisions.md` | ADRs — check before proposing alternatives that may already be decided |
| `10_quality_requirements.md` | Performance, reliability, and UX thresholds |
| `11_technical_risks.md` | Known risks and mitigations |
| `12_glossary.md` | Canonical terms; use these names consistently in code and docs |

If a change **contradicts an existing ADR**, point this out explicitly and
propose a new ADR entry in `09_architecture_decisions.md` rather than silently
deviating.

---

## Keeping documentation up-to-date

Apply the following rules on every code change, not as a separate follow-up:

### README.md

Update `README.md` when:
- A new user-facing feature is added, changed, or removed.
- A public service / provider API (method, stream, state shape) changes.
- Platform support changes (targets added or dropped).
- Build or installation instructions change (new dependencies, steps, or flags).
- The quick-start section becomes stale.

### docs/TODO.md

- Mark items `✅` (done) when the corresponding code lands.
- Add new tasks under the appropriate milestone when scoping new work.
- Do not remove open tasks; only update their status.

### docs/s-ad/ (arc42)

Update the arc42 sections alongside the code change that triggers them:

| Code change | Arc42 section(s) to update |
|-------------|----------------------------|
| New or renamed feature module, screen, or service | `05_building_block_view.md` |
| New public method, stream, or ChangeNotifier state shape | `05_building_block_view.md` |
| New async inference or audio pipeline step | `06_runtime_view.md` |
| New platform target | `07_deployment_view.md`, `02_architecture_constraints.md` |
| New pub.dev dependency or platform plugin | `04_solution_strategy.md`, `02_architecture_constraints.md` |
| State management or async model change | `06_runtime_view.md`, `08_concepts.md` |
| New build script or CI job step | `07_deployment_view.md` |
| Decision that overrides or extends an ADR | `09_architecture_decisions.md` (add a new ADR entry) |
| New quality requirement or threshold | `10_quality_requirements.md` |
| New or resolved technical risk | `11_technical_risks.md` |
| New term introduced in code or docs | `12_glossary.md` |

### docs/references.md

Add a reference entry when introducing a new external package, specification,
or standard that the codebase depends on.

---

## Coding conventions

- Follow `analysis_options.yaml`; do not suppress lints for convenience.
- Organise features under `lib/features/<feature_name>/` with sub-folders
  `screens/`, `widgets/`, and `providers/` (Riverpod).  Shared widgets live in
  `lib/shared/widgets/`.  Business logic services live in `lib/core/services/`.
- State management is Riverpod (`flutter_riverpod`).  Prefer `AsyncNotifier`
  and `StreamNotifier` for anything that has asynchronous lifecycle.
- Use the type names from `docs/s-ad/12_glossary.md` verbatim in class names,
  comments, and documentation.
- Error handling: surface errors through typed `AsyncValue.error` states in
  providers; never swallow exceptions silently.  Use `AppException` (defined in
  `lib/core/error/app_exception.dart`) for domain errors.
- All file paths that reference on-device model files must be obtained via
  `path_provider`; never hardcode absolute paths.
- Do not add platform-specific `dart:io` Platform checks without a
  corresponding entry in `docs/s-ad/02_architecture_constraints.md`.

---

## Workflow rules

- Before marking any code change as done, run `flutter analyze` and
  `flutter test` and confirm they pass.
- When generating or editing any Dart file in `lib/`, check whether the public
  API or user-facing behaviour changed and update `README.md` and
  `docs/s-ad/05_building_block_view.md` in the same response.
- When editing `.github/workflows/` or `scripts/`, update
  `docs/s-ad/07_deployment_view.md` if the deployment topology or build steps
  change.
- When adding a new feature (not a bug fix), add an entry to `docs/TODO.md`
  under the relevant milestone, or mark an existing open task as done.
- When adding a new `pub.dev` package, add it to `docs/references.md` with a
  one-line rationale.
- Propose doc updates as concrete file edits, not as suggestions like
  "you should update the docs".
- Do not commit without running `flutter analyze --fatal-infos` to catch
  unused imports and style violations.
