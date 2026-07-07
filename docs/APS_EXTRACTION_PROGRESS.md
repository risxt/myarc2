# APS Extraction Progress Notes

## Completed in GAG2 modules

### ApsSafetyService

Implemented:

- `fireReverseOnce()`
- `fireReverseWithRetry(maxRetries)`
- `fireCancelReverse()`
- `safeRejoin(ctx)`

Safety behavior:

- abort teleport if reverse fails,
- check manual stop before reverse,
- check manual stop after wait,
- retry teleport only after another reverse,
- log SAFETY events.

### WebhookService

Implemented:

- `buildApsSuccessPayload(data)`
- `sendApsSuccess(data)`

Webhook behavior:

- success-only,
- `@everyone`,
- green embed,
- no emoji,
- non-blocking `task.spawn`,
- failure does not affect APS logic.

### GardenService

Implemented:

- `thresholdPass(mode, threshold, kg)`
- `getMyPlot()`
- `waitForMyPlot(timeout)`
- `isFruitReady(fruit)`
- `getSyncedPlantKg(plant)`
- `getGameFruitKg(fruit)`
- `getFruitDisplayKg(fruit, seedName)`
- `collectCurrentPlantIds(cropName)`
- `scanCropForThreshold(...)`

### ApsController

Implemented controller target methods:

- `start(reason)`
- `manualStop(reason)`
- `prepareEnvironment(cycleId)`
- `placeSprinkler(cycleId, pos)`
- `plantBatch(cycleId, pos)`
- `scanForTarget(cycleId, ignoredPlantIds, batchStartedAt)`
- `handleSuccess(result)`
- `handleFailRejoin(reason)`
- `runCycle(cycleId)`

## Not yet production-wired

None of these modules are wired into `../gag2.lua` yet.

Current production behavior is unchanged.

## Remaining before live wiring

1. Compare `GardenService.scanCropForThreshold` against current `gag2.lua` line-by-line.
2. Provide missing production deps:
   - `PositionService.getSavedSprinklerVector`,
   - `SprinklerService.placeOneSprinklerAt`,
   - `PlantingService.plantSeedBatchAt`,
   - `ConfigService.saveNow`.
3. Add feature flag:

```lua
local USE_GAG2_APS_CONTROLLER = false
```

4. Build integration shim.
5. Run manual checklist.
