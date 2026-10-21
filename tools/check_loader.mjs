import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {mkdir,readFile,writeFile} from 'node:fs/promises';
import {chromium} from 'playwright';
import {PNG} from 'pngjs';import pixelmatch from 'pixelmatch';
const folder='output/playwright/loader';await mkdir(folder,{recursive:true});
const frames=JSON.parse(await readFile(folder+'/native/frames.json','utf8')),timeline=[],web=[],errors=[],issues=[];let version;
const browser=await chromium.launch({channel:'chrome',headless:true});
try{
 version=browser.version();const page=await browser.newPage({viewport:{width:600,height:300}});page.on('pageerror',e=>errors.push(e.message));let last='';
 for(const frame of frames){
  const key=[frame.mode,frame.size??'skeleton'].join('-');
  if(key!==last){await page.goto('http://127.0.0.1:8767/?'+new URLSearchParams({component:'loader',mode:frame.mode,...(frame.kind?{kind:frame.kind}:{size:String(frame.size)})}),{waitUntil:'networkidle'});last=key;}
  await page.evaluate(ms=>{const svg=document.querySelector('[role=status]');if(svg){svg.pauseAnimations();svg.setCurrentTime(ms/1000);}for(const a of document.getAnimations()){a.pause();a.currentTime=ms;}},frame.ms);
  await page.waitForTimeout(20);const path=folder+'/reference-'+frame.file;await page.getByRole('group',{name:'Loader preview',exact:true}).screenshot({path});
  const[a,b]=await Promise.all([folder+'/native/'+frame.file,path].map(async p=>PNG.sync.read(await readFile(p))));assert.equal(a.width,b.width);assert.equal(a.height,b.height);const diff=new PNG({width:a.width,height:a.height});const count=pixelmatch(a.data,b.data,diff.data,a.width,a.height,{threshold:.1});const diffPath=folder+'/diff-'+frame.file;await writeFile(diffPath,PNG.sync.write(diff));timeline.push({...frame,nativePath:folder+'/native/'+frame.file,referencePath:path,diffPath,changedPixels:count,pixelDifferenceRatio:count/(a.width*a.height)});
 }
 console.log(JSON.stringify({timelineFrames:timeline.length,maxPixelRatio:Math.max(...timeline.map(x=>x.pixelDifferenceRatio))}));
 const cdp=await page.context().newCDPSession(page);await cdp.send('Audits.enable');cdp.on('Audits.issueAdded',({issue})=>issues.push(issue));
 for(const mode of ['light','dark'])for(const config of [{size:'sm'},{size:'base'},{size:'lg'},{size:'45'},{size:'0'},{size:'24',color:'red'},{size:'32',direction:'rtl'},{kind:'skeleton'},{kind:'skeleton',block:'true'}]){
  console.log(JSON.stringify({mode,...config}));await page.emulateMedia({reducedMotion:'reduce'});await page.goto('http://127.0.0.1:8766/?'+new URLSearchParams({sample:'loader',mode,...config}),{waitUntil:'networkidle'});const group=config.size==='0'||config.kind?page.getByText('Loader preview',{exact:true}).locator('..'):page.getByRole('group',{name:'Loader preview',exact:true});await group.waitFor();
  if(config.size==='0'){assert.equal(await page.getByRole('status').count(),0);}else if(!config.kind){const node=page.getByRole('status',{name:'読み込み中',exact:true});await node.waitFor({state:config.size==='0'?'attached':'visible'});const rect=await node.boundingBox(),expected=Number(config.size)||({sm:16,base:24,lg:32}[config.size]??0);if(rect){assert.equal(rect.width,expected);assert.equal(rect.height,expected);}}
  else assert.equal(await page.getByRole('status').count(),0);
  const a=await group.screenshot();await page.waitForTimeout(230);const b=await group.screenshot();const moving=!a.equals(b);if(config.size!=='0')assert(moving,'Reduced-motion override keeps animation active');const path=folder+'/web-'+web.length+'.png';await writeFile(path,b);web.push({mode,...config,moving,path});
 }
}finally{await browser.close();await writeFile(folder+'/comparison.json',JSON.stringify({success:timeline.length===90&&web.length===18&&!errors.length,referenceSha:'947065ad39694fdc688b1128cc9c360f566a4f73',browser:version,candidateArtifactSha256:createHash('sha256').update(await readFile('apps/demo/build/web/main.dart.wasm')).digest('hex'),timelineKind:'Flutter software widget raster at exact pump times versus official SVG SMIL/CSS setCurrentTime. Web build dimensions/status/movement tested separately; not a claim of phase-synchronized Flutter Web frames.',fullVisualParity:false,timeline,web,errors,issues},null,2)+'\n');}
assert.equal(errors.length,0);assert.equal(timeline.length,90);assert.equal(web.length,18);console.log(JSON.stringify({success:true,frames:timeline.length,webContexts:web.length}));
