-- AutoSellController.lua
-- Modular Auto Sell controller ported from gag2.lua Auto Sell section.

local AutoSellController = {}

local PET_RARITY_SELL = {
    Frog="Common",Snail="Common",Cat="Common",Bunny="Common",Chick="Common",Dog="Common",
    Bee="Uncommon",Butterfly="Uncommon",Cow="Uncommon",Duck="Uncommon",
    Panda="Rare",Deer="Rare",Dodo="Rare",
    Eagle="Epic",Goat="Epic",Owl="Epic",
    ["Polar Bear"]="Legendary",Peacock="Legendary",Shark="Legendary",
    Minotaur="Mythic",Trex="Mythic",
}

local SELL_ALL_MIN_COOLDOWN = 5
local SELL_BATCH_LIMIT = 15
local SELL_REMOTE_PAUSE = 0.05

local running = false
local lastSellAllAt = 0

local function msEmpty(t)
    return type(t) ~= "table" or next(t) == nil
end

local function msMatch(selected, value)
    if msEmpty(selected) then return true end
    return selected[value] == true or table.find(selected, value) ~= nil
end

local function msMutMatch(selected, value)
    if msEmpty(selected) then return true end
    value = value or ""
    if selected[value] == true or table.find(selected, value) ~= nil then return true end
    if value == "" and (selected.None == true or selected["None"] == true) then return true end
    return false
end

local function passSellFruitFilter(tool)
    local cfg = AutoSellController.Cfg or {}
    local valueBelow = tonumber(cfg.sellValueBelow) or 0
    local hasFilter = valueBelow > 0
        or not msEmpty(cfg.selSellFruit)
        or not msEmpty(cfg.selSellRarity)
        or not msEmpty(cfg.selSellMut)
        or cfg.selSellThresh ~= ""
    if not hasFilter then return false end
    local name = tool:GetAttribute("FruitName") or ""
    local mut = tool:GetAttribute("Mutation") or ""
    local w = tonumber(tool:GetAttribute("Weight"))
    if valueBelow > 0 and type(AutoSellController.calcFruitValue) == "function" then
        local val = AutoSellController.calcFruitValue(name, tool:GetAttribute("SizeMultiplier") or 1, mut, tool:GetAttribute("DecayAlpha") or 0)
        return val <= valueBelow
    end
    if not msMatch(cfg.selSellFruit, name) then return false end
    if not msMatch(cfg.selSellRarity, (AutoSellController.SEED_RARITY or {})[name] or "Common") then return false end
    if not msMutMatch(cfg.selSellMut, mut) then return false end
    if cfg.selSellThresh ~= "" then
        if not w then return false end
        if cfg.selSellThresh == "Above" and w < cfg.sellWeightThresh then return false end
        if cfg.selSellThresh == "Below" and w > cfg.sellWeightThresh then return false end
    end
    return true
end

local function getBackpackFruits()
    local fruits = {}
    local player = AutoSellController.LocalPlayer
    local bp = player and player:FindFirstChild("Backpack")
    if not bp then return fruits end
    for _, t in pairs(bp:GetChildren()) do
        if t:GetAttribute("HarvestedFruit") and t:GetAttribute("Id") then
            table.insert(fruits, t)
        end
    end
    return fruits
end

local function backpackFruitCountAtLeast(limit)
    local player = AutoSellController.LocalPlayer
    local bp = player and player:FindFirstChild("Backpack")
    if not bp then return false end
    local count = 0
    for _, t in pairs(bp:GetChildren()) do
        if t:GetAttribute("HarvestedFruit") and t:GetAttribute("Id") then
            count += 1
            if count >= limit then return true end
        end
    end
    return false
end

function AutoSellController.init(deps)
    deps = deps or {}
    AutoSellController.Logger = deps.Logger
    AutoSellController.Cfg = deps.Cfg or {}
    AutoSellController.Networking = deps.Networking
    AutoSellController.LocalPlayer = deps.LocalPlayer
    AutoSellController.calcFruitValue = deps.calcFruitValue
    AutoSellController.SEED_RARITY = deps.SEED_RARITY or {}
    AutoSellController.SpeedLibrary = deps.SpeedLibrary
    AutoSellController.FeatureRegistry = deps.FeatureRegistry
    if AutoSellController.FeatureRegistry then
        AutoSellController.FeatureRegistry.set("AutoSell", "modular")
    end
    return AutoSellController
end

function AutoSellController.tick()
    local cfg = AutoSellController.Cfg or {}
    local net = AutoSellController.Networking
    if not net or not net.NPCS then return false, "missing_networking" end
    if not (cfg.autoSellAll or cfg.autoSellFruit or cfg.autoSellPets) then return true end
    if cfg.sellIfFull and not backpackFruitCountAtLeast(5) then return true end

    local sellDelay = math.max(tonumber(cfg.sellDelay) or 1, 0.5)
    if cfg.autoSellAll and os.clock() - lastSellAllAt >= math.max(sellDelay, SELL_ALL_MIN_COOLDOWN) then
        lastSellAllAt = os.clock()
        if cfg.sellBargain and net.NPCS.AskBidAll then net.NPCS.AskBidAll:Fire(); task.wait(0.2) end
        if cfg.sellDailyDeal and net.NPCS.CheckDailyDeal and net.NPCS.UseDailyDealAll then
            local deal = net.NPCS.CheckDailyDeal:Fire()
            if deal and deal.Active then net.NPCS.UseDailyDealAll:Fire() else net.NPCS.SellAll:Fire() end
        elseif net.NPCS.SellAll then
            net.NPCS.SellAll:Fire()
        end
    end

    if cfg.autoSellFruit and net.NPCS.SellFruit then
        local soldCount = 0
        for _, tool in pairs(getBackpackFruits()) do
            if passSellFruitFilter(tool) then
                net.NPCS.SellFruit:Fire(tool:GetAttribute("Id"))
                soldCount += 1
                if soldCount >= SELL_BATCH_LIMIT then break end
                if soldCount % 3 == 0 then task.wait(SELL_REMOTE_PAUSE) end
            end
        end
    end

    if cfg.autoSellPets and net.NPCS.SellPet and AutoSellController.LocalPlayer and AutoSellController.LocalPlayer:FindFirstChild("Backpack") then
        local soldCount = 0
        for _, tool in pairs(AutoSellController.LocalPlayer.Backpack:GetChildren()) do
            local petId = tool:GetAttribute("PetId")
            if petId then
                local petName = tool:GetAttribute("Pet") or ""
                local petSize = tool:GetAttribute("PetSize") or ""
                local petRarity = PET_RARITY_SELL[petName] or "Common"
                local pass = msMatch(cfg.selSellPet, petName) and msMatch(cfg.selSellPetRarity, petRarity) and msMatch(cfg.selSellPetSize, petSize)
                if pass then
                    net.NPCS.SellPet:Fire(petId)
                    soldCount += 1
                    if soldCount >= SELL_BATCH_LIMIT then break end
                    if soldCount % 3 == 0 then task.wait(SELL_REMOTE_PAUSE) end
                end
            end
        end
    end
    return true
end

function AutoSellController.start()
    if running then return true end
    running = true
    task.spawn(function()
        while running do
            local cfg = AutoSellController.Cfg or {}
            task.wait(math.max(tonumber(cfg.sellDelay) or 1, 0.5))
            AutoSellController.tick()
        end
    end)
    return true
end

function AutoSellController.stop()
    running = false
    return true
end

return AutoSellController
