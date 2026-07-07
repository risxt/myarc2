const fs = require('fs');
const path = require('path');
const root = path.join(process.cwd(), 'GAG2');
const files = [];
function walk(dir){ for(const e of fs.readdirSync(dir,{withFileTypes:true})){ const p=path.join(dir,e.name); if(e.isDirectory()) walk(p); else if(e.name.endsWith('.lua')) files.push(p); }}
walk(path.join(root,'src'));
let report = [];
let ok = true;
for (const file of files) {
  const rel = path.relative(root,file).replace(/\\/g,'/');
  const txt = fs.readFileSync(file,'utf8');
  const teleportRefs = [...txt.matchAll(/[:.]Teleport\s*\(/g)].length;
  const reverseConst = txt.includes('":\\xF7"') || txt.includes('":\\\\xF7"');
  const saveResumeTrue = [...txt.matchAll(/apsResume\s*=\s*true/g)].length;
  const saveResumeFalse = [...txt.matchAll(/apsResume\s*=\s*false/g)].length;
  report.push(`## ${rel}\n- teleport refs: ${teleportRefs}\n- reverse const: ${reverseConst}\n- apsResume=true refs: ${saveResumeTrue}\n- apsResume=false refs: ${saveResumeFalse}\n- returns module: ${/return\s+\w+/m.test(txt)}\n`);
  if (teleportRefs && !rel.includes('ApsSafetyService')) ok = false;
}
fs.writeFileSync(path.join(root,'tests','static_verification_report.md'), '# Static Verification Report\n\n' + report.join('\n') + `\n## Result\n\n${ok ? 'PASS' : 'FAIL'}\n`, 'utf8');
console.log(fs.readFileSync(path.join(root,'tests','static_verification_report.md'),'utf8'));
process.exit(ok ? 0 : 2);
