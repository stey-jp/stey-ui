import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {mkdir,readFile,writeFile} from 'node:fs/promises';
import {chromium} from 'playwright';
import {PNG} from 'pngjs';
import pixelmatch from 'pixelmatch';

const folder=process.env.BADGE_OUTPUT??'output/playwright/badge';await mkdir(folder,{recursive:true});
const variants=['primary','secondary','error','warning','success','destructive','info','beta','outline','red','green','neutral','orange','purple','teal','teal-subtle','blue'];
const cases=[];
for(const mode of ['light','dark']){
 for(const variant of variants)for(const appearance of ['filled','dot'])cases.push({mode,variant,appearance});
 for(const variant of variants)cases.push({mode,variant,icon:'true'});
 for(const variant of ['primary','beta','outline','success'])for(const appearance of ['filled','dot'])cases.push({mode,variant,appearance,link:'true'});
 for(const extra of [{long:'true',host:'160'},{empty:'true'},{empty:'true',icon:'true'},{empty:'true',appearance:'dot'},{icon:'true',scale:'2'},{icon:'true',direction:'rtl'},{appearance:'dot',link:'true',direction:'rtl'}])cases.push({mode,variant:'success',...extra});
}
const only=process.argv.find(s=>s.startsWith('--case='));const selected=cases.map((item,index)=>({item,index})).filter(({index})=>!only||index===Number(only.split('=')[1]));
const results=[],issues=[],errors=[];let version;
const browser=await chromium.launch({channel:'chrome',headless:true});
try{
 version=browser.version();const context=await browser.newContext({viewport:{width:600,height:300}}),pages={};
 for(const target of ['reference','flutter']){
  const page=await context.newPage(),cdp=await context.newCDPSession(page);pages[target]=page;
  await cdp.send('Audits.enable');cdp.on('Audits.issueAdded',({issue})=>issues.push({target,...issue}));page.on('pageerror',e=>errors.push({target,message:e.message}));
 }
 for(const {item,index}of selected){
  console.log(JSON.stringify({index,...item}));const captures={};
  for(const target of ['reference','flutter']){
   const page=pages[target],url=new URL('http://127.0.0.1:'+(target==='reference'?8767:8766)+'/');url.searchParams.set(target==='reference'?'component':'sample','badge');for(const[k,v]of Object.entries(item))url.searchParams.set(k,v);
   await page.goto(url.href,{waitUntil:'networkidle'});const group=page.getByRole('group',{name:'Badge preview',exact:true});await group.waitFor();
   const badge=target==='reference'?group.locator('[data-kumo-component="Badge"]'):item.empty==='true'?group.getByText('Badge target',{exact:true}).locator('..'):group.getByRole('group',{name:'Badge target',exact:true});await badge.waitFor();await page.evaluate(()=>document.fonts.ready);
   const rows=[],capture=async step=>{
    const bounds=await badge.boundingBox(),frame=await group.boundingBox(),path=folder+'/'+index+'-'+step+'-'+target+'.png';await page.screenshot({path});
    const crop={x:Math.floor(bounds.x)-3,y:Math.floor(bounds.y)-3,width:Math.ceil(bounds.x+bounds.width)+3-(Math.floor(bounds.x)-3),height:Math.ceil(bounds.y+bounds.height)+3-(Math.floor(bounds.y)-3)};
    rows.push({step,path,bounds,frame,crop,referenceStyle:target==='reference'?await badge.evaluate(e=>{const s=getComputedStyle(e);return{background:s.backgroundColor,color:s.color,border:s.border,boxShadow:s.boxShadow,fontSize:s.fontSize,lineHeight:s.lineHeight};}):undefined});
   };
   await page.mouse.move(1,1);await page.waitForTimeout(40);await capture('idle');
   if(item.link==='true'){
    const link=group.getByRole('link');assert.equal(await link.getAttribute('href'),target==='reference'?'#badge':new URL('#badge',url).href);
    const r=await link.boundingBox();await page.mouse.move(r.x+2,r.y+2);await page.waitForTimeout(30);await capture('ancestor-hover');
    await page.mouse.move(1,1);await page.keyboard.press('Tab');await page.keyboard.press('Enter');await page.getByText('Link calls: 1',{exact:true}).or(page.locator('[aria-label="Link calls: 1"]')).first().waitFor();
    await page.keyboard.press('Space');assert(await page.getByText('Link calls: 1',{exact:true}).or(page.locator('[aria-label="Link calls: 1"]')).count());await capture('keyboard');
    await link.click();await page.getByText('Link calls: 2',{exact:true}).or(page.locator('[aria-label="Link calls: 2"]')).first().waitFor();assert.equal(new URL(page.url()).search,url.search);await capture('pointer');
    await page.mouse.move(1,1);await page.waitForTimeout(30);await capture('exit');
   }else{
    const r=await badge.boundingBox();await page.mouse.move(r.x+r.width/2,r.y+r.height/2);await page.waitForTimeout(30);await capture('direct-hover');
   }
   captures[target]=rows;
  }
  const states=[];
  for(const [n,a]of captures.reference.entries()){
   const b=captures.flutter[n];assert.equal(a.step,b.step);const delta=(x,y)=>Object.fromEntries(['x','y','width','height'].map(k=>[k,Math.abs(x[k]-y[k])]));
   const badgeDelta=delta(a.bounds,b.bounds),frameDelta=delta(a.frame,b.frame),geometryPass=Math.max(...Object.values(badgeDelta),...Object.values(frameDelta))<=1;
   const [pa,pb]=await Promise.all([a,b].map(async c=>PNG.sync.read(await readFile(c.path))));const diff=new PNG({width:pa.width,height:pa.height});const whole=pixelmatch(pa.data,pb.data,diff.data,pa.width,pa.height,{threshold:.1})/(pa.width*pa.height);await writeFile(folder+'/'+index+'-'+a.step+'-diff.png',PNG.sync.write(diff));
   const x=Math.floor(Math.min(a.bounds.x,b.bounds.x))-3,y=Math.floor(Math.min(a.bounds.y,b.bounds.y))-3,w=Math.ceil(Math.max(a.bounds.x+a.bounds.width,b.bounds.x+b.bounds.width))+3-x,h=Math.ceil(Math.max(a.bounds.y+a.bounds.height,b.bounds.y+b.bounds.height))+3-y;
   const ca=new PNG({width:w,height:h}),cb=new PNG({width:w,height:h});PNG.bitblt(pa,ca,x,y,w,h,0,0);PNG.bitblt(pb,cb,x,y,w,h,0,0);const roiDiff=new PNG({width:w,height:h});const ratio=pixelmatch(ca.data,cb.data,roiDiff.data,w,h,{threshold:.1})/(w*h);const roi=folder+'/'+index+'-'+a.step+'-badge-diff.png';await writeFile(roi,PNG.sync.write(roiDiff));
   states.push({step:a.step,captures:[a,b],badgeGeometryDelta:badgeDelta,frameGeometryDelta:frameDelta,geometryPass,pixelDifferenceRatio:whole,badgeRegion:{x,y,width:w,height:h,pixelDifferenceRatio:ratio,diffPath:roi}});
  }
  results.push({index,...item,states});
 }
}finally{
 await browser.close();await writeFile(folder+'/comparison.json',JSON.stringify({success:results.length===selected.length&&!errors.length&&results.every(r=>r.states.every(s=>s.geometryPass)),fullRun:selected.length===cases.length,browser:version,
  referenceSha:'7e0ff40546f08405d05bc9754f0ff0fd009ece0a',latestObservedSha:'947065ad39694fdc688b1128cc9c360f566a4f73',candidateArtifactSha256:createHash('sha256').update(await readFile('apps/demo/build/web/main.dart.wasm')).digest('hex'),
  geometryContract:'Badge and host rectangles within 1 CSS px. Badge-only and viewport pixel diagnostics retain unaligned glyph/dash/native focus differences, not a full visual certification.',fullVisualParity:false,results,issues,errors},null,2)+'\n');
}
assert.equal(errors.length,0);const mismatches=results.flatMap(r=>r.states.filter(s=>!s.geometryPass).map(s=>({index:r.index,step:s.step,badge:s.badgeGeometryDelta,frame:s.frameGeometryDelta})));
console.log(JSON.stringify({contexts:results.length,states:results.reduce((n,r)=>n+r.states.length,0),issues:issues.length,errors:errors.length,geometryMismatches:mismatches}));assert.equal(mismatches.length,0);
