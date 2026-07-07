const fs = require('fs');
let src = fs.readFileSync('src/Controllers/ApsController.lua', 'utf8');
src = src.split('`r`n').join('\n');
fs.writeFileSync('src/Controllers/ApsController.lua', src, 'utf8');
console.log('Fixed ApsController.lua');
