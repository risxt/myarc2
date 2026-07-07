-- StealController.lua
local StealController = {}
function StealController.init(deps)
    deps = deps or {}
    StealController.Logger = deps.Logger
    StealController.Cfg = deps.Cfg
    StealController.FeatureRegistry = deps.FeatureRegistry
    if StealController.FeatureRegistry then StealController.FeatureRegistry.set("Steal", "partial") end
    return StealController
end
function StealController.start() return false, "not_migrated_monolith_fallback_required" end
function StealController.stop() return true end
return StealController
