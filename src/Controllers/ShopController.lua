-- ShopController.lua
-- Boundary for Auto Shop migration. Live behavior still comes from monolith fallback.

local ShopController = {}

function ShopController.init(deps)
    deps = deps or {}
    ShopController.Logger = deps.Logger
    ShopController.Cfg = deps.Cfg
    ShopController.FeatureRegistry = deps.FeatureRegistry
    if ShopController.FeatureRegistry then
        ShopController.FeatureRegistry.set("AutoShop", "partial")
    end
    return ShopController
end

function ShopController.start()
    return false, "not_migrated_monolith_fallback_required"
end

function ShopController.stop()
    return true
end

return ShopController
