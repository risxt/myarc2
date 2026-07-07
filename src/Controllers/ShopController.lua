-- ShopController.lua
-- Modular Auto Shop controller ported from gag2.lua Auto Shop section.

local ShopController = {}
local running = false

local function cleanSelectionTable(selected)
    if type(selected) ~= "table" then return {} end
    local out = {}
    for k, v in pairs(selected) do
        if type(k) == "number" and type(v) == "string" and v ~= "" then table.insert(out, v) end
        if type(k) == "string" and v == true and k ~= "" then table.insert(out, k) end
    end
    return out
end

local function getStock(folder, name)
    if not folder or type(name) ~= "string" or name == "" then return 0 end
    local v = folder:FindFirstChild(name)
    return tonumber(v and v.Value) or 0
end

local function drainBuy(remote, folder, name)
    if not remote or type(remote.Fire) ~= "function" then return 0, "missing_remote" end
    local stock = math.clamp(getStock(folder, name), 0, 250)
    for _ = 1, stock do
        remote:Fire(name)
        task.wait(0.05)
    end
    return stock
end

local function drainBuyAll(remote, folder)
    if not folder then return 0 end
    local total = 0
    for _, v in pairs(folder:GetChildren()) do
        total += drainBuy(remote, folder, v.Name) or 0
        task.wait(0.05)
    end
    return total
end

local function drainBuySelected(remote, folder, selected)
    local total = 0
    for _, name in ipairs(cleanSelectionTable(selected)) do
        total += drainBuy(remote, folder, name) or 0
        task.wait(0.05)
    end
    return total
end

function ShopController.init(deps)
    deps = deps or {}
    ShopController.Logger = deps.Logger
    ShopController.Cfg = deps.Cfg or {}
    ShopController.Networking = deps.Networking
    ShopController.ReplicatedStorage = deps.ReplicatedStorage or (game and game:GetService("ReplicatedStorage"))
    ShopController.FeatureRegistry = deps.FeatureRegistry
    if ShopController.FeatureRegistry then ShopController.FeatureRegistry.set("AutoShop", "modular") end
    return ShopController
end

function ShopController.resolveStockFolders()
    local rs = ShopController.ReplicatedStorage
    local sv = rs and rs:FindFirstChild("StockValues")
    local seedItems = sv and sv:FindFirstChild("SeedShop")
    seedItems = seedItems and seedItems:FindFirstChild("Items")
    local gearItems = sv and sv:FindFirstChild("GearShop")
    gearItems = gearItems and gearItems:FindFirstChild("Items")
    local crateItems = sv and sv:FindFirstChild("CrateShop")
    crateItems = crateItems and crateItems:FindFirstChild("Items")
    return seedItems, gearItems, crateItems
end

function ShopController.auditSelection()
    local cfg = ShopController.Cfg or {}
    local seedItems, gearItems, crateItems = ShopController.resolveStockFolders()
    local result = { Seed = {}, Gear = {}, Crate = {} }
    for _, name in ipairs(cleanSelectionTable(cfg.selBuySeed)) do result.Seed[name] = getStock(seedItems, name) end
    for _, name in ipairs(cleanSelectionTable(cfg.selBuyGear)) do result.Gear[name] = getStock(gearItems, name) end
    for _, name in ipairs(cleanSelectionTable(cfg.selBuyCrate)) do result.Crate[name] = getStock(crateItems, name) end
    return result
end

function ShopController.tick()
    local cfg = ShopController.Cfg or {}
    local net = ShopController.Networking
    if not net then return false, "missing_networking" end
    local seedItems, gearItems, crateItems = ShopController.resolveStockFolders()
    if cfg.autoBuySeed and net.SeedShop and net.SeedShop.PurchaseSeed then drainBuySelected(net.SeedShop.PurchaseSeed, seedItems, cfg.selBuySeed) end
    if cfg.autoBuyAllSeeds and net.SeedShop and net.SeedShop.PurchaseSeed then drainBuyAll(net.SeedShop.PurchaseSeed, seedItems) end
    if cfg.autoBuyGear and net.GearShop and net.GearShop.PurchaseGear then drainBuySelected(net.GearShop.PurchaseGear, gearItems, cfg.selBuyGear) end
    if cfg.autoBuyAllGear and net.GearShop and net.GearShop.PurchaseGear then drainBuyAll(net.GearShop.PurchaseGear, gearItems) end
    if cfg.autoBuyCrate and net.CrateShop and net.CrateShop.PurchaseCrate then drainBuySelected(net.CrateShop.PurchaseCrate, crateItems, cfg.selBuyCrate) end
    if cfg.autoBuyAllCrates and net.CrateShop and net.CrateShop.PurchaseCrate then drainBuyAll(net.CrateShop.PurchaseCrate, crateItems) end
    return true
end

function ShopController.start()
    if running then return true end
    running = true
    task.spawn(function()
        while running do
            local cfg = ShopController.Cfg or {}
            task.wait(math.max(tonumber(cfg.buyShopDelay) or 1, 1))
            ShopController.tick()
        end
    end)
    return true
end

function ShopController.stop()
    running = false
    return true
end

return ShopController
