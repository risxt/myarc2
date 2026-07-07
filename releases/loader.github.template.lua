-- loader.github.lua
-- Remote GitHub loader template for GAG2. Not production active yet.

local GAG2Loader = {}

GAG2Loader.Config = {
    BaseUrl = "https://raw.githubusercontent.com/risxt/myarc2/main/",
    UseCache = true,
    CachePrefix = "GAG2_cache_",
}

local function cacheName(path)
    return GAG2Loader.Config.CachePrefix .. path:gsub("[^%w_%-%.]", "_")
end

local function httpGet(url)
    if game and game.HttpGet then
        return game:HttpGet(url)
    end
    error("HttpGet unavailable")
end

function GAG2Loader.fetch(path)
    local url = GAG2Loader.Config.BaseUrl .. path
    local ok, body = pcall(httpGet, url)
    if ok and type(body) == "string" and #body > 0 then
        if GAG2Loader.Config.UseCache and type(writefile) == "function" then
            pcall(writefile, cacheName(path), body)
        end
        return body
    end

    if GAG2Loader.Config.UseCache and type(readfile) == "function" and type(isfile) == "function" then
        local c = cacheName(path)
        if isfile(c) then
            local readOk, cached = pcall(readfile, c)
            if readOk and type(cached) == "string" and #cached > 0 then
                return cached
            end
        end
    end

    error("Failed to load module: " .. tostring(path))
end

function GAG2Loader.loadModule(path)
    local source = GAG2Loader.fetch(path)
    local fn, compileErr = loadstring(source)
    if not fn then error("Compile failed for " .. tostring(path) .. ": " .. tostring(compileErr)) end
    return fn()
end

function GAG2Loader.bootstrap(runtime)
    runtime = runtime or {}

    local Logger = GAG2Loader.loadModule("src/Core/Logger.lua")
    local ApsState = GAG2Loader.loadModule("src/Core/ApsState.lua")
    local ConfigService = GAG2Loader.loadModule("src/Core/ConfigService.lua")
    local GardenService = GAG2Loader.loadModule("src/Services/GardenService.lua")
    local ApsSafetyService = GAG2Loader.loadModule("src/Services/ApsSafetyService.lua")
    local WebhookService = GAG2Loader.loadModule("src/Services/WebhookService.lua")
    local ApsController = GAG2Loader.loadModule("src/Controllers/ApsController.lua")

    ConfigService.init({ Logger = Logger, Cfg = runtime.Cfg, saveNow = runtime.saveNow })
    GardenService.init({ Logger = Logger, Cfg = runtime.Cfg, LocalPlayer = runtime.LocalPlayer, workspace = workspace, DISPLAY_KG_BASE = runtime.DISPLAY_KG_BASE })
    ApsSafetyService.init({ Logger = Logger, ApsState = ApsState, Cfg = runtime.Cfg, TeleportService = runtime.TeleportService, LocalPlayer = runtime.LocalPlayer, ReplicatedStorage = runtime.ReplicatedStorage, saveResume = runtime.saveResume })
    WebhookService.init({ Logger = Logger, Cfg = runtime.Cfg, Player = runtime.Player, HttpService = runtime.HttpService, request = runtime.request })
    ApsController.init({ Logger = Logger, Cfg = runtime.Cfg, ConfigService = ConfigService, ApsState = ApsState, GardenService = GardenService, ApsSafetyService = ApsSafetyService, WebhookService = WebhookService, PositionService = runtime.PositionService, SprinklerService = runtime.SprinklerService, PlantingService = runtime.PlantingService, setStatus = runtime.setStatus })

    return {
        Logger = Logger,
        ApsState = ApsState,
        ConfigService = ConfigService,
        GardenService = GardenService,
        ApsSafetyService = ApsSafetyService,
        WebhookService = WebhookService,
        ApsController = ApsController,
    }
end

return GAG2Loader
