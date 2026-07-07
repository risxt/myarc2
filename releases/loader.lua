-- GAG2 Safe Modular Loader
-- Normal one-line entrypoint loader for releases/main.lua.

local URL = "https://raw.githubusercontent.com/risxt/myarc2/main/releases/main.lua"

local ok, source = pcall(function()
    return game:HttpGet(URL)
end)

if not ok then
    warn("[GAG2 Loader] HttpGet failed: " .. tostring(source))
    return
end

if type(source) ~= "string" or #source < 100 then
    warn("[GAG2 Loader] Bad response. Length: " .. tostring(source and #source or "nil"))
    warn("[GAG2 Loader] First 300 chars: " .. tostring(source and source:sub(1, 300) or "nil"))
    return
end

local fn, compileErr = loadstring(source)
if not fn then
    warn("[GAG2 Loader] Compile error in releases/main.lua: " .. tostring(compileErr))
    warn("[GAG2 Loader] First 300 chars: " .. source:sub(1, 300))
    return
end

print("[GAG2 Loader] Loaded modular main.lua (" .. #source .. " bytes). Executing...")

local runOk, runtimeErr = pcall(fn)
if not runOk then
    warn("[GAG2 Loader] Runtime error in modular main.lua: " .. tostring(runtimeErr))
end
