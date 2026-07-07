-- main.lua
-- Real modular entrypoint for GAG2.
-- Current status: loads modular runtime and exposes modules, but does not yet replace all monolith features.

local BASE = "https://raw.githubusercontent.com/risxt/myarc2/main/"

local function loadRemote(path)
    local source = game:HttpGet(BASE .. path)
    local fn, err = loadstring(source)
    if not fn then error("Compile failed: " .. path .. " | " .. tostring(err)) end
    return fn()
end

local ModuleLoader = loadRemote("src/Runtime/ModuleLoader.lua")
local RuntimeContext = ModuleLoader.load("src/Runtime/RuntimeContext.lua")

local runtime = RuntimeContext.build()

local Logger = ModuleLoader.load("src/Core/Logger.lua")
local ApsState = ModuleLoader.load("src/Core/ApsState.lua")
local ConfigService = ModuleLoader.load("src/Core/ConfigService.lua")
local GardenService = ModuleLoader.load("src/Services/GardenService.lua")
local ApsSafetyService = ModuleLoader.load("src/Services/ApsSafetyService.lua")
local WebhookService = ModuleLoader.load("src/Services/WebhookService.lua")
local ApsController = ModuleLoader.load("src/Controllers/ApsController.lua")

local GAG2 = {
    Runtime = runtime,
    Logger = Logger,
    ApsState = ApsState,
    ConfigService = ConfigService,
    GardenService = GardenService,
    ApsSafetyService = ApsSafetyService,
    WebhookService = WebhookService,
    ApsController = ApsController,
    ModularLive = true,
    FullyMigrated = false,
}

_G.GAG2 = GAG2

Logger.info("Main", "GAG2 modular runtime loaded")
Logger.warn("Main", "Full feature migration is not complete yet; monolith fallback still required for full hub behavior")

return GAG2
