import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {mkdir,readFile,writeFile} from 'node:fs/promises';
import {chromium} from 'playwright';
import {PNG} from 'pngjs';
import pixelmatch from 'pixelmatch';

const folder=process.env.CRUMB_OUTPUT??'output/playwright/breadcrumbs';await mkdir(folder,{recursive:true});
const cases=[];
for(const mode of ['light','dark']){
 for(const crumbSize of ['sm','base'])for(const viewport of [390,640,1200])for(const direction of ['ltr','rtl'])
  cases.push({mode,crumbSize,viewport,direction,host:viewport===390?350:480,scenario:'matrix'});
 for(const scenario of ['one','two','four','long','loading','icon','loading-icon','no-copy','extra','empty-copy','narrow-desktop'])
  cases.push({mode,viewport:scenario==='narrow-desktop'?1200:390,host:scenario==='narrow-desktop'?220:350,direction:'ltr',scenario,
   ...(['one','two','four'].includes(scenario)?{count:{one:1,two:2,four:4}[scenario]}:{}),
   ...(scenario==='long'?{long:'true'}:{}),...(scenario.startsWith('loading')?{loading:'true'}:{}),
   ...(['icon','loading-icon'].includes(scenario)?{icon:'true'}:{}),...(scenario==='no-copy'?{copy:'false'}:{}),
   ...(scenario==='extra'?{extra:'true'}:{}),...(scenario==='empty-copy'?{empty:'true'}:{})});
}
const only=process.argv.find(a=>a.startsWith('--case='));const selected=cases.map((item,index)=>({item,index})).filter(({index})=>!only||index===Number(only.split('=')[1]));
const results=[],errors=[],issues=[];let target,version;
const browser=await chromium.launch({channel:'chrome',headless:true});
try{
 version=browser.version();const context=await browser.newContext({permissions:['clipboard-read','clipboard-write']}),page=await context.newPage(),cdp=await context.newCDPSession(page);
 await cdp.send('Audits.enable');cdp.on('Audits.issueAdded',({issue})=>issues.push({target,...issue}));page.on('pageerror',e=>errors.push({target,message:e.message}));
 for(const {item,index}of selected){
  console.log(JSON.stringify({index,...item}));const captures={};
  for(target of ['reference','flutter']){
   await page.setViewportSize({width:item.viewport,height:900});const url=new URL('http://127.0.0.1:'+(target==='reference'?8767:(process.env.CRUMB_PORT??8766))+'/');
   url.searchParams.set(target==='reference'?'component':'sample','breadcrumbs');for(const[k,v]of Object.entries(item))if(!['viewport','scenario'].includes(k))url.searchParams.set(k,String(v));
   await page.goto(url.href,{waitUntil:'networkidle'});const group=page.getByRole('group',{name:'Breadcrumbs preview',exact:true});await group.waitFor();
   const nav=group.getByRole('navigation',{name:'breadcrumb',exact:true});await nav.waitFor();
   const count=item.count??3,expectedNames=count===1?[]:Array.from({length:count-1},(_,i)=>i===0?'Account':i===1?'Projects':'Section '+i);
   const expected=item.viewport<640&&count>2?expectedNames.slice(-1):expectedNames;
   assert.deepEqual(await nav.getByRole('link').allTextContents(),expected,index+' '+target+' visible links');
   for(const [i,link]of (await nav.getByRole('link').all()).entries()){
    const original=count>2&&item.viewport<640?count-2:i;assert.equal(await link.getAttribute('href'),target==='reference'?'#level-'+original:new URL('#level-'+original,url).href);
   }
   const copy=nav.getByRole('button',{name:'Copy',exact:true}),rows=[];
   const capture=async step=>{
    const path=folder+'/'+index+'-'+step+'-'+target+'.png';await page.screenshot({path});
    const current=item.loading==='true'?null:target==='reference'?nav.locator('[aria-current="page"]:visible'):nav.getByText(item.long==='true'?'Current resource with a very long display name':'Current resource',{exact:true});
    const currentBounds=current?await current.evaluate((el,flutter)=>{const n=flutter?el.closest('flt-semantics'):el;const{x,y,width,height}=n.getBoundingClientRect();return{x,y,width,height};},target==='flutter'):null;
    rows.push({step,path,frame:await group.boundingBox(),nav:await nav.boundingBox(),links:await nav.getByRole('link').evaluateAll(es=>es.map(e=>{const{x,y,width,height}=e.getBoundingClientRect();return{x,y,width,height};})),copy:item.copy==='false'?null:await copy.boundingBox(),current:currentBounds});
   };
   await page.mouse.move(1,1);await page.waitForTimeout(170);await capture('idle');
   await nav.hover({force:true});await page.waitForTimeout(180);await capture('hover');
   await page.mouse.move(1,1);
   if(expected.length&&item.scenario!=='narrow-desktop'){
    const first=nav.getByRole('link').first();await page.keyboard.press('Tab');await page.waitForTimeout(60);
    assert(await first.evaluate(el=>el===document.activeElement||el.contains(document.activeElement)),index+' '+target+' one Tab target per link');
    await page.keyboard.press('Enter');await page.waitForTimeout(80);
    const calls=()=>target==='reference'?page.locator('[aria-label="Link calls: 1"]'):page.getByText('Link calls: 1; Copy calls: 0',{exact:true});
    await calls().waitFor();await page.keyboard.press('Space');assert(await calls().count());await capture('link');
    await first.click();await (target==='reference'?page.locator('[aria-label="Link calls: 2"]'):page.getByText('Link calls: 2; Copy calls: 0',{exact:true})).waitFor();assert.equal(new URL(page.url()).search,url.search);await capture('pointer');
   }
   if(item.copy!=='false'&&item.scenario!=='narrow-desktop'){
    await page.evaluate(()=>navigator.clipboard.writeText('copy-sentinel'));
    await nav.hover({force:true});await page.waitForTimeout(180);await copy.click({force:true});await page.waitForTimeout(80);
    const expected=item.empty==='true'?'': 'https://example.com/projects/settings';
    assert.equal(await page.evaluate(()=>navigator.clipboard.readText()),expected||'copy-sentinel');
    await capture('copied');
    // Native buttons copy on Space up, after click has focused the control.
    if(expected){
     await page.evaluate(()=>navigator.clipboard.writeText('space-sentinel'));await page.keyboard.down('Space');await page.waitForTimeout(20);assert.equal(await page.evaluate(()=>navigator.clipboard.readText()),'space-sentinel');await page.keyboard.up('Space');await page.waitForTimeout(80);
     assert.equal(await page.evaluate(()=>navigator.clipboard.readText()),expected);await capture('repeat');
    }
    await page.waitForTimeout(2050);await capture('reset');
   }
   captures[target]=rows;
  }
  const states=[];
  for(const[n,a]of captures.reference.entries()){
   const b=captures.flutter[n];assert.equal(a.step,b.step);assert.equal(a.links.length,b.links.length);
   const delta=(x,y)=>Object.fromEntries(['x','y','width','height'].map(k=>[k,Math.abs(x[k]-y[k])]));
   const frameDelta=delta(a.frame,b.frame),navDelta=delta(a.nav,b.nav),linkDeltas=a.links.map((x,i)=>delta(x,b.links[i])),copyDelta=a.copy?delta(a.copy,b.copy):{},currentDelta=a.current?delta(a.current,b.current):{};
   const[i,j]=await Promise.all([a,b].map(async c=>PNG.sync.read(await readFile(c.path))));const diff=new PNG({width:i.width,height:i.height});
   const ratio=pixelmatch(i.data,j.data,diff.data,i.width,i.height,{threshold:.1})/(i.width*i.height);await writeFile(folder+'/'+index+'-'+a.step+'-diff.png',PNG.sync.write(diff));
   const geometryPass=Math.max(...Object.values(frameDelta),...Object.values(navDelta),...linkDeltas.flatMap(x=>Object.values(x)),...Object.values(copyDelta),...Object.values(currentDelta))<=1;
   states.push({step:a.step,captures:[a,b],frameGeometryDelta:frameDelta,navGeometryDelta:navDelta,linkGeometryDeltas:linkDeltas,copyGeometryDelta:copyDelta,currentGeometryDelta:currentDelta,pixelDifferenceRatio:ratio,geometryPass});
  }
  results.push({index,...item,states});
 }
}finally{
 await browser.close();await writeFile(folder+'/comparison.json',JSON.stringify({success:results.length===selected.length&&!errors.length&&results.every(r=>r.states.every(s=>s.geometryPass)),fullRun:selected.length===cases.length,browser:version,
  referenceSha:'7e0ff40546f08405d05bc9754f0ff0fd009ece0a',latestObservedSha:'947065ad39694fdc688b1128cc9c360f566a4f73',candidateArtifactSha256:createHash('sha256').update(await readFile('apps/demo/build/web/main.dart.wasm')).digest('hex'),
  geometryContract:'Outer frame, navigation box, visible link bounds, current bounds and copy target bounds within 1 CSS px. Current selected semantics differs from aria-current; loading skeleton randomness and native focus revelation remain diagnostic, not pixel certification.',fullVisualParity:false,results,issues,errors},null,2)+'\n');
}
assert.equal(errors.length,0);const mismatches=results.flatMap(r=>r.states.filter(s=>!s.geometryPass).map(s=>({index:r.index,scenario:r.scenario,step:s.step,nav:s.navGeometryDelta,links:s.linkGeometryDeltas,copy:s.copyGeometryDelta,current:s.currentGeometryDelta})));
console.log(JSON.stringify({contexts:results.length,states:results.reduce((n,r)=>n+r.states.length,0),issues:issues.length,errors:errors.length,geometryMismatches:mismatches}));assert.equal(mismatches.length,0);
