-- ApsSafetyService.lua
-- APS safety module. Ported from gag2.lua safety behavior, but not production-wired yet.
-- Invariant: APS must never teleport/rejoin without reverse safety.

local ApsSafetyService = {}

local function log(level, message, data)
    local logger = ApsSafetyService.Logger
    local fn = logger and logger[string.lower(level)]
    if type(fn) == "function" then
        fn("ApsSafetyService", message, data)
    elseif logger and type(logger.log) == "function" then
        logger.log(level, "ApsSafetyService", message, data)
    else
        print(string.format("[%s] [ApsSafetyService] %s %s", tostring(level), tostring(message), data ~= nil and tostring(data) or ""))
    end
end

local function isStopped()
    local state = ApsSafetyService.ApsState
    local cfg = ApsSafetyService.Cfg
    if state and state.stopToken then return true end
    if cfg and cfg.autoPlantScan == false then return true end
    return false
end

local function getReverseRemote()
    if ApsSafetyService.ReverseRemote then return ApsSafetyService.ReverseRemote end
    local rs = ApsSafetyService.ReplicatedStorage or (game and game:GetService("ReplicatedStorage"))
    local shared = rs and rs:FindFirstChild("SharedModules")
    local packet = shared and shared:FindFirstChild("Packet")
    local remote = packet and packet:FindFirstChild("RemoteEvent")
    ApsSafetyService.ReverseRemote = remote
    return remote
end

function ApsSafetyService.init(deps)
    deps = deps or {}
    ApsSafetyService.Logger = deps.Logger
    ApsSafetyService.ApsState = deps.ApsState
    ApsSafetyService.Cfg = deps.Cfg
    ApsSafetyService.TeleportService = deps.TeleportService
    ApsSafetyService.LocalPlayer = deps.LocalPlayer
    ApsSafetyService.ReplicatedStorage = deps.ReplicatedStorage
    ApsSafetyService.ReverseRemote = deps.ReverseRemote
    ApsSafetyService.saveResume = deps.saveResume
    return ApsSafetyService
end

function ApsSafetyService.fireReverseOnce()
    log("INFO", "reverse_fire_start")
    local remote = getReverseRemote()
    if not remote then
        log("SAFETY", "reverse_fire_missing_remote")
        return false, "missing_remote"
    end

    local ok, err = pcall(function()
        for _ = 1, 3 do
            remote:FireServer(54, ":\xF7")
            task.wait(0.08)
        end
    end)
    log(ok and "INFO" or "SAFETY", "reverse_fire_done", "ok=" .. tostring(ok) .. " err=" .. tostring(err))
    return ok, err
end

function ApsSafetyService.fireReverseWithRetry(maxRetries)
    maxRetries = math.max(1, tonumber(maxRetries) or 3)
    for attempt = 1, maxRetries do
        if isStopped() then
            log("INFO", "reverse_aborted_stopped", "attempt=" .. tostring(attempt))
            return false, "stopped"
        end
        local ok, err = ApsSafetyService.fireReverseOnce()
        if ok then return true end
        log("WARN", "reverse_retry", "attempt=" .. tostring(attempt) .. " err=" .. tostring(err))
        task.wait(0.25)
    end
    log("SAFETY", "reverse_failed_all_retries", "maxRetries=" .. tostring(maxRetries))
    return false, "reverse_failed"
end

function ApsSafetyService.fireCancelReverse()
    log("INFO", "reverse_cancel_start")
    local remote = getReverseRemote()
    if not remote then
        log("WARN", "reverse_cancel_missing_remote")
        return false, "missing_remote"
    end

    local ok, err = pcall(function()
        for _ = 1, 2 do
            remote:FireServer(54, "")
            task.wait(0.05)
            remote:FireServer(54, " ")
            task.wait(0.05)
            remote:FireServer(54, nil)
            task.wait(0.05)
        end
    end)
    log(ok and "INFO" or "WARN", "reverse_cancel_done", "ok=" .. tostring(ok) .. " err=" .. tostring(err))
    return ok, err
end

function ApsSafetyService.safeRejoin(ctx)
    ctx = type(ctx) == "table" and ctx or {}
    local reason = tostring(ctx.reason or "aps_rejoin")
    log("INFO", "safe_rejoin_requested", reason)

    if isStopped() then
        log("INFO", "safe_rejoin_abort_before_reverse", "stopped=true")
        return false, "stopped_before_reverse"
    end

    local reverseOk, reverseErr = ApsSafetyService.fireReverseWithRetry(ctx.reverseRetries or 3)
    if not reverseOk then
        log("SAFETY", "safe_rejoin_abort_reverse_failed_before_save", tostring(reverseErr))
        return false, "reverse_failed_before_save"
    end

    if type(ApsSafetyService.saveResume) == "function" then
        local ok, err = pcall(ApsSafetyService.saveResume, reason)
        log(ok and "INFO" or "WARN", "safe_rejoin_save_resume", "ok=" .. tostring(ok) .. " err=" .. tostring(err))
    end

    local delaySeconds = math.max(7, tonumber(ctx.delay or (ApsSafetyService.Cfg and ApsSafetyService.Cfg.apsRejoinDelay)) or 7)
    log("INFO", "safe_rejoin_wait", "delay=" .. tostring(delaySeconds))
    task.wait(delaySeconds)

    if isStopped() then
        log("INFO", "safe_rejoin_abort_after_wait", "stopped=true")
        return false, "stopped_after_wait"
    end

    reverseOk, reverseErr = ApsSafetyService.fireReverseWithRetry(ctx.reverseRetries or 3)
    if not reverseOk then
        log("SAFETY", "safe_rejoin_abort_reverse_failed_before_teleport", tostring(reverseErr))
        return false, "reverse_failed_before_teleport"
    end

    task.wait(tonumber(ctx.preTeleportDelay) or 0.25)

    local tp = ApsSafetyService.TeleportService or (game and game:GetService("TeleportService"))
    local player = ApsSafetyService.LocalPlayer or (game and game:GetService("Players").LocalPlayer)
    if not tp or not player then
        log("SAFETY", "safe_rejoin_abort_missing_teleport_dependencies")
        return false, "missing_teleport_dependencies"
    end

    log("SAFETY", "teleport_attempt_after_reverse", reason)
    local ok, err = pcall(function()
        tp:Teleport(game.PlaceId, player)
    end)
    log(ok and "INFO" or "WARN", "teleport_returned", "ok=" .. tostring(ok) .. " err=" .. tostring(err))
    if ok then return true end

    task.wait(tonumber(ctx.retryDelay) or 3)
    if isStopped() then
        log("INFO", "safe_rejoin_retry_abort_stopped")
        return false, "stopped_before_retry"
    end

    reverseOk, reverseErr = ApsSafetyService.fireReverseWithRetry(ctx.reverseRetries or 3)
    if not reverseOk then
        log("SAFETY", "safe_rejoin_retry_abort_reverse_failed", tostring(reverseErr))
        return false, "reverse_failed_before_retry"
    end

    task.wait(tonumber(ctx.preTeleportDelay) or 0.25)
    log("SAFETY", "teleport_retry_after_reverse", reason)
    local retryOk, retryErr = pcall(function()
        tp:Teleport(game.PlaceId, player)
    end)
    log(retryOk and "INFO" or "WARN", "teleport_retry_returned", "ok=" .. tostring(retryOk) .. " err=" .. tostring(retryErr))
    return retryOk, retryErr
end

return ApsSafetyService
