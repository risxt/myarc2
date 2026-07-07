const fs = require('fs');
const path = require('path');
const mono = fs.readFileSync('c:\\Users\\faris\\OneDrive\\Desktop\\gag\\gag2.lua','utf8');
const root = process.cwd();

// Extract all section headers from monolith
const sectionRx = /^-- =+ (.+?) =+$/gm;
const sections = [];
let m;
while((m = sectionRx.exec(mono)) !== null) sections.push(m[1].trim());
const unique = [...new Set(sections)];

// Map section → which modular file owns it
const controllerDir = path.join(root,'src','Controllers');
const serviceDir = path.join(root,'src','Services');
const coreDir = path.join(root,'src','Core');
const uiDir = path.join(root,'src','UI');
const dirs = [controllerDir, serviceDir, coreDir, uiDir];
const allFiles = [];
for(const d of dirs){
    if(!fs.existsSync(d)) continue;
    for(const f of fs.readdirSync(d).filter(x=>x.endsWith('.lua'))){
        allFiles.push({name:f, content:fs.readFileSync(path.join(d,f),'utf8')});
    }
}

const coverage = {};
for(const sec of unique){
    const secLow = sec.toLowerCase().replace(/[^a-z]/g,'');
    let found = [];
    for(const f of allFiles){
        const fLow = f.name.toLowerCase().replace(/[^a-z]/g,'');
        if(fLow.includes(secLow.replace('auto','')) || fLow.includes(secLow)){
            found.push(f.name);
        }
    }
    // Check content-based matches
    if(found.length===0){
        const keywords = sec.split(/\s+/).filter(w=>w.length>3).map(w=>w.toLowerCase());
        for(const f of allFiles){
            const cLow = f.content.toLowerCase();
            if(keywords.every(k=>cLow.includes(k))){
                found.push(f.name + ' (content)');
            }
        }
    }
    coverage[sec] = found.length > 0 ? found.join(', ') : '** NOT FOUND **';
}

let report = ['# Monolith Section Coverage Audit','','| Monolith Section | Modular Owner |','|---|---|'];
let missing = [];
for(const sec of unique){
    const owner = coverage[sec];
    report.push(`| ${sec} | ${owner} |`);
    if(owner === '** NOT FOUND **') missing.push(sec);
}
report.push('',`## Missing Sections: ${missing.length}`);
if(missing.length) report.push('',missing.map(s=>`- ${s}`).join('\n'));
else report.push('','None — all sections have modular ownership.');
fs.writeFileSync(path.join(root,'tests','section_coverage_audit.md'), report.join('\n'), 'utf8');
console.log(report.join('\n'));
