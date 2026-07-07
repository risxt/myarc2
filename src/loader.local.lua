-- loader.local.lua
-- Local prototype loader for GAG2 modules.
-- This file is for structure/load-order design only; it is not production autoexecute yet.

local GAG2 = {
    Version = "0.1.0-local",
    Modules = {},
}

-- In Roblox/GitHub production this will become HttpGet/loadstring.
-- In local design, modules are loaded by planned order and dependency injection.

local function safeInit(name, module, deps)
    if type(module) == "table" and type(module.init) == "function" then
        local ok, result = pcall(function()
            return module.init(deps or {})
        end)
        if ok then
            return result or module
        end
        warn("[GAG2 Loader] init failed for", name, result)
        return nil
    end
    return module
end

function GAG2.bootstrap(runtime)
    runtime = runtime or {}

    -- These require paths are placeholders for local/module testing.
    -- In executor production, loader.lua will fetch raw GitHub module text instead.
    local Logger = runtime.Logger
    local ApsState = runtime.ApsState
    local ConfigService = runtime.ConfigService
    local GardenService = runtime.GardenService
    local ApsSafetyService = runtime.ApsSafetyService
    local WebhookService = runtime.WebhookService
    local ApsController = runtime.ApsController

    GAG2.Modules.Logger = Logger
    GAG2.Modules.ApsState = ApsState
    GAG2.Modules.ConfigService = ConfigService
    GAG2.Modules.GardenService = GardenService

    GAG2.Modules.ApsSafetyService = safeInit("ApsSafetyService", ApsSafetyService, {
        Logger = Logger,
        ApsState = ApsState,
        Cfg = runtime.Cfg,
        TeleportService = runtime.TeleportService,
        LocalPlayer = runtime.LocalPlayer,
    })

    GAG2.Modules.WebhookService = safeInit("WebhookService", WebhookService, {
        Logger = Logger,
        Cfg = runtime.Cfg,
        Player = runtime.Player,
        HttpService = runtime.HttpService,
        request = runtime.request,
    })

    GAG2.Modules.ApsController = safeInit("ApsController", ApsController, {
        Logger = Logger,
        Cfg = runtime.Cfg,
        ConfigService = ConfigService,
        ApsState = ApsState,
        GardenService = GardenService,
        ApsSafetyService = GAG2.Modules.ApsSafetyService,
        WebhookService = GAG2.Modules.WebhookService,
    })

    return GAG2
end

return GAG2
