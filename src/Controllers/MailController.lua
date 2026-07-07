-- MailController.lua
local MailController = {}
function MailController.init(deps)
    deps = deps or {}
    MailController.Logger = deps.Logger
    MailController.Cfg = deps.Cfg
    MailController.FeatureRegistry = deps.FeatureRegistry
    if MailController.FeatureRegistry then MailController.FeatureRegistry.set("Mail", "partial") end
    return MailController
end
function MailController.sendStart() return false, "not_migrated_monolith_fallback_required" end
function MailController.claimStart() return false, "not_migrated_monolith_fallback_required" end
function MailController.stop() return true end
return MailController
