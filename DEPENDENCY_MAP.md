# Dependency Map

## Critical Services / Remotes

| Dependency | Used By | Failure Mode | Current Handling | Refactor Target |
|---|---|---|---|---|
| `ReplicatedStorage.SharedModules.Packet.RemoteEvent` | APS reverse/cancel reverse | Missing remote / FireServer fail | `pcall` + trace | `ApsSafetyService.fireReverseWithRetry()` |
| `TeleportService` | APS rejoin and other teleports | Teleport pcall fail | `pcall`, retry APS once | `ApsSafetyService.safeRejoin()` for APS only |
| `HttpService` | Webhooks, config JSON | JSON encode fail / request unavailable | `pcall`, skip | `WebhookService`, `ConfigService` |
| Executor request function | Discord webhook | unavailable / bad URL | skip + trace | `WebhookService.sendApsSuccess()` |
| `writefile/readfile/isfile` | Config/debug logs | unavailable / write fail / corruption | partial pcall | `ConfigService` with fallback/backup |
| `workspace.Gardens` | Plot/plant scanning | plot missing/loading | wait/retry | `GardenService` |
| `PlayerScripts.Controllers.GardenSyncController` | plant KG sync | require fail / API missing | cache false | `GardenService.getSyncedPlantKg()` |
| `PlayerScripts.Controllers.FruitVisualizerController` | fruit KG calc | require fail / API missing | cache false | `GardenService.getGameFruitKg()` |
| Planting remote/helper | APS plant batch | tool/remote fail | stop/retry path | `GardenService` or `PlantingService` |
| Sprinkler/place helper | APS place sprinkler | placement fail | retry keep resume | `GardenService` or `SprinklerService` |
| `Cfg.autoPlantScan` | APS lifecycle | stale true after manual off | manual guards | `ApsState` + `ConfigService` |
| `Cfg.apsResume` | Autoexecute resume | stale resume loop | manual OFF clears | `ApsController` resume semantics |

## Teleport Policy

APS teleport must only happen through `ApsSafetyService.safeRejoin()`.
Non-APS teleport must be reviewed separately and must not inherit APS reverse rules unless intentionally needed.
