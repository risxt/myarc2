-- AutoCollectController.lua (REWRITE)
-- Modular controller: weather seed collect + reactive instant collect + dropped items.
local AutoCollectController = {}
local running = false
local lockActive = false
local queue, queued, attempts = {}, {}, {}
local MAX_ATTEMPTS = 4
local connections = {}
local reactiveConns = {}
local reactiveTracked = {}
local function getHRP() local lp=AutoCollectController.LocalPlayer; local c=lp and lp.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function wantSeed(part) local cfg=AutoCollectController.Cfg or {}; if not part or not part.Parent then return false end; local isGold=part:GetAttribute("GoldSeed")==true; local isRainbow=part:GetAttribute("RainbowSeed")==true; return (isGold and cfg.autoGoldSeed) or (isRainbow and cfg.autoRainbowSeed) end
function AutoCollectController.init(deps)
    deps=deps or {}; AutoCollectController.Logger=deps.Logger; AutoCollectController.Cfg=deps.Cfg or {}; AutoCollectController.LocalPlayer=deps.LocalPlayer; AutoCollectController.Networking=deps.Networking; AutoCollectController.RunService=deps.RunService or (game and game:GetService("RunService")); AutoCollectController.Workspace=deps.Workspace or workspace; AutoCollectController.FeatureRegistry=deps.FeatureRegistry; AutoCollectController.GardenService=deps.GardenService; AutoCollectController.isFruitReady=deps.isFruitReady; AutoCollectController.passFruitFilter=deps.passFruitFilter; AutoCollectController.isBest=deps.isBest; AutoCollectController.shouldWaitMutation=deps.shouldWaitMutation; AutoCollectController.hasFruitCollectFilter=deps.hasFruitCollectFilter; AutoCollectController.isFullCheck=deps.isFullCheck; AutoCollectController.State=deps.State
    if AutoCollectController.FeatureRegistry then AutoCollectController.FeatureRegistry.set("AutoCollect","modular") end
    return AutoCollectController
end
function AutoCollectController.resolveSeedFolder() local map=AutoCollectController.Workspace:FindFirstChild("Map") or AutoCollectController.Workspace:WaitForChild("Map",30); return map and (map:FindFirstChild("SeedPackSpawnServerLocations") or map:WaitForChild("SeedPackSpawnServerLocations",30)) end
function AutoCollectController.collectOne(part)
    local cfg=AutoCollectController.Cfg or {}; if not part or not part.Parent then return true end; if not wantSeed(part) then return true end
    local prompt=part:FindFirstChildWhichIsA("ProximityPrompt",true); if not prompt then local elapsed=0; repeat task.wait(0.05); elapsed+=0.05; prompt=part:FindFirstChildWhichIsA("ProximityPrompt",true) until prompt or not part.Parent or elapsed>=3 end
    if not part.Parent then return true end; if not prompt then return false end
    local lockConn; if not cfg.disableTp then local hrp=getHRP(); if hrp then local targetCF=CFrame.new(part.Position+Vector3.new(0,3,0)); hrp.CFrame=targetCF; hrp.AssemblyLinearVelocity=Vector3.zero; lockActive=true; lockConn=AutoCollectController.RunService.Heartbeat:Connect(function() local h=getHRP(); if h then h.CFrame=targetCF; h.AssemblyLinearVelocity=Vector3.zero end end) end
    else local char=AutoCollectController.LocalPlayer and AutoCollectController.LocalPlayer.Character; local hum=char and char:FindFirstChildOfClass("Humanoid"); if hum then local deadline=os.clock()+8; while part.Parent and os.clock()<deadline do local h=getHRP(); if not h then break end; if (h.Position-part.Position).Magnitude<=10 then break end; hum:MoveTo(part.Position); task.wait(0.2) end end end
    for _=1,20 do if not part.Parent then break end; local p=part:FindFirstChildWhichIsA("ProximityPrompt",true); if p and type(fireproximityprompt)=="function" then fireproximityprompt(p) else local h=getHRP(); if h and type(firetouchinterest)=="function" then firetouchinterest(h,part,0); firetouchinterest(h,part,1) end end; task.wait(0.1) end
    if lockConn then lockConn:Disconnect() end; lockActive=false; return not part.Parent
end
function AutoCollectController.enqueue(part) if queued[part] or not wantSeed(part) then return false end; queued[part]=true; table.insert(queue,part); return true end
function AutoCollectController.preTp(pos,kind) local cfg=AutoCollectController.Cfg or {}; if kind=="gold" and not cfg.autoGoldSeed then return end; if kind=="rainbow" and not cfg.autoRainbowSeed then return end; if cfg.disableTp or lockActive then return end; local hrp=getHRP(); if hrp then hrp.CFrame=CFrame.new(pos+Vector3.new(0,3,0)); hrp.AssemblyLinearVelocity=Vector3.zero end end
-- REACTIVE INSTANT COLLECT
function AutoCollectController.tryInstantCollect(plant,fruit)
    local cfg=AutoCollectController.Cfg or {}; local active=cfg.autoHarvest or cfg.autoCollectAll or cfg.autoCollectFruit or cfg.autoCollectBest; if not active then return end
    if type(AutoCollectController.isFullCheck)=="function" and AutoCollectController.isFullCheck() then return end
    local plantId=plant:GetAttribute("PlantId"); local fruitId=fruit:GetAttribute("FruitId"); if fruitId==nil and plant==fruit then fruitId="" end; if not plantId or not fruitId then return end
    if fruitId=="" and plant:FindFirstChild("Fruits") then return end
    if type(AutoCollectController.isFruitReady)=="function" and not AutoCollectController.isFruitReady(fruit) then return end
    local key=tostring(plantId).."_"..tostring(fruitId); if reactiveTracked[key] then return end
    local ok=false; if cfg.autoHarvest then ok=true elseif cfg.autoCollectAll then ok=(type(AutoCollectController.hasFruitCollectFilter)=="function" and AutoCollectController.hasFruitCollectFilter()) and (type(AutoCollectController.passFruitFilter)=="function" and AutoCollectController.passFruitFilter(plant,fruit)) or true elseif cfg.autoCollectBest then ok=type(AutoCollectController.isBest)=="function" and AutoCollectController.isBest(plant,fruit) elseif cfg.autoCollectFruit then ok=type(AutoCollectController.passFruitFilter)=="function" and AutoCollectController.passFruitFilter(plant,fruit) end
    if ok and type(AutoCollectController.shouldWaitMutation)=="function" and AutoCollectController.shouldWaitMutation(plant,fruit) then ok=false end
    if ok then reactiveTracked[key]=true; task.wait(math.random(3,12)/100); local net=AutoCollectController.Networking; if net and net.Garden and net.Garden.CollectFruit then pcall(function() net.Garden.CollectFruit:Fire(plantId,fruitId) end) end; local st=AutoCollectController.State; if st then st.harvested=(st.harvested or 0)+1 end end
end
function AutoCollectController.watchFruit(plant,fruit)
    if not fruit:IsA("Model") and not fruit:IsA("BasePart") then return end; local fruitId=fruit:GetAttribute("FruitId"); if fruitId==nil and plant==fruit then fruitId="" end; if not fruitId then return end
    local cKey=tostring(plant:GetFullName()).."/"..tostring(fruitId); if reactiveConns[cKey] then return end
    AutoCollectController.tryInstantCollect(plant,fruit); reactiveConns[cKey]=fruit:GetAttributeChangedSignal("Age"):Connect(function() AutoCollectController.tryInstantCollect(plant,fruit) end)
end
function AutoCollectController.watchPlant(plant)
    local fruitsF=plant:FindFirstChild("Fruits"); if fruitsF then for _,fruit in ipairs(fruitsF:GetChildren()) do AutoCollectController.watchFruit(plant,fruit) end; local conn=fruitsF.ChildAdded:Connect(function(f) task.wait(0.5); AutoCollectController.watchFruit(plant,f) end); reactiveConns[tostring(plant:GetFullName()).."_add"]=conn
    else AutoCollectController.watchFruit(plant,plant); reactiveConns[tostring(plant:GetFullName()).."_childadd"]=plant.ChildAdded:Connect(function(child) if child.Name=="Fruits" then for _,fruit in ipairs(child:GetChildren()) do AutoCollectController.watchFruit(plant,fruit) end; reactiveConns[tostring(plant:GetFullName()).."_add"]=child.ChildAdded:Connect(function(f) task.wait(0.5); AutoCollectController.watchFruit(plant,f) end) end end) end
end
function AutoCollectController.scanPlot()
    local getMyPlot=AutoCollectController.GardenService and AutoCollectController.GardenService.getMyPlot; local plot=type(getMyPlot)=="function" and getMyPlot() or nil; if not plot then return end
    local plants=plot:FindFirstChild("Plants"); if not plants then return end; for _,plant in ipairs(plants:GetChildren()) do if plant:GetAttribute("PlantId") then AutoCollectController.watchPlant(plant) end end
    local pKey="plants_"..plants:GetFullName(); if not reactiveConns[pKey] then reactiveConns[pKey]=plants.ChildAdded:Connect(function(plant) task.wait(); if plant:GetAttribute("PlantId") then AutoCollectController.watchPlant(plant) end end) end
end
-- DROPPED ITEMS
function AutoCollectController.wantDroppedItem(item) local cfg=AutoCollectController.Cfg or {}; if not item:IsA("Model") then return false end; local ownerR=item:GetAttribute("OwnerRestricted"); local dropBy=item:GetAttribute("DroppedBy"); if ownerR and dropBy~=AutoCollectController.LocalPlayer.UserId then return false end; local name=item:GetAttribute("ItemName") or ""; local cat=item:GetAttribute("ItemCategory") or ""; return cfg.autoDropped or (cfg.autoGoldSeed and name=="Gold" and cat=="Seeds") or (cfg.autoRainbowSeed and name=="Rainbow" and cat=="Seeds") end
function AutoCollectController.collectDropped(item)
    local cfg=AutoCollectController.Cfg or {}; local prompt=item:FindFirstChildWhichIsA("ProximityPrompt",true); if not prompt then local dl=os.clock()+0.5; repeat task.wait() until item:FindFirstChildWhichIsA("ProximityPrompt",true) or not item.Parent or os.clock()>dl; prompt=item:FindFirstChildWhichIsA("ProximityPrompt",true) end
    if not prompt or not item.Parent then return end; local lockConn; if not cfg.disableTp then local hrp=getHRP(); local base=item:FindFirstChildWhichIsA("BasePart"); if hrp and base then local targetCF=CFrame.new(base.Position+Vector3.new(0,3,0)); hrp.CFrame=targetCF; hrp.AssemblyLinearVelocity=Vector3.zero; lockConn=AutoCollectController.RunService.Heartbeat:Connect(function() local h=getHRP(); if h then h.CFrame=targetCF; h.AssemblyLinearVelocity=Vector3.zero end end); task.wait(0.15) end end
    if not item.Parent then if lockConn then lockConn:Disconnect() end; return end; if type(fireproximityprompt)=="function" then fireproximityprompt(prompt) end; task.wait((prompt.HoldDuration or 1)+0.3); if lockConn then lockConn:Disconnect() end
end
function AutoCollectController.start()
    if running then return true end; running=true
    local folder=AutoCollectController.resolveSeedFolder(); if folder then
        table.insert(connections,folder.ChildAdded:Connect(function(part) AutoCollectController.enqueue(part) end))
        local net=AutoCollectController.Networking; if net and net.WeatherEffects then if net.WeatherEffects.GoldMoonStrike then table.insert(connections,net.WeatherEffects.GoldMoonStrike.OnClientEvent:Connect(function(pos) AutoCollectController.preTp(pos,"gold") end)) end; if net.WeatherEffects.RainbowMoonStrike then table.insert(connections,net.WeatherEffects.RainbowMoonStrike.OnClientEvent:Connect(function(pos) AutoCollectController.preTp(pos,"rainbow") end)) end end
        for _,part in pairs(folder:GetChildren()) do AutoCollectController.enqueue(part) end
        task.spawn(function() while running do task.wait(0.05); while running and #queue>0 do local part=table.remove(queue,1); local done=AutoCollectController.collectOne(part); if (not done) and part.Parent then local n=(attempts[part] or 0)+1; attempts[part]=n; if n<MAX_ATTEMPTS then table.insert(queue,part) else attempts[part]=nil; queued[part]=nil end else attempts[part]=nil; queued[part]=nil end; task.wait(0.2) end end end)
        task.spawn(function() while running do local cfg=AutoCollectController.Cfg or {}; if cfg.autoGoldSeed or cfg.autoRainbowSeed then for _,part in pairs(folder:GetChildren()) do AutoCollectController.enqueue(part) end end; task.wait(4) end end)
    end
    -- Reactive instant collect
    task.spawn(function() task.wait(2); AutoCollectController.scanPlot(); while running do task.wait(10); for key,conn in pairs(reactiveConns) do if not conn.Connected then reactiveConns[key]=nil end end; if next(reactiveTracked) then local count=0; for _ in pairs(reactiveTracked) do count+=1 end; if count>500 then reactiveTracked={} end end end end)
    -- Dropped items
    task.spawn(function()
        local dropFolder=AutoCollectController.Workspace:WaitForChild("DroppedItems",30); if not dropFolder then return end; local dropQueue,dropQueued={},{}
        local function enqueueDrop(item) if dropQueued[item] then return end; local cfg=AutoCollectController.Cfg or {}; if not (cfg.autoDropped or cfg.autoGoldSeed or cfg.autoRainbowSeed) then return end; if not AutoCollectController.wantDroppedItem(item) then return end; dropQueued[item]=true; table.insert(dropQueue,item) end
        table.insert(connections,dropFolder.ChildAdded:Connect(enqueueDrop))
        task.spawn(function() while running do task.wait(0.05); while #dropQueue>0 do if not running then break end; local item=table.remove(dropQueue,1); dropQueued[item]=nil; if item.Parent and AutoCollectController.wantDroppedItem(item) then AutoCollectController.collectDropped(item) end; task.wait(0.2) end end end)
        while running do local cfg=AutoCollectController.Cfg or {}; if cfg.autoDropped or cfg.autoGoldSeed or cfg.autoRainbowSeed then for _,item in pairs(dropFolder:GetChildren()) do enqueueDrop(item) end end; task.wait(1) end
    end)
    return true
end
function AutoCollectController.stop() running=false; for _,c in ipairs(connections) do pcall(function() c:Disconnect() end) end; connections={}; for _,c in pairs(reactiveConns) do pcall(function() c:Disconnect() end) end; reactiveConns={}; reactiveTracked={}; return true end
return AutoCollectController
