-- ToolAutomationController.lua
-- Boundary for sprinkler/watering/trowel/shovel/favorite tool automation.
local ToolAutomationController = {}
function ToolAutomationController.init(deps)
    deps = deps or {}
    ToolAutomationController.Logger = deps.Logger
    ToolAutomationController.Cfg = deps.Cfg
    ToolAutomationController.FeatureRegistry = deps.FeatureRegistry
    if ToolAutomationController.FeatureRegistry then ToolAutomationController.FeatureRegistry.set("Tools", "partial") end
    return ToolAutomationController
end
function ToolAutomationController.start(featureName) return false, "not_migrated_monolith_fallback_required", featureName end
function ToolAutomationController.stop(featureName) return true, featureName end
return ToolAutomationController
