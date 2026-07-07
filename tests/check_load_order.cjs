const fs = require('fs');
const path = require('path');
const root = path.join(process.cwd(), 'GAG2');
const files = [
  'src/loader.local.lua',
  'src/Core/Logger.lua',
  'src/Core/ApsState.lua',
  'src/Core/ConfigService.lua',
  'src/Services/GardenService.lua',
  'src/Services/ApsSafetyService.lua',
  'src/Services/WebhookService.lua',
  'src/Controllers/ApsController.lua',
];
let ok = true;
for (const rel of files) {
  const full = path.join(root, rel);
  if (!fs.existsSync(full)) {
    console.error('[MISSING]', rel);
    ok = false;
    continue;
  }
  const text = fs.readFileSync(full, 'utf8');
  if (!/return\s+\w+/m.test(text)) {
    console.error('[NO RETURN]', rel);
    ok = false;
  } else {
    console.log('[OK]', rel);
  }
}
process.exit(ok ? 0 : 1);
