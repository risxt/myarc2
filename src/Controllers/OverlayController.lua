-- OverlayController.lua (REWRITE)
-- Modular overlay/ESP controller with tracked GUI ownership: ESP labels, Weather HUD, Inventory Value.
local OverlayController = {}
local running = {}
local espLabels = {}
local espLabelCount = 0
local ESP_MAX_LABELS = 350
local connections = {}
local weatherTimers = {}
local RARITY_COLORS={Common=Color3.fromRGB(180,180,180),Uncommon=Color3.fromRGB(80,200,80),Rare=Color3.fromRGB(80,130,255),Epic=Color3.fromRGB(180,80,255),Legendary=Color3.fromRGB(255,200,0),Mythic=Color3.fromRGB(255,80,80),Super=Color3.fromRGB(255,150,0)}
local MUT_COLORS={Gold="rgb(255,245,0)",Rainbow="rgb(0,255,170)",Electric="rgb(3,151,225)",Frozen="rgb(0,245,255)",Bloodlit="rgb(200,30,30)",Chained="rgb(139,47,175)",Starstruck="rgb(239,140,253)",Aurora="rgb(31,140,254)",Solarflare="rgb(255,120,0)",Pizza="rgb(255,180,50)"}
local PET_RARITY={Frog="Common",Snail="Common",Cat="Common",Bunny="Common",Chick="Common",Dog="Common",Bee="Uncommon",Butterfly="Uncommon",Cow="Uncommon",Duck="Uncommon",Panda="Rare",Deer="Rare",Dodo="Rare",Eagle="Epic",Goat="Epic",["Polar Bear"]="Legendary",Peacock="Legendary",Shark="Legendary",Minotaur="Mythic",Trex="Mythic"}
local function msMatch(sel,val) if type(sel)~="table" or #sel==0 then return true end; for _,v in ipairs(sel) do if v==val or v=="All" or v=="*" or v=="Select Options" then return true end end; return false end
local function msEmpty(sel) return type(sel)~="table" or #sel==0 or (sel[1]=="Select Options" and #sel==1) end
local function msMutMatch(sel,mut) if msEmpty(sel) then return true end; mut=tostring(mut or ""); for _,v in ipairs(sel) do if v=="None" and mut=="" then return true end; if mut:find(v) then return true end end; return false end
function OverlayController.init(deps)
    deps=deps or {}; OverlayController.Logger=deps.Logger; OverlayController.Cfg=deps.Cfg or {}; OverlayController.LocalPlayer=deps.LocalPlayer; OverlayController.Workspace=deps.Workspace or workspace; OverlayController.FeatureRegistry=deps.FeatureRegistry; OverlayController.SEED_RARITY=deps.SEED_RARITY or {}; OverlayController.calcFruitValue=deps.calcFruitValue
    if OverlayController.FeatureRegistry then OverlayController.FeatureRegistry.set("ESP","modular"); OverlayController.FeatureRegistry.set("Overlays","modular") end; return OverlayController
end
-- ESP LOGIC
local function cleanupAllESPLabels() for _,obj in pairs(OverlayController.Workspace:GetDescendants()) do if obj:IsA("BillboardGui") and obj.Name=="_ESPLabel" then obj:Destroy() end end end
local function makeLabel(part,text,color) if espLabels[part] or espLabelCount>=ESP_MAX_LABELS then return end; local bg=Instance.new("BillboardGui"); bg.Name="_ESPLabel"; bg.AlwaysOnTop=true; bg.Size=UDim2.fromOffset(330,30); bg.StudsOffset=Vector3.new(0,2.35,0); bg.MaxDistance=500; local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.fromScale(1,1); lbl.BackgroundTransparency=1; lbl.TextColor3=color or Color3.fromRGB(255,255,255); lbl.RichText=true; lbl.Text=text; lbl.TextScaled=false; lbl.TextSize=18; lbl.TextStrokeColor3=Color3.fromRGB(0,0,0); lbl.TextStrokeTransparency=0.08; lbl.Font=Enum.Font.GothamBlack; lbl.Parent=bg; bg.Parent=part; espLabels[part]=bg; espLabelCount+=1; part.AncestryChanged:Connect(function(_,p) if not p then bg:Destroy(); espLabels[part]=nil; espLabelCount=math.max(espLabelCount-1,0) end end) end
local function removeLabel(part) local bg=espLabels[part]; if bg then bg:Destroy(); espLabels[part]=nil; espLabelCount=math.max(espLabelCount-1,0) end end
local function clearESP() for _,bg in pairs(espLabels) do if bg and bg.Parent then bg:Destroy() end end; espLabels={}; espLabelCount=0; cleanupAllESPLabels() end
local function hideFruitTechParts(fruit) for _,obj in pairs(fruit:GetDescendants()) do if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Beam") or obj:IsA("Trail") then obj.Enabled=false elseif obj:IsA("BasePart") then obj.Transparency=1 end end end
local function tryFruitESP(plant)
    local cfg=OverlayController.Cfg; if not cfg.espFruit then return end; local seedName=plant:GetAttribute("SeedName") or ""; if seedName=="" then return end; local fruitsF=plant:FindFirstChild("Fruits"); if not fruitsF then return end
    for _,fruit in pairs(fruitsF:GetChildren()) do
        hideFruitTechParts(fruit); local mut=fruit:GetAttribute("Mutation") or ""
        if msMatch(cfg.selEspFruit,seedName) and msMatch(cfg.selEspRarity,OverlayController.SEED_RARITY[seedName] or "Common") and msMutMatch(cfg.selEspMut,mut) then
            local hasPrompt=fruit:FindFirstChildWhichIsA("ProximityPrompt",true); if hasPrompt then local anchor=hasPrompt.Parent; local base=(anchor and anchor:IsA("BasePart") and anchor) or fruit:FindFirstChild("HarvestPart",true) or fruit.PrimaryPart; if base then
                local sm=fruit:GetAttribute("SizeMulti") or 1; local w=tonumber(fruit:GetAttribute("Weight")) or 1; if cfg.espKgThresh>0 then if cfg.espKgMode=="Above" and w<cfg.espKgThresh then continue end; if cfg.espKgMode=="Below" and w>cfg.espKgThresh then continue end end
                local weightStr=string.format("%.2fkg",w); local val=type(OverlayController.calcFruitValue)=="function" and OverlayController.calcFruitValue(seedName,sm,mut,0) or 0
                local namePart; if mut~="" then local mutCol=MUT_COLORS[mut] or "rgb(255,255,255)"; namePart='<font color="'..mutCol..'">'..mut..'</font> '..seedName else namePart=seedName end
                local function fmtValue(v) local form=v; while true do form,k=string.gsub(form,"^(-?%d+)(%d%d%d)","%1,%2"); if k==0 then break end end; return "$" .. form end
                local valPart='<font color="rgb(80,255,120)">'..fmtValue(val)..'</font>'
                makeLabel(base,namePart.." [ "..weightStr.." ] [ "..valPart.." ]")
            end end
        end
    end
end
local function watchPlant(plant) if not plant:IsA("Model") then return end; table.insert(connections, plant.DescendantAdded:Connect(function(d) local cfg=OverlayController.Cfg; if cfg.espFruit and d:IsA("ProximityPrompt") then tryFruitESP(plant) end end)); table.insert(connections, plant.DescendantRemoving:Connect(function(d) if d:IsA("ProximityPrompt") then local fruit=d.Parent and d.Parent.Parent; if fruit and fruit:IsA("Model") then local anchor=d.Parent; local base=(anchor and anchor:IsA("BasePart") and anchor) or fruit:FindFirstChild("HarvestPart",true) or fruit.PrimaryPart; if base then removeLabel(base) end end end end)); tryFruitESP(plant) end
local function watchPlantsFolder(plantsFolder) for _,plant in pairs(plantsFolder:GetChildren()) do task.spawn(watchPlant,plant) end; table.insert(connections, plantsFolder.ChildAdded:Connect(function(plant) task.spawn(watchPlant,plant) end)) end
local function tryPetESP(part)
    local cfg=OverlayController.Cfg; if not cfg.espPet then return end; if not part:IsA("BasePart") then return end; local species=part:GetAttribute("PetSpecies") or ""; if species=="" then return end; local size=part:GetAttribute("PetSize") or ""
    if not (msMatch(cfg.selEspPet,species) and msMatch(cfg.selEspPetRarity,PET_RARITY[species] or "Common") and msMatch(cfg.selEspPetSize,size)) then return end
    local col=RARITY_COLORS[PET_RARITY[species] or "Common"] or Color3.new(1,1,1); local label=size~="" and (size.." "..species) or species; makeLabel(part,label,col)
end
-- WEATHER HUD LOGIC
local function mkCS(...)
    local args, kps = {...}, {}
    for i = 1, #args, 2 do
        if args[i] ~= nil and args[i + 1] ~= nil then
            kps[#kps + 1] = ColorSequenceKeypoint.new(args[i], args[i + 1])
        end
    end
    if #kps < 2 then
        local fallback = Color3.fromRGB(255, 255, 255)
        kps = {
            ColorSequenceKeypoint.new(0, fallback),
            ColorSequenceKeypoint.new(1, fallback),
        }
    end
    return ColorSequence.new(kps)
end
local PRED_TYPES={{name="Sunset",vec="rbxassetid://86217612022586",grad=mkCS(0,Color3.fromRGB(180,70,0),0.5,Color3.fromRGB(255,140,20),1,Color3.fromRGB(180,70,0))},{name="Moon",vec="rbxassetid://76206945378403",grad=mkCS(0,Color3.fromRGB(7,61,159),1,Color3.fromRGB(7,61,159))},{name="Goldmoon",vec="rbxassetid://84902063004871",grad=mkCS(0,Color3.fromRGB(120,80,0),0.5,Color3.fromRGB(220,160,0),1,Color3.fromRGB(120,80,0))},{name="Bloodmoon",vec="rbxassetid://72350957717841",grad=mkCS(0,Color3.fromRGB(170,0,0),0.5,Color3.fromRGB(255,0,0),1,Color3.fromRGB(170,0,0))},{name="Rainbow Moon",vec="rbxassetid://71907919634074",grad=mkCS(0,Color3.fromRGB(255,154,0),0.111,Color3.fromRGB(184,255,0),0.222,Color3.fromRGB(29,255,17),0.333,Color3.fromRGB(0,254,154),0.444,Color3.fromRGB(0,184,255),0.555,Color3.fromRGB(17,26,255),0.666,Color3.fromRGB(158,0,255),0.777,Color3.fromRGB(253,0,184),0.888,Color3.fromRGB(255,12,28),1,Color3.fromRGB(255,154,0))}}
local function makeCard(wt,parent)
    local card=Instance.new("ImageLabel"); card.Name="_Pred_"..wt.name; card.BackgroundColor3=Color3.new(1,1,1); card.BackgroundTransparency=0; card.Size=UDim2.new(0.0589,0,0.5226,0); card.LayoutOrder=0; card.Parent=parent; local ar=Instance.new("UIAspectRatioConstraint",card); ar.AspectRatio=1; local grad=Instance.new("UIGradient",card); grad.Color=wt.grad; local stroke=Instance.new("UIStroke",card); stroke.Color=Color3.fromRGB(0,18,54); stroke.Thickness=0.035; local bevel=Instance.new("ImageLabel",card); bevel.Name="BevelEffect"; bevel.AnchorPoint=Vector2.new(0.5,0.5); bevel.Position=UDim2.new(0.5,0,0.5,0); bevel.Size=UDim2.new(1,0,1,0); bevel.BackgroundTransparency=1; bevel.Image="rbxassetid://112886786873408"; bevel.ImageTransparency=0.05; local inlet=Instance.new("ImageLabel",card); inlet.Name="InletTexture"; inlet.AnchorPoint=Vector2.new(0.5,0.5); inlet.Position=UDim2.new(0.5,0,0.5,0); inlet.Size=UDim2.new(1,0,1,0); inlet.BackgroundTransparency=1; inlet.Image="rbxassetid://118449132151095"; inlet.ImageTransparency=0.64; local vec=Instance.new("ImageLabel",card); vec.Name="Vector"; vec.AnchorPoint=Vector2.new(0.5,0.5); vec.Position=UDim2.new(0.5,0,0.5,0); vec.Size=UDim2.new(0.8,0,0.8,0); vec.BackgroundTransparency=1; vec.Image=wt.vec; vec.ZIndex=1
    local function makeLbl(name,posY,sizeY) local lbl=Instance.new("TextLabel",card); lbl.Name=name; lbl.AnchorPoint=Vector2.new(0.5,0.5); lbl.Position=UDim2.new(0.5,0,posY,0); lbl.Size=UDim2.new(1,0,sizeY,0); lbl.BackgroundTransparency=1; lbl.TextColor3=Color3.new(1,1,1); lbl.TextScaled=true; lbl.TextXAlignment=Enum.TextXAlignment.Center; lbl.TextYAlignment=Enum.TextYAlignment.Center; pcall(function() lbl.FontFace=Font.new("rbxasset://fonts/families/ComicNeueAngular.json",Enum.FontWeight.Bold) end); if lbl.Font==Enum.Font.Unknown then lbl.Font=Enum.Font.GothamBold end; lbl.ZIndex=2; local s=Instance.new("UIStroke",lbl); s.Thickness=1; Instance.new("UIPadding",lbl); return lbl end
    makeLbl("Weather",0.14,0.231).Text=wt.name; return makeLbl("Time",0.855,0.233)
end
local function injectCards() local pg=OverlayController.LocalPlayer:WaitForChild("PlayerGui",15); if not pg then return end; local wUI=pg:WaitForChild("WeatherUI",15); if not wUI then return end; local frame=wUI:WaitForChild("Frame",15); if not frame then return end; for _,c in ipairs(frame:GetChildren()) do if c.Name:sub(1,6)=="_Pred_" then c:Destroy() end end; weatherTimers={}; for _,wt in ipairs(PRED_TYPES) do weatherTimers[wt.name]=makeCard(wt,frame) end end
local function predictNightType(x) local a=2654435761; local c=4.3*10^9; local s=x%c; s=(s*a)%c; if s%100<5 then return "Goldmoon" elseif s%100<10 then return "Rainbow Moon" elseif s%100<20 then return "Bloodmoon" else return "Moon" end end
local function getAllTimings() local now=os.time(); local offset=OverlayController.Workspace:GetAttribute("CycleOffset") or 0; local pos=(now+offset)%600; local toSunset=((450-pos)+600)%600; if toSunset==0 then toSunset=600 end; local toNight=((480-pos)+600)%600; if toNight==0 then toNight=600 end; local result={Sunset=toSunset}; local remaining={Moon=true,Goldmoon=true,["Rainbow Moon"]=true,Bloodmoon=true}; local t=now+toNight; while next(remaining) and t<now+86400*3 do local nType=predictNightType(math.floor(t/600)); if remaining[nType] then result[nType]=t-now; remaining[nType]=nil end; t=t+600 end; return result end
local function fmtCountdown(s) local m=math.floor(s/60); local sc=s%60; local h=math.floor(m/60); m=m%60; if h>0 then return string.format("%d:%02d:%02d",h,m,sc) else return string.format("%02d:%02d",m,sc) end end
-- INVENTORY VALUE OVERLAY
local totalLbl
local function calcTotalValue() local total,count=0,0; local function countTools(c) for _,t in pairs(c:GetChildren()) do if t:GetAttribute("HarvestedFruit") and t:GetAttribute("Id") then total+=type(OverlayController.calcFruitValue)=="function" and OverlayController.calcFruitValue(t:GetAttribute("FruitName") or "",t:GetAttribute("SizeMultiplier") or 1,t:GetAttribute("Mutation") or "",t:GetAttribute("DecayAlpha") or 0) or 0; count+=1 end end end; countTools(OverlayController.LocalPlayer.Backpack); if OverlayController.LocalPlayer.Character then countTools(OverlayController.LocalPlayer.Character) end; return count,total end
local function injectSlot(slot)
    if not (slot:IsA("TextButton") or slot:IsA("Frame")) then return end; local toolNameLbl=slot:FindFirstChild("ToolName"); local toolCountLbl=slot:FindFirstChild("ToolCount"); if not toolNameLbl then return end; local fruitName=toolNameLbl.Text; local weight=tonumber((toolCountLbl and toolCountLbl.Text or ""):match("([%d%.]+)")) or 0; local tool; local char=OverlayController.LocalPlayer.Character
    if char then for _,t in pairs(char:GetChildren()) do if t:IsA("Tool") and t:GetAttribute("FruitName")==fruitName and math.abs((t:GetAttribute("Weight") or 0)-weight)<0.1 then tool=t; break end end end; if not tool then for _,t in pairs(OverlayController.LocalPlayer.Backpack:GetChildren()) do if t:GetAttribute("FruitName")==fruitName and math.abs((t:GetAttribute("Weight") or 0)-weight)<0.1 then tool=t; break end end end
    local lbl=slot:FindFirstChild("_GAG2_Val"); if not tool then if lbl then lbl:Destroy() end; return end
    local val=type(OverlayController.calcFruitValue)=="function" and OverlayController.calcFruitValue(tool:GetAttribute("FruitName") or "",tool:GetAttribute("SizeMultiplier") or 1,tool:GetAttribute("Mutation") or "",tool:GetAttribute("DecayAlpha") or 0) or 0
    if not lbl then lbl=Instance.new("TextLabel"); lbl.Name="_GAG2_Val"; lbl.Size=UDim2.new(1,0,0,14); lbl.Position=UDim2.new(0,0,0,2); lbl.BackgroundTransparency=1; lbl.TextColor3=Color3.fromRGB(80,255,120); lbl.TextScaled=true; lbl.Font=Enum.Font.GothamBold; lbl.ZIndex=10; lbl.Parent=slot end
    local function fmtValue(v) local form=v; while true do form,k=string.gsub(form,"^(-?%d+)(%d%d%d)","%1,%2"); if k==0 then break end end; return "$" .. form end
    lbl.Text=fmtValue(val)
end
function OverlayController.start(name)
    name=name or "ESP"; if running[name] then return true end; running[name]=true
    cleanupAllESPLabels(); task.spawn(injectCards)
    task.spawn(function()
        local gardens=OverlayController.Workspace:WaitForChild("Gardens",30); if not gardens then return end
        for _,plot in pairs(gardens:GetChildren()) do task.spawn(function() local plantsF=plot:FindFirstChild("Plants") or plot:WaitForChild("Plants",10); if plantsF then watchPlantsFolder(plantsF) end end) end
        table.insert(connections, gardens.ChildAdded:Connect(function(plot) task.spawn(function() local plantsF=plot:FindFirstChild("Plants") or plot:WaitForChild("Plants",10); if plantsF then watchPlantsFolder(plantsF) end end) end))
    end)
    task.spawn(function()
        local petRefs=OverlayController.Workspace:WaitForChild("PlayerPetReferences",30); if not petRefs then return end
        local function watchPlayerPets(folder) for _,part in pairs(folder:GetChildren()) do task.spawn(tryPetESP,part) end; table.insert(connections, folder.ChildAdded:Connect(function(part) task.spawn(tryPetESP,part) end)) end
        for _,folder in pairs(petRefs:GetChildren()) do task.spawn(watchPlayerPets,folder) end
        table.insert(connections, petRefs.ChildAdded:Connect(function(folder) task.spawn(watchPlayerPets,folder) end))
    end)
    task.spawn(function() while running[name] do local ok,res=pcall(getAllTimings); if ok and res then for nm,lbl in pairs(weatherTimers) do if lbl and lbl.Parent then local secs=res[nm]; lbl.Text=secs and fmtCountdown(secs) or "N/A" end end end; task.wait(1) end end)
    task.spawn(function()
        local pg=OverlayController.LocalPlayer:WaitForChild("PlayerGui"); local bg=pg:WaitForChild("BackpackGui",30); if not bg then return end; local backpackFrame=bg:WaitForChild("Backpack",10); local inventoryFrame=backpackFrame and backpackFrame:WaitForChild("Inventory",10); local ugf=inventoryFrame; ugf=ugf and ugf:WaitForChild("ScrollingFrame",10); ugf=ugf and ugf:WaitForChild("UIGridFrame",10); if not ugf then return end; local hotbarSlotContainer=backpackFrame:FindFirstChild("Hotbar")
        local function refreshAllSlots(c) for _,slot in pairs(c:GetChildren()) do task.spawn(injectSlot,slot) end end
        local function updateTotal(anchor) local count,total=calcTotalValue(); if not totalLbl or not totalLbl.Parent then totalLbl=Instance.new("TextLabel"); totalLbl.Name="_GAG2_Total"; totalLbl.Size=UDim2.new(0,300,0,24); totalLbl.AnchorPoint=Vector2.new(0,0.5); totalLbl.Position=UDim2.new(0,210,0,22); totalLbl.BackgroundColor3=Color3.new(0,0,0); totalLbl.BackgroundTransparency=1; totalLbl.TextColor3=Color3.fromRGB(80,255,120); totalLbl.TextScaled=false; totalLbl.TextSize=20; totalLbl.TextXAlignment=Enum.TextXAlignment.Left; totalLbl.Font=Enum.Font.GothamBold; totalLbl.ZIndex=20; totalLbl.Parent=anchor; Instance.new("UICorner",totalLbl).CornerRadius=UDim.new(0,4) end
        local function fmtValue(v) local form=v; while true do form,k=string.gsub(form,"^(-?%d+)(%d%d%d)","%1,%2"); if k==0 then break end end; return "$" .. form end
        totalLbl.Text=count.." Fruits | "..fmtValue(total) end
        local function onChanged() task.wait(0.1); refreshAllSlots(ugf); if hotbarSlotContainer then refreshAllSlots(hotbarSlotContainer) end; updateTotal(inventoryFrame) end
        refreshAllSlots(ugf); if hotbarSlotContainer then refreshAllSlots(hotbarSlotContainer) end; updateTotal(inventoryFrame)
        table.insert(connections, ugf.ChildAdded:Connect(function(slot) task.wait(0.05); injectSlot(slot) end)); if hotbarSlotContainer then table.insert(connections, hotbarSlotContainer.ChildAdded:Connect(function(slot) task.wait(0.05); injectSlot(slot) end)) end
        table.insert(connections, OverlayController.LocalPlayer.Backpack.ChildAdded:Connect(onChanged)); table.insert(connections, OverlayController.LocalPlayer.Backpack.ChildRemoved:Connect(onChanged))
        local function hookChar(c) table.insert(connections, c.ChildAdded:Connect(onChanged)); table.insert(connections, c.ChildRemoved:Connect(onChanged)) end
        if OverlayController.LocalPlayer.Character then hookChar(OverlayController.LocalPlayer.Character) end; table.insert(connections, OverlayController.LocalPlayer.CharacterAdded:Connect(function(c) task.wait(0.1); hookChar(c); onChanged() end))
    end)
    return true
end
function OverlayController.stop(name) name=name or "ESP"; running[name]=false; clearESP(); for _,c in ipairs(connections) do pcall(function() c:Disconnect() end) end; connections={}; return true end
function OverlayController.isRunning(name) return running[name or "ESP"]==true end
return OverlayController
