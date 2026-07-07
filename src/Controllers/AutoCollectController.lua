-- AutoCollectController.lua
-- Placeholder controller boundary for reactive instant collect and weather seed collection.
-- Logic remains in monolith fallback until exact parity port.

local AutoCollectController = {}

function AutoCollectController.init(deps)
    deps = deps or {}
    AutoCollectController.Logger = deps.Logger
    AutoCollectController.Cfg = deps.Cfg
    AutoCollectController.FeatureRegistry = deps.FeatureRegistry
    if AutoCollectController.FeatureRegistry then
        AutoCollectController.FeatureRegistry.set("AutoCollect", "partial")
    end
    return AutoCollectController
end

function AutoCollectController.start()
    return false, "not_migrated_monolith_fallback_required"
end

function AutoCollectController.stop()
    return true
end

return AutoCollectController
