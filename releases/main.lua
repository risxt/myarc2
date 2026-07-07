-- main.lua
-- Hybrid live entrypoint for GAG2.
-- Loads modular runtime first, then runs current full hub monolith as fallback until feature migration is complete.

local BASE = "https://raw.githubusercontent.com/risxt/myarc2/main/"

local function loadRemote(path)
    local source = game:HttpGet(BASE .. path)
    local fn, err = loadstring(source)
    if not fn then error("Compile failed: " .. path .. " | " .. tostring(err)) end
    return fn()
end

local function loadRemoteFunction(path)
    local source = game:HttpGet(BASE .. path)
    local fn, err = loadstring(source)
    if not fn then error("Compile failed: " .. path .. " | " .. tostring(err)) end
    return fn
end

local ModuleLoader = loadRemote("src/Runtime/ModuleLoader.lua")
local RuntimeContext = ModuleLoader.load("src/Runtime/RuntimeContext.lua")
local MonolithBridge = ModuleLoader.load("src/Runtime/MonolithBridge.lua")
local MigrationGuard = ModuleLoader.load("src/Runtime/MigrationGuard.lua")
local RuntimeDiagnostics = ModuleLoader.load("src/Runtime/RuntimeDiagnostics.lua")
local runtime = RuntimeContext.build()

local Logger = ModuleLoader.load("src/Core/Logger.lua")
local ApsState = ModuleLoader.load("src/Core/ApsState.lua")
local ConfigService = ModuleLoader.load("src/Core/ConfigService.lua")
local FeatureRegistry = ModuleLoader.load("src/Core/FeatureRegistry.lua")
local HttpRequestService = ModuleLoader.load("src/Services/HttpRequestService.lua")
local RemoteService = ModuleLoader.load("src/Services/RemoteService.lua")
local GardenService = ModuleLoader.load("src/Services/GardenService.lua")
local ApsSafetyService = ModuleLoader.load("src/Services/ApsSafetyService.lua")
local WebhookService = ModuleLoader.load("src/Services/WebhookService.lua")
local PositionService = ModuleLoader.load("src/Services/PositionService.lua")
local SprinklerService = ModuleLoader.load("src/Services/SprinklerService.lua")
local PlantingService = ModuleLoader.load("src/Services/PlantingService.lua")
local UIRegistry = ModuleLoader.load("src/UI/UIRegistry.lua")
local ToggleBinder = ModuleLoader.load("src/UI/ToggleBinder.lua")
local AutoCollectController = ModuleLoader.load("src/Controllers/AutoCollectController.lua")
local AutoSellController = ModuleLoader.load("src/Controllers/AutoSellController.lua")
local ShopController = ModuleLoader.load("src/Controllers/ShopController.lua")
local MailController = ModuleLoader.load("src/Controllers/MailController.lua")
local PetsController = ModuleLoader.load("src/Controllers/PetsController.lua")
local ToolAutomationController = ModuleLoader.load("src/Controllers/ToolAutomationController.lua")
local WeatherController = ModuleLoader.load("src/Controllers/WeatherController.lua")
local OverlayController = ModuleLoader.load("src/Controllers/OverlayController.lua")
local ApsController = ModuleLoader.load("src/Controllers/ApsController.lua")


FeatureRegistry.init({ Logger = Logger })
MonolithBridge.init({ Logger = Logger, ModuleLoader = ModuleLoader, fallbackPath = "releases/gag2.live.lua", enabled = true })
MigrationGuard.init({ Logger = Logger, FeatureRegistry = FeatureRegistry,
    MonolithBridge = MonolithBridge,
    MigrationGuard = MigrationGuard,
    RuntimeDiagnostics = RuntimeDiagnostics, MonolithBridge = MonolithBridge })
HttpRequestService.init({ Logger = Logger, request = runtime.request, HttpService = runtime.HttpService })
RemoteService.init({ Logger = Logger, ReplicatedStorage = runtime.ReplicatedStorage })
ConfigService.init({ Logger = Logger, HttpService = runtime.HttpService })
GardenService.init({ Logger = Logger, LocalPlayer = runtime.LocalPlayer, workspace = workspace })
ApsSafetyService.init({ Logger = Logger, ApsState = ApsState, TeleportService = runtime.TeleportService, LocalPlayer = runtime.LocalPlayer, ReplicatedStorage = runtime.ReplicatedStorage })
WebhookService.init({ Logger = Logger, Player = runtime.Player, HttpService = runtime.HttpService, request = runtime.request })
PositionService.init({ Logger = Logger })
SprinklerService.init({ Logger = Logger })
PlantingService.init({ Logger = Logger })
UIRegistry.init({ Logger = Logger })
ToggleBinder.init({ Logger = Logger, ConfigService = ConfigService })
AutoCollectController.init({ Logger = Logger, FeatureRegistry = FeatureRegistry })
AutoSellController.init({ Logger = Logger, FeatureRegistry = FeatureRegistry })
ShopController.init({ Logger = Logger, FeatureRegistry = FeatureRegistry })
MailController.init({ Logger = Logger, FeatureRegistry = FeatureRegistry })
PetsController.init({ Logger = Logger, FeatureRegistry = FeatureRegistry })
ToolAutomationController.init({ Logger = Logger, FeatureRegistry = FeatureRegistry })
WeatherController.init({ Logger = Logger, FeatureRegistry = FeatureRegistry })
OverlayController.init({ Logger = Logger, FeatureRegistry = FeatureRegistry })
ApsController.init({
    Logger = Logger,
    ConfigService = ConfigService,
    ApsState = ApsState,
    GardenService = GardenService,
    ApsSafetyService = ApsSafetyService,
    WebhookService = WebhookService,
    PositionService = PositionService,
    SprinklerService = SprinklerService,
    PlantingService = PlantingService,
})
local GAG2 = {
    Runtime = runtime,
    Logger = Logger,
    ApsState = ApsState,
    ConfigService = ConfigService,
    FeatureRegistry = FeatureRegistry,
    MonolithBridge = MonolithBridge,
    MigrationGuard = MigrationGuard,
    RuntimeDiagnostics = RuntimeDiagnostics,
    HttpRequestService = HttpRequestService,
    RemoteService = RemoteService,
    GardenService = GardenService,
    ApsSafetyService = ApsSafetyService,
    WebhookService = WebhookService,
    PositionService = PositionService,
    SprinklerService = SprinklerService,
    PlantingService = PlantingService,
    UIRegistry = UIRegistry,
    ToggleBinder = ToggleBinder,
    AutoCollectController = AutoCollectController,
    AutoSellController = AutoSellController,
    ShopController = ShopController,
    MailController = MailController,
    PetsController = PetsController,
    ToolAutomationController = ToolAutomationController,
    WeatherController = WeatherController,
    OverlayController = OverlayController,
    ApsController = ApsController,
    ModularLive = true,
    FullyMigrated = false,
    MigrationPercent = 60,
}

_G.GAG2 = GAG2
RuntimeDiagnostics.init({ Logger = Logger, GAG2 = GAG2 })

Logger.info("Main", "GAG2 modular runtime loaded")
Logger.warn("Main", "Feature migration is not complete; loading monolith fallback for full hub behavior")

local ok, err = MonolithBridge.runFallback()
if not ok then
    Logger.error("Main", "Monolith fallback failed", tostring(err))
    error(err)
end

Logger.info("Main", "Monolith fallback completed/started")
return GAG2






