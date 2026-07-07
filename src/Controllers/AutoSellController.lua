-- AutoSellController.lua
-- Boundary for Auto Sell migration. Live behavior still comes from monolith fallback.

local AutoSellController = {}

function AutoSellController.init(deps)
    deps = deps or {}
    AutoSellController.Logger = deps.Logger
    AutoSellController.Cfg = deps.Cfg
    AutoSellController.FeatureRegistry = deps.FeatureRegistry
    if AutoSellController.FeatureRegistry then
        AutoSellController.FeatureRegistry.set("AutoSell", "partial")
    end
    return AutoSellController
end

function AutoSellController.start()
    return false, "not_migrated_monolith_fallback_required"
end

function AutoSellController.stop()
    return true
end

return AutoSellController
