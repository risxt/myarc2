# Logical Single-File Refactor Design

## Purpose

Design logical modules before moving production logic. These can first live inside one file, then later become physical modules.

## Module Boundaries

```lua
local Logger = {}
local ConfigService = {}
local ApsState = {}
local ApsSafetyService = {}
local WebhookService = {}
local GardenService = {}
local ApsController = {}
```

## Dependency Direction

```txt
UI -> ApsController
ApsController -> ApsState, GardenService, ApsSafetyService, WebhookService, ConfigService, Logger
ApsSafetyService -> Logger, TeleportService, reverse remote
WebhookService -> Logger, Http/request, Config
GardenService -> workspace.Gardens, LocalPlayer, weight controllers
ConfigService -> Cfg, file APIs
```

No service should call UI directly.

## Start/Stop Lifecycle

```lua
ApsController.start("user_toggle" | "resume")
ApsController.manualStop("user_toggle_off")
ApsController.runCycle(cycleId)
```

Manual stop must always clear resume and invalidate old cycles.

## Safety Wrapper Ownership

Only `ApsSafetyService.safeRejoin(ctx)` may call APS teleport.

## Webhook Ownership

Only `WebhookService.sendApsSuccess(data)` sends APS Discord notification.

## Migration Rule

Do not delete old APS worker until new controller passes parity matrix.
