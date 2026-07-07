-- integration.disabled.lua
-- Disabled-by-default production integration sketch for GAG2 APS.
-- Do not paste into gag2.lua until parity review and manual tests are ready.

local USE_GAG2_APS_CONTROLLER = false

local GAG2Integration = {}

function GAG2Integration.shouldUseNewAps()
    return USE_GAG2_APS_CONTROLLER == true
end

function GAG2Integration.buildRuntime(env)
    env = env or {}
    return {
        Logger = env.Logger,
        ApsState = env.ApsState,
        ConfigService = env.ConfigService,
        GardenService = env.GardenService,
        ApsSafetyService = env.ApsSafetyService,
        WebhookService = env.WebhookService,
        ApsController = env.ApsController,

        Cfg = env.Cfg,
        Player = env.Player,
        LocalPlayer = env.LocalPlayer,
        HttpService = env.HttpService,
        TeleportService = env.TeleportService,
        ReplicatedStorage = env.ReplicatedStorage,
        request = env.request,
    }
end

function GAG2Integration.makeAdapters(env)
    env = env or {}
    return {
        ConfigService = {
            saveNow = env.saveConfigNow,
        },
        PositionService = {
            getSavedSprinklerVector = env.getSavedSprinklerVector,
        },
        SprinklerService = {
            placeOneSprinklerAt = env.placeOneSprinklerAt,
        },
        PlantingService = {
            plantSeedBatchAt = env.plantSeedBatchAt,
        },
    }
end

function GAG2Integration.guardCriticalModules(modules)
    if not modules then return false, "missing_modules" end
    if not modules.ApsSafetyService then return false, "missing_aps_safety" end
    if not modules.ApsController then return false, "missing_aps_controller" end
    if not modules.GardenService then return false, "missing_garden_service" end
    return true
end

return GAG2Integration
