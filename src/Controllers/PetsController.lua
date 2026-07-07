-- PetsController.lua
local PetsController = {}
function PetsController.init(deps)
    deps = deps or {}
    PetsController.Logger = deps.Logger
    PetsController.Cfg = deps.Cfg
    PetsController.FeatureRegistry = deps.FeatureRegistry
    if PetsController.FeatureRegistry then PetsController.FeatureRegistry.set("Pets", "partial") end
    return PetsController
end
function PetsController.start() return false, "not_migrated_monolith_fallback_required" end
function PetsController.stop() return true end
return PetsController
