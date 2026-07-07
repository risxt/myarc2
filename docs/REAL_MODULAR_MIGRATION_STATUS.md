# Real Modular Migration Status

## Truth

`releases/gag2.live.lua` is currently a GitHub-hosted monolith.
It is not the final modular architecture.

## Target

Final live entrypoint should be:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/risxt/myarc2/main/releases/main.lua"))()
```

`releases/main.lua` must load modules from `src/` and run GAG2 through services/controllers.

## Migration Rule

Do not mark a feature as migrated until the live entrypoint uses the module instead of old monolith code.

## Feature Migration Table

| Feature Area | Current Live | Module Target | Status |
|---|---|---|---|
| APS reverse safety | Patched in monolith | `ApsSafetyService` | Partially migrated, not live modular |
| APS webhook | Monolith `_G._sendApsWebhook` | `WebhookService` | Ported, not live modular |
| APS garden scan | Monolith helpers | `GardenService` | Ported draft, not live modular |
| APS lifecycle | Monolith worker | `ApsController` | Ported draft, not live modular |
| Config save/load | Monolith | `ConfigService` | Skeleton only |
| UI / Speed Library | Monolith | `UI/*` | Not migrated |
| Auto collect | Monolith | Controller/service TBD | Not migrated |
| Stock webhook | Monolith | `StockWebhookService` | Not migrated |
| Sprinkler helpers | Monolith | `SprinklerService` | Not migrated |
| Planting helpers | Monolith | `PlantingService` | Not migrated |
| Teleport utilities | Monolith | `TeleportService` wrapper | Not migrated |

## Immediate Direct Work

1. Create true modular `releases/main.lua`.
2. Create missing production adapter modules:
   - `Runtime/ModuleLoader.lua`
   - `Runtime/RuntimeContext.lua`
   - `Services/PlantingService.lua`
   - `Services/SprinklerService.lua`
   - `Services/PositionService.lua`
3. Wire APS modules under feature flag.
4. Keep monolith `gag2.live.lua` only as fallback until all features migrate.
5. Move feature-by-feature until no monolith fallback is needed.
