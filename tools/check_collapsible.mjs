import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {mkdir,readFile,writeFile} from 'node:fs/promises';
import {chromium} from 'playwright';
import {PNG} from 'pngjs';
import pixelmatch from 'pixelmatch';

const folder='output/playwright/collapsible';await mkdir(folder,{recursive:true});
const cases=[];
for(const mode of ['light','dark']) {
 for(const kind of ['default','bare','custom'])for(const viewport of [390,1200])for(const open of ['false','true'])
  cases.push({mode,kind,viewport,open,host:viewport===390?350:480,direction:viewport===390?'rtl':'ltr',scenario:'matrix'});
 for(const scenario of ['keep','lazy','controlled','cancel','disabled','long','multiple'])
  cases.push({mode,viewport:390,host:350,direction:'rtl',scenario,
   ...(['keep','lazy'].includes(scenario)?{input:'true',keep:String(scenario==='keep')}:{}),
   ...(scenario==='controlled'?{controlled:'true'}:{}),...(scenario==='cancel'?{cancel:'true'}:{}),
   ...(scenario==='disabled'?{state:'disabled'}:{}),...(['long','multiple'].includes(scenario)?{[scenario]:'true'}:{})});
}
const only=process.argv.find(a=>a.startsWith('--case='));
const selected=cases.map((item,index)=>({item,index})).filter(({index})=>!only||index===Number(only.split('=')[1]));
const results=[],errors=[],issues=[];let target,version;
const browser=await chromium.launch({channel:'chrome',headless:true});
try {
 version=browser.version();const page=await browser.newPage(),cdp=await page.context().newCDPSession(page);
 await cdp.send('Audits.enable');cdp.on('Audits.issueAdded',({issue})=>issues.push({target,...issue}));
 page.on('pageerror',e=>errors.push({target,message:e.message}));
 for(const {item,index}of selected){
  console.log(JSON.stringify({index,...item}));const captures={};
  for(target of ['reference','flutter']){
   await page.setViewportSize({width:item.viewport,height:900});const url=new URL('http://127.0.0.1:'+(target==='reference'?8767:8766)+'/');
   url.searchParams.set(target==='reference'?'component':'sample','collapsible');
   for(const [k,v]of Object.entries(item))if(!['viewport','scenario'].includes(k))url.searchParams.set(k,String(v));
   await page.goto(url.href,{waitUntil:'networkidle'});
   const group=page.getByRole('group',{name:'Collapsible preview',exact:true});await group.waitFor();
   const label=item.long==='true'?'Review access permissions and project settings before saving':'Details';
   const trigger=group.getByRole('button',{name:label,exact:true});
   const counter=n=>target==='reference'?page.locator('[aria-label="Change calls: '+n+'"]'):page.getByText('Change calls: '+n,{exact:true});
   const rows=[];
   const capture=async step=>{
    await page.waitForTimeout(140);
    const path=folder+'/'+index+'-'+step+'-'+target+'.png';await page.screenshot({path});
    const expanded=await trigger.getAttribute('aria-expanded'),controls=await trigger.getAttribute('aria-controls');
    if(expanded==='true')assert(controls&&await page.locator('[id="'+controls+'"]').count(),index+' '+target+' controls relationship');
    else assert.equal(controls,null,index+' '+target+' no closed controls relationship');
    rows.push({step,path,frame:await group.boundingBox(),trigger:await trigger.boundingBox(),expanded,controls,
     inner:item.input==='true'&&expanded==='true'?await group.getByRole('button',{name:/Inner count:/}).innerText():null});
   };
   await page.mouse.move(1,1);await capture('idle');
   if(item.state==='disabled'){
    await trigger.click({force:true});await page.keyboard.press('Tab');await page.keyboard.press('Enter');
    assert(await counter(0).count());await capture('blocked');
   } else {
    await page.keyboard.press('Tab');assert(await trigger.evaluate(el=>el===document.activeElement||el.contains(document.activeElement)),index+' '+target+' Tab');await capture('focus');
    await page.keyboard.down('Space');assert(await counter(0).count(),index+' '+target+' Space-up only');await page.keyboard.up('Space');
    await counter(1).waitFor();await capture('space');
    assert.equal(await trigger.getAttribute('aria-expanded'),item.cancel==='true'?'false':item.open==='true'?'false':'true');
    if(item.input==='true'){
     await group.getByRole('button',{name:'Inner count: 0',exact:true}).click();
     await group.getByRole('button',{name:'Inner count: 1',exact:true}).waitFor();
     await trigger.click();await counter(2).waitFor();await capture('closed-with-state');
     // Closed content must not appear in the accessibility tree or Tab order.
     assert.equal(await group.getByRole('button',{name:/Inner count:/}).count(),0);
     await trigger.press('Enter');await counter(3).waitFor();await capture('reopened');
     assert.equal(await group.getByRole('button',{name:/Inner count:/}).innerText(),'Inner count: '+(item.keep==='true'?1:0));
    } else {
     await trigger.press('Enter');await counter(2).waitFor();await capture('enter');
    }
   }
   captures[target]=rows;
  }
  const states=[];
  for(const [n,a]of captures.reference.entries()){
   const b=captures.flutter[n];assert.equal(a.step,b.step);assert.equal(a.expanded,b.expanded);assert.equal(a.inner,b.inner);
   const delta=(x,y)=>Object.fromEntries(['x','y','width','height'].map(k=>[k,Math.abs(x[k]-y[k])]));
   const frameDelta=delta(a.frame,b.frame),triggerDelta=delta(a.trigger,b.trigger);
   const [i,j]=await Promise.all([a,b].map(async c=>PNG.sync.read(await readFile(c.path))));
   const diff=new PNG({width:i.width,height:i.height});const ratio=pixelmatch(i.data,j.data,diff.data,i.width,i.height,{threshold:.1})/(i.width*i.height);
   await writeFile(folder+'/'+index+'-'+a.step+'-diff.png',PNG.sync.write(diff));
   states.push({step:a.step,captures:[a,b],frameGeometryDelta:frameDelta,triggerGeometryDelta:triggerDelta,
    pixelDifferenceRatio:ratio,geometryPass:Math.max(...Object.values(frameDelta),...Object.values(triggerDelta))<=1});
  }
  results.push({index,...item,states});
 }
} finally {
 await browser.close();await writeFile(folder+'/comparison.json',JSON.stringify({success:results.length===selected.length&&!errors.length&&results.every(r=>r.states.every(s=>s.geometryPass)),fullRun:selected.length===cases.length,browser:version,
  referenceSha:'7e0ff40546f08405d05bc9754f0ff0fd009ece0a',candidateArtifactSha256:createHash('sha256').update(await readFile('apps/demo/build/web/main.dart.wasm')).digest('hex'),
  geometryContract:'Preview and trigger bounds within 1 CSS px; raw DOM and Flutter semantics bounds retained. Pixel differences remain diagnostic. Motion timing/reversal/height preservation checked by widget tests, not frame synchronized pixel certification.',fullVisualParity:false,results,issues,errors},null,2)+'\n');
}
assert.equal(errors.length,0);const mismatches=results.flatMap(r=>r.states.filter(s=>!s.geometryPass).map(s=>({index:r.index,scenario:r.scenario,step:s.step,frame:s.frameGeometryDelta,trigger:s.triggerGeometryDelta})));
console.log(JSON.stringify({contexts:results.length,states:results.reduce((n,r)=>n+r.states.length,0),issues:issues.length,errors:errors.length,geometryMismatches:mismatches}));assert.equal(mismatches.length,0);
