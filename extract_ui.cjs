const fs = require('fs');
const src = fs.readFileSync('C:/Users/faris/OneDrive/Desktop/gag/gag2.lua', 'utf8');
const uiIdx = src.indexOf('-- ==================== UI ====================');
if (uiIdx > -1) {
    let uiCode = src.substring(uiIdx);
    
    // Comment out maclib window creation since it is injected
    uiCode = uiCode.replace(/local Window = maclib:Window\([^\)]+\)/g, '-- Window provided by deps');
    uiCode = uiCode.replace(/local maclib = .*/g, '-- maclib provided by deps');
    
    const header = `-- MonolithUI.lua
-- Extracted UI tab definitions from gag2.lua for GAG2 modular injection.
local MonolithUI = {}
function MonolithUI.init(deps)
    local Window = deps.Window
    local Cfg = deps.Cfg
    local UIRegistry = deps.UIRegistry
    local ToggleBinder = deps.ToggleBinder
    local maclib = deps.maclib
    
    if not Window then return end
    
    local _G = getfenv(0)
    _G.Cfg = Cfg
    
`;
    
    const footer = `
    return true
end
return MonolithUI
`;

    fs.writeFileSync('C:/Users/faris/OneDrive/Desktop/gag/GAG2/src/UI/MonolithUI.lua', header + uiCode + footer, 'utf8');
    console.log('UI extracted successfully.');
} else {
    console.log('UI section not found.');
}
