-- ApsState.lua
-- Logical state model for APS lifecycle. Skeleton only; not production-wired yet.

local ApsState = {
    status = "IDLE",
    stopToken = false,
    cycleId = 0,
    manualOffAt = 0,
    lastResumeReason = "",
    busy = false,
}

function ApsState.newCycle(reason)
    ApsState.cycleId += 1
    ApsState.stopToken = false
    ApsState.busy = true
    ApsState.status = "RUNNING"
    ApsState.lastResumeReason = tostring(reason or "")
    return ApsState.cycleId
end

function ApsState.stop(reason)
    ApsState.stopToken = true
    ApsState.busy = false
    ApsState.status = tostring(reason or "STOPPED")
end

function ApsState.isStopped(cycleId)
    return ApsState.stopToken or (cycleId and cycleId ~= ApsState.cycleId)
end

return ApsState
