const fs = require('fs');
let src = fs.readFileSync('releases/main.lua', 'utf8');
src = src.split('`r`n').join('\n');
fs.writeFileSync('releases/main.lua', src, 'utf8');
console.log('Fixed main.lua');
