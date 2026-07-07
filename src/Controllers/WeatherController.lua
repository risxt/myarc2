-- WeatherController.lua
-- Boundary for weather prediction, disconnect, HUD, and weather seed features.
local WeatherController = {}
function WeatherController.init(deps)
    deps = deps or {}
    WeatherController.Logger = deps.Logger
    WeatherController.Cfg = deps.Cfg
    WeatherController.FeatureRegistry = deps.FeatureRegistry
    if WeatherController.FeatureRegistry then WeatherController.FeatureRegistry.set("Weather", "partial") end
    return WeatherController
end
function WeatherController.startPredict() return false, "not_migrated_monolith_fallback_required" end
function WeatherController.startDisconnect() return false, "not_migrated_monolith_fallback_required" end
function WeatherController.startHud() return false, "not_migrated_monolith_fallback_required" end
function WeatherController.stop() return true end
return WeatherController
