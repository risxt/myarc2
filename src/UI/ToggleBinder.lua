-- ToggleBinder.lua
-- Standardizes UI toggle callbacks to controller methods.

local ToggleBinder = {}

function ToggleBinder.init(deps)
    deps = deps or {}
    ToggleBinder.Logger = deps.Logger
    ToggleBinder.ConfigService = deps.ConfigService
    return ToggleBinder
end

function ToggleBinder.bind(config)
    config = config or {}
    local cfg = ToggleBinder.ConfigService and ToggleBinder.ConfigService.getCfg and ToggleBinder.ConfigService.getCfg()
    return function(value)
        if cfg and config.configKey then
            cfg[config.configKey] = value
            if ToggleBinder.ConfigService and ToggleBinder.ConfigService.saveNow then
                ToggleBinder.ConfigService.saveNow()
            end
        end
        if value and type(config.onEnable) == "function" then
            return config.onEnable(value)
        elseif not value and type(config.onDisable) == "function" then
            return config.onDisable(value)
        elseif type(config.onChange) == "function" then
            return config.onChange(value)
        end
    end
end

return ToggleBinder
