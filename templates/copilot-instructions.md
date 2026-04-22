# GitHub Copilot Instructions — Godot-LiteRT-LM

## Project overview

Godot-LiteRT-LM is a **GDExtension plugin** (C++17) that wraps the
[LiteRT-LM](https://github.com/google-ai-edge/LiteRT-LM) inference engine and
exposes it to Godot 4 via a clean GDScript API.  The two public Godot nodes are
`LiteRTLMEngine` (model lifecycle) and `LiteRTLMSession` (per-inference
context).  The build system is SCons; cross-platform CI runs on GitHub Actions.

---

## Architecture documentation — read before acting

The `docs/s-ad/` directory contains the full arc42 software-architecture
description for this project.  **Before implementing or proposing any
non-trivial change, read the relevant sections:**

| Section | When to consult |
|---------|-----------------|
| `01_introduction_and_goals.md` | Validating that a change aligns with project requirements (R1–R7) and quality goals |
| `02_architecture_constraints.md` | Any change that touches build system, platform support, or third-party SDK |
| `03_context_and_scope.md` | Understanding what is inside / outside the system boundary |
| `04_solution_strategy.md` | High-level technology decisions and rationale |
| `05_building_block_view.md` | Component structure; where new C++ code belongs |
| `06_runtime_view.md` | Async / signal flow; how inference is triggered |
| `07_deployment_view.md` | Platform targets and packaging |
| `08_concepts.md` | Cross-cutting concerns (threading, error handling, memory) |
| `09_architecture_decisions.md` | ADRs — check before proposing alternatives that may already be decided |
| `10_quality_requirements.md` | Performance, reliability, and portability thresholds |
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
- A new GDScript API (`LiteRTLMEngine` or `LiteRTLMSession` methods/signals/properties) is added, changed, or removed.
- Platform support changes (targets added or dropped).
- Build instructions change (new dependencies, flags, or steps).
- The quick-start example becomes stale.

### docs/TODO.md

- Mark items `✅` (done) as the corresponding code lands.
- Add new tasks under the appropriate milestone when scoping new work.
- Do not remove open tasks; only update their status.

### docs/s-ad/ (arc42)

Update the arc42 sections alongside the code change that triggers them:

| Code change | Arc42 section(s) to update |
|-------------|----------------------------|
| New or renamed public node / class | `05_building_block_view.md` |
| New public method, signal, or property | `05_building_block_view.md`, `06_runtime_view.md` (if async) |
| New platform target | `07_deployment_view.md`, `02_architecture_constraints.md` |
| New third-party dependency | `04_solution_strategy.md`, `02_architecture_constraints.md` |
| Threading or async model change | `06_runtime_view.md`, `08_concepts.md` |
| New build system option or script | `07_deployment_view.md` |
| Decision that overrides or extends an ADR | `09_architecture_decisions.md` (add a new ADR entry) |
| New quality requirement or threshold | `10_quality_requirements.md` |
| New or resolved technical risk | `11_technical_risks.md` |
| New term introduced in code or docs | `12_glossary.md` |

### docs/references.md

Add a reference entry when introducing a new external library, specification,
or standard that the codebase depends on.

---

## Coding conventions

- Follow existing code style in `src/`; do not reformat unrelated lines.
- Godot node classes inherit from `godot::Node` and are registered in `register_types.cpp`.
- Use the type names from `docs/s-ad/12_glossary.md` verbatim in code identifiers, comments, and documentation.
- Error handling: follow the patterns established in `docs/s-ad/08_concepts.md`; surface errors via Godot's `ERR_FAIL_*` macros and emit a dedicated error signal where async recovery is possible.
- Do not introduce platform-specific `#ifdef` blocks without a corresponding entry in `docs/s-ad/02_architecture_constraints.md`.

---

## Workflow rules

- When generating or editing **any** source file in `src/`, check whether public API changed and update `README.md` and `docs/s-ad/05_building_block_view.md` in the same response. Use build scripts and tests to validate changes before marking them as done.
- When editing `.github/workflows/build.yml` or `scripts/`, update `docs/s-ad/07_deployment_view.md` if the deployment topology or build steps change. Use `act` to test workflow changes locally before finishing.
- When adding a new feature (not a bug fix), add an entry to `docs/TODO.md` under the relevant milestone, or mark an existing open task as done.
- Propose doc updates as concrete file edits, not as suggestions like "you should update the docs".
