import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {mkdir,readFile,writeFile} from 'node:fs/promises';
import {chromium} from 'playwright';
import {PNG} from 'pngjs';
import pixelmatch from 'pixelmatch';

const folder=process.env.METER_OUTPUT??'output/playwright/meter';await mkdir(folder,{recursive:true});
const cases=[];
for(const mode of ['light','dark'])for(const extra of [
 ...['0','25','65','100','-25','125','NaN','Infinity','-Infinity'].map(value=>({value})),
 {value:'50',min:'20',max:'80'},{value:'15',min:'20',max:'80'},
 {value:'85',min:'20',max:'80'},{value:'-30',min:'-100',max:'0'},
 {hide:'true'},{custom:'650 / 1,000 GB'},{custom:'650 / 1,000 GB',hide:'true'},
 {custom:''},{format:'decimal',value:'65.25'},{format:'currency',value:'125'},
 {locale:'de'},{locale:'fr'},{direction:'rtl'},{host:'160',long:'true'},
 {color:'green'},{aria:'true',value:'125'},
])cases.push({mode,...extra});
const only=process.argv.find(s=>s.startsWith('--case=')),selected=cases.map((item,index)=>({item,index})).filter(({index})=>!only||index===Number(only.split('=')[1]));
const results=[],timeline=[],motion=[],errors=[],issues=[];let version,completed=false;
const browser=await chromium.launch({channel:'chrome',headless:true});
const delta=(a,b)=>Object.fromEntries(['x','y','width','height'].map(k=>[k,Math.abs(a[k]-b[k])]));
const colorRun=(png,rect)=>{const y=Math.min(png.height-1,Math.floor(rect.y+rect.height-4)),xs=[];for(let x=Math.ceil(rect.x);x<rect.x+rect.width;x++){const n=(y*png.width+x)*4,c=[png.data[n],png.data[n+1],png.data[n+2]];if(Math.max(...c)-Math.min(...c)>20)xs.push(x);}return{first:xs.length?xs[0]:null,last:xs.length?xs.at(-1):null,pixels:xs.length};};
try{
 version=browser.version();const context=await browser.newContext({viewport:{width:600,height:300}}),pages={};
 for(const target of ['reference','flutter']){
  const p=await context.newPage();p.setDefaultTimeout(30000);pages[target]=p;const cdp=await context.newCDPSession(p);await cdp.send('Audits.enable');cdp.on('Audits.issueAdded',({issue})=>issues.push({target,...issue}));p.on('pageerror',e=>errors.push({target,message:e.message}));
 }
 for(const {item,index}of selected){
  console.log(JSON.stringify({index,...item}));const captures={};
  for(const target of ['reference','flutter']){
   const p=pages[target],q=new URLSearchParams(item);q.set(target==='reference'?'component':'sample','meter');
   await p.goto('http://127.0.0.1:'+(target==='reference'?8767:8766)+'/?'+q,{waitUntil:'networkidle'});
   const group=p.getByRole('group',{name:'Meter preview',exact:true});await group.waitFor();await p.evaluate(()=>document.fonts.ready);
   const meter=group.getByRole(target==='reference'?'meter':'progressbar');await meter.waitFor();assert((await meter.getAttribute(target==='reference'?'aria-labelledby':'aria-label'))?.length);
   const bounds=await meter.boundingBox(),frame=await group.boundingBox(),path=`${folder}/${index}-${target}.png`;
   await p.screenshot({path});const png=PNG.sync.read(await readFile(path));
   const attrs=await meter.evaluate(e=>Object.fromEntries(['role','aria-valuemin','aria-valuemax','aria-valuenow','aria-valuetext','aria-describedby','aria-description'].map(k=>[k,e.getAttribute(k)])));
   captures[target]={path,bounds,frame,attrs,fill:colorRun(png,bounds)};
  }
  const a=captures.reference,b=captures.flutter;
  for(const k of ['aria-valuemin','aria-valuemax','aria-valuenow'])assert.equal(Number(a.attrs[k]),Number(b.attrs[k]),`${index} ${k}`);
  const meterDelta=delta(a.bounds,b.bounds),frameDelta=delta(a.frame,b.frame),fillDelta=Math.abs(a.fill.pixels-b.fill.pixels);
  const geometryPass=Math.max(...Object.values(meterDelta),...Object.values(frameDelta),fillDelta)<=1;
  const [pa,pb]=await Promise.all([a,b].map(async c=>PNG.sync.read(await readFile(c.path))));
  const x=Math.floor(Math.min(a.bounds.x,b.bounds.x)),y=Math.floor(Math.min(a.bounds.y,b.bounds.y)),width=Math.ceil(Math.max(a.bounds.x+a.bounds.width,b.bounds.x+b.bounds.width))-x,height=Math.ceil(Math.max(a.bounds.y+a.bounds.height,b.bounds.y+b.bounds.height))-y;
  const crop=p=>{const q=new PNG({width,height});PNG.bitblt(p,q,x,y,width,height,0,0);return q;},ca=crop(pa),cb=crop(pb),diff=new PNG({width,height});
  const ratio=pixelmatch(ca.data,cb.data,diff.data,width,height,{threshold:.1})/(width*height),diffPath=`${folder}/${index}-diff.png`;await writeFile(diffPath,PNG.sync.write(diff));
  results.push({index,...item,reference:a,candidate:b,meterDelta,frameDelta,fillDelta,geometryPass,pixelDifferenceRatio:ratio,diffPath,region:{x,y,width,height}});
 }
 if(!only){
  const frames=JSON.parse(await readFile(folder+'/native/frames.json','utf8'));let last='';
  const p=pages.reference;
  for(const frame of frames){
   const key=frame.mode+'-'+frame.direction;
   if(last!==key){await p.goto('http://127.0.0.1:8767/?'+new URLSearchParams({component:'meter',mode:frame.mode,direction:frame.direction,value:'25',target:'75'}),{waitUntil:'networkidle'});await p.getByRole('button',{name:'Change value',exact:true}).click();await p.locator('.review-meter-indicator').evaluate(e=>{for(const a of e.getAnimations())a.pause()});last=key;}
   await p.locator('.review-meter-indicator').evaluate((e,ms)=>{for(const a of e.getAnimations()){a.pause();a.currentTime=ms}},frame.ms);await p.waitForTimeout(20);
   const path=folder+'/reference-'+frame.file;await p.getByRole('group',{name:'Meter preview',exact:true}).screenshot({path});
   const [a,b]=await Promise.all([folder+'/native/'+frame.file,path].map(async path=>PNG.sync.read(await readFile(path))));assert.equal(a.width,b.width);assert.equal(a.height,b.height);const diff=new PNG({width:a.width,height:a.height});const ratio=pixelmatch(a.data,b.data,diff.data,a.width,a.height,{threshold:.1})/(a.width*a.height),diffPath=folder+'/diff-'+frame.file;await writeFile(diffPath,PNG.sync.write(diff));
   const indicator=await p.locator('.review-meter-indicator').boundingBox();const widthDelta=Math.abs(indicator.width-320*frame.fraction);assert(widthDelta<=1,'Controlled phase width');timeline.push({...frame,nativePath:folder+'/native/'+frame.file,referencePath:path,diffPath,pixelDifferenceRatio:ratio,widthDelta});
  }
  for(const mode of ['light','dark']){
   const p=pages.flutter;await p.emulateMedia({reducedMotion:'reduce'});await p.goto('http://127.0.0.1:8766/?'+new URLSearchParams({sample:'meter',mode,value:'0',target:'100'}),{waitUntil:'networkidle'});
   const g=p.getByRole('group',{name:'Meter preview',exact:true});await g.waitFor();const before=PNG.sync.read(await g.screenshot());await p.getByRole('button',{name:'Change value',exact:true}).click();await p.waitForTimeout(70);const during=PNG.sync.read(await g.screenshot());await p.waitForTimeout(350);const after=PNG.sync.read(await g.screenshot());
   const a=colorRun(before,{x:0,y:44,width:320,height:32}),b=colorRun(during,{x:0,y:44,width:320,height:32}),c=colorRun(after,{x:0,y:44,width:320,height:32});assert.equal(a.pixels,0);assert(b.pixels>0&&b.pixels<c.pixels,'Reduced-motion still transitions');assert(c.pixels>=318);motion.push({mode,before:a,during:b,after:c});
  }
 }
 completed=true;
}finally{
 await browser.close();await writeFile(folder+'/comparison.json',JSON.stringify({success:completed&&results.length===selected.length&&!errors.length&&results.every(r=>r.geometryPass),fullRun:!only,browser:version,referenceSha:'947065ad39694fdc688b1128cc9c360f566a4f73',baseUiVersion:'1.9.0',candidateArtifactSha256:createHash('sha256').update(await readFile('apps/demo/build/web/main.dart.wasm')).digest('hex'),geometryContract:'Meter/host bounds and colored fill width within1px. Software widget-raster transition phases are separate from unsynchronized Flutter Web frames. Native progressbar role and formatted hint differ from upstream meter/aria-valuetext. No full visual certification.',fullVisualParity:false,results,timeline,motion,issues,errors},null,2)+'\n');
}
const mismatches=results.filter(r=>!r.geometryPass).map(r=>({index:r.index,meterDelta:r.meterDelta,fillDelta:r.fillDelta}));console.log(JSON.stringify({contexts:results.length,frames:timeline.length,motion:motion.length,issues:issues.length,errors:errors.length,mismatches}));assert.equal(errors.length,0);assert.equal(mismatches.length,0);
