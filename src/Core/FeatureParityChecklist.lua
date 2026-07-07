-- FeatureParityChecklist.lua
-- Runtime-readable checklist used to prevent losing monolith feature branches.
local FeatureParityChecklist = {}
FeatureParityChecklist.Items = {
    "Config load/save and account mapping",
    "Speed UI Library controls",
    "APS success path",
    "APS fail rejoin path",
    "APS manual OFF during scan/rejoin",
    "Reactive instant collect",
    "Weather seed collect",
    "Auto sell",
    "Auto shop",
    "Auto steal",
    "Auto pets",
    "Mail send",
    "Mail claim",
    "Stack farm",
    "Sprinkler automation",
    "Watering can",
    "Trowel",
    "Shovel",
    "Favorite automation",
    "ESP",
    "Misc",
    "Auto plants",
    "Local player features",
    "Weather predict",
    "Weather disconnect",
    "Weather HUD",
    "Inventory value overlay",
}
function FeatureParityChecklist.init(deps) FeatureParityChecklist.Logger = deps and deps.Logger; return FeatureParityChecklist end
function FeatureParityChecklist.count() return #FeatureParityChecklist.Items end
return FeatureParityChecklist
