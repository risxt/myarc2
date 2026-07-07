-- StealController.lua
-- Modular Auto Steal controller ported from gag2.lua Auto Steal section.

local StealController = {}
local running = false
local flingRunning = false
local hitRunning = false
local hitCooldowns = {}

local function msEmpty(t) return type(t) ~= "table" or next(t) == nil end
local function msMatch(selected, value)
    if msEmpty(selected) then return true end
    return selected[value] == true or table.find(selected, value) ~= nil
end
local function msMutMatch(selected, value)
    if msEmpty(selected) then return true end
    value = value or ""
    return selected[value] == true or table.find(selected, value) ~= nil or (value == "" and selected.None == true)
end
local function getHRP()
    local lp = StealController.LocalPlayer
    local char = lp and lp.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end
function StealController.init(deps)
    deps = deps or {}
    StealController.Logger = deps.Logger
    StealController.Cfg = deps.Cfg or {}
    StealController.Networking = deps.Networking
    StealController.LocalPlayer = deps.LocalPlayer
    StealController.Players = deps.Players or (game and game:GetService("Players"))
    StealController.CollectionService = deps.CollectionService or (game and game:GetService("CollectionService"))
    StealController.ReplicatedStorage = deps.ReplicatedStorage or (game and game:GetService("ReplicatedStorage"))
    StealController.SEED_RARITY = deps.SEED_RARITY or {}
    StealController.RARITY_RANK = deps.RARITY_RANK or { Common=1, Uncommon=2, Rare=3, Epic=4, Legendary=5, Mythic=6, Divine=7, Prismatic=8 }
    StealController.FeatureRegistry = deps.FeatureRegistry
    if StealController.FeatureRegistry then StealController.FeatureRegistry.set("Steal", "modular") end
    return StealController
end
function StealController.isNight()
    local n = StealController.ReplicatedStorage and StealController.ReplicatedStorage:FindFirstChild("Night")
    return n and n.Value == true
end
function StealController.passStealFilter(model)
    local cfg = StealController.Cfg or {}
    if cfg.selStealFilter == "Select Options" then return true end
    local seedName = model:GetAttribute("SeedName") or ""
    if cfg.selStealFilter == "Fruit" then return msMatch(cfg.selStealFruit, seedName) end
    if cfg.selStealFilter == "Rarity" then return msMatch(cfg.selStealRarity, (StealController.SEED_RARITY or {})[seedName] or "Common") end
    if cfg.selStealFilter == "Mutation" then return msMutMatch(cfg.selStealMut, model:GetAttribute("Mutation") or "") end
    return true
end
function StealController.isBestSteal(model)
    local seedName = model:GetAttribute("SeedName") or ""
    local mut = model:GetAttribute("Mutation") or ""
    return mut ~= "" or ((StealController.RARITY_RANK or {})[(StealController.SEED_RARITY or {})[seedName] or "Common"] or 0) >= 5
end
function StealController.doSteal(prompt)
    local net = StealController.Networking
    if not (net and net.Steal and net.Steal.BeginSteal and net.Steal.CompleteSteal) then return false, "missing_steal_remotes" end
    local parent = prompt.Parent
    local model = parent and parent:FindFirstAncestorWhichIsA("Model")
    if not model then return false, "missing_model" end
    local ownerId = tonumber(model:GetAttribute("UserId"))
    local plantId = model:GetAttribute("PlantId")
    local fruitId = model:GetAttribute("FruitId") or ""
    if not ownerId or not plantId then return false, "missing_ids" end
    if not (StealController.Cfg or {}).disableTp then
        local hrp, base = getHRP(), model:FindFirstChildWhichIsA("BasePart", true)
        if hrp and base then hrp.CFrame = CFrame.new(base.Position + Vector3.new(0, 3, 0)); task.wait(0.1) end
    end
    net.Steal.BeginSteal:Fire(ownerId, plantId, fruitId)
    task.wait(0.05)
    net.Steal.CompleteSteal:Fire()
    return true
end
function StealController.tick()
    local cfg, cs = StealController.Cfg or {}, StealController.CollectionService
    if not ((cfg.autoSteal or cfg.autoStealBest) and StealController.isNight()) then return true end
    for _, prompt in pairs(cs:GetTagged("StealPrompt")) do
        if not (cfg.autoSteal or cfg.autoStealBest) then break end
        if prompt:IsA("ProximityPrompt") and prompt:IsDescendantOf(workspace) and prompt.Enabled then
            local model = prompt.Parent and prompt.Parent:FindFirstAncestorWhichIsA("Model")
            if model and ((cfg.autoSteal and StealController.passStealFilter(model)) or (cfg.autoStealBest and StealController.isBestSteal(model))) then
                StealController.doSteal(prompt); task.wait(0.1)
            end
        end
    end
    return true
end
function StealController.startFlingLoop()
    if flingRunning then return true end
    flingRunning = true
    task.spawn(function()
        while flingRunning do
            if (StealController.Cfg or {}).flingPlayers then
                for _, plr in pairs(StealController.Players:GetPlayers()) do
                    if plr ~= StealController.LocalPlayer then
                        local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then hrp.AssemblyLinearVelocity = Vector3.new(0, 500, 0) end
                    end
                end
            end
            task.wait(0.2)
        end
    end)
    return true
end
function StealController.startHitLoop()
    if hitRunning then return true end
    hitRunning = true
    task.spawn(function()
        while hitRunning do
            local cfg, net = StealController.Cfg or {}, StealController.Networking
            if cfg.autoHitStolen and net and net.Shovel and net.Shovel.HitPlayer then
                for _, plr in pairs(StealController.Players:GetPlayers()) do
                    if plr ~= StealController.LocalPlayer and (plr:GetAttribute("IsStealingFruit") or plr:GetAttribute("CarryingStolenFruit")) then
                        local now = os.clock()
                        if not hitCooldowns[plr] or now - hitCooldowns[plr] >= 1 then hitCooldowns[plr] = now; net.Shovel.HitPlayer:Fire(plr.UserId) end
                    end
                end
            end
            task.wait(0.3)
        end
    end)
    return true
end
function StealController.start()
    if running then return true end
    running = true; StealController.startFlingLoop(); StealController.startHitLoop()
    task.spawn(function()
        while running do task.wait(math.max(tonumber((StealController.Cfg or {}).stealDelay) or 0.5, 0.5)); StealController.tick() end
    end)
    return true
end
function StealController.stop() running = false; flingRunning = false; hitRunning = false; return true end
return StealController
