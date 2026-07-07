const fs = require('fs');
const path = require('path');
const root = process.cwd();
const oldFile = path.join(root, 'gag2.lua');
const newGarden = path.join(root, 'GAG2/src/Services/GardenService.lua');
const newSafety = path.join(root, 'GAG2/src/Services/ApsSafetyService.lua');
const newWebhook = path.join(root, 'GAG2/src/Services/WebhookService.lua');
const old = fs.readFileSync(oldFile, 'utf8');
const garden = fs.readFileSync(newGarden, 'utf8');
const safety = fs.readFileSync(newSafety, 'utf8');
const webhook = fs.readFileSync(newWebhook, 'utf8');
const checks = [
  ['threshold Above >=', /return kg >= threshold/.test(old), /return kg >= threshold/.test(garden)],
  ['threshold Below <=', /return kg <= threshold/.test(old), /return kg <= threshold/.test(garden)],
  ['kg nil false', /if not kg then return false end/.test(old), /if not kg then return false end/.test(garden)],
  ['isFruitReady age maxAge', /Age/.test(old) && /MaxAge/.test(old), /Age/.test(garden) && /MaxAge/.test(garden)],
  ['old plant ids _plants', /_plants = \{\}/.test(old), /_plants = \{\}/.test(garden)],
  ['old fruit ids prefix', /"fruit:"/.test(old), /"fruit:"/.test(garden)],
  ['plantedAfterStart guard', /plantedAfterStart/.test(old), /plantedAfterStart/.test(garden)],
  ['multi scan type', /type = "multi"/.test(old), /type = "multi"/.test(garden)],
  ['single scan type', /type = "single"/.test(old), /type = "single"/.test(garden)],
  ['reverse constant', /":\\xF7"/.test(old), /":\\xF7"/.test(safety)],
  ['cancel empty', /FireServer\(54, ""\)/.test(old), /FireServer\(54, ""\)/.test(safety)],
  ['cancel space', /FireServer\(54, " "\)/.test(old), /FireServer\(54, " "\)/.test(safety)],
  ['cancel nil', /FireServer\(54, nil\)/.test(old), /FireServer\(54, nil\)/.test(safety)],
  ['webhook everyone', /content = "@everyone"/.test(old), /content = "@everyone"/.test(webhook)],
  ['webhook green', /color = 5763719/.test(old), /color = 5763719/.test(webhook)],
  ['webhook title', /Auto-Plant — Target Hit/.test(old), /Auto-Plant — Target Hit/.test(webhook)],
];
let md = '# Parity Static Check Report\n\n| Check | Old gag2.lua | GAG2 Module | Result |\n|---|---:|---:|---|\n';
let pass = true;
for (const [name, oldOk, newOk] of checks) {
  const ok = oldOk && newOk;
  if (!ok) pass = false;
  md += `| ${name} | ${oldOk ? 'yes' : 'no'} | ${newOk ? 'yes' : 'no'} | ${ok ? 'PASS' : 'REVIEW'} |\n`;
}
md += `\n## Overall\n\n${pass ? 'PASS' : 'REVIEW REQUIRED'}\n`;
fs.writeFileSync(path.join(root, 'GAG2/tests/parity_static_check.md'), md, 'utf8');
console.log(md);
process.exit(pass ? 0 : 1);
