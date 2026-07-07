-- GardenService.lua
-- Shared garden, readiness, threshold, and lightweight scan helpers.
-- Keep parity with current gag2.lua before production wiring.

local GardenService = {}

local function log(level, message, data)
    local logger = GardenService.Logger
    local fn = logger and logger[string.lower(level)]
    if type(fn) == "function" then
        fn("GardenService", message, data)
    elseif logger and type(logger.log) == "function" then
        logger.log(level, "GardenService", message, data)
    else
        print(string.format("[%s] [GardenService] %s %s", tostring(level), tostring(message), data ~= nil and tostring(data) or ""))
    end
end

function GardenService.init(deps)
    deps = deps or {}
    GardenService.Logger = deps.Logger
    GardenService.Cfg = deps.Cfg
    GardenService.LocalPlayer = deps.LocalPlayer
    GardenService.workspace = deps.workspace or workspace
    GardenService.Gardens = deps.Gardens or (GardenService.workspace and GardenService.workspace:FindFirstChild("Gardens"))
    GardenService.DISPLAY_KG_BASE = deps.DISPLAY_KG_BASE or {}
    return GardenService
end

function GardenService.thresholdPass(mode, threshold, kg)
    threshold = tonumber(threshold) or 0
    kg = tonumber(kg)
    if not kg then return false end
    if mode == "Below" then return kg <= threshold end
    return kg >= threshold
end

function GardenService.getMyPlot()
    local gardens = GardenService.Gardens or (GardenService.workspace and GardenService.workspace:FindFirstChild("Gardens"))
    local player = GardenService.LocalPlayer
    if not gardens or not player then return nil end
    local uid = player.UserId
    for _, plot in pairs(gardens:GetChildren()) do
        if plot:GetAttribute("OwnerUserId") == uid then return plot end
    end
    return nil
end

function GardenService.waitForMyPlot(timeout)
    local deadline = os.clock() + (tonumber(timeout) or 8)
    local plot = GardenService.getMyPlot()
    while not plot and os.clock() < deadline do
        task.wait(0.1)
        plot = GardenService.getMyPlot()
    end
    return plot
end

function GardenService.isFruitReady(fruit)
    if not fruit then return false, nil, nil end
    local age = tonumber(fruit:GetAttribute("Age"))
    local maxAge = tonumber(fruit:GetAttribute("MaxAge"))
    if not age or not maxAge then return false, age, maxAge end
    return age >= maxAge, age, maxAge
end

function GardenService.getSyncedPlantKg(plant)
    if not plant then return nil end
    if GardenService._gardenSyncController == false then return nil end
    if not GardenService._gardenSyncController then
        local ok, controller = pcall(function()
            local player = GardenService.LocalPlayer
            local ps = player and player:FindFirstChild("PlayerScripts")
            local controllers = ps and ps:FindFirstChild("Controllers")
            local mod = controllers and controllers:FindFirstChild("GardenSyncController")
            return mod and require(mod)
        end)
        GardenService._gardenSyncController = (ok and controller) or false
    end
    local controller = GardenService._gardenSyncController
    if type(controller) ~= "table" or type(controller.GetGarden) ~= "function" then return nil end

    local plantId = plant:GetAttribute("PlantId")
    if not plantId then return nil end

    local ok, garden = pcall(function()
        return controller:GetGarden(GardenService.LocalPlayer.UserId)
    end)
    if not ok or type(garden) ~= "table" then return nil end

    local data = garden[plantId]
    if type(data) ~= "table" then return nil end

    return tonumber(data.Weight) or tonumber(data.SizeMultiplier)
end

function GardenService.getGameFruitKg(fruit)
    if not fruit then return nil end
    if GardenService._fruitWeightController == false then return nil end
    if not GardenService._fruitWeightController then
        local ok, controller = pcall(function()
            local player = GardenService.LocalPlayer
            local ps = player and player:FindFirstChild("PlayerScripts")
            local controllers = ps and ps:FindFirstChild("Controllers")
            local mod = controllers and controllers:FindFirstChild("FruitVisualizerController")
            return mod and require(mod)
        end)
        GardenService._fruitWeightController = (ok and controller) or false
    end
    local controller = GardenService._fruitWeightController
    if type(controller) == "table" and type(controller.CalculateFruitWeight) == "function" then
        local ok, kg = pcall(function()
            return controller:CalculateFruitWeight(fruit)
        end)
        if ok then
            kg = tonumber(kg)
            if kg then return kg end
        end
    end
    return nil
end

function GardenService.getFruitDisplayKg(fruit, seedName)
    local gameKg = GardenService.getGameFruitKg(fruit)
    if gameKg then return gameKg end

    local sizeMulti = tonumber(fruit and (fruit:GetAttribute("SizeMulti") or fruit:GetAttribute("SizeMultiplier")))
    if not sizeMulti and fruit and fruit:GetAttribute("PlantId") and not fruit:GetAttribute("FruitId") then
        sizeMulti = GardenService.getSyncedPlantKg(fruit)
        if sizeMulti then return sizeMulti end
    end

    local baseName = (type(seedName) == "string" and seedName ~= "" and seedName) or (fruit and fruit:GetAttribute("CorePartName")) or ""
    local base = GardenService.DISPLAY_KG_BASE[baseName]
    if sizeMulti and base then return sizeMulti * base end

    if fruit then
        for _, d in ipairs(fruit:GetDescendants()) do
            if (d:IsA("TextLabel") or d:IsA("TextButton")) and type(d.Text) == "string" then
                local kgText = d.Text:match("([%d%.]+)%s*[kK][gG]")
                local kg = tonumber(kgText)
                if kg then return kg end
            end
        end
    end
    return nil
end

function GardenService.collectCurrentPlantIds(cropName)
    local ids = { _plants = {}, _fruits = {} }
    cropName = tostring(cropName or "")
    local plot = GardenService.getMyPlot()
    local plantsF = plot and plot:FindFirstChild("Plants")
    if not plantsF then return ids end

    for _, plant in pairs(plantsF:GetChildren()) do
        if plant:IsA("Model") and (cropName == "" or tostring(plant:GetAttribute("SeedName") or "") == cropName) then
            ids._plants[plant] = true
            local plantId = plant:GetAttribute("PlantId")
            if plantId then ids[tostring(plantId)] = true end
            local fruitsF = plant:FindFirstChild("Fruits")
            if fruitsF then
                for _, fruit in pairs(fruitsF:GetChildren()) do
                    ids._fruits[fruit] = true
                    local fruitId = fruit:GetAttribute("FruitId")
                    if fruitId then ids["fruit:" .. tostring(fruitId)] = true end
                end
            end
        end
    end
    return ids
end

function GardenService.scanCropForThreshold(cropName, threshold, mode, ignoredPlantIds, seen, minPlantedAt)
    cropName = tostring(cropName or "")
    local plot = GardenService.getMyPlot()
    local plantsF = plot and plot:FindFirstChild("Plants")
    if cropName == "" or not plantsF then return nil end

    for _, plant in pairs(plantsF:GetChildren()) do
        local plantId = plant:GetAttribute("PlantId")
        local plantIgnored = ignoredPlantIds and ((ignoredPlantIds._plants and ignoredPlantIds._plants[plant]) or (plantId and ignoredPlantIds[tostring(plantId)]))
        if plant:IsA("Model") and tostring(plant:GetAttribute("SeedName") or "") == cropName then
            local seedName = plant:GetAttribute("SeedName") or ""
            local plantedAt = tonumber(plant:GetAttribute("PlantedAt"))
            local plantedAfterStart = not minPlantedAt or (plantedAt and plantedAt >= (tonumber(minPlantedAt) or 0) - 2)
            local fruitsF = plant:FindFirstChild("Fruits")

            if fruitsF then
                for _, fruit in pairs(fruitsF:GetChildren()) do
                    local fruitId = fruit:GetAttribute("FruitId")
                    local ready = GardenService.isFruitReady(fruit)
                    local fruitIgnored = ignoredPlantIds and ((ignoredPlantIds._fruits and ignoredPlantIds._fruits[fruit]) or (fruitId and ignoredPlantIds["fruit:" .. tostring(fruitId)]))
                    if ready and not fruitIgnored then
                        local kg = GardenService.getFruitDisplayKg(fruit, seedName)
                        local pass = GardenService.thresholdPass(mode, threshold, kg)
                        local key = tostring(plantId or plant:GetFullName()) .. ":" .. tostring(fruitId or fruit:GetFullName())
                        if seen and not seen[key] then
                            seen[key] = { pass = pass, kg = kg, type = "multi", plantId = plantId, fruitId = fruitId }
                        end
                        if pass then
                            local mut = tostring(fruit:GetAttribute("Mutation") or "")
                            return { type = "multi", plant = plant, fruit = fruit, plantId = plantId, fruitId = fruitId, mutation = mut == "" and "None" or mut, kg = kg, ready = true }
                        end
                    end
                end
            elseif not plantIgnored and plantedAfterStart and GardenService.isFruitReady(plant) then
                local kg = GardenService.getFruitDisplayKg(plant, seedName)
                local pass = GardenService.thresholdPass(mode, threshold, kg)
                local key = tostring(plantId or plant:GetFullName()) .. ":single"
                if seen and not seen[key] then
                    seen[key] = { pass = pass, kg = kg, type = "single", plantId = plantId, fruitId = nil }
                end
                if pass then
                    local mut = tostring(plant:GetAttribute("Mutation") or "")
                    return { type = "single", plant = plant, fruit = plant, plantId = plantId, fruitId = "", mutation = mut == "" and "None" or mut, kg = kg, ready = true }
                end
            end
        end
    end
    return nil
end

return GardenService
