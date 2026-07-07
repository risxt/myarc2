-- PlantingService.lua (REWRITE)
-- Handles auto-planting logic based on empty spots and settings.
local PlantingService = {}
local running = false
local connections = {}
local function getHRP() local lp=PlantingService.LocalPlayer; local c=lp and lp.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function getMyPlot() return PlantingService.GardenService and type(PlantingService.GardenService.getMyPlot)=="function" and PlantingService.GardenService.getMyPlot() or nil end
function PlantingService.init(deps)
    deps=deps or {}; PlantingService.Logger=deps.Logger; PlantingService.Cfg=deps.Cfg or {}; PlantingService.LocalPlayer=deps.LocalPlayer; PlantingService.Workspace=deps.Workspace or workspace; PlantingService.Networking=deps.Networking; PlantingService.GardenService=deps.GardenService; PlantingService.CollectionService=deps.CollectionService or (game and game:GetService("CollectionService")); PlantingService.State=deps.State; return PlantingService
end
local SPRINKLER_RADIUS={["Common Sprinkler"]=20,["Uncommon Sprinkler"]=25,["Rare Sprinkler"]=30,["Legendary Sprinkler"]=40,["Super Sprinkler"]=55}
local function getSprinklerRadius(name) for k,v in pairs(SPRINKLER_RADIUS) do if name:find(k) then return v/2 end end; return 15 end
local function getSprinklerCenterPart(model) if not model then return nil end; return model.PrimaryPart or model:FindFirstChild("Root") or model:FindFirstChild("RootPart") or model:FindFirstChild("Base") or model:FindFirstChildWhichIsA("BasePart") end
local function isUsablePlantArea(area) if not area or not area:IsA("BasePart") then return false end; local c=area.Color; if c and c.G>c.R and c.G>c.B then return false end; return true end
local function getAllSeedTools() local bp=PlantingService.LocalPlayer:FindFirstChild("Backpack"); local char=PlantingService.LocalPlayer.Character; local tools={}; if bp then for _,t in pairs(bp:GetChildren()) do if t:IsA("Tool") and t:GetAttribute("SeedTool") then tools[#tools+1]=t end end end; if char then for _,t in pairs(char:GetChildren()) do if t:IsA("Tool") and t:GetAttribute("SeedTool") then tools[#tools+1]=t end end end; return tools end
function PlantingService.getEmptySpots(myPlot)
    local cfg=PlantingService.Cfg; local plantsFolder=myPlot:FindFirstChild("Plants"); local plantPositions={}; if plantsFolder then for _,p in pairs(plantsFolder:GetChildren()) do local pos=p:GetPivot().Position; plantPositions[#plantPositions+1]=Vector2.new(pos.X,pos.Z) end end
    local refPos,refRadius=nil,nil
    if cfg.plantPosition=="Sprinkler Radius" then
        local sprinklersF=myPlot:FindFirstChild("Sprinklers"); if sprinklersF then local selected=tostring(cfg.plantSprinkler or "Select Options"); local bestPos,bestRadius=nil,-math.huge
        for _,s in pairs(sprinklersF:GetChildren()) do local sname=tostring(s:GetAttribute("Sprinkler") or s:GetAttribute("SprinklerName") or s.Name); local bp=getSprinklerCenterPart(s); if bp then local radius=getSprinklerRadius(sname); local isSel=selected~="" and selected~="Select Options" and (sname==selected or s.Name==selected); if isSel then refPos=bp.Position; refRadius=radius; break elseif selected=="" or selected=="Select Options" then if radius>bestRadius then bestPos=bp.Position; bestRadius=radius end end end end; if not refPos and bestPos then refPos=bestPos; refRadius=bestRadius end end
        if not refPos then return {} end
    elseif cfg.plantPosition=="Saved Position" and cfg.savedPlantPos then refPos=cfg.savedPlantPos; refRadius=35
    elseif cfg.plantPosition=="Player Position" then local hrp=getHRP(); if hrp then local stackSpots={}; for i=1,100 do stackSpots[i]=hrp.Position end; return stackSpots end end
    local spots={}
    if cfg.plantPosition=="Random" then local areas={}; for _,area in pairs(PlantingService.CollectionService:GetTagged("PlantArea")) do if area:IsDescendantOf(myPlot) and isUsablePlantArea(area) then areas[#areas+1]=area end end; if #areas==0 then return {} end; local attempts=60; for _=1,attempts do local area=areas[math.random(1,#areas)]; local sx,sz=area.Size.X,area.Size.Z; local lx=math.random()*(sx-4)-(sx/2-2); local lz=math.random()*(sz-4)-(sz/2-2); local world=area.CFrame:PointToWorldSpace(Vector3.new(lx,0,lz)); local wx,wz=world.X,world.Z; local p2=Vector2.new(wx,wz); local occ=false; for _,pp in pairs(plantPositions) do if (p2-pp).Magnitude<2 then occ=true; break end end; if not occ then spots[#spots+1]=Vector3.new(wx,area.Position.Y,wz); plantPositions[#plantPositions+1]=p2 end end; return spots end
    local spacing=3; for _,area in pairs(PlantingService.CollectionService:GetTagged("PlantArea")) do if area:IsDescendantOf(myPlot) and isUsablePlantArea(area) then local cy=area.Position.Y; local sx,sz=area.Size.X,area.Size.Z; local ox=-sx/2+2; while ox<=sx/2-2 do local oz=-sz/2+2; while oz<=sz/2-2 do local world=area.CFrame:PointToWorldSpace(Vector3.new(ox,0,oz)); local wx,wz=world.X,world.Z; local p2=Vector2.new(wx,wz); local inR=true; if refPos and refRadius then inR=(Vector2.new(refPos.X,refPos.Z)-p2).Magnitude<=refRadius end; if inR then local occ=false; for _,pp in pairs(plantPositions) do if (p2-pp).Magnitude<2 then occ=true; break end end; if not occ then spots[#spots+1]=Vector3.new(wx,cy,wz) end end; oz+=spacing end; ox+=spacing end end end
    if refPos then table.sort(spots,function(a,b) return (a-refPos).Magnitude<(b-refPos).Magnitude end) end; return spots
end
function PlantingService.start()
    if running then return true end; running=true
    task.spawn(function()
        while running do
            local cfg=PlantingService.Cfg; if not cfg.autoPlantSeed and not cfg.autoPlantAll then task.wait(1) else
                local myPlot=getMyPlot(); if not myPlot then task.wait(2) else
                    local spots=PlantingService.getEmptySpots(myPlot); if #spots==0 then task.wait(5) else
                        local seedPool={}; if cfg.autoPlantAll then seedPool=getAllSeedTools() elseif cfg.plantSeedName~="Select Options" then local tools=getAllSeedTools(); for _,t in ipairs(tools) do if t:GetAttribute("SeedTool")==cfg.plantSeedName then seedPool={t}; break end end end
                        if #seedPool>0 then
                            local si=1; local net=PlantingService.Networking; local st=PlantingService.State
                            for _,pos in pairs(spots) do
                                if not cfg.autoPlantSeed and not cfg.autoPlantAll then break end; local char=PlantingService.LocalPlayer.Character; local hum=char and char:FindFirstChild("Humanoid"); if not hum then break end
                                local tool=seedPool[si]; if not tool or not tool.Parent then si+=1; if si>#seedPool then break end; tool=seedPool[si] end; if not tool then break end
                                local bp=PlantingService.LocalPlayer:FindFirstChild("Backpack"); local realTool=(bp and bp:FindFirstChild(tool.Name)) or tool
                                if realTool and realTool.Parent~=bp and realTool.Parent~=char then local tools=getAllSeedTools(); realTool=nil; for _,t in ipairs(tools) do if t.Name==tool.Name then realTool=t; break end end; if realTool then seedPool[si]=realTool end end
                                if realTool and (realTool.Parent==bp or realTool.Parent==char) then
                                    if net and net.Plant and net.Plant.PlantSeed then net.Plant.PlantSeed:Fire(pos,realTool:GetAttribute("SeedTool"),realTool) end
                                    if st then st.planted=(st.planted or 0)+1 end
                                    if cfg.autoPlantAll then si+=1; if si>#seedPool then si=1 end end
                                    local d=tonumber(cfg.plantDelay) or 0; if d>0 then task.wait(d) elseif st and st.planted%25==0 then task.wait() end
                                else break end
                            end
                        end
                        task.wait((tonumber(cfg.plantDelay) or 0)>0 and 0.5 or 0.1)
                    end
                end
            end
        end
    end)
    return true
end
function PlantingService.stop() running=false; return true end
return PlantingService
