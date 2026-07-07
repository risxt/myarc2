-- GAG2 Safe Loader
-- Fetches gag2.live.lua from GitHub with error handling

local URL = "https://raw.githubusercontent.com/risxt/myarc2/main/releases/gag2.live.lua"

local ok, source = pcall(function()
    return game:HttpGet(URL)
end)

if not ok then
    warn("[GAG2 Loader] HttpGet failed: " .. tostring(source))
    return
end

if type(source) ~= "string" or #source < 100 then
    warn("[GAG2 Loader] Bad response. Length: " .. tostring(source and #source or "nil"))
    warn("[GAG2 Loader] First 200 chars: " .. tostring(source and source:sub(1, 200) or "nil"))
    return
end

local fn, err = loadstring(source)
if not fn then
    warn("[GAG2 Loader] Compile error: " .. tostring(err))
    return
end

print("[GAG2 Loader] Loaded " .. #source .. " bytes. Executing...")
fn()
