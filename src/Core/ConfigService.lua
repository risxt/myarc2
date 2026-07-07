-- ConfigService.lua
-- Production-oriented config service skeleton for GAG2.
-- Still needs exact monolith key/default parity before replacing live config.

local ConfigService = {}

local function log(level, message, data)
    local logger = ConfigService.Logger
    local fn = logger and logger[string.lower(level)]
    if type(fn) == "function" then
        fn("ConfigService", message, data)
    elseif logger and type(logger.log) == "function" then
        logger.log(level, "ConfigService", message, data)
    else
        print(string.format("[%s] [ConfigService] %s %s", tostring(level), tostring(message), data ~= nil and tostring(data) or ""))
    end
end

function ConfigService.init(deps)
    deps = deps or {}
    ConfigService.Logger = deps.Logger
    ConfigService.Cfg = deps.Cfg or {}
    ConfigService.HttpService = deps.HttpService or (game and game:GetService("HttpService"))
    ConfigService.fileName = deps.fileName
    ConfigService.cfgReadyToSave = deps.cfgReadyToSave
    ConfigService.saveNowImpl = deps.saveNow
    return ConfigService
end

function ConfigService.getCfg()
    ConfigService.Cfg = ConfigService.Cfg or {}
    return ConfigService.Cfg
end

function ConfigService.set(key, value, opts)
    local cfg = ConfigService.getCfg()
    cfg[key] = value
    if not opts or opts.save ~= false then
        ConfigService.saveNow()
    end
    return value
end

function ConfigService.mergeDefaults(defaults)
    local cfg = ConfigService.getCfg()
    for k, v in pairs(defaults or {}) do
        if cfg[k] == nil then cfg[k] = v end
    end
    return cfg
end

function ConfigService.encode(data)
    local http = ConfigService.HttpService
    if not http then return nil, "missing_httpservice" end
    local ok, encoded = pcall(function()
        return http:JSONEncode(data)
    end)
    if not ok then return nil, encoded end
    return encoded
end

function ConfigService.decode(text)
    local http = ConfigService.HttpService
    if not http then return nil, "missing_httpservice" end
    local ok, decoded = pcall(function()
        return http:JSONDecode(text)
    end)
    if not ok then return nil, decoded end
    return decoded
end

function ConfigService.saveNow()
    if type(ConfigService.saveNowImpl) == "function" then
        return ConfigService.saveNowImpl()
    end

    local fileName = ConfigService.fileName
    if not fileName or type(writefile) ~= "function" then
        log("WARN", "save skipped; no file writer or fileName")
        return false
    end

    local body, err = ConfigService.encode(ConfigService.getCfg())
    if not body then
        log("WARN", "encode failed", tostring(err))
        return false
    end

    local ok, writeErr = pcall(function()
        if type(isfile) == "function" and type(readfile) == "function" and isfile(fileName) then
            local old = readfile(fileName)
            pcall(writefile, fileName .. ".bak", old)
        end
        writefile(fileName, body)
    end)
    log(ok and "INFO" or "WARN", "saveNow", tostring(writeErr))
    return ok
end

return ConfigService
