const fs = require('fs');
const path = require('path');
function root(){ const cwd=process.cwd(); if(fs.existsSync(path.join(cwd,'src'))) return cwd; if(fs.existsSync(path.join(cwd,'GAG2','src'))) return path.join(cwd,'GAG2'); throw new Error('no root'); }
const r=root();
const controllers=path.join(r,'src','Controllers');
const files=fs.readdirSync(controllers).filter(f=>f.endsWith('.lua'));
let rows=['# Controller Migration Audit','','| Controller | Has fallback marker | Status |','|---|---:|---|'];
let blockers=[];
for(const f of files){
  const txt=fs.readFileSync(path.join(controllers,f),'utf8');
  const fallback=txt.includes('not_migrated_monolith_fallback_required');
  if(fallback) blockers.push(f);
  rows.push(`| ${f} | ${fallback ? 'yes' : 'no'} | ${fallback ? 'BLOCKED' : 'PORTING/DRAFT'} |`);
}
rows.push('',`## Blocker Count`,`${blockers.length}`,'',`## Result`, blockers.length ? 'NOT 100%' : 'READY FOR RUNTIME TEST');
fs.writeFileSync(path.join(r,'tests','controller_migration_audit.md'), rows.join('\n'), 'utf8');
console.log(rows.join('\n'));
process.exit(blockers.length ? 1 : 0);
