# Local Loader Prototype

## Purpose

`src/loader.local.lua` defines the dependency injection order for local development before GitHub remote loading.

## Load Order

1. `Logger`
2. `ApsState`
3. `ConfigService`
4. `GardenService`
5. `ApsSafetyService`
6. `WebhookService`
7. `ApsController`

## Rule

Modules should not hardcode GitHub URLs.

The loader owns module loading and injects dependencies.

## Production Translation Later

Local skeleton:

```lua
local ApsController = runtime.ApsController
```

GitHub loader later:

```lua
local ApsController = loadModule("src/Controllers/ApsController.lua")
```

Then inject dependencies using the same shape.

## Critical Safety

If `ApsSafetyService` fails to load, APS must not start.
