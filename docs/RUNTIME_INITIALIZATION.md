# Runtime Initialization Contract

`releases/main.lua` must not only load modules; it must initialize them with shared runtime dependencies.

## Initialized services

- `FeatureRegistry`
- `HttpRequestService`
- `RemoteService`
- `ConfigService`
- `GardenService`
- `ApsSafetyService`
- `WebhookService`
- `PositionService`
- `SprinklerService`
- `PlantingService`
- `ApsController`

## Current limitation

Some services are initialized without full `Cfg` because full config migration is not finished yet. Monolith fallback still owns production config behavior.
