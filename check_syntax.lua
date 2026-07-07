local chunk, err = loadfile("releases/main.lua")
if not chunk then
    print("MAIN SYNTAX ERROR:", err)
else
    print("MAIN COMPILED SUCCESSFULLY")
end

local chunk2, err2 = loadfile("gag2_modular_bundled.lua")
if not chunk2 then
    print("BUNDLE SYNTAX ERROR:", err2)
else
    print("BUNDLE COMPILED SUCCESSFULLY")
end
