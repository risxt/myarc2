-- MonolithBridge.lua
-- Temporary bridge while migrating from gag2.live.lua to fully modular services.
-- Owns fallback execution and exposes honest migration metadata.

local MonolithBridge = {}

function MonolithBridge.init(deps)
    deps = deps or {}
    MonolithBridge.Logger = deps.Logger
    MonolithBridge.ModuleLoader = deps.ModuleLoader
    MonolithBridge.fallbackPath = deps.fallbackPath or "releases/gag2.live.lua"
    MonolithBridge.enabled = deps.enabled ~= false
    MonolithBridge.loaded = false
    return MonolithBridge
end

function MonolithBridge.runFallback()
    if not MonolithBridge.enabled then
        return false, "fallback_disabled"
    end
    local loader = MonolithBridge.ModuleLoader
    if not loader or type(loader.fetch) ~= "function" then
        return false, "missing_loader"
    end
    local source = loader.fetch(MonolithBridge.fallbackPath)
    local fn, err = loadstring(source)
    if not fn then return false, err end
    local ok, runErr = pcall(fn)
    MonolithBridge.loaded = ok
    return ok, runErr
end

function MonolithBridge.status()
    return {
        enabled = MonolithBridge.enabled,
        loaded = MonolithBridge.loaded,
        fallbackPath = MonolithBridge.fallbackPath,
    }
end

return MonolithBridge
