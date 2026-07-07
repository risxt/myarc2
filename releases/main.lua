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
local ModuleManifest = ModuleLoader.load("src/Runtime/ModuleManifest.lua")
local RuntimeContext = ModuleLoader.load("src/Runtime/RuntimeContext.lua")
local MonolithBridge = ModuleLoader.load("src/Runtime/MonolithBridge.lua")
local MigrationGuard = ModuleLoader.load("src/Runtime/MigrationGuard.lua")
local RuntimeDiagnostics = ModuleLoader.load("src/Runtime/RuntimeDiagnostics.lua")
local StartupValidator = ModuleLoader.load("src/Runtime/StartupValidator.lua")
local ReleaseMode = ModuleLoader.load("src/Runtime/ReleaseMode.lua")
local LiveReadinessGate = ModuleLoader.load("src/Runtime/LiveReadinessGate.lua")
local RuntimeSelfTest = ModuleLoader.load("src/Runtime/RuntimeSelfTest.lua")
local runtime = RuntimeContext.build()

local Logger = ModuleLoader.load("src/Core/Logger.lua")
local ApsState = ModuleLoader.load("src/Core/ApsState.lua")
local ConfigService = ModuleLoader.load("src/Core/ConfigService.lua")
local FeatureRegistry = ModuleLoader.load("src/Core/FeatureRegistry.lua")
local FeatureParityChecklist = ModuleLoader.load("src/Core/FeatureParityChecklist.lua")
local HttpRequestService = ModuleLoader.load("src/Services/HttpRequestService.lua")
local RemoteService = ModuleLoader.load("src/Services/RemoteService.lua")
local ParityReportService = ModuleLoader.load("src/Services/ParityReportService.lua")
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
local StackFarmController = ModuleLoader.load("src/Controllers/StackFarmController.lua")
local StealController = ModuleLoader.load("src/Controllers/StealController.lua")
local LocalPlayerController = ModuleLoader.load("src/Controllers/LocalPlayerController.lua")
local MiscController = ModuleLoader.load("src/Controllers/MiscController.lua")
local ApsController = ModuleLoader.load("src/Controllers/ApsController.lua")


FeatureRegistry.init({ Logger = Logger })
FeatureParityChecklist.init({ Logger = Logger })
MonolithBridge.init({ Logger = Logger, ModuleLoader = ModuleLoader, fallbackPath = "releases/gag2.live.lua", enabled = true })
MigrationGuard.init({ Logger = Logger, FeatureRegistry = FeatureRegistry,
    FeatureParityChecklist = FeatureParityChecklist,
    MonolithBridge = MonolithBridge,
    MigrationGuard = MigrationGuard,
    RuntimeDiagnostics = RuntimeDiagnostics,
    ModuleManifest = ModuleManifest,
    StartupValidator = StartupValidator,
    ParityReportService = ParityReportService,
    ReleaseMode = ReleaseMode,
    LiveReadinessGate = LiveReadinessGate,
    RuntimeSelfTest = RuntimeSelfTest, MonolithBridge = MonolithBridge })
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
AutoCollectController.init({ Logger = Logger, FeatureRegistry = FeatureRegistry, LocalPlayer = runtime.LocalPlayer, Networking = nil, Workspace = workspace })
AutoSellController.init({ Logger = Logger, FeatureRegistry = FeatureRegistry, LocalPlayer = runtime.LocalPlayer })
ShopController.init({ Logger = Logger, FeatureRegistry = FeatureRegistry, ReplicatedStorage = runtime.ReplicatedStorage })
MailController.init({ Logger = Logger, FeatureRegistry = FeatureRegistry })
PetsController.init({ Logger = Logger, FeatureRegistry = FeatureRegistry, LocalPlayer = runtime.LocalPlayer, Workspace = workspace })
ToolAutomationController.init({ Logger = Logger, FeatureRegistry = FeatureRegistry, LocalPlayer = runtime.LocalPlayer })
WeatherController.init({ Logger = Logger, FeatureRegistry = FeatureRegistry, LocalPlayer = runtime.LocalPlayer, TeleportService = runtime.TeleportService, Workspace = workspace })
OverlayController.init({ Logger = Logger, FeatureRegistry = FeatureRegistry })
StackFarmController.init({ Logger = Logger, FeatureRegistry = FeatureRegistry })
StealController.init({ Logger = Logger, FeatureRegistry = FeatureRegistry, LocalPlayer = runtime.LocalPlayer, Players = runtime.Players, ReplicatedStorage = runtime.ReplicatedStorage })
LocalPlayerController.init({ Logger = Logger, FeatureRegistry = FeatureRegistry, LocalPlayer = runtime.LocalPlayer })
MiscController.init({ Logger = Logger, FeatureRegistry = FeatureRegistry })
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
    FeatureParityChecklist = FeatureParityChecklist,
    MonolithBridge = MonolithBridge,
    MigrationGuard = MigrationGuard,
    RuntimeDiagnostics = RuntimeDiagnostics,
    ModuleManifest = ModuleManifest,
    StartupValidator = StartupValidator,
    ParityReportService = ParityReportService,
    ReleaseMode = ReleaseMode,
    LiveReadinessGate = LiveReadinessGate,
    RuntimeSelfTest = RuntimeSelfTest,
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
    StackFarmController = StackFarmController,
    StealController = StealController,
    LocalPlayerController = LocalPlayerController,
    MiscController = MiscController,
    ApsController = ApsController,
    ModularLive = true,
    FullyMigrated = false,
    MigrationPercent = 90,
}

_G.GAG2 = GAG2
StartupValidator.init({ Logger = Logger, ModuleManifest = ModuleManifest, ModuleLoader = ModuleLoader })
ReleaseMode.init({ Logger = Logger, FeatureRegistry = FeatureRegistry, MigrationGuard = MigrationGuard, mode = "hybrid" })
LiveReadinessGate.init({ StartupValidator = StartupValidator, MigrationGuard = MigrationGuard, ParityReportService = ParityReportService, ReleaseMode = ReleaseMode })
RuntimeSelfTest.init({ StartupValidator = StartupValidator, ParityReportService = ParityReportService, LiveReadinessGate = LiveReadinessGate })
ParityReportService.init({ FeatureRegistry = FeatureRegistry, FeatureParityChecklist = FeatureParityChecklist, MigrationGuard = MigrationGuard })
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














