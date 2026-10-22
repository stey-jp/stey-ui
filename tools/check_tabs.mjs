import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {mkdir,readFile,writeFile} from 'node:fs/promises';
import {chromium} from 'playwright';
import {PNG} from 'pngjs';
import pixelmatch from 'pixelmatch';

const folder=process.env.TABS_OUTPUT??'output/playwright/tabs';await mkdir(folder,{recursive:true});
const variants=[{}, {size:'sm'}, {variant:'underline'}, {variant:'underline',size:'sm'}, {state:'hover'}, {variant:'underline',state:'hover'}, {scenario:'manual'}, {variant:'underline',size:'sm',scenario:'manual'}, {activate:'true',scenario:'automatic'}, {direction:'rtl',scenario:'manual'}, {direction:'rtl',activate:'true',scenario:'automatic'}, {uncontrolled:'true',value:'settings'}, {frozen:'true',scenario:'frozen'}, {rich:'true',scenario:'click'}, {rich:'true',size:'sm'}, {direction:'rtl',variant:'underline',size:'sm',rich:'true'}, {many:'true',scenario:'controls'}, {many:'true',host:'160',scenario:'drag'}, {many:'true',host:'160',variant:'underline',scenario:'end'}, {value:'analytics'}, {value:'missing'}, {value:'missing',uncontrolled:'true'}, {empty:'true'}, {many:'true',size:'sm',host:'160',scenario:'controls'}];
const cases=['light','dark'].flatMap(mode=>variants.map(v=>({mode,...v}))),only=process.argv.find(s=>s.startsWith('--case=')),selected=cases.map((item,index)=>({item,index})).filter(r=>!only||r.index===Number(only.split('=')[1]));
const results=[],timeline=[],rtlOverflow=[],issues=[],errors=[];let version,completed=false;
const browser=await chromium.launch({channel:'chrome',headless:true});
const delta=(a,b)=>Object.fromEntries(['x','y','width','height'].map(k=>[k,Math.abs(a[k]-b[k])]));
const state=async p=>JSON.parse(await p.getByText(/^\{"value":/).last().innerText());
const settled=async p=>p.waitForTimeout(360);
async function snapshot(p,label){return{label,...await state(p),tabs:await p.getByRole('tab').evaluateAll(es=>es.map(e=>({name:e.getAttribute('aria-label')||e.textContent,selected:e.getAttribute('aria-selected'),tabIndex:e.getAttribute('tabindex'),focused:e===document.activeElement})))}}
async function act(p,item){
 const steps=[];const save=async label=>steps.push(await snapshot(p,label));await save('initial');if(item.empty==='true')return steps;
 const tab=name=>p.getByRole('tab',{name,exact:true});
 if(item.state==='hover')await tab('Analytics').hover();
 if(item.scenario==='click'){await tab('Analytics').click();await settled(p);await save('click');}
 if(item.scenario==='manual'||item.scenario==='automatic'){
  await tab('Overview').click();await p.keyboard.press(item.direction==='rtl'?'ArrowLeft':'ArrowRight');await settled(p);await save('arrow');
  if(item.scenario==='manual')assert.equal((await state(p)).value,'overview');else assert.equal((await state(p)).value,'analytics');
  await p.keyboard.press('Enter');await settled(p);await save('enter');
  await p.keyboard.press('End');await settled(p);await save('end');await p.keyboard.press('Space');await settled(p);await save('space');
  await p.keyboard.press('Home');await p.keyboard.press('Enter');await settled(p);await save('home');await p.keyboard.press('Tab');await settled(p);assert(await p.getByRole('button',{name:'After tabs',exact:true}).evaluate(e=>e===document.activeElement),'Tab exits to next operation');
 }
 if(item.scenario==='frozen'){await tab('Settings').click();await settled(p);await save('frozen click');await p.keyboard.press('Enter');await settled(p);await save('frozen enter');}
 if(item.scenario==='controls'){
  for(let i=0;i<8;i++){const right=p.getByRole('button',{name:'Scroll tabs right',exact:true});if(!await right.count())break;try{await right.click({timeout:1500});}catch(e){if(!await right.count())break;throw e;}await p.waitForTimeout(600);}await save('end scroll');
 }
 if(item.scenario==='drag'){
  const box=await p.getByRole('group',{name:'Tabs preview',exact:true}).boundingBox();await p.mouse.move(box.x+box.width*.6,box.y+box.height/2);await p.mouse.down();await p.mouse.move(box.x+box.width*.6-70,box.y+box.height/2,{steps:10});await p.mouse.up();await settled(p);await save('drag');assert.equal((await state(p)).calls,0);
 }
 if(item.scenario==='end'){await tab('Overview').click();await p.keyboard.press('End');await p.keyboard.press('Enter');await settled(p);await save('keyboard last');assert.equal((await state(p)).value,'history');}
 return steps;
}
try{
 version=browser.version();const context=await browser.newContext({viewport:{width:1000,height:701}}),pages={};
 for(const target of['reference','flutter']){const p=await context.newPage();p.setDefaultTimeout(20000);pages[target]=p;const cdp=await context.newCDPSession(p);await cdp.send('Audits.enable');cdp.on('Audits.issueAdded',({issue})=>issues.push({target,...issue}));p.on('pageerror',e=>errors.push({target,message:e.message}));}
 for(const{item,index}of selected){
  console.log(JSON.stringify({index,...item}));const captures={};
  for(const target of['reference','flutter']){
   const p=pages[target],q=new URLSearchParams(item);q.set(target==='reference'?'component':'sample','tabs');await p.goto('http://127.0.0.1:'+(target==='reference'?8767:8766)+'/?'+q,{waitUntil:'networkidle'});await p.getByRole('button',{name:'After tabs',exact:true}).waitFor();await p.evaluate(()=>document.fonts.ready);await p.waitForTimeout(60);
   const states=await act(p,item),frame=item.empty==='true'?null:await p.getByRole('group',{name:'Tabs preview',exact:true}).boundingBox();
   const tabs=await p.getByRole('tab').evaluateAll(es=>es.map(e=>{const r=e.getBoundingClientRect();return{name:e.getAttribute('aria-label')||e.textContent,rect:{x:r.x,y:r.y,width:r.width,height:r.height},selected:e.getAttribute('aria-selected'),tabIndex:e.getAttribute('tabindex')};}));
   const path=`${folder}/${index}-${target}.png`;await p.screenshot({path});captures[target]={frame,tabs,states,path};
   if(item.empty!=='true' && (target==='reference'||!item.scenario))assert.equal(tabs.filter(t=>t.tabIndex==='0').length,1,'initial one tab stop');
  }
  const a=captures.reference,c=captures.flutter;assert.deepEqual(a.states.map(({tabs,...s})=>s),c.states.map(({tabs,...s})=>s),'state/callback contract');
  assert.deepEqual(a.tabs.map(t=>[t.name,t.selected]),c.tabs.map(t=>[t.name,t.selected]));
  let frameDelta=null,tabDeltas=[],pixelDifferenceRatio=null,diffPath=null,region=null;
  if(a.frame){frameDelta=delta(a.frame,c.frame);tabDeltas=a.tabs.map((t,i)=>({name:t.name,delta:delta(t.rect,c.tabs[i].rect)}));
   const[pa,pb]=await Promise.all([a,c].map(async r=>PNG.sync.read(await readFile(r.path))));
   const x=Math.floor(Math.min(a.frame.x,c.frame.x))-4,y=Math.floor(Math.min(a.frame.y,c.frame.y))-4,width=Math.ceil(Math.max(a.frame.x+a.frame.width,c.frame.x+c.frame.width))+4-x,height=Math.ceil(Math.max(a.frame.y+a.frame.height,c.frame.y+c.frame.height))+4-y;
   const crop=p=>{const q=new PNG({width,height});PNG.bitblt(p,q,x,y,width,height,0,0);return q;},ca=crop(pa),cb=crop(pb),diff=new PNG({width,height});pixelDifferenceRatio=pixelmatch(ca.data,cb.data,diff.data,width,height,{threshold:.1})/(width*height);diffPath=`${folder}/${index}-diff.png`;await writeFile(diffPath,PNG.sync.write(diff));region={x,y,width,height};
  }
  // Offscreen semantic bounds are clipped by Flutter; compare visible tab rectangles only when the full list fits.
  const geometryPass=!a.frame||Math.max(...Object.values(frameDelta),...(item.many==='true'?[]:tabDeltas.flatMap(t=>Object.values(t.delta))))<=1;
  results.push({index,...item,reference:a,candidate:c,frameDelta,tabDeltas,geometryPass,pixelDifferenceRatio,diffPath,region});
 }
 if(!only){
  const frames=JSON.parse(await readFile(folder+'/native/frames.json','utf8')),p=pages.reference;await p.setViewportSize({width:1000,height:501});let last='';
  for(const frame of frames){const key=[frame.mode,frame.direction,frame.variant].join('-');
   if(key!==last){await p.goto('http://127.0.0.1:8767/?'+new URLSearchParams({component:'tabs',mode:frame.mode,direction:frame.direction,variant:frame.variant}),{waitUntil:'networkidle'});await p.getByRole('tab',{name:'Overview',exact:true}).waitFor();await p.evaluate(()=>document.fonts.ready);await p.locator('[role=tablist] [role=presentation]').evaluate(e=>e.getBoundingClientRect());await p.evaluate(()=>globalThis.__tabsSetValue('settings'));await p.waitForFunction(()=>document.querySelector('[role=tablist] [role=presentation]').getAnimations().length>0);await p.locator('[role=tablist] [role=presentation]').evaluate(e=>{window.__tabsAnimations=e.getAnimations();for(const a of window.__tabsAnimations)a.pause();});last=key;}
   await p.evaluate(ms=>{for(const a of window.__tabsAnimations){a.pause();a.currentTime=ms;}},frame.ms);await p.waitForTimeout(20);const group=p.getByRole('group',{name:'Tabs preview',exact:true}),g=await group.boundingBox(),r=await p.locator('[role=tablist] [role=presentation]').boundingBox();const path=folder+'/reference-'+frame.file;await p.screenshot({path,clip:{x:g.x-10,y:g.y-10,width:g.width+20,height:g.height+20}});
   const nativePath=folder+'/native/'+frame.file,[a,b]=await Promise.all([nativePath,path].map(async path=>PNG.sync.read(await readFile(path))));assert.equal(a.width,b.width);assert.equal(a.height,b.height);const diff=new PNG({width:a.width,height:a.height}),ratio=pixelmatch(a.data,b.data,diff.data,a.width,a.height,{threshold:.1})/(a.width*a.height),diffPath=folder+'/diff-'+frame.file;await writeFile(diffPath,PNG.sync.write(diff));const rect={x:r.x-g.x,y:r.y-g.y,width:r.width,height:r.height},rectDelta=delta(rect,frame.rect);timeline.push({...frame,nativePath,referencePath:path,diffPath,referenceRect:rect,rectDelta,pixelDifferenceRatio:ratio});
  }
  for(const target of['reference','flutter']){const p=pages[target];await p.goto('http://127.0.0.1:'+(target==='reference'?8767:8766)+'/?'+new URLSearchParams({[target==='reference'?'component':'sample']:'tabs',many:'true',host:'160',direction:'rtl'}),{waitUntil:'networkidle'});await p.getByRole('tab',{name:'Overview',exact:true}).waitFor();const before={left:await p.getByRole('button',{name:'Scroll tabs left',exact:true}).count(),right:await p.getByRole('button',{name:'Scroll tabs right',exact:true}).count()},positions=[];if(target==='reference'){const list=p.getByRole('tablist');positions.push(await list.evaluate(e=>e.scrollLeft));await p.getByRole('button',{name:'Scroll tabs right',exact:true}).click();await settled(p);positions.push(await list.evaluate(e=>e.scrollLeft));}else{await p.getByRole('button',{name:'Scroll tabs left',exact:true}).click();await settled(p);assert(await p.getByRole('button',{name:'Scroll tabs right',exact:true}).count());await p.getByRole('button',{name:'Scroll tabs right',exact:true}).click();await settled(p);}rtlOverflow.push({target,before,positions});}
 }
 completed=true;
}finally{await browser.close();await writeFile(folder+'/comparison.json',JSON.stringify({success:completed&&results.length===selected.length&&!errors.length&&results.every(r=>r.geometryPass)&&timeline.every(r=>Math.max(...Object.values(r.rectDelta))<=1),fullRun:!only,browser:version,referenceSha:'947065ad39694fdc688b1128cc9c360f566a4f73',baseUiVersion:'1.9.0',candidateArtifactSha256:createHash('sha256').update(await readFile('apps/demo/build/web/main.dart.wasm')).digest('hex'),geometryContract:'Host and fitting tab bounds within1px. Overflow semantic bounds are separately recorded due to viewport clipping. Controlled CSS transition times are compared with software widget-raster frames, not synchronized Flutter Web frames. Pixel differences and RTL overflow deviations remain diagnostic; full library parity is not certified.',fullVisualParity:false,results,timeline,rtlOverflow,issues,errors},null,2)+'\n');}
const mismatches=results.filter(r=>!r.geometryPass).map(r=>({index:r.index,frame:r.frameDelta,tabs:r.tabDeltas})),phaseMismatches=timeline.filter(r=>Math.max(...Object.values(r.rectDelta))>1).map(r=>({file:r.file,delta:r.rectDelta}));console.log(JSON.stringify({contexts:results.length,frames:timeline.length,issues:issues.length,errors:errors.length,mismatches,phaseMismatches}));assert.equal(errors.length,0);assert.equal(mismatches.length,0);assert.equal(phaseMismatches.length,0);
