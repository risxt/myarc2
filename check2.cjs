const fs = require('fs');
const main = fs.readFileSync('releases/main.lua', 'utf8');
const aps = fs.readFileSync('src/Controllers/ApsController.lua', 'utf8');
if (main.includes('`r`n')) console.log('main HAS BACKTICK ERROR');
if (aps.includes('`r`n')) console.log('aps HAS BACKTICK ERROR');
console.log('check done');
