-- MiscController.lua
local MiscController = {}
function MiscController.init(deps)
    deps = deps or {}
    MiscController.Logger = deps.Logger
    MiscController.Cfg = deps.Cfg
    MiscController.FeatureRegistry = deps.FeatureRegistry
    if MiscController.FeatureRegistry then MiscController.FeatureRegistry.set("Misc", "partial") end
    return MiscController
end
function MiscController.start(name) return false, "not_migrated_monolith_fallback_required", name end
function MiscController.stop(name) return true, name end
return MiscController
