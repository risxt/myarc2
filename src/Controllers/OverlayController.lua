-- OverlayController.lua
-- Boundary for ESP, weather HUD, and inventory value overlays.
local OverlayController = {}
function OverlayController.init(deps)
    deps = deps or {}
    OverlayController.Logger = deps.Logger
    OverlayController.Cfg = deps.Cfg
    OverlayController.FeatureRegistry = deps.FeatureRegistry
    if OverlayController.FeatureRegistry then
        OverlayController.FeatureRegistry.set("ESP", "partial")
        OverlayController.FeatureRegistry.set("Overlays", "partial")
    end
    return OverlayController
end
function OverlayController.start(name) return false, "not_migrated_monolith_fallback_required", name end
function OverlayController.stop(name) return true, name end
return OverlayController
