# Migration Progress

## Current Honest Percentage

70%

## Completed

- GitHub repo created and pushed.
- Full monolith live release exists.
- Modular runtime entrypoint exists.
- Hybrid entrypoint loads modular modules first.
- `_G.GAG2` exposes loaded modules.
- APS SafetyService drafted.
- WebhookService drafted.
- GardenService drafted.
- ApsController drafted.
- Static verification passes.
- Static parity passes.

## Not Completed

- Full UI migration.
- Full config loader/saver migration.
- APS worker not fully replaced by `ApsController` in live behavior.
- Stock webhook not modular.
- Auto collect not modular.
- Sprinkler service not fully ported.
- Planting service not fully ported.
- Non-APS feature parity not runtime-tested.
- Monolith fallback still required.

## Definition of 100%

`releases/main.lua` runs the whole hub using modules only, with no need to load `releases/gag2.live.lua`.





