import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {mkdir,readFile,writeFile} from 'node:fs/promises';
import {chromium} from 'playwright';
import {PNG} from 'pngjs';
import pixelmatch from 'pixelmatch';

const folder='output/playwright/empty';await mkdir(folder,{recursive:true});
const cases=[];
for(const mode of ['light','dark']) {
 for(const emptySize of ['sm','base','lg'])for(const viewport of [390,1200])for(const description of ['none','present'])
  cases.push({mode,emptySize,viewport,description,host:viewport===390?350:600,direction:viewport===390?'rtl':'ltr',scenario:'matrix'});
 for(const scenario of ['minimal','icon','actions','multiple','long','long-command','description-cap'])
  cases.push({mode,viewport:scenario==='description-cap'?1200:390,host:scenario==='description-cap'?900:350,direction:'ltr',scenario,
   ...(scenario==='minimal'?{description:'none',command:'none'}:{}),...(scenario==='icon'?{icon:'true'}:{}),
   ...(['actions','multiple'].includes(scenario)?{actions:'true',multiple:String(scenario==='multiple')}:{}),
   ...(['long','description-cap'].includes(scenario)?{long:'true'}:{}),...(scenario==='long-command'?{command:'long'}:{})});
}
const only=process.argv.find(a=>a.startsWith('--case='));const selected=cases.map((item,index)=>({item,index})).filter(({index})=>!only||index===Number(only.split('=')[1]));
const results=[],errors=[],issues=[];let target,version;
const browser=await chromium.launch({channel:'chrome',headless:true});
try {
 version=browser.version();const context=await browser.newContext({permissions:['clipboard-read','clipboard-write']}),page=await context.newPage(),cdp=await context.newCDPSession(page);
 await cdp.send('Audits.enable');cdp.on('Audits.issueAdded',({issue})=>issues.push({target,...issue}));page.on('pageerror',e=>errors.push({target,message:e.message}));
 for(const {item,index}of selected){
  console.log(JSON.stringify({index,...item}));const captures={};
  for(target of ['reference','flutter']){
   await page.setViewportSize({width:item.viewport,height:1000});const url=new URL('http://127.0.0.1:'+(target==='reference'?8767:8766)+'/');
   url.searchParams.set(target==='reference'?'component':'sample','empty');
   for(const [k,v]of Object.entries(item))if(!['viewport','scenario'].includes(k))url.searchParams.set(k,String(v));
   await page.goto(url.href,{waitUntil:'networkidle'});
   const group=page.getByRole('group',{name:'Empty preview',exact:true});await group.waitFor();
   const title=group.getByRole('heading',{level:2});assert.equal(await title.innerText(),item.long==='true'?'No project resources have been created yet':'No resources found');
   const copy=group.getByRole('button',{name:'Copy command',exact:true});const rows=[];
   const capture=async step=>{
    const path=folder+'/'+index+'-'+step+'-'+target+'.png';await page.screenshot({path});
    rows.push({step,path,frame:await group.boundingBox(),title:await title.boundingBox(),copy:item.command==='none'?null:await copy.boundingBox()});
   };
   await page.mouse.move(1,1);await capture('idle');
   if(item.command!=='none'){
    await copy.hover();await capture('hover');await page.mouse.move(1,1);
    let tabs=0;
    do {await page.keyboard.press('Tab');await page.waitForTimeout(60);tabs++;} while(tabs<2&&!await copy.evaluate(el=>el===document.activeElement||el.contains(document.activeElement)));
    assert(await copy.evaluate(el=>el===document.activeElement||el.contains(document.activeElement)),index+' '+target+' reachable copy Tab');await capture('focus');
    await page.evaluate(()=>navigator.clipboard.writeText('sentinel'));
    await page.keyboard.down('Space');assert.equal(await page.evaluate(()=>navigator.clipboard.readText()),'sentinel');await page.keyboard.up('Space');
    const expected=item.command==='long'?'flutter create --org stey.jp resource-example --platforms web,windows,macos,linux,android,ios':'flutter create resource-example';
    await page.waitForFunction(expected=>navigator.clipboard.readText().then(v=>v===expected),expected);
    await page.waitForTimeout(450);await capture('copied');
    await page.keyboard.press('Enter');await page.waitForTimeout(650);await capture('repeated-copy');
    await page.waitForTimeout(450);await capture('reset');
   }
   if(item.actions==='true'){
    await group.getByRole('button',{name:'Create resource',exact:true}).click();
    if(target==='reference')await page.locator('[aria-label="Action calls: 1"]').waitFor();else await page.getByText('Copy calls: 2; Action calls: 1',{exact:true}).waitFor();
    if(item.multiple==='true')await group.getByRole('button',{name:'Read guide',exact:true}).click();await capture('action');
   }
   if(item.command!=='none'){
    const reset=rows.find(r=>r.step==='reset'),base=PNG.sync.read(await readFile(reset.path));
    for(const step of ['copied','repeated-copy']){
     const row=rows.find(r=>r.step===step),check=PNG.sync.read(await readFile(row.path));let changed=0;
     const box=row.copy;
     for(let y=Math.ceil(box.y+3);y<Math.floor(box.y+box.height-3);y++)for(let x=Math.ceil(box.x+3);x<Math.floor(box.x+box.width-3);x++){
      const pos=(y*base.width+x)*4;if([0,1,2].some(i=>Math.abs(base.data[pos+i]-check.data[pos+i])>25))changed++;
     }
     row.feedbackChangedPixelsFromReset=changed;assert(changed>5,index+' '+target+' '+step+' visible feedback and timed reset');
    }
   }
   captures[target]=rows;
  }
  const states=[];
  for(const [n,a]of captures.reference.entries()){
   const b=captures.flutter[n];assert.equal(a.step,b.step);
   const delta=(x,y)=>Object.fromEntries(['x','y','width','height'].map(k=>[k,Math.abs(x[k]-y[k])]));
   const frameDelta=delta(a.frame,b.frame),titleDelta=delta(a.title,b.title),copyDelta=a.copy?delta(a.copy,b.copy):{};
   const [i,j]=await Promise.all([a,b].map(async c=>PNG.sync.read(await readFile(c.path))));const diff=new PNG({width:i.width,height:i.height});
   const ratio=pixelmatch(i.data,j.data,diff.data,i.width,i.height,{threshold:.1})/(i.width*i.height);await writeFile(folder+'/'+index+'-'+a.step+'-diff.png',PNG.sync.write(diff));
   // Native and CSS monospace metrics differ; retain raw copy-button X/Y/width.
   // Text balancing is a separate documented difference; only title Y/height
   // and outer frame are asserted, not its renderer-dependent text width.
   const geometryPass=Math.max(...Object.values(frameDelta),titleDelta.y,titleDelta.height,copyDelta.height??0)<=1;
   states.push({step:a.step,captures:[a,b],frameGeometryDelta:frameDelta,titleGeometryDelta:titleDelta,rawCopyGeometryDelta:copyDelta,pixelDifferenceRatio:ratio,geometryPass});
  }
  results.push({index,...item,states});
 }
} finally {
 await browser.close();await writeFile(folder+'/comparison.json',JSON.stringify({success:results.length===selected.length&&!errors.length&&results.every(r=>r.states.every(s=>s.geometryPass)),fullRun:selected.length===cases.length,browser:version,
  referenceSha:'7e0ff40546f08405d05bc9754f0ff0fd009ece0a',candidateArtifactSha256:createHash('sha256').update(await readFile('apps/demo/build/web/main.dart.wasm')).digest('hex'),
  geometryContract:'Outer frame, heading Y/height and copy target height within 1 CSS px. Raw title and copy bounds retained. CSS text-balance, monospace metrics, selected text and synchronized bounce frames are not certified.',fullVisualParity:false,results,issues,errors},null,2)+'\n');
}
assert.equal(errors.length,0);const mismatches=results.flatMap(r=>r.states.filter(s=>!s.geometryPass).map(s=>({index:r.index,scenario:r.scenario,step:s.step,frame:s.frameGeometryDelta,title:s.titleGeometryDelta,copy:s.rawCopyGeometryDelta})));
console.log(JSON.stringify({contexts:results.length,states:results.reduce((n,r)=>n+r.states.length,0),issues:issues.length,errors:errors.length,geometryMismatches:mismatches}));assert.equal(mismatches.length,0);
