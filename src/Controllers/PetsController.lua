-- PetsController.lua
-- Modular Auto Pets controller ported from gag2.lua Auto Pets section.

local PetsController = {}
local running = false
local PET_RARITY_BUY = {
    Frog="Common", Snail="Common", Cat="Common", Bunny="Common", Chick="Common", Dog="Common",
    Bee="Uncommon", Butterfly="Uncommon", Cow="Uncommon", Duck="Uncommon",
    Panda="Rare", Deer="Rare", Dodo="Rare", Eagle="Epic", Goat="Epic", Owl="Epic",
    ["Polar Bear"]="Legendary", Peacock="Legendary", Shark="Legendary", Minotaur="Mythic", Trex="Mythic",
}
local function msEmpty(t) return type(t) ~= "table" or next(t) == nil end
local function msMatch(selected, value) if msEmpty(selected) then return true end return selected[value] == true or table.find(selected, value) ~= nil end
local function getHRP() local lp=PetsController.LocalPlayer; local c=lp and lp.Character; return c and c:FindFirstChild("HumanoidRootPart") end
function PetsController.init(deps)
    deps = deps or {}; PetsController.Logger=deps.Logger; PetsController.Cfg=deps.Cfg or {}; PetsController.Networking=deps.Networking; PetsController.LocalPlayer=deps.LocalPlayer; PetsController.Workspace=deps.Workspace or workspace; PetsController.FeatureRegistry=deps.FeatureRegistry
    if deps.PET_RARITY_BUY then for k,v in pairs(deps.PET_RARITY_BUY) do PET_RARITY_BUY[k]=v end end
    pcall(function() local pd=require(game:GetService("ReplicatedStorage"):WaitForChild("SharedData"):WaitForChild("PetData")); for k,v in pairs(pd) do if type(v)=="table" and v.Rarity then PET_RARITY_BUY[k]=v.Rarity end end end)
    if PetsController.FeatureRegistry then PetsController.FeatureRegistry.set("Pets", "modular") end
    return PetsController
end
function PetsController.passPetBuyFilter(model)
    local cfg=PetsController.Cfg or {}; local petName=model:GetAttribute("PetName") or model.Name; local petSize=model:GetAttribute("PetSize") or ""
    return msMatch(cfg.selBuyPet, petName) and msMatch(cfg.selBuyPetRarity, PET_RARITY_BUY[petName] or "Common") and msMatch(cfg.selBuyPetSize, petSize)
end
function PetsController.tick()
    local cfg=PetsController.Cfg or {}; if not cfg.autoBuyPet then return true end
    local net=PetsController.Networking; if not (net and net.Pets and net.Pets.WildPetTame) then return false,"missing_pet_remote" end
    local pvc=PetsController.Workspace:FindFirstChild("_PetVisualClient"); local models=pvc and pvc:FindFirstChild("Models"); if not models then return true end
    for _, model in pairs(models:GetChildren()) do
        if cfg.autoBuyPet and PetsController.passPetBuyFilter(model) then
            if not cfg.disableTp then local hrp,base=getHRP(),model:FindFirstChildWhichIsA("BasePart",true); if hrp and base then hrp.CFrame=CFrame.new(base.Position+Vector3.new(0,3,0)); task.wait(0.1) end end
            net.Pets.WildPetTame:Fire(model); task.wait(0.5)
        end
    end
    return true
end
function PetsController.start() if running then return true end; running=true; task.spawn(function() while running do task.wait(math.max(tonumber((PetsController.Cfg or {}).buyPetDelay) or 1,1)); PetsController.tick() end end); return true end
function PetsController.stop() running=false; return true end
return PetsController
