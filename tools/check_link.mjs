import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {mkdir,readFile,writeFile} from 'node:fs/promises';
import {chromium} from 'playwright';
import {PNG} from 'pngjs';
import pixelmatch from 'pixelmatch';

const folder=process.env.LINK_OUTPUT??'output/playwright/link';await mkdir(folder,{recursive:true});
const hash=async()=>createHash('sha256').update(await readFile('apps/demo/build/web/main.dart.wasm')).digest('hex');
const artifactHash=await hash();
const variants=['inline','current','plain'].flatMap(variant=>[
 {variant},{variant,external:'true'},{variant,parent:'true'},
 {variant,font:'16',external:'true'},
 {variant,host:'120',content:'Read documentation across the network',external:'true'},
 {variant,direction:'rtl',external:'true'},
 {variant,host:'180',scale:'2',external:'true'},
 {variant,disabled:'true'},
]),cases=['light','dark'].flatMap(mode=>variants.map(v=>({mode,...v})))
 .concat(['light','dark'].map(mode=>({mode,badge:'true',variant:'plain'})));
const only=process.argv.find(a=>a.startsWith('--case='));
const selected=cases.map((item,index)=>({item,index})).filter(r=>!only||r.index===Number(only.split('=')[1]));
const results=[],issues=[],errors=[];let complete=false,version;
const browser=await chromium.launch({channel:'chrome',headless:true});
try {
 version=browser.version();const context=await browser.newContext({viewport:{width:1100,height:800}}),pages={};
 for(const target of ['reference','flutter']) {
  const p=await context.newPage(),cdp=await context.newCDPSession(p);pages[target]=p;p.setDefaultTimeout(15000);
  await cdp.send('Audits.enable');cdp.on('Audits.issueAdded',({issue})=>issues.push({target,...issue}));
  p.on('pageerror',e=>errors.push({target,message:e.message,stack:e.stack}));
 }
 for(const {item,index}of selected) {
  console.log(JSON.stringify({index,...item}));const captures={};
  for(const target of ['reference','flutter']) {
   const p=pages[target],q=new URLSearchParams(item);q.set(target==='reference'?'component':'sample','link');
   await p.bringToFront();await p.goto('http://127.0.0.1:'+(target==='reference'?8767:8766)+'/?'+q,{waitUntil:'networkidle'});
   const group=p.getByRole('group',{name:'Link preview',exact:true}),link=target==='flutter'&&item.disabled==='true'?group.locator('a'):group.getByRole('link');
   await group.waitFor();await link.waitFor();await p.evaluate(()=>document.fonts.ready);await p.waitForTimeout(100);
   const states={};
   for(const state of ['idle','hover','focus']) {
    if(state==='hover')await link.hover();
    if(state==='focus'){await p.mouse.move(0,0);await p.keyboard.press('Tab');}
    await p.waitForTimeout(180);const frame=await link.boundingBox(),path=`${folder}/${index}-${target}-${state}.png`;
    await p.screenshot({path});
    const computed=target==='reference'?await link.evaluate(e=>{const s=getComputedStyle(e);return Object.fromEntries(['fontSize','lineHeight','color','textDecorationColor','textDecorationThickness','textUnderlineOffset','outlineColor','outlineStyle','outlineWidth','borderRadius'].map(k=>[k,s[k]]));}):null;
    states[state]={frame,path,computed,accessibilitySnapshot:await link.ariaSnapshot()};
   }
   // Disabled is a native extension and an explicit application policy in the
   // reference fixture. Kumo does not expose a disabled Link prop.
   if(item.disabled!=='true') {
    await p.keyboard.press('Enter');await p.waitForTimeout(60);
    await p.keyboard.press('Space');await p.waitForTimeout(100);
    assert(await group.getByText('Activations: 1',{exact:true}).count(),'Enter once; Space does not activate');
    await link.click();await p.waitForTimeout(100);
    assert(await group.getByText('Activations: 2',{exact:true}).count(),'pointer activates once');
   }else{
    await link.click({force:true});await p.waitForTimeout(100);
    assert(await group.getByText('Activations: 0',{exact:true}).count(),'disabled blocks activation');
   }
   await group.getByRole('button',{name:'Next action',exact:true}).click();await p.waitForTimeout(100);
   assert(await group.getByText('Activations: '+(item.disabled==='true'?1:3),{exact:true}).count(),'neighbor remains usable');
   captures[target]=states;
  }
  for(const state of ['idle','hover','focus']) {
   const a=captures.reference[state],b=captures.flutter[state];
   const frameDelta=Object.fromEntries(['x','y','width','height'].map(k=>[k,Math.abs(a.frame[k]-b.frame[k])]));
   const geometryPass=Math.max(...Object.values(frameDelta))<=1;
   const [pa,pb]=await Promise.all([a,b].map(async r=>PNG.sync.read(await readFile(r.path))));
   const x=Math.floor(Math.min(a.frame.x,b.frame.x))-4,y=Math.floor(Math.min(a.frame.y,b.frame.y))-4,width=Math.ceil(Math.max(a.frame.x+a.frame.width,b.frame.x+b.frame.width))+4-x,height=Math.ceil(Math.max(a.frame.y+a.frame.height,b.frame.y+b.frame.height))+4-y;
   const crop=p=>{const out=new PNG({width,height});PNG.bitblt(p,out,x,y,width,height,0,0);return out;};
   const ca=crop(pa),cb=crop(pb),diff=new PNG({width,height});
   const pixelDifferenceRatio=pixelmatch(ca.data,cb.data,diff.data,width,height,{threshold:.1})/(width*height),diffPath=`${folder}/${index}-${state}-diff.png`;await writeFile(diffPath,PNG.sync.write(diff));
   results.push({index,...item,state,reference:a,candidate:b,frameDelta,geometryPass,behaviorPass:true,pixelDifferenceRatio,diffPath,region:{x,y,width,height}});
   if(!geometryPass)console.log(JSON.stringify({mismatch:index,state,frameDelta}));
  }
 }complete=true;
}finally {
 await browser.close();const candidateArtifactUnchanged=artifactHash===await hash();
 await writeFile(folder+'/comparison.json',JSON.stringify({success:complete&&candidateArtifactUnchanged&&results.length===selected.length*3&&!errors.length&&results.every(r=>r.geometryPass&&r.behaviorPass),fullRun:!only,referenceSha:'947065ad39694fdc688b1128cc9c360f566a4f73',browser:version,candidateArtifactSha256:artifactHash,candidateArtifactUnchanged,geometryContract:'Link bounds within1px;pointer/Enter once,Space non-activation,disabled and neighbor operation. Disabled is application policy rather than upstream prop. Pixels diagnostic;native underline offset/skip ink,UA focus and all DOM/navigation behavior are not certified.',fullVisualParity:false,results,issues,errors},null,2)+'\n');
}
console.log(JSON.stringify({frames:results.length,issues:issues.length,errors:errors.length,mismatches:results.filter(r=>!r.geometryPass||!r.behaviorPass).map(r=>[r.index,r.state])}));
assert.equal(errors.length,0);assert(results.every(r=>r.geometryPass&&r.behaviorPass));
