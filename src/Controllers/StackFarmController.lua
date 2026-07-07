-- StackFarmController.lua
local StackFarmController = {}
function StackFarmController.init(deps)
    deps = deps or {}
    StackFarmController.Logger = deps.Logger
    StackFarmController.Cfg = deps.Cfg
    StackFarmController.FeatureRegistry = deps.FeatureRegistry
    if StackFarmController.FeatureRegistry then StackFarmController.FeatureRegistry.set("StackFarm", "partial") end
    return StackFarmController
end
function StackFarmController.start() return false, "not_migrated_monolith_fallback_required" end
function StackFarmController.stop() return true end
return StackFarmController
