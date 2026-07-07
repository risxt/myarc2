-- ModuleManifest.lua
-- Single source of truth for modules loaded by the modular runtime.

local ModuleManifest = {}

ModuleManifest.Core = {
    "src/Core/Logger.lua",
    "src/Core/ApsState.lua",
    "src/Core/ConfigService.lua",
    "src/Core/FeatureRegistry.lua",
    "src/Core/FeatureParityChecklist.lua",
}

ModuleManifest.Runtime = {
    "src/Runtime/RuntimeContext.lua",
    "src/Runtime/MonolithBridge.lua",
    "src/Runtime/MigrationGuard.lua",
    "src/Runtime/RuntimeDiagnostics.lua",
}

ModuleManifest.Services = {
    "src/Services/HttpRequestService.lua",
    "src/Services/RemoteService.lua",
    "src/Services/GardenService.lua",
    "src/Services/ApsSafetyService.lua",
    "src/Services/WebhookService.lua",
    "src/Services/PositionService.lua",
    "src/Services/SprinklerService.lua",
    "src/Services/PlantingService.lua",
}

ModuleManifest.UI = {
    "src/UI/UIRegistry.lua",
    "src/UI/ToggleBinder.lua",
}

ModuleManifest.Controllers = {
    "src/Controllers/ApsController.lua",
    "src/Controllers/AutoCollectController.lua",
    "src/Controllers/AutoSellController.lua",
    "src/Controllers/ShopController.lua",
    "src/Controllers/MailController.lua",
    "src/Controllers/PetsController.lua",
    "src/Controllers/ToolAutomationController.lua",
    "src/Controllers/WeatherController.lua",
    "src/Controllers/OverlayController.lua",
    "src/Controllers/StackFarmController.lua",
    "src/Controllers/StealController.lua",
    "src/Controllers/LocalPlayerController.lua",
    "src/Controllers/MiscController.lua",
}

function ModuleManifest.all()
    local out = {}
    for _, group in ipairs({ ModuleManifest.Core, ModuleManifest.Runtime, ModuleManifest.Services, ModuleManifest.UI, ModuleManifest.Controllers }) do
        for _, path in ipairs(group) do table.insert(out, path) end
    end
    return out
end

return ModuleManifest
