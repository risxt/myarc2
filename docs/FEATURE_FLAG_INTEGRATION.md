# Feature Flag Integration Sketch

## Status

Disabled by default.

```lua
local USE_GAG2_APS_CONTROLLER = false
```

## Purpose

This sketch documents how `gag2.lua` will eventually choose between:

- old APS worker,
- new GAG2 APS controller.

## Rule

Until verification passes, production must keep:

```lua
USE_GAG2_APS_CONTROLLER = false
```

## Required Guards

New APS must not start if any critical module is missing:

- `ApsSafetyService`,
- `ApsController`,
- `GardenService`.

If `ApsSafetyService` is missing, APS must be disabled, not partially started.

## Adapter Requirements

The old `gag2.lua` helpers must be injected as adapters before the new controller can run:

```lua
saveConfigNow
getSavedSprinklerVector
placeOneSprinklerAt
plantSeedBatchAt
```

## Rollback

Set flag back to false and old APS worker remains the source of truth.
