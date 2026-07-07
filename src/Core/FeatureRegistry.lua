-- FeatureRegistry.lua
-- Tracks feature migration status at runtime.

local FeatureRegistry = {}

FeatureRegistry.Features = {
    CoreRuntime = "modular",
    Config = "modular",
    APS = "modular",
    UI = "modular",
    AutoCollect = "monolith",
    AutoSell = "monolith",
    AutoShop = "monolith",
    Pets = "monolith",
    Mail = "monolith",
    Sprinkler = "modular",
    Tools = "monolith",
    ESP = "monolith",
    Weather = "monolith",
    Overlays = "modular",
    StackFarm = "modular",
    Steal = "modular",
    LocalPlayer = "modular",
    Misc = "modular",
}

function FeatureRegistry.init(deps)
    deps = deps or {}
    FeatureRegistry.Logger = deps.Logger
    return FeatureRegistry
end

function FeatureRegistry.set(name, status)
    FeatureRegistry.Features[name] = status
end

function FeatureRegistry.summary()
    local counts = { modular = 0, partial = 0, monolith = 0 }
    for _, status in pairs(FeatureRegistry.Features) do
        counts[status] = (counts[status] or 0) + 1
    end
    return counts
end

function FeatureRegistry.percent()
    local total, score = 0, 0
    for _, status in pairs(FeatureRegistry.Features) do
        total += 1
        if status == "modular" then score += 1
        elseif status == "partial" then score += 0.5 end
    end
    if total == 0 then return 0 end
    return math.floor((score / total) * 100 + 0.5)
end

return FeatureRegistry


