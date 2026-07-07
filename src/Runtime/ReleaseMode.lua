-- ReleaseMode.lua
-- Controls whether GAG2 runs hybrid fallback or pure modular mode.

local ReleaseMode = {}

ReleaseMode.Modes = {
    HYBRID = "hybrid",
    MODULAR_ONLY = "modular_only",
}

ReleaseMode.current = ReleaseMode.Modes.HYBRID

function ReleaseMode.init(deps)
    deps = deps or {}
    ReleaseMode.Logger = deps.Logger
    ReleaseMode.FeatureRegistry = deps.FeatureRegistry
    ReleaseMode.MigrationGuard = deps.MigrationGuard
    ReleaseMode.current = deps.mode or ReleaseMode.current
    return ReleaseMode
end

function ReleaseMode.set(mode)
    if mode ~= ReleaseMode.Modes.HYBRID and mode ~= ReleaseMode.Modes.MODULAR_ONLY then
        return false, "invalid_mode"
    end
    if mode == ReleaseMode.Modes.MODULAR_ONLY then
        local guard = ReleaseMode.MigrationGuard
        if guard and guard.assertCanRemoveFallback then
            local ok, err = guard.assertCanRemoveFallback()
            if not ok then return false, err end
        end
    end
    ReleaseMode.current = mode
    return true
end

function ReleaseMode.isHybrid()
    return ReleaseMode.current == ReleaseMode.Modes.HYBRID
end

function ReleaseMode.isModularOnly()
    return ReleaseMode.current == ReleaseMode.Modes.MODULAR_ONLY
end

return ReleaseMode
