-- RuntimeSelfTest.lua
-- Non-destructive runtime self-test for modular infrastructure.

local RuntimeSelfTest = {}

function RuntimeSelfTest.init(deps)
    deps = deps or {}
    RuntimeSelfTest.StartupValidator = deps.StartupValidator
    RuntimeSelfTest.ParityReportService = deps.ParityReportService
    RuntimeSelfTest.LiveReadinessGate = deps.LiveReadinessGate
    return RuntimeSelfTest
end

function RuntimeSelfTest.run(g)
    local results = {}
    local function add(name, ok, err)
        table.insert(results, { name = name, ok = ok == true, err = err })
    end

    if RuntimeSelfTest.StartupValidator then
        add("validateGAG2", RuntimeSelfTest.StartupValidator.validateGAG2(g))
    end
    if RuntimeSelfTest.ParityReportService then
        local ok, report = pcall(function() return RuntimeSelfTest.ParityReportService.build() end)
        add("parityReport", ok, ok and nil or report)
    end
    if RuntimeSelfTest.LiveReadinessGate then
        local ok, err = RuntimeSelfTest.LiveReadinessGate.check(g)
        add("liveReadiness", ok, err)
    end

    return results
end

return RuntimeSelfTest
