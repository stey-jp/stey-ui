import assert from'node:assert/strict';
import{createHash}from'node:crypto';
import{mkdir,readFile,writeFile}from'node:fs/promises';
import{chromium}from'playwright';
import{PNG}from'pngjs';
import pixelmatch from'pixelmatch';
const folder=process.env.INPUT_GROUP_OUTPUT??'output/playwright/input-group';await mkdir(folder,{recursive:true});
const variants=[...['xs','sm','base','lg'].flatMap(size=>['plain','addons','suffix','action','individual','hybrid','hybrid-suffix'].map(layout=>({size,layout}))),
 {layout:'plain',state:'focus'},{layout:'individual',state:'focus'},{layout:'hybrid',state:'focus'},
 {layout:'suffix',scenario:'edit'},{layout:'suffix',frozen:'true',scenario:'edit'},
 {layout:'action',scenario:'clear'},{layout:'hybrid',scenario:'clear'},
 {layout:'individual',scenario:'action'},{layout:'hybrid',scenario:'action'},
 {layout:'individual',scenario:'hover'},{layout:'hybrid',scenario:'hover'},
 {layout:'addons',label:'true',description:'true',required:'true',scenario:'label'},
 {layout:'hybrid',label:'true',description:'true',required:'false',error:'true'},
 {layout:'plain',error:'true',state:'focus'},{layout:'individual',error:'true',state:'focus'},
 {layout:'addons',disabled:'true'},{layout:'individual',disabled:'true'},{layout:'hybrid',disabled:'true'},
 {layout:'suffix',host:'160',value:'a very long worker name here'},
 {layout:'addons',direction:'rtl',host:'160'},{layout:'individual',direction:'rtl'},
 {layout:'leading-hybrid'},{layout:'ghost'},{layout:'addons',textAddon:'true'},
 {layout:'plain',readOnly:'true',scenario:'readonly'}, {layout:'suffix',value:''},
 {layout:'hybrid',variant:'primary'},{layout:'individual',variant:'destructive',scenario:'hover'}];
const cases=['light','dark'].flatMap(mode=>variants.map(v=>({mode,...v}))),only=process.argv.find(s=>s.startsWith('--case=')),selected=cases.map((item,index)=>({item,index})).filter(r=>!only||r.index===Number(only.split('=')[1]));
const artifactHash=async()=>createHash('sha256').update(await readFile('apps/demo/build/web/main.dart.wasm')).digest('hex'),startedArtifactHash=await artifactHash();
const results=[],issues=[],errors=[];let completed=false,version;
const browser=await chromium.launch({channel:'chrome',headless:true});
const delta=(a,b)=>Object.fromEntries(['x','y','width','height'].map(k=>[k,Math.abs(a[k]-b[k])]));
const status=async p=>JSON.parse(await p.getByText(/^\{"value":/).last().innerText());
try{
 version=browser.version();const context=await browser.newContext({viewport:{width:1000,height:701}}),pages={};
 for(const target of['reference','flutter']){const p=await context.newPage();p.setDefaultTimeout(15000);pages[target]=p;const c=await context.newCDPSession(p);await c.send('Audits.enable');c.on('Audits.issueAdded',({issue})=>issues.push({target,...issue}));p.on('pageerror',e=>errors.push({target,message:e.message,stack:e.stack}));}
 for(const{item,index}of selected){console.log(JSON.stringify({index,...item}));const captures={};
  for(const target of['reference','flutter']){const p=pages[target],q=new URLSearchParams(item);q.set(target==='reference'?'component':'sample','input-group');await p.goto('http://127.0.0.1:'+(target==='reference'?8767:8766)+'/?'+q,{waitUntil:'networkidle'});await p.getByRole('button',{name:'After group',exact:true}).waitFor();await p.evaluate(()=>document.fonts.ready);await p.waitForTimeout(40);
   const g=p.getByRole('group',{name:'Input group preview',exact:true}),field=p.getByRole('textbox'),steps=[{stage:'initial',...await status(p)}],heights=[],initialFocused=await field.evaluate(e=>e===document.activeElement);await p.getByRole('button',{name:'After group',exact:true}).focus();await p.waitForTimeout(60);
   if(item.state==='focus')await field.click();
   if(item.scenario==='label'){const labelBox=await p.getByText('Project',{exact:true}).boundingBox();await p.mouse.click(labelBox.x+labelBox.width/2,labelBox.y+labelBox.height/2);await p.waitForTimeout(60);assert(await field.evaluate(e=>e===document.activeElement),'label focuses editor');}
   if(item.scenario==='edit'){await field.click();await p.waitForTimeout(60);await field.fill('Changed');await p.waitForTimeout(100);steps.push({stage:'input',...await status(p)});assert.equal(await field.inputValue(),item.frozen==='true'?'my-worker':'Changed');}
   if(item.scenario==='readonly'){await field.click();await p.keyboard.type('x');await p.waitForTimeout(60);assert.equal(await field.inputValue(),'my-worker');steps.push({stage:'readonly',...await status(p)});}
   if(item.scenario==='clear'){await p.getByRole('button',{name:'Clear',exact:true}).click();await p.waitForTimeout(100);steps.push({stage:'clear',...await status(p)});assert.equal((await status(p)).value,'',target+' clear state');await field.click();await p.waitForTimeout(60);assert.equal(await field.inputValue(),'',target+' refocused cleared editor');await p.getByRole('button',{name:'Clear',exact:true}).focus();}
   if(item.scenario==='action'){await p.getByRole('button',{name:'Go',exact:true}).click();await p.waitForTimeout(60);steps.push({stage:'action',...await status(p)});assert.equal((await status(p)).actions,1);assert.equal(await field.evaluate(e=>e===document.activeElement),false);}
   if(item.scenario==='hover'){await p.getByRole('button',{name:'Go',exact:true}).hover();await p.waitForTimeout(60);assert.equal(await field.evaluate(e=>e===document.activeElement),false);}
   const frame=await g.boundingBox(),editor=await field.boundingBox(),attrs=await field.evaluate(e=>Object.fromEntries(['role','type','aria-label','aria-invalid','aria-required','aria-disabled','readonly','disabled'].map(k=>[k,e.getAttribute(k)]))),path=`${folder}/${index}-${target}.png`;await p.screenshot({path});captures[target]={buttons:await g.getByRole('button').evaluateAll(es=>es.map(e=>({text:e.getAttribute('aria-label')||e.textContent,rect:e.getBoundingClientRect().toJSON(),disabled:e.getAttribute('aria-disabled')||e.hasAttribute('disabled')}))),frame,editor,attrs,steps,heights,path,initialFocused,finalFocused:await field.evaluate(e=>e===document.activeElement)};
  }
  const a=captures.reference,c=captures.flutter;assert.deepEqual(a.steps,c.steps,'group notifications and action values');const frameDelta=delta(a.frame,c.frame),geometryPass=Math.max(...Object.values(frameDelta))<=1;
  const[pa,pb]=await Promise.all([a,c].map(async r=>PNG.sync.read(await readFile(r.path))));const x=Math.floor(Math.min(a.frame.x,c.frame.x))-4,y=Math.floor(Math.min(a.frame.y,c.frame.y))-4,width=Math.ceil(Math.max(a.frame.x+a.frame.width,c.frame.x+c.frame.width))+4-x,height=Math.ceil(Math.max(a.frame.y+a.frame.height,c.frame.y+c.frame.height))+4-y;
  const crop=p=>{const q=new PNG({width,height});PNG.bitblt(p,q,x,y,width,height,0,0);return q;},ca=crop(pa),cb=crop(pb),diff=new PNG({width,height}),pixelDifferenceRatio=pixelmatch(ca.data,cb.data,diff.data,width,height,{threshold:.1})/(width*height),diffPath=`${folder}/${index}-diff.png`;await writeFile(diffPath,PNG.sync.write(diff));
  results.push({index,...item,reference:a,candidate:c,frameDelta,geometryPass,pixelDifferenceRatio,diffPath,region:{x,y,width,height}});
 }
 completed=true;
}finally{await browser.close();const candidateArtifactUnchanged=startedArtifactHash===await artifactHash();await writeFile(folder+'/comparison.json',JSON.stringify({success:completed&&candidateArtifactUnchanged&&results.length===selected.length&&!errors.length&&results.every(r=>r.geometryPass),fullRun:!only,referenceSha:'947065ad39694fdc688b1128cc9c360f566a4f73',baseUiVersion:'1.9.0',browser:version,candidateArtifactSha256:startedArtifactHash,candidateArtifactUnchanged,geometryContract:'Input group preview host bounds within1px. DOM editor bounds/attributes are recorded separately because native SDK semantics/selection controls and browser input boxes differ. Focus is normalized to the neighboring button before each scenario, and initial SDK route-default focus is recorded separately. Compound modes, all sizes, controlled editing, clear/action notification counts, read-only, label focus, RTL, narrow suffix and disabled compared. Segoe UI input in official CSS and bundled Inter in native differ; editor/button DOM rects are diagnostic separately. Pixels remain diagnostic; not full library parity.',fullVisualParity:false,results,issues,errors},null,2)+'\n');}
const mismatches=results.filter(r=>!r.geometryPass).map(r=>({index:r.index,delta:r.frameDelta}));console.log(JSON.stringify({contexts:results.length,issues:issues.length,errors:errors.length,mismatches}));assert.equal(errors.length,0);assert.equal(mismatches.length,0);
