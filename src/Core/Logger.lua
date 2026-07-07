-- Logger.lua
-- Lightweight logger skeleton for GAG2 modules.

local Logger = {}

function Logger.log(level, module, message, data)
    local line = string.format("[%s] [%s] %s", tostring(level), tostring(module), tostring(message))
    if data ~= nil then line ..= " | " .. tostring(data) end
    print(line)
end

function Logger.info(module, message, data) Logger.log("INFO", module, message, data) end
function Logger.warn(module, message, data) Logger.log("WARN", module, message, data) end
function Logger.error(module, message, data) Logger.log("ERROR", module, message, data) end
function Logger.safety(module, message, data) Logger.log("SAFETY", module, message, data) end

return Logger
