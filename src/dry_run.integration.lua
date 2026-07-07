-- dry_run.integration.lua
-- Dry-run integration harness for GAG2 modules.
-- Purpose: load/init modules and validate dependency shape without replacing old APS.

local DryRun = {}

function DryRun.validate(modules)
    local required = {
        "Logger",
        "ApsState",
        "ConfigService",
        "GardenService",
        "ApsSafetyService",
        "WebhookService",
        "ApsController",
    }
    for _, name in ipairs(required) do
        if not modules or not modules[name] then
            return false, "missing_" .. name
        end
    end
    return true
end

function DryRun.report(modules)
    local ok, reason = DryRun.validate(modules)
    local lines = {
        "[GAG2 DryRun] module validation: " .. tostring(ok),
        "[GAG2 DryRun] reason: " .. tostring(reason or "ok"),
        "[GAG2 DryRun] old APS remains active; new APS is not started",
    }
    for _, line in ipairs(lines) do print(line) end
    return ok, reason
end

return DryRun
