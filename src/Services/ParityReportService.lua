-- ParityReportService.lua
-- Runtime-readable migration/parity report generator.

local ParityReportService = {}

function ParityReportService.init(deps)
    deps = deps or {}
    ParityReportService.FeatureRegistry = deps.FeatureRegistry
    ParityReportService.FeatureParityChecklist = deps.FeatureParityChecklist
    ParityReportService.MigrationGuard = deps.MigrationGuard
    return ParityReportService
end

function ParityReportService.build()
    local registry = ParityReportService.FeatureRegistry
    local checklist = ParityReportService.FeatureParityChecklist
    local guard = ParityReportService.MigrationGuard
    return {
        percent = guard and guard.percent and guard.percent() or 0,
        fullyMigrated = guard and guard.isFullyMigrated and guard.isFullyMigrated() or false,
        features = registry and registry.Features or {},
        checklistCount = checklist and checklist.count and checklist.count() or 0,
    }
end

return ParityReportService
