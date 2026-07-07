-- RuntimeDiagnostics.lua
-- Lightweight diagnostics for loaded modular runtime.
local RuntimeDiagnostics = {}
function RuntimeDiagnostics.init(deps)
    deps = deps or {}
    RuntimeDiagnostics.Logger = deps.Logger
    RuntimeDiagnostics.GAG2 = deps.GAG2
    return RuntimeDiagnostics
end
function RuntimeDiagnostics.snapshot()
    local g = RuntimeDiagnostics.GAG2 or _G.GAG2 or {}
    local registry = g.FeatureRegistry
    local bridge = g.MonolithBridge
    return {
        modularLive = g.ModularLive == true,
        fullyMigrated = g.FullyMigrated == true,
        migrationPercent = g.MigrationPercent or 0,
        features = registry and registry.Features or {},
        fallback = bridge and bridge.status and bridge.status() or nil,
    }
end
return RuntimeDiagnostics
