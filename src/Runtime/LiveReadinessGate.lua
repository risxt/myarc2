-- LiveReadinessGate.lua
-- Hard gate before claiming production modular completion.

local LiveReadinessGate = {}

function LiveReadinessGate.init(deps)
    deps = deps or {}
    LiveReadinessGate.StartupValidator = deps.StartupValidator
    LiveReadinessGate.MigrationGuard = deps.MigrationGuard
    LiveReadinessGate.ParityReportService = deps.ParityReportService
    LiveReadinessGate.ReleaseMode = deps.ReleaseMode
    return LiveReadinessGate
end

function LiveReadinessGate.check(g)
    local startup = LiveReadinessGate.StartupValidator
    if startup and startup.validateGAG2 then
        local ok, err = startup.validateGAG2(g)
        if not ok then return false, err end
    end

    local report = LiveReadinessGate.ParityReportService and LiveReadinessGate.ParityReportService.build and LiveReadinessGate.ParityReportService.build() or {}
    if report.fullyMigrated ~= true then
        return false, "not_fully_migrated"
    end

    local mode = LiveReadinessGate.ReleaseMode
    if mode and mode.isHybrid and mode.isHybrid() then
        return false, "fallback_still_enabled"
    end

    return true
end

return LiveReadinessGate
