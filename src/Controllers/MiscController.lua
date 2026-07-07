-- MiscController.lua (REWRITE)
-- Modular controller: Anti-fling, Noclip plants, Hide plants/fruits, Prompts, Gardens, Auto Hop
local MiscController = {}
local running = false
local connections = {}
local hpConns = {}
local hpActive = false
-- helpers
local function msMatch(sel,val) if type(sel)~="table" or #sel==0 then return true end; for _,v in ipairs(sel) do if v==val or v=="All" or v=="*" or v=="Select Options" then return true end end; return false end
local function msEmpty(sel) return type(sel)~="table" or #sel==0 or (sel[1]=="Select Options" and #sel==1) end
local function getHRP() local lp=MiscController.LocalPlayer; local c=lp and lp.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function getMyPlot() return MiscController.GardenService and type(MiscController.GardenService.getMyPlot)=="function" and MiscController.GardenService.getMyPlot() or nil end
function MiscController.init(deps)
    deps=deps or {}; MiscController.Logger=deps.Logger; MiscController.Cfg=deps.Cfg or {}; MiscController.LocalPlayer=deps.LocalPlayer; MiscController.RunService=deps.RunService or (game and game:GetService("RunService")); MiscController.TeleportService=deps.TeleportService or (game and game:GetService("TeleportService")); MiscController.GardenService=deps.GardenService; MiscController.Workspace=deps.Workspace or workspace; MiscController.FeatureRegistry=deps.FeatureRegistry
    if MiscController.FeatureRegistry then MiscController.FeatureRegistry.set("Misc","modular") end; return MiscController
end
-- Hide Plants Logic
local function isVFX(obj) return obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Beam") or obj:IsA("Trail") end
local function hookObj(obj) if hpConns[obj] then return end; if obj:IsA("BasePart") then obj.LocalTransparencyModifier=1; hpConns[obj]=obj:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function() if hpActive and obj.Parent and obj.LocalTransparencyModifier<1 then obj.LocalTransparencyModifier=1 end end) elseif isVFX(obj) then obj.Enabled=false; hpConns[obj]=obj:GetPropertyChangedSignal("Enabled"):Connect(function() if hpActive and obj.Parent and obj.Enabled then obj.Enabled=false end end) end end
local function unhookAll() for obj,conn in pairs(hpConns) do pcall(function() conn:Disconnect() end); if obj.Parent then if obj:IsA("BasePart") then obj.LocalTransparencyModifier=0 else obj.Enabled=true end end end; hpConns={} end
local function applyAllHidePlants() local plot=getMyPlot(); local plantsF=plot and plot:FindFirstChild("Plants"); if not plantsF then return end; local cfg=MiscController.Cfg or {}; for _,plant in pairs(plantsF:GetChildren()) do local sn=plant:GetAttribute("SeedName") or ""; if msMatch(cfg.selHidePlants,sn) then for _,obj in pairs(plant:GetDescendants()) do hookObj(obj) end end end end
-- Main Loop
function MiscController.start()
    if running then return true end; running = true
    -- Anti-fling, less knockback, bypass paused
    table.insert(connections, MiscController.RunService.Heartbeat:Connect(function()
        local cfg=MiscController.Cfg or {}; if not (cfg.antiFling or cfg.lessKnockback or cfg.bypassPaused) then return end
        local hrp=getHRP(); if not hrp then return end; local vel=hrp.AssemblyLinearVelocity
        if cfg.antiFling and vel.Magnitude>100 then hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero elseif cfg.lessKnockback and vel.Magnitude>30 then hrp.AssemblyLinearVelocity=vel.Unit*30 end
        if cfg.bypassPaused then if hrp.Anchored then hrp.Anchored=false end; local hum=MiscController.LocalPlayer.Character and MiscController.LocalPlayer.Character:FindFirstChildOfClass("Humanoid"); if hum and hum.WalkSpeed==0 then hum.WalkSpeed=16 end end
    end))
    -- Instant interact / Disable harvest prompt
    table.insert(connections, game.DescendantAdded:Connect(function(d)
        local cfg=MiscController.Cfg or {}; if d:IsA("ProximityPrompt") then if cfg.instantPrompt then task.wait(); d.HoldDuration=0 end; if cfg.disableHarvestPrompt then local plot=getMyPlot(); if plot and d:IsDescendantOf(plot) then task.wait(); d.Enabled=false end end end
    end))
    -- Noclip plants / Hide fruits
    task.spawn(function() while running do
        local cfg=MiscController.Cfg or {}; local plot=getMyPlot()
        if cfg.noclipPlants and plot then local plantsF=plot:FindFirstChild("Plants"); if plantsF then for _,obj in pairs(plantsF:GetDescendants()) do if obj:IsA("BasePart") and obj.CanCollide then obj.CanCollide=false end end end end
        if cfg.hideFruits and plot then for _,obj in pairs(plot:GetDescendants()) do if obj:FindFirstAncestor("Fruits") then if obj:IsA("BasePart") and obj.Transparency<1 then obj.Transparency=1 elseif isVFX(obj) and obj.Enabled then obj.Enabled=false end end end end
        task.wait(0.5)
    end end)
    -- Hide plants task
    task.spawn(function() while running do local cfg=MiscController.Cfg or {}; if cfg.hidePlants and not msEmpty(cfg.selHidePlants) then hpActive=true; applyAllHidePlants() else if hpActive then hpActive=false; unhookAll() end end; task.wait(2) end; hpActive=false; unhookAll() end)
    -- Remove other gardens
    local gardensFolder=MiscController.Workspace:WaitForChild("Gardens",10)
    if gardensFolder then
        table.insert(connections, gardensFolder.ChildAdded:Connect(function(plot) local cfg=MiscController.Cfg or {}; if cfg.autoRemoveOtherGardens then task.wait(1); local myPlot=getMyPlot(); if plot~=myPlot then for _,obj in pairs(plot:GetDescendants()) do if obj:IsA("BasePart") then obj.LocalTransparencyModifier=1 end end end end end))
        task.spawn(function() while running do local cfg=MiscController.Cfg or {}; if cfg.autoRemoveOtherGardens then local myPlot=getMyPlot(); for _,plot in pairs(gardensFolder:GetChildren()) do if plot~=myPlot then for _,obj in pairs(plot:GetDescendants()) do if obj:IsA("BasePart") then obj.LocalTransparencyModifier=1 end end end end end; task.wait(5) end end)
    end
    -- Auto Hop
    task.spawn(function() while running do local cfg=MiscController.Cfg or {}; if cfg.autoHopUntilVer then local target=tonumber(cfg.hopPlaceVer); if target and game.PlaceVersion~=target then MiscController.TeleportService:Teleport(game.PlaceId); task.wait(5) else cfg.autoHopUntilVer=false end end; task.wait(1) end end)
    
    _G._HidePlantsOn=function() hpActive=true; applyAllHidePlants() end
    _G._HidePlantsOff=function() hpActive=false; unhookAll() end
    return true
end
function MiscController.stop() running = false; for _,c in ipairs(connections) do pcall(function() c:Disconnect() end) end; connections={}; hpActive=false; unhookAll(); return true end
return MiscController
