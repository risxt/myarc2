# GAG2 Roadmap

## Current Status

Milestone 1 started: workspace foundation.

## Milestones

### Milestone 1 — Workspace Foundation
- [x] Create `GAG2/` folder structure.
- [x] Backup current `gag2.lua`.
- [x] Create `PROJECT_BRAIN.md`.
- [x] Create `ROADMAP.md`.
- [x] Create `APS_PARITY_MATRIX.md`.
- [x] Create `DEPENDENCY_MAP.md`.

### Milestone 2 — Documentation Lock
- [x] Document current APS flow in `docs/CURRENT_APS_FLOW.md`.
- [x] Document safety invariants in `docs/SAFETY_INVARIANTS.md`.
- [x] Document webhook spec in `docs/WEBHOOK_SPEC.md`.
- [x] Document manual test checklist in `tests/manual_test_checklist.md`.

### Milestone 3 — Logical Single-File Refactor Design
- [x] Define `ApsState`.
- [x] Define `ApsSafetyService` pseudo-code.
- [x] Define `WebhookService` pseudo-code.
- [x] Define `ApsController` pseudo-code.

### Milestone 4 — Local Modular Prototype
- [x] Create local `src/` module skeletons.
- [x] Create local loader prototype.
- [x] Test load order locally.

### Milestone 5 — APS Extraction
- [x] Move APS safety functions.
- [x] Move APS webhook function.
- [x] Move shared scan helpers after dependency mapping.
- [x] Move APS worker/controller.
- [x] Keep old APS behind feature flag.

### Milestone 6 — Verification
- [ ] Success threshold test.
- [ ] Below/rejoin test.
- [ ] Manual OFF during scan test.
- [ ] Manual OFF during wait test.
- [ ] Reverse fail simulation if possible.
- [ ] Two-account sanity.

### Milestone 7 — GitHub Prep
- [x] Create GitHub repo structure.
- [x] Add remote `loader.lua` template.
- [x] Add dependency-injection loader.
- [x] Add cache fallback plan.

### Milestone 8 — Production Rollout
- [ ] Use stable branch/tag.
- [ ] Keep old `gag2.lua` fallback.
- [ ] Monitor APS debug logs.
- [ ] Replace autoexecute with remote loader only after tests pass.
