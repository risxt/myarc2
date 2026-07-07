-- LocalPlayerController.lua (REWRITE)
-- Modular controller: Walkspeed, Noclip, Inf Jump, Player Freeze.
local LocalPlayerController = {}
local running = false
local connections = {}
local function char() local lp=LocalPlayerController.LocalPlayer; return lp and lp.Character end
function LocalPlayerController.init(deps)
    deps = deps or {}
    LocalPlayerController.Logger = deps.Logger
    LocalPlayerController.Cfg = deps.Cfg or {}
    LocalPlayerController.LocalPlayer = deps.LocalPlayer
    LocalPlayerController.FeatureRegistry = deps.FeatureRegistry
    LocalPlayerController.UserInputService = deps.UserInputService or (game and game:GetService("UserInputService"))
    if LocalPlayerController.FeatureRegistry then LocalPlayerController.FeatureRegistry.set("LocalPlayer", "modular") end
    return LocalPlayerController
end
function LocalPlayerController.applyWalkspeed()
    local cfg=LocalPlayerController.Cfg; local hum=char() and char():FindFirstChildOfClass("Humanoid")
    if hum and cfg.playerSpeedEnabled and tonumber(cfg.playerSpeed) then hum.WalkSpeed = tonumber(cfg.playerSpeed) end
end
function LocalPlayerController.start()
    if running then return true end; running = true
    table.insert(connections, LocalPlayerController.LocalPlayer.CharacterAdded:Connect(function() task.wait(0.5); LocalPlayerController.applyWalkspeed() end))
    if LocalPlayerController.UserInputService then
        table.insert(connections, LocalPlayerController.UserInputService.JumpRequest:Connect(function() local cfg=LocalPlayerController.Cfg; if cfg.infJump then local hum=char() and char():FindFirstChildOfClass("Humanoid"); if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end end end))
    end
    task.spawn(function()
        local lastFreeze = false
        while running do
            task.wait(0.1)
            local cfg=LocalPlayerController.Cfg; local c=char()
            if c then
                if cfg.noclip then for _,p in next,c:GetDescendants() do if p:IsA("BasePart") then p.CanCollide=false end end end
                local hrp=c:FindFirstChild("HumanoidRootPart")
                if hrp then if cfg.playerFreeze then hrp.Anchored=true; lastFreeze=true elseif lastFreeze then hrp.Anchored=false; lastFreeze=false end end
            end
        end
    end)
    return true
end
function LocalPlayerController.stop() running = false; for _,c in ipairs(connections) do pcall(function() c:Disconnect() end) end; connections={}; return true end
function LocalPlayerController.setWalkSpeed(value) local hum=char() and char():FindFirstChildOfClass("Humanoid"); if hum and tonumber(value) then hum.WalkSpeed=tonumber(value); return true end; return false end
return LocalPlayerController
