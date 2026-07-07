const fs = require('fs');

const src = fs.readFileSync('C:/Users/faris/OneDrive/Desktop/gag/gag2.lua', 'utf8');

const libStart = src.indexOf('local Speed_Library, Notification = {}, {}');
const libEnd = src.indexOf('\n-- ================================================================', libStart);

const uiStart = src.indexOf('-- ==================== UI ====================');

const libCode = src.substring(libStart, libEnd);
let uiCode = src.substring(uiStart);

const header = `-- MonolithUI.lua
-- Extracted UI library (Speed_Library) and definitions from gag2.lua for GAG2 modular injection.
local MonolithUI = {}

function MonolithUI.init(deps)
    local Cfg = deps.Cfg
    local UIRegistry = deps.UIRegistry
    local ToggleBinder = deps.ToggleBinder
    
    local _G = getfenv(0)
    _G.Cfg = Cfg
    _G.Menu = {
        ['Main'] = {
            ['Auto Hatch'] = false
        }
    } -- placeholder to prevent legacy errors
`;

const footer = `
    return true
end
return MonolithUI
`;

fs.writeFileSync('C:/Users/faris/OneDrive/Desktop/gag/GAG2/src/UI/MonolithUI.lua', header + '\n' + libCode + '\n' + uiCode + '\n' + footer, 'utf8');
console.log('Successfully regenerated MonolithUI.lua with Speed_Library included!');
