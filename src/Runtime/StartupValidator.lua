-- StartupValidator.lua
-- Validates that critical modular pieces are present before/after startup.

local StartupValidator = {}

function StartupValidator.init(deps)
    deps = deps or {}
    StartupValidator.Logger = deps.Logger
    StartupValidator.ModuleManifest = deps.ModuleManifest
    StartupValidator.ModuleLoader = deps.ModuleLoader
    return StartupValidator
end

function StartupValidator.validateManifestFetch()
    local manifest = StartupValidator.ModuleManifest
    local loader = StartupValidator.ModuleLoader
    if not manifest or type(manifest.all) ~= "function" then return false, "missing_manifest" end
    if not loader or type(loader.fetch) ~= "function" then return false, "missing_loader" end
    for _, path in ipairs(manifest.all()) do
        local ok, body = pcall(function() return loader.fetch(path) end)
        if not ok or type(body) ~= "string" or #body == 0 then
            return false, "missing_module:" .. tostring(path)
        end
    end
    return true
end

function StartupValidator.validateGAG2(g)
    g = g or _G.GAG2
    if type(g) ~= "table" then return false, "missing_GAG2" end
    local required = {
        "Logger", "ApsState", "ConfigService", "FeatureRegistry",
        "HttpRequestService", "RemoteService", "GardenService", "ApsSafetyService",
        "WebhookService", "ApsController", "MonolithBridge", "MigrationGuard",
    }
    for _, key in ipairs(required) do
        if not g[key] then return false, "missing_runtime_key:" .. key end
    end
    return true
end

return StartupValidator
