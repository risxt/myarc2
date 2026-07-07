-- ModuleLoader.lua
-- Real GitHub module loader for GAG2 modular entrypoint.

local ModuleLoader = {}

ModuleLoader.BaseUrl = "https://raw.githubusercontent.com/risxt/myarc2/main/"
ModuleLoader.CachePrefix = "GAG2_cache_"
ModuleLoader.UseCache = true

local function cacheName(path)
    return ModuleLoader.CachePrefix .. path:gsub("[^%w_%-%.]", "_")
end

function ModuleLoader.fetch(path)
    local url = ModuleLoader.BaseUrl .. path
    local ok, body = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and type(body) == "string" and #body > 0 then
        if ModuleLoader.UseCache and type(writefile) == "function" then
            pcall(writefile, cacheName(path), body)
        end
        return body
    end

    if ModuleLoader.UseCache and type(isfile) == "function" and type(readfile) == "function" then
        local c = cacheName(path)
        if isfile(c) then
            local readOk, cached = pcall(readfile, c)
            if readOk and type(cached) == "string" and #cached > 0 then
                return cached
            end
        end
    end

    error("GAG2 failed to fetch module: " .. tostring(path))
end

function ModuleLoader.load(path)
    local source = ModuleLoader.fetch(path)
    local fn, err = loadstring(source)
    if not fn then error("GAG2 compile failed for " .. tostring(path) .. ": " .. tostring(err)) end
    return fn()
end

return ModuleLoader
