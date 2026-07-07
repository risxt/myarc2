-- ConfigService.lua
-- Skeleton wrapper for config reads/writes. Production wiring later.

local ConfigService = {}

function ConfigService.init(deps)
    ConfigService.Logger = deps.Logger
    ConfigService.Cfg = deps.Cfg
    ConfigService.saveNowImpl = deps.saveNow
    return ConfigService
end

function ConfigService.saveNow()
    if type(ConfigService.saveNowImpl) == "function" then
        return ConfigService.saveNowImpl()
    end
    if ConfigService.Logger then
        ConfigService.Logger.warn("ConfigService", "saveNow called before production wiring")
    end
    return false
end

return ConfigService
