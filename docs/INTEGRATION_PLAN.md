# GAG2 Integration Plan

## Goal

Wire GAG2 modules into production only after parity review.

## Feature Flag

Production integration must start disabled:

```lua
local USE_GAG2_APS_CONTROLLER = false
```

## Required Runtime Dependencies

The integration shim must inject:

```lua
local runtime = {
    Logger = Logger,
    ApsState = ApsState,
    ConfigService = ConfigService,
    GardenService = GardenService,
    ApsSafetyService = ApsSafetyService,
    WebhookService = WebhookService,
    ApsController = ApsController,

    Cfg = Cfg,
    Player = Player,
    LocalPlayer = LocalPlayer,
    HttpService = HttpService,
    TeleportService = TeleportService,
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    request = getHttpRequest(),
}
```

Additional adapters needed:

```lua
PositionService.getSavedSprinklerVector(plot)
SprinklerService.placeOneSprinklerAt(pos, sprinklerName)
PlantingService.plantSeedBatchAt(pos, seedName, amount, sprinklerName)
ConfigService.saveNow()
```

## Rollout Steps

1. Keep old APS worker active.
2. Load GAG2 modules in dry-run mode.
3. Confirm modules load.
4. Compare scan output in debug mode without acting.
5. Enable new APS for one private-server run.
6. If any mismatch occurs, turn flag off.

## Abort Conditions

Immediately disable new APS if:

- reverse service fails to load,
- scan helper mismatch is detected,
- manual OFF does not clear resume,
- webhook blocks logic,
- teleport path does not pass safety wrapper.
