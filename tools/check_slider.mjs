import assert from'node:assert/strict';
import{createHash}from'node:crypto';
import{mkdir,readFile,writeFile}from'node:fs/promises';
import{chromium}from'playwright';
import{PNG}from'pngjs';import pixelmatch from'pixelmatch';

const folder=process.env.SLIDER_OUTPUT??'output/playwright/slider';await mkdir(folder,{recursive:true});
const cases=[];
for(const mode of['light','dark'])for(const extra of[
 {value:'0'},{value:'40',keyboard:true},{value:'100'},
 {size:'sm',value:'40'},{disabled:'true'},{noLabel:'true'},
 {value:'0',alignment:'center'},{values:'0,100'},
 {values:'25,75',keyboard:true},{values:'25,75',collision:'none',drag:true},
 {values:'25,75',collision:'swap',drag:true},{values:'20,50,80',gap:'10',drag:true},
 {values:'25,75',gap:'10',drag:true},{value:'40',drag:true},
 {value:'0.25',min:'-0.25',max:'0.75',step:'0.1',format:'decimal'},
 {values:'25,75',direction:'rtl',drag:true,keyboard:true},{direction:'rtl',keyboard:true},
 {uncontrolled:'true',keyboard:true},{cancel:'true',drag:true},{frozen:'true',drag:true},
 {host:'160',values:'25,75'},{locale:'de',format:'decimal'},
])cases.push({mode,...extra});
const only=process.argv.find(s=>s.startsWith('--case=')),selected=cases.map((item,index)=>({item,index})).filter(({index})=>!only||index===Number(only.split('=')[1]));
const results=[],issues=[],errors=[];let version,completed=false;const b=await chromium.launch({channel:'chrome',headless:true});
const state=async(p,target)=>JSON.parse(await(target==='reference'?p.getByRole('status'):p.locator('flt-semantics').getByText(/^\{"value":.*\}$/,{exact:true})).textContent());
const delta=(a,b)=>Object.fromEntries(['x','y','width','height'].map(k=>[k,Math.abs(a[k]-b[k])]));
const waitState=async(p,target,condition)=>{for(let n=0;n<100;n++){const s=await state(p,target);if(condition(s))return s;await p.waitForTimeout(20);}assert.fail('State did not settle');};
try{
 version=b.version();const context=await b.newContext({viewport:{width:1000,height:400}}),pages={};
 for(const target of['reference','flutter']){const p=await context.newPage();p.setDefaultTimeout(15000);pages[target]=p;const cdp=await context.newCDPSession(p);await cdp.send('Audits.enable');cdp.on('Audits.issueAdded',({issue})=>issues.push({target,...issue}));p.on('pageerror',e=>errors.push({target,message:e.message}));}
 for(const{item,index}of selected){
  console.log(JSON.stringify({index,...item}));const captures={};
  for(const target of['reference','flutter']){
   const p=pages[target],q=new URLSearchParams(Object.entries(item).filter(([k])=>!['keyboard','drag'].includes(k)));q.set(target==='reference'?'component':'sample','slider');
   await p.goto('http://127.0.0.1:'+(target==='reference'?8767:8766)+'/?'+q,{waitUntil:'networkidle'});const g=p.getByRole('group',{name:'Slider preview',exact:true});await g.waitFor();await p.evaluate(()=>document.fonts.ready);
   const rows=[],capture=async step=>{
    await p.waitForTimeout(50);const sliders=g.getByRole('slider'),thumbs=[];
    for(const e of await sliders.all())thumbs.push(await e.evaluate(e=>({bounds:e.parentElement.getBoundingClientRect().toJSON(),name:e.getAttribute('aria-label')??e.parentElement.getAttribute('aria-label'),now:e.getAttribute('aria-valuenow'),text:e.getAttribute('aria-valuetext'),min:e.getAttribute('aria-valuemin'),max:e.getAttribute('aria-valuemax'),disabled:e.disabled})));
    const path=`${folder}/${index}-${step}-${target}.png`,frame=await g.boundingBox();await p.screenshot({path});rows.push({step,path,frame,thumbs,status:await state(p,target)});
   };
   await capture('idle');
   if(item.keyboard){
    const first=g.getByRole('slider').first();await first.focus();await p.keyboard.press('Tab');await p.keyboard.press('Shift+Tab');await p.waitForTimeout(60);await capture('focus');
    for(const key of['ArrowRight','Shift+ArrowUp','PageDown','Home','End','End']){await p.keyboard.press(key);await p.waitForTimeout(60);await capture(key.replaceAll('+','-'));}
   }
   if(item.drag){
    const thumb=g.getByRole('slider').first();const r=await thumb.evaluate(e=>e.parentElement.getBoundingClientRect().toJSON()),frame=await g.boundingBox();
    const min=Number(item.min??0),max=Number(item.max??100),logical=n=>(n-min)/(max-min),x=n=>frame.x+11+(frame.width-22)*(item.direction==='rtl'?1-logical(n):logical(n));
    await p.mouse.move(r.x+r.width/2,r.y+r.height/2);await p.mouse.down();await p.mouse.move(x(90),r.y+r.height/2);await p.waitForTimeout(50);await capture('drag-forward');
    await p.mouse.move(x(30),r.y+r.height/2);await p.waitForTimeout(50);await capture('drag-back');await p.mouse.up();await p.waitForTimeout(60);await capture('released');
   }
   const before=await state(p,target);await p.getByRole('button',{name:'After slider',exact:true}).click();await waitState(p,target,s=>s.calls===before.calls+1);await capture('after-button');
   captures[target]=rows;
  }
  const states=[];
  for(const[n,a]of captures.reference.entries()){
   const c=captures.flutter[n];assert.equal(a.step,c.step);assert.deepEqual(c.status,a.status,`Case${index}/${a.step} callback/value contract`);
   const frameDelta=delta(a.frame,c.frame),thumbDeltas=[];
   if(item.disabled!=='true'){
    assert.equal(c.thumbs.length,a.thumbs.length,`Case${index} thumb semantics count`);
    for(let i=0;i<a.thumbs.length;i++){
     assert.equal(c.thumbs[i].text?.split(' ')[0],a.thumbs[i].text?.split(' ')[0]??String(a.status.value instanceof Array?a.status.value[i]:a.status.value),`Case${index}/${a.step} accessible value`);
     thumbDeltas.push(delta(a.thumbs[i].bounds,c.thumbs[i].bounds));
    }
   }
   const geometryPass=Math.max(...Object.values(frameDelta),...thumbDeltas.flatMap(Object.values))<=1;
   const[pa,pb]=await Promise.all([a,c].map(async r=>PNG.sync.read(await readFile(r.path))));
   const x=Math.floor(Math.min(a.frame.x,c.frame.x))-10,y=Math.floor(Math.min(a.frame.y,c.frame.y)),width=Math.ceil(Math.max(a.frame.x+a.frame.width,c.frame.x+c.frame.width))+10-x,height=Math.ceil(Math.max(a.frame.y+a.frame.height,c.frame.y+c.frame.height))-y;
   const crop=p=>{const q=new PNG({width,height});PNG.bitblt(p,q,x,y,width,height,0,0);return q;},ca=crop(pa),cb=crop(pb),diff=new PNG({width,height});const ratio=pixelmatch(ca.data,cb.data,diff.data,width,height,{threshold:.1})/(width*height),diffPath=`${folder}/${index}-${a.step}-diff.png`;await writeFile(diffPath,PNG.sync.write(diff));
   states.push({step:a.step,reference:a,candidate:c,frameDelta,thumbDeltas,geometryPass,pixelDifferenceRatio:ratio,diffPath,region:{x,y,width,height}});
  }
  results.push({index,...item,states});
 }
 completed=results.every(r=>r.states.every(s=>s.geometryPass));
}finally{
 await b.close();await writeFile(folder+'/comparison.json',JSON.stringify({success:completed&&results.length===selected.length&&!errors.length,fullRun:!only,referenceSha:'947065ad39694fdc688b1128cc9c360f566a4f73',baseUiVersion:'1.9.0',browser:version,candidateArtifactSha256:createHash('sha256').update(await readFile('apps/demo/build/web/main.dart.wasm')).digest('hex'),geometryContract:'Host and enabled thumb bounds within1px. Disabled Flutter semantics and Web surrogate min/max/now differ from native HTML range; formatted aria-valuetext is compared. Pixel diagnostics retain native font/ring differences and do not certify whole-library parity.',fullVisualParity:false,results,issues,errors},null,2)+'\n');
}
const mismatches=results.flatMap(r=>r.states.filter(s=>!s.geometryPass).map(s=>({index:r.index,step:s.step,frame:s.frameDelta,thumbs:s.thumbDeltas})));console.log(JSON.stringify({contexts:results.length,states:results.reduce((n,r)=>n+r.states.length,0),issues:issues.length,errors:errors.length,mismatches}));assert.equal(errors.length,0);assert.equal(mismatches.length,0);
