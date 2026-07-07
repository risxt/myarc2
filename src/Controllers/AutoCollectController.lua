-- AutoCollectController.lua
-- Modular weather seed auto-collect controller ported from gag2.lua.

local AutoCollectController = {}
local running = false
local lockActive = false
local queue, queued, attempts = {}, {}, {}
local MAX_ATTEMPTS = 4
local connections = {}

local function getHRP()
    local lp = AutoCollectController.LocalPlayer
    local c = lp and lp.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function wantSeed(part)
    local cfg = AutoCollectController.Cfg or {}
    if not part or not part.Parent then return false end
    local isGold = part:GetAttribute("GoldSeed") == true
    local isRainbow = part:GetAttribute("RainbowSeed") == true
    return (isGold and cfg.autoGoldSeed) or (isRainbow and cfg.autoRainbowSeed)
end
function AutoCollectController.init(deps)
    deps=deps or {}; AutoCollectController.Logger=deps.Logger; AutoCollectController.Cfg=deps.Cfg or {}; AutoCollectController.LocalPlayer=deps.LocalPlayer; AutoCollectController.Networking=deps.Networking; AutoCollectController.RunService=deps.RunService or (game and game:GetService("RunService")); AutoCollectController.Workspace=deps.Workspace or workspace; AutoCollectController.FeatureRegistry=deps.FeatureRegistry
    if AutoCollectController.FeatureRegistry then AutoCollectController.FeatureRegistry.set("AutoCollect","modular") end
    return AutoCollectController
end
function AutoCollectController.resolveSeedFolder()
    local map = AutoCollectController.Workspace:FindFirstChild("Map") or AutoCollectController.Workspace:WaitForChild("Map", 30)
    local folder = map and (map:FindFirstChild("SeedPackSpawnServerLocations") or map:WaitForChild("SeedPackSpawnServerLocations", 30))
    return folder
end
function AutoCollectController.collectOne(part)
    local cfg = AutoCollectController.Cfg or {}
    if not part or not part.Parent then return true end
    if not wantSeed(part) then return true end
    local prompt = part:FindFirstChildWhichIsA("ProximityPrompt", true)
    if not prompt then
        local elapsed = 0
        repeat task.wait(0.05); elapsed += 0.05; prompt = part:FindFirstChildWhichIsA("ProximityPrompt", true) until prompt or not part.Parent or elapsed >= 3
    end
    if not part.Parent then return true end
    if not prompt then return false end
    local lockConn
    if not cfg.disableTp then
        local hrp = getHRP()
        if hrp then
            local targetCF = CFrame.new(part.Position + Vector3.new(0, 3, 0))
            hrp.CFrame = targetCF; hrp.AssemblyLinearVelocity = Vector3.zero; lockActive = true
            lockConn = AutoCollectController.RunService.Heartbeat:Connect(function() local h=getHRP(); if h then h.CFrame=targetCF; h.AssemblyLinearVelocity=Vector3.zero end end)
        end
    else
        local char = AutoCollectController.LocalPlayer and AutoCollectController.LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then local deadline=os.clock()+8; while part.Parent and os.clock()<deadline do local h=getHRP(); if not h then break end; if (h.Position-part.Position).Magnitude<=10 then break end; hum:MoveTo(part.Position); task.wait(0.2) end end
    end
    for _=1,20 do
        if not part.Parent then break end
        local p = part:FindFirstChildWhichIsA("ProximityPrompt", true)
        if p and type(fireproximityprompt)=="function" then fireproximityprompt(p) else local h=getHRP(); if h and type(firetouchinterest)=="function" then firetouchinterest(h, part, 0); firetouchinterest(h, part, 1) end end
        task.wait(0.1)
    end
    if lockConn then lockConn:Disconnect() end; lockActive = false
    return not part.Parent
end
function AutoCollectController.enqueue(part)
    if queued[part] or not wantSeed(part) then return false end
    queued[part]=true; table.insert(queue, part); return true
end
function AutoCollectController.preTp(pos, kind)
    local cfg = AutoCollectController.Cfg or {}
    if kind == "gold" and not cfg.autoGoldSeed then return end
    if kind == "rainbow" and not cfg.autoRainbowSeed then return end
    if cfg.disableTp or lockActive then return end
    local hrp=getHRP(); if hrp then hrp.CFrame=CFrame.new(pos+Vector3.new(0,3,0)); hrp.AssemblyLinearVelocity=Vector3.zero end
end
function AutoCollectController.start()
    if running then return true end; running=true
    local folder = AutoCollectController.resolveSeedFolder(); if not folder then return false,"missing_seed_folder" end
    table.insert(connections, folder.ChildAdded:Connect(function(part) AutoCollectController.enqueue(part) end))
    local net=AutoCollectController.Networking
    if net and net.WeatherEffects then
        if net.WeatherEffects.GoldMoonStrike then table.insert(connections, net.WeatherEffects.GoldMoonStrike.OnClientEvent:Connect(function(pos) AutoCollectController.preTp(pos,"gold") end)) end
        if net.WeatherEffects.RainbowMoonStrike then table.insert(connections, net.WeatherEffects.RainbowMoonStrike.OnClientEvent:Connect(function(pos) AutoCollectController.preTp(pos,"rainbow") end)) end
    end
    for _,part in pairs(folder:GetChildren()) do AutoCollectController.enqueue(part) end
    task.spawn(function() while running do task.wait(0.05); while running and #queue>0 do local part=table.remove(queue,1); local done=AutoCollectController.collectOne(part); if (not done) and part.Parent then local n=(attempts[part] or 0)+1; attempts[part]=n; if n<MAX_ATTEMPTS then table.insert(queue,part) else attempts[part]=nil; queued[part]=nil end else attempts[part]=nil; queued[part]=nil end; task.wait(0.2) end end end)
    task.spawn(function() while running do local cfg=AutoCollectController.Cfg or {}; if cfg.autoGoldSeed or cfg.autoRainbowSeed then for _,part in pairs(folder:GetChildren()) do AutoCollectController.enqueue(part) end end; task.wait(4) end end)
    return true
end
function AutoCollectController.stop() running=false; for _,c in ipairs(connections) do pcall(function() c:Disconnect() end) end; connections={}; return true end
return AutoCollectController
