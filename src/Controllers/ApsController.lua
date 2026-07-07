-- ApsController.lua
-- APS controller module. Branch-by-branch extraction target; not production-wired yet.

local ApsController = {}

local function log(level, message, data)
    local logger = ApsController.Logger
    local fn = logger and logger[string.lower(level)]
    if type(fn) == "function" then
        fn("ApsController", message, data)
    elseif logger and type(logger.log) == "function" then
        logger.log(level, "ApsController", message, data)
    else
        print(string.format("[%s] [ApsController] %s %s", tostring(level), tostring(message), data ~= nil and tostring(data) or ""))
    end
end

local function saveNow()
    local service = ApsController.ConfigService
    if service and type(service.saveNow) == "function" then
        return service.saveNow()
    end
    return false
end

local function isStopped(cycleId)
    local state = ApsController.ApsState
    if not state then return true end
    if type(state.isStopped) == "function" then return state.isStopped(cycleId) end
    return state.stopToken == true
end

function ApsController.init(deps)
    deps = deps or {}
    ApsController.Logger = deps.Logger
    ApsController.Cfg = deps.Cfg
    ApsController.ConfigService = deps.ConfigService
    ApsController.ApsState = deps.ApsState
    ApsController.GardenService = deps.GardenService
    ApsController.ApsSafetyService = deps.ApsSafetyService
    ApsController.WebhookService = deps.WebhookService
    ApsController.PlantingService = deps.PlantingService
    ApsController.SprinklerService = deps.SprinklerService
    ApsController.PositionService = deps.PositionService
    ApsController.setStatus = deps.setStatus
    if deps.FeatureRegistry then deps.FeatureRegistry.set("APS", "modular") end
    return ApsController
end

function ApsController.status(message)
    if type(ApsController.setStatus) == "function" then
        ApsController.setStatus(message)
    end
    log("INFO", "status", message)
end

function ApsController.start(reason)
    local state = ApsController.ApsState
    if not state then return nil, "missing_state" end
    local cycleId = state.newCycle(reason)
    local cfg = ApsController.Cfg
    if cfg then
        cfg.autoPlantScan = true
        if reason == "resume" or reason == "fail_rejoin" then
            cfg.apsResume = true
        end
    end
    log("INFO", "start", "cycleId=" .. tostring(cycleId) .. " reason=" .. tostring(reason))
    return cycleId
end

function ApsController.manualStop(reason)
    local cfg = ApsController.Cfg
    local state = ApsController.ApsState
    if state then
        state.manualOffAt = os.clock()
        state.stop(tostring(reason or "MANUAL_OFF"))
    end
    if cfg then
        cfg.autoPlantScan = false
        cfg.apsResume = false
    end
    saveNow()
    log("INFO", "manual_stop", tostring(reason or "MANUAL_OFF"))
end

function ApsController.prepareEnvironment(cycleId)
    if isStopped(cycleId) then return false, "stopped" end
    local cfg = ApsController.Cfg
    local garden = ApsController.GardenService
    local position = ApsController.PositionService

    local plot = garden and garden.waitForMyPlot and garden.waitForMyPlot(10)
    if isStopped(cycleId) then return false, "stopped_after_plot_wait" end
    if not plot then return false, "plot_missing" end

    local pos, posReason
    if position and type(position.getSavedSprinklerVector) == "function" then
        pos, posReason = position.getSavedSprinklerVector(plot)
    end
    if not pos then
        return false, posReason or "saved_position_missing"
    end

    if cfg then
        cfg.disableTp = true
        cfg.disablePlantTp = true
        cfg.autoTpToSprinkler = false
        cfg.sprinklerPlaceMode = "Saved Position"
    end

    return true, { plot = plot, pos = pos }
end

function ApsController.placeSprinkler(cycleId, pos)
    if isStopped(cycleId) then return false, "stopped" end
    local sprinkler = ApsController.SprinklerService
    local cfg = ApsController.Cfg
    if not sprinkler or type(sprinkler.placeOneSprinklerAt) ~= "function" then
        return false, "sprinkler_service_missing"
    end
    return sprinkler.placeOneSprinklerAt(pos, cfg and cfg.apsSprinkler), "place_attempted"
end

function ApsController.plantBatch(cycleId, pos)
    if isStopped(cycleId) then return 0, "stopped" end
    local planting = ApsController.PlantingService
    local cfg = ApsController.Cfg
    if not planting or type(planting.plantSeedBatchAt) ~= "function" then
        return 0, "planting_service_missing"
    end
    local plantAmount = math.max(1, math.floor(tonumber(cfg and cfg.apsPlantAmount) or 24))
    local planted = planting.plantSeedBatchAt(pos, cfg and cfg.apsSeedName, plantAmount, cfg and cfg.apsSprinkler)
    return tonumber(planted) or 0, plantAmount
end

function ApsController.scanForTarget(cycleId, ignoredPlantIds, batchStartedAt)
    local cfg = ApsController.Cfg
    local garden = ApsController.GardenService
    if not garden or type(garden.scanCropForThreshold) ~= "function" then
        return nil, {}, "garden_scan_missing"
    end

    local found = nil
    local seen = {}
    local scanSeconds = math.max(8, tonumber(cfg and cfg.apsScanWindow) or 0.75)
    local scanDeadline = os.clock() + scanSeconds
    log("INFO", "scan_start", "seconds=" .. tostring(scanSeconds))

    repeat
        if isStopped(cycleId) then return nil, seen, "stopped_during_scan" end
        found = garden.scanCropForThreshold(cfg.apsCropName, cfg.apsWeightThresh, cfg.apsThreshMode, ignoredPlantIds, seen, batchStartedAt)
        if found then break end
        task.wait(0.05)
    until os.clock() >= scanDeadline

    if not found and not isStopped(cycleId) and not next(seen) then
        local extraDeadline = os.clock() + 12
        log("INFO", "scan_no_candidate_grace", "extra=12")
        repeat
            if isStopped(cycleId) then return nil, seen, "stopped_during_grace" end
            found = garden.scanCropForThreshold(cfg.apsCropName, cfg.apsWeightThresh, cfg.apsThreshMode, ignoredPlantIds, seen, batchStartedAt)
            if found then break end
            task.wait(0.10)
        until os.clock() >= extraDeadline or next(seen) ~= nil
    end

    return found, seen, found and "found" or "not_found"
end

function ApsController.handleSuccess(result)
    local cfg = ApsController.Cfg
    local state = ApsController.ApsState
    local safety = ApsController.ApsSafetyService
    local webhook = ApsController.WebhookService

    if safety and type(safety.fireCancelReverse) == "function" then
        safety.fireCancelReverse()
    end
    if cfg then
        cfg.autoPlantScan = false
        cfg.apsResume = false
    end
    if state then state.stop("SUCCESS") end
    saveNow()
    if webhook and type(webhook.sendApsSuccess) == "function" then
        webhook.sendApsSuccess(result)
    end
    log("INFO", "success", result and ("kg=" .. tostring(result.kg) .. " type=" .. tostring(result.type)) or "")
end

function ApsController.handleFailRejoin(reason)
    local cfg = ApsController.Cfg
    local safety = ApsController.ApsSafetyService
    if not safety or type(safety.safeRejoin) ~= "function" then
        log("SAFETY", "safe_rejoin_missing", tostring(reason))
        return false, "safe_rejoin_missing"
    end
    if cfg then
        cfg.autoPlantScan = true
        cfg.apsResume = true
    end
    return safety.safeRejoin({ reason = reason or "threshold_not_found" })
end

function ApsController.runCycle(cycleId)
    -- Port target for current worker. This stays disabled until production wiring.
    local cfg = ApsController.Cfg
    local garden = ApsController.GardenService
    if isStopped(cycleId) then return false, "stopped" end

    local ok, env = ApsController.prepareEnvironment(cycleId)
    if not ok then
        log("WARN", "prepare_failed", tostring(env))
        return false, env
    end

    local safety = ApsController.ApsSafetyService
    if safety and type(safety.fireReverseWithRetry) == "function" then
        local reverseOk = safety.fireReverseWithRetry(3)
        if not reverseOk then return false, "reverse_failed_before_sprinkler" end
    end

    local placed = ApsController.placeSprinkler(cycleId, env.pos)
    if not placed then
        if cfg then
            cfg.autoPlantScan = true
            cfg.apsResume = true
        end
        saveNow()
        return false, "sprinkler_place_failed"
    end

    task.wait(1)
    local ignored = garden.collectCurrentPlantIds(cfg.apsCropName)
    local batchStartedAt = math.floor((workspace.GetServerTimeNow and workspace:GetServerTimeNow()) or os.time())
    local planted, amount = ApsController.plantBatch(cycleId, env.pos)
    log("INFO", "plant_batch_done", "planted=" .. tostring(planted) .. " amount=" .. tostring(amount))
    if planted <= 0 then
        if cfg then
            cfg.autoPlantScan = false
            cfg.apsResume = false
        end
        if ApsController.ApsState then ApsController.ApsState.stop("NO_SEED_OR_POSITIONS") end
        saveNow()
        return false, "no_seed_or_positions"
    end

    local found = ApsController.scanForTarget(cycleId, ignored, batchStartedAt)
    if found then
        ApsController.handleSuccess(found)
        return true, "success"
    end

    if isStopped(cycleId) then
        if cfg then cfg.apsResume = false end
        saveNow()
        return false, "manual_stop_before_rejoin"
    end

    return ApsController.handleFailRejoin("threshold_not_found")
end

return ApsController

