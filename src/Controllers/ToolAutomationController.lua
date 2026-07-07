-- ToolAutomationController.lua (REWRITE)
-- Modular tool automation: equip/activate + auto sprinkler + watering can + trowel + shovel + favorite.
local ToolAutomationController = {}
local running = {}
local connections = {}
local function backpack() local lp=ToolAutomationController.LocalPlayer; return lp and lp:FindFirstChild("Backpack") end
local function char() local lp=ToolAutomationController.LocalPlayer; return lp and lp.Character end
local function getHRP() local c=char(); return c and c:FindFirstChild("HumanoidRootPart") end
local function equipTool(tool) local c=char(); local hum=c and c:FindFirstChildOfClass("Humanoid"); if tool and hum and tool.Parent~=c then hum:EquipTool(tool); task.wait(0.15) end; return tool and tool.Parent==c end
-- msMatch multi-select helper
local function msMatch(sel,val) if type(sel)~="table" or #sel==0 then return true end; for _,v in ipairs(sel) do if v==val or v=="All" or v=="*" or v=="Select Options" then return true end end; return false end
local function msEmpty(sel) return type(sel)~="table" or #sel==0 or (sel[1]=="Select Options" and #sel==1) end
local function msMutMatch(sel,mut) if msEmpty(sel) then return true end; mut=tostring(mut or ""); for _,v in ipairs(sel) do if v=="None" and mut=="" then return true end; if mut:find(v) then return true end end; return false end
function ToolAutomationController.init(deps)
    deps=deps or {}; ToolAutomationController.Logger=deps.Logger; ToolAutomationController.Cfg=deps.Cfg or {}; ToolAutomationController.LocalPlayer=deps.LocalPlayer; ToolAutomationController.Networking=deps.Networking; ToolAutomationController.FeatureRegistry=deps.FeatureRegistry; ToolAutomationController.GardenService=deps.GardenService; ToolAutomationController.SEED_RARITY=deps.SEED_RARITY or {}; ToolAutomationController.Players=deps.Players
    if ToolAutomationController.FeatureRegistry then ToolAutomationController.FeatureRegistry.set("Tools","modular") end; return ToolAutomationController
end
function ToolAutomationController.findTool(predicate) local bp=backpack(); if not bp then return nil end; for _,t in ipairs(bp:GetChildren()) do if t:IsA("Tool") and predicate(t) then return t end end; local c=char(); if c then for _,t in ipairs(c:GetChildren()) do if t:IsA("Tool") and predicate(t) then return t end end end; return nil end
function ToolAutomationController.equipTool(tool) return equipTool(tool) end
function ToolAutomationController.activateTool(tool) local ok=equipTool(tool); if not ok then return false,"equip_failed" end; if type(tool.Activate)=="function" then tool:Activate(); return true end; return false,"tool_no_activate" end
-- AUTO SPRINKLER
function ToolAutomationController.findSprinklerTool(attrName) return ToolAutomationController.findTool(function(t) return t:GetAttribute("Sprinkler")==attrName end) end
function ToolAutomationController.getPlacePosition()
    local cfg=ToolAutomationController.Cfg or {}; local getMyPlot=ToolAutomationController.GardenService and ToolAutomationController.GardenService.getMyPlot
    if cfg.sprinklerPlaceMode=="Saved Position" then local p=cfg.sprinklerSavedPosition; if type(p)=="table" and tonumber(p.x) and tonumber(p.y) and tonumber(p.z) then return Vector3.new(tonumber(p.x),tonumber(p.y),tonumber(p.z)) end
    elseif cfg.sprinklerPlaceMode=="At Plants" and type(getMyPlot)=="function" then local plot=getMyPlot(); if plot then local plantsF=plot:FindFirstChild("Plants"); if plantsF then local fb; for _,plant in pairs(plantsF:GetChildren()) do local pp=plant.PrimaryPart or plant:FindFirstChildWhichIsA("BasePart"); if pp then fb=fb or pp.Position; local sn=plant:GetAttribute("SeedName") or ""; if sn~="" and msMatch(cfg.selSprinklerPlant,sn) then return pp.Position end end end; return fb end end end
    local hrp=getHRP(); return hrp and hrp.Position
end
function ToolAutomationController.doSprinklerCycle(force)
    local cfg=ToolAutomationController.Cfg or {}; if not (cfg.autoSprinkler or cfg.autoSprinklerAll) then return end; local net=ToolAutomationController.Networking; if not net then return end
    local selected=cfg.selSprinkler; if type(selected)~="table" or #selected==0 then return end
    local getMyPlot=ToolAutomationController.GardenService and ToolAutomationController.GardenService.getMyPlot; local plot=type(getMyPlot)=="function" and getMyPlot(); if not plot then return end; local plotId=tonumber(string.match(plot.Name,"%d+")); if not plotId then return end
    local basePos=ToolAutomationController.getPlacePosition(); if not basePos then return end
    local offsets={Vector3.new(0,0,0),Vector3.new(1.25,0,0),Vector3.new(-1.25,0,0),Vector3.new(0,0,1.25),Vector3.new(0,0,-1.25),Vector3.new(0.9,0,0.9),Vector3.new(-0.9,0,0.9),Vector3.new(0.9,0,-0.9),Vector3.new(-0.9,0,-0.9)}
    for i,spName in ipairs(selected) do local tool=ToolAutomationController.findSprinklerTool(spName); if tool then equipTool(tool); tool=ToolAutomationController.findSprinklerTool(spName) or tool; local pos=basePos+(offsets[i] or Vector3.new((i-1)*1.25,0,0)); if net.Place and net.Place.PlaceSprinkler then net.Place.PlaceSprinkler:Fire(pos,spName,tool,plotId) end; task.wait(1) end end
end
-- AUTO WATERING CAN
function ToolAutomationController.findWaterCanTool(preferred)
    local prefSet={}; if type(preferred)=="table" then for _,name in ipairs(preferred) do prefSet[tostring(name)]=true end elseif type(preferred)=="string" and preferred~="" then prefSet[preferred]=true end
    local function allowed(canName) if next(prefSet)==nil then return true end; return prefSet[tostring(canName)]==true end; local best
    local function scan(cont) if not cont then return nil end; for _,tool in ipairs(cont:GetChildren()) do if tool:IsA("Tool") then local canName=tool:GetAttribute("WateringCan"); if canName and allowed(canName) then if canName=="Super Watering Can" then return tool end; best=best or tool end end end; return best end
    local found=scan(char()); if found then return found end; return scan(backpack())
end
function ToolAutomationController.useWaterCanAt(pos)
    if not pos then return false end; local cfg=ToolAutomationController.Cfg or {}; local tool=ToolAutomationController.findWaterCanTool(cfg.selWaterCan); if not tool then return false end; equipTool(tool); tool=ToolAutomationController.findWaterCanTool(cfg.selWaterCan) or tool; local canName=tool:GetAttribute("WateringCan"); if not canName then return false end; local net=ToolAutomationController.Networking; if net and net.WateringCan and net.WateringCan.UseWateringCan then local ok=pcall(function() net.WateringCan.UseWateringCan:Fire(pos-Vector3.new(0,0.3,0),canName,tool) end); return ok end; return false
end
function ToolAutomationController.doWateringCanCycle()
    local cfg=ToolAutomationController.Cfg or {}; if not cfg.autoWaterCan then return end; local uses=math.clamp(math.floor(tonumber(cfg.waterCanUses) or 1),1,20); for i=1,uses do if not cfg.autoWaterCan then break end; if ToolAutomationController.useWaterCanAt(ToolAutomationController._lastSprinklerAnchor) then if i<uses then task.wait(0.35) end else task.wait(2); break end end
end
-- AUTO TROWEL
function ToolAutomationController.findTrowelTool() return ToolAutomationController.findTool(function(t) return t:GetAttribute("Trowel")~=nil end) end
function ToolAutomationController.doTrowelCycle()
    local cfg=ToolAutomationController.Cfg or {}; if not cfg.autoTrowel then return end; local tool=ToolAutomationController.findTrowelTool(); if not tool then return end; equipTool(tool); tool=ToolAutomationController.findTrowelTool() or tool
    local target; if cfg.selTrowelPos=="Saved Position" and ToolAutomationController._savedTrowelPos then target=ToolAutomationController._savedTrowelPos else local hrp=getHRP(); target=hrp and hrp.Position end; if not target then return end
    local getMyPlot=ToolAutomationController.GardenService and ToolAutomationController.GardenService.getMyPlot; local plot=type(getMyPlot)=="function" and getMyPlot(); if not plot then return end; local visual=plot:FindFirstChild("Plants"); if not visual then return end; local net=ToolAutomationController.Networking
    ToolAutomationController._movedTrowel=ToolAutomationController._movedTrowel or {}
    for _,plant in pairs(visual:GetChildren()) do if cfg.autoTrowel and plant:IsA("Model") then local plantId=plant:GetAttribute("PlantId"); local seedName=plant:GetAttribute("SeedName") or ""; if plantId and seedName~="" and msMatch(cfg.selTrowelPlant,seedName) and not ToolAutomationController._movedTrowel[tostring(plantId)] then if net and net.Trowel and net.Trowel.MovePlant then net.Trowel.MovePlant:Fire(plantId,target,0) end; ToolAutomationController._movedTrowel[tostring(plantId)]=true; task.wait(0.3) end end end
end
-- AUTO SHOVEL
function ToolAutomationController.findShovelTool() return ToolAutomationController.findTool(function(t) return t:GetAttribute("Shovel")~=nil end) end
function ToolAutomationController.doShovelCycle()
    local cfg=ToolAutomationController.Cfg or {}; if not (cfg.autoShovelTree or cfg.autoShovelFruit) then return end; local tool=ToolAutomationController.findShovelTool(); if not tool then return end; equipTool(tool); tool=ToolAutomationController.findShovelTool() or tool; local shovelAttr=tool:GetAttribute("Shovel")
    local getMyPlot=ToolAutomationController.GardenService and ToolAutomationController.GardenService.getMyPlot; local plot=type(getMyPlot)=="function" and getMyPlot(); if not plot then return end; local visual=plot:FindFirstChild("Plants"); if not visual then return end; local net=ToolAutomationController.Networking; local SR=ToolAutomationController.SEED_RARITY
    for _,plant in pairs(visual:GetChildren()) do if plant:IsA("Model") then local plantId=plant:GetAttribute("PlantId"); local seedName=plant:GetAttribute("SeedName") or ""; if plantId and seedName~="" then local doIt,useFruitId=false,""
        if cfg.autoShovelFruit then local mut=plant:GetAttribute("Mutation") or ""; local weight=tonumber(plant:GetAttribute("Weight")) or 1; if msMatch(cfg.selShovelFruit,seedName) and msMatch(cfg.selShovelFruitRarity,SR[seedName] or "Common") and msMutMatch(cfg.selShovelFruitMut,mut) then local pass=true; if cfg.selShovelThreshMode~="" then if cfg.selShovelThreshMode=="Above" and weight<cfg.shovelWeightThresh then pass=false end; if cfg.selShovelThreshMode=="Below" and weight>cfg.shovelWeightThresh then pass=false end end; if pass then doIt=true; useFruitId=plant:GetAttribute("FruitId") or "" end end end
        if not doIt and cfg.autoShovelTree then local mut=plant:GetAttribute("Mutation") or ""; if msMatch(cfg.selShovelTree,seedName) and msMatch(cfg.selShovelTreeRarity,SR[seedName] or "Common") and msMutMatch(cfg.selShovelTreeMut,mut) then doIt=true; useFruitId="" end end
        if doIt and net and net.Shovel and net.Shovel.UseShovel then net.Shovel.UseShovel:Fire(plantId,useFruitId,shovelAttr,tool); task.wait(0.5) end end end end
end
-- AUTO FAVORITE
function ToolAutomationController.doFavoriteCycle()
    local cfg=ToolAutomationController.Cfg or {}; if not (cfg.autoFavFruit or cfg.autoUnFavFruit or cfg.autoUnFavAll) then return end; local bp=backpack(); if not bp then return end; local net=ToolAutomationController.Networking; if not (net and net.Backpack and net.Backpack.SetFruitFavorite) then return end; local SR=ToolAutomationController.SEED_RARITY
    local function passFavFilter(tool) local name=tool:GetAttribute("FruitName") or ""; local mut=tool:GetAttribute("Mutation") or ""; local w=tool:GetAttribute("Weight") or 0; if not msMatch(cfg.selFavFruit,name) then return false end; if not msMatch(cfg.selFavRarity,SR[name] or "Common") then return false end; if not msMutMatch(cfg.selFavMut,mut) then return false end; if cfg.selFavThresh~="" then if cfg.selFavThresh=="Above" and w<cfg.favWeightThresh then return false end; if cfg.selFavThresh=="Below" and w>cfg.favWeightThresh then return false end end; return true end
    local fruits={}; for _,t in pairs(bp:GetChildren()) do if t:GetAttribute("HarvestedFruit") and t:GetAttribute("Id") then table.insert(fruits,t) end end
    if cfg.autoFavFruit then for _,tool in pairs(fruits) do if tool:GetAttribute("IsFavorite")~=true and passFavFilter(tool) then net.Backpack.SetFruitFavorite:Fire(tool:GetAttribute("Id"),true); task.wait(0.05) end end end
    if cfg.autoUnFavFruit then for _,tool in pairs(fruits) do if tool:GetAttribute("IsFavorite")==true and passFavFilter(tool) then net.Backpack.SetFruitFavorite:Fire(tool:GetAttribute("Id"),false); task.wait(0.05) end end end
    if cfg.autoUnFavAll then for _,tool in pairs(fruits) do if tool:GetAttribute("IsFavorite")==true then net.Backpack.SetFruitFavorite:Fire(tool:GetAttribute("Id"),false); task.wait(0.05) end end end
end
-- SFM Registration
function ToolAutomationController.registerSFM()
    if _G._SFM_Register then _G._SFM_Register("Sprinkler",function() ToolAutomationController.doSprinklerCycle(false) end); _G._SFM_Register("Trowel",function() ToolAutomationController.doTrowelCycle() end); _G._SFM_Register("Shovel",function() ToolAutomationController.doShovelCycle() end) end
    _G._SaveTrowelPos=function() local hrp=getHRP(); if hrp then ToolAutomationController._savedTrowelPos=hrp.Position end end; _G._ResetAutoTrowelMoved=function() ToolAutomationController._movedTrowel={} end; _G._RunSprinklerNow=function() ToolAutomationController.doSprinklerCycle(true) end
end
function ToolAutomationController.start(featureName)
    featureName=featureName or "default"; if running[featureName] then return true end; running[featureName]=true; ToolAutomationController.registerSFM()
    task.spawn(function() while running[featureName] do local cfg=ToolAutomationController.Cfg or {}; if not cfg.stackFarm then ToolAutomationController.doSprinklerCycle(false); task.wait(1) else task.wait(5) end end end)
    task.spawn(function() local lastWater=0; while running[featureName] do local cfg=ToolAutomationController.Cfg or {}; if cfg.autoWaterCan then local delay=math.max(tonumber(cfg.waterCanDelay) or 30,5); if os.clock()-lastWater>=delay then ToolAutomationController.doWateringCanCycle(); lastWater=os.clock() end end; task.wait(1) end end)
    task.spawn(function() while running[featureName] do local cfg=ToolAutomationController.Cfg or {}; if not cfg.stackFarm then ToolAutomationController.doTrowelCycle() end; task.wait(math.max(cfg.trowelDelay or 2,1)) end end)
    task.spawn(function() while running[featureName] do local cfg=ToolAutomationController.Cfg or {}; if not cfg.stackFarm then ToolAutomationController.doShovelCycle() end; local d=math.min(cfg.shovelTreeDelay or 2,cfg.shovelFruitDelay or 2); task.wait(math.max(d,1)) end end)
    task.spawn(function() while running[featureName] do local cfg=ToolAutomationController.Cfg or {}; ToolAutomationController.doFavoriteCycle(); task.wait(math.max(cfg.favDelay or 0.5,0.5)) end end)
    return true
end
function ToolAutomationController.stop(featureName) running[featureName or "default"]=false; for _,c in ipairs(connections) do pcall(function() c:Disconnect() end) end; connections={}; return true end
function ToolAutomationController.isRunning(featureName) return running[featureName or "default"]==true end
return ToolAutomationController
