-- LocalPlayerController.lua
local LocalPlayerController = {}
function LocalPlayerController.init(deps)
    deps = deps or {}
    LocalPlayerController.Logger = deps.Logger
    LocalPlayerController.Cfg = deps.Cfg
    LocalPlayerController.LocalPlayer = deps.LocalPlayer
    LocalPlayerController.FeatureRegistry = deps.FeatureRegistry
    if LocalPlayerController.FeatureRegistry then FeatureRegistry = nil; LocalPlayerController.FeatureRegistry.set("LocalPlayer", "modular") end
    return LocalPlayerController
end
function LocalPlayerController.setWalkSpeed(value)
    local player = LocalPlayerController.LocalPlayer
    local hum = player and player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum and tonumber(value) then hum.WalkSpeed = tonumber(value); return true end
    return false, "humanoid_or_value_missing"
end
return LocalPlayerController

