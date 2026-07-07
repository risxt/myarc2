# Current APS Flow

## Source

Current production source: `../../gag2.lua`.

This document records the APS behavior that must be preserved before any extraction/refactor.

## Main Cycle

1. Worker waits until `Cfg.autoPlantScan == true` and no APS cycle is busy.
2. Worker marks APS busy.
3. Wait for local player plot.
4. Resolve saved sprinkler position.
5. If saved position is missing/invalid:
   - update status,
   - trace missing position,
   - keep resume state unchanged,
   - retry later.
6. Force APS movement safety settings:
   - `Cfg.disableTp = true`,
   - `Cfg.disablePlantTp = true`,
   - `Cfg.autoTpToSprinkler = false`,
   - `Cfg.sprinklerPlaceMode = "Saved Position"`.
7. Fire reverse packet.
8. Place sprinkler at saved position.
9. If sprinkler placement fails:
   - keep APS/resume true,
   - save config,
   - retry later.
10. Snapshot old/current crop/fruit IDs via `collectCurrentPlantIds`.
11. Plant seed batch at generated positions.
12. If planted count is zero:
   - stop APS,
   - clear resume,
   - save config,
   - return.
13. Scan target crop for threshold.
14. If no candidate/KG is seen, run extra grace scan before rejoin.
15. If found/pass threshold:
   - trace success,
   - cancel reverse,
   - stop APS,
   - clear resume,
   - save config,
   - send success webhook,
   - return.
16. If user manually turned APS OFF before rejoin:
   - clear resume,
   - save config,
   - stop.
17. If fail/below threshold:
   - trace fail/rejoin,
   - keep APS/resume true,
   - fire reverse before save,
   - save config,
   - wait rejoin delay,
   - if user turned APS OFF during wait, abort teleport,
   - fire reverse before teleport,
   - teleport/rejoin.
18. If teleport fails:
   - wait,
   - fire reverse again,
   - retry teleport.
19. Worker clears busy flag.

## Important Branches

- No saved position: wait, do not disable resume.
- Sprinkler placement failed: keep resume and retry.
- No seeds/valid spots: stop and clear resume.
- Below threshold: safe rejoin.
- No candidate: grace scan before rejoin.
- Manual OFF during scan: stop and clear resume.
- Manual OFF during wait: abort teleport.
- Success: cancel reverse, stop, clear resume.

## Current Timing

- Initial scan window minimum: 8 seconds.
- No-candidate grace scan: 12 seconds.
- Rejoin delay: minimum/default 7 seconds.
- Reverse packet repeat: 3 fires with short waits.
- Cancel reverse packet: multiple empty/space/nil fires.

## Refactor Warning

Do not move or rewrite APS until every branch above is represented in `APS_PARITY_MATRIX.md` and test checklist.
