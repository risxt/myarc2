-- MigrationGuard.lua
-- Runtime guard to prevent false 100% migration claims.

local MigrationGuard = {}

function MigrationGuard.init(deps)
    deps = deps or {}
    MigrationGuard.FeatureRegistry = deps.FeatureRegistry
    MigrationGuard.MonolithBridge = deps.MonolithBridge
    MigrationGuard.Logger = deps.Logger
    return MigrationGuard
end

function MigrationGuard.isFullyMigrated()
    local bridge = MigrationGuard.MonolithBridge
    if bridge and bridge.enabled then return false end
    local registry = MigrationGuard.FeatureRegistry
    if not registry or not registry.Features then return false end
    for _, status in pairs(registry.Features) do
        if status ~= "modular" then return false end
    end
    return true
end

function MigrationGuard.percent()
    local registry = MigrationGuard.FeatureRegistry
    if registry and type(registry.percent) == "function" then
        return registry.percent()
    end
    return 0
end

function MigrationGuard.assertCanRemoveFallback()
    if not MigrationGuard.isFullyMigrated() then
        return false, "not_fully_migrated"
    end
    return true
end

return MigrationGuard
