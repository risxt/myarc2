const fs = require('fs');
let src = fs.readFileSync('releases/main.lua', 'utf8');

src = src.replace(/local maclib = nil\r?\npcall\(function\(\)\r?\n\s*maclib = loadstring\(game:HttpGet\("https:\/\/raw\.githubusercontent\.com\/mac2115\/maclib\/main\/maclib\.lua"\)\)\(\)\r?\nend\)\r?\n/g, '');

fs.writeFileSync('releases/main.lua', src, 'utf8');
console.log('Fixed main.lua');
