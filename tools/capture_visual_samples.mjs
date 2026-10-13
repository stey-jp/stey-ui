import {chromium} from 'playwright';
import {mkdir,readFile,writeFile} from 'node:fs/promises';
import {resolve} from 'node:path';
import {PNG} from 'pngjs';
import pixelmatch from 'pixelmatch';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
const output=resolve('output/visual-samples');await mkdir(output,{recursive:true});
const candidateSourceSha=execFileSync('git',['rev-parse','HEAD'],{encoding:'utf8'}).trim();
if(execFileSync('git',['diff','HEAD','--','packages/stey_ui_modern/lib','apps/demo/lib'],{encoding:'utf8'}).trim())throw Error('SAMPLE_PRODUCT_SOURCE_UNCOMMITTED');
const candidateWasmSha256=createHash('sha256').update(await readFile(resolve('apps/demo/build/web/main.dart.wasm'))).digest('hex');
const referenceRuntime=process.env.KUMO_REFERENCE_DIRECTORY?Object.fromEntries(await Promise.all(['react','react-dom','@base-ui/react','@phosphor-icons/react','tailwindcss'].map(async name=>[name,JSON.parse(await readFile(resolve(process.env.KUMO_REFERENCE_DIRECTORY,'node_modules',name,'package.json'),'utf8')).version]))):null;
if(!referenceRuntime)throw Error('SAMPLE_REFERENCE_RUNTIME_UNSPECIFIED');
const expectedRuntime={'react':'19.2.0','react-dom':'19.2.0','@base-ui/react':'1.9.0','@phosphor-icons/react':'2.1.10','tailwindcss':'4.3.3'};
if(Object.entries(expectedRuntime).some(([name,version])=>referenceRuntime[name]!==version))throw Error('SAMPLE_REFERENCE_RUNTIME_DIFFERS_FROM_UPSTREAM_LOCK');
function paintedBounds(a,b){
 let left=a.width,top=a.height,right=-1,bottom=-1;
 for(let y=0;y<a.height;y++)for(let x=0;x<a.width;x++){
  const offset=(y*a.width+x)*4;
  if([a,b].some(png=>[0,1,2].some(channel=>Math.abs(png.data[offset+channel]-png.data[channel])>4))){
   left=Math.min(left,x);top=Math.min(top,y);right=Math.max(right,x);bottom=Math.max(bottom,y);
  }
 }
 return right<0?null:{left,top,width:right-left+1,height:bottom-top+1};
}
const badgeVariants=['primary','secondary','error','warning','success','destructive','info','beta','outline','red','green','neutral','orange','purple','teal','tealSubtle','blue'];
const buttonVariants=['primary','secondary','ghost','destructive','secondaryDestructive','outline'];
const samples=[];
for(const variant of buttonVariants)for(const state of ['idle','hover','focus','disabled','loading'])samples.push({component:'button',variant,state});
for(const size of ['xs','sm','base','lg'])for(const shape of ['base','square','circle'])if(size!=='base'||shape!=='base')samples.push({component:'button',variant:'secondary',size,shape});
for(const variant of badgeVariants)for(const appearance of ['filled','dot'])samples.push({component:'badge',variant,appearance});
samples.push({component:'input',variant:'default'});
for(const variant of ['default','error'])for(const checked of ['false','true','mixed'])for(const state of ['idle','hover','focus','disabled'])samples.push({component:'checkbox',variant,checked,state});
for(const variant of ['default','neutral'])for(const size of ['sm','base','lg'])for(const checked of ['false','true'])for(const state of ['idle','hover','focus','disabled'])samples.push({component:'switch',variant,size,checked,state});
for(const variant of ['default','error'])for(const checked of ['false','true'])for(const state of ['idle','hover','focus','disabled'])samples.push({component:'radio',variant,checked,state});
for(const size of ['xs','sm','base','lg'])for(const state of ['idle','hover','focus','disabled','readonly','error','loading','open'])samples.push({component:'select',variant:'default',size,state});
const requestedComponents=process.argv.find(argument=>argument.startsWith('--components='))?.slice(13).split(',');
if(requestedComponents?.some(component=>!['button','badge','input','checkbox','switch','radio','select'].includes(component)))throw Error('SAMPLE_COMPONENT_INVALID');
const requestedState=process.argv.find(argument=>argument.startsWith('--state='))?.slice(8);
if(requestedState&&!['idle','hover','focus','disabled','loading','readonly','error','open'].includes(requestedState))throw Error('SAMPLE_STATE_INVALID');
const selectedSamples=samples.filter(sample=>(!requestedState||(sample.state??'idle')===requestedState)&&(!requestedComponents||requestedComponents.includes(sample.component)));
const previous=requestedState||requestedComponents?JSON.parse(await readFile(resolve(output,'report.json'),'utf8')):null;
if(previous&&previous.upstreamSha!=='f46e8bc9922c37dc1d3e7da779e589fe171df306')throw Error('SAMPLE_UPSTREAM_CHANGED');
const browser=await chromium.launch({channel:'chrome',headless:true});const rows=[];
try{
 for(const mode of ['light','dark']){
  for(const sample of selectedSamples){
   const context=await browser.newContext({viewport:{width:600,height:sample.component==='select'?360:160},colorScheme:mode});
   const reference=await context.newPage(),candidate=await context.newPage();
   const {component,variant,size='base',shape='base',state='idle',appearance='filled',checked}=sample;
   const id=[component,variant,appearance==='dot'?'dot':null,size!=='base'?size:null,shape!=='base'?shape:null,checked,state!=='idle'?state:null,mode].filter(Boolean).join('-');
   const upstreamVariant=variant==='secondaryDestructive'?'secondary-destructive':variant==='tealSubtle'?'teal-subtle':variant;
   const parameters={variant:upstreamVariant,appearance,mode,size,shape,state};
   if(checked!==undefined)parameters.checked=checked;
   const role=component==='checkbox'?'checkbox':component==='switch'?'switch':component==='radio'?'radio':component==='input'?'textbox':'button';
   const name=['checkbox','switch','radio'].includes(component)?'Toggle':component==='input'?'Name':'Save';
   const target=page=>component==='select'?page.getByRole(page===reference?'combobox':'button',{name:/^Choice(?:\s|$)/}):page.getByRole(role,{name,exact:true});
   const referenceResponse=await reference.goto('http://127.0.0.1:8767/?'+new URLSearchParams({component,...parameters}),{waitUntil:'networkidle'});
   if(!referenceResponse.ok())throw Error('SAMPLE_REFERENCE_HTTP_ERROR:'+id+':'+referenceResponse.status());
   if(component==='input')await reference.locator('input').waitFor();
   else if(component==='badge')await reference.getByText('Active',{exact:true}).waitFor();
   else await target(reference).waitFor().catch(async error=>{
    await reference.screenshot({path:resolve(output,id+'-reference-failed.png')});
    throw Error('SAMPLE_REFERENCE_NOT_RENDERED:'+id,{cause:error});
   });
   await reference.evaluate(()=>document.fonts.ready);
   await candidate.goto('http://127.0.0.1:8766/?'+new URLSearchParams({sample:component,...parameters,variant}),{waitUntil:'networkidle'});
   if(component==='badge')await candidate.getByText('Active',{exact:true}).waitFor();
   else await target(candidate).waitFor();
   for(const page of [reference,candidate]){
    await page.mouse.click(20,20);
    if(state==='hover')await target(page).hover();
    if(state==='open')await target(page).click();
    if(state==='focus'){
     const button=target(page);
     if(['checkbox','switch','radio','select'].includes(component)){
      await page.mouse.move(20,20);
      for(let step=0;step<8;step++){
       await page.keyboard.press('Tab');
       if(await button.evaluate(element=>element===document.activeElement))break;
      }
     }else{
     await button.click();await page.mouse.move(20,20);await page.keyboard.press('Tab');
     if(page===reference)await page.keyboard.press('Shift+Tab');
     }
     if(!await button.evaluate(element=>element===document.activeElement))throw Error('SAMPLE_KEYBOARD_FOCUS_MISSING');
    }
    await page.evaluate(()=>new Promise(resolve=>requestAnimationFrame(()=>requestAnimationFrame(resolve))));
   }
   const ref=await reference.screenshot({path:resolve(output,id+'-reference.png')});
   const actual=await candidate.screenshot({path:resolve(output,id+'-candidate.png')});
   const a=PNG.sync.read(ref),b=PNG.sync.read(actual),diff=new PNG({width:a.width,height:a.height});
   const changed=pixelmatch(a.data,b.data,diff.data,a.width,a.height,{threshold:.1,includeAA:true});
   const bounds=paintedBounds(a,b);
   let boundsComparison=null;
   if(bounds){
    const first=new PNG({width:bounds.width,height:bounds.height}),second=new PNG({width:bounds.width,height:bounds.height});
    PNG.bitblt(a,first,bounds.left,bounds.top,bounds.width,bounds.height,0,0);
    PNG.bitblt(b,second,bounds.left,bounds.top,bounds.width,bounds.height,0,0);
    const count=pixelmatch(first.data,second.data,null,bounds.width,bounds.height,{threshold:.1,includeAA:true});
    boundsComparison={componentPixelBounds:bounds,componentChangedPixels:count,componentChangedRatio:count/(bounds.width*bounds.height)};
   }
   await writeFile(resolve(output,id+'-diff.png'),PNG.sync.write(diff));
   rows.push({id,component,state,checked,candidateSourceSha,candidateWasmSha256,referenceRuntime,referenceScreenshotSha256:createHash('sha256').update(ref).digest('hex'),candidateScreenshotSha256:createHash('sha256').update(actual).digest('hex'),...boundsComparison,changedPixels:changed,totalPixels:a.width*a.height,changedRatio:changed/(a.width*a.height),animationPhaseAligned:state==='loading'?false:null});
   await context.close();
   if(rows.length%20===0)console.log(JSON.stringify({completed:rows.length,total:selectedSamples.length*2}));
  }
 }
}finally{await browser.close();}
const mergedRows=previous?[...previous.rows.filter(old=>!rows.some(row=>row.id===old.id)),...rows]:rows;
const report={upstreamSha:'f46e8bc9922c37dc1d3e7da779e589fe171df306',source:'Exact upstream source rendered in a temporary Vite fixture',note:'Diagnostic samples only. Loading timelines are not phase-aligned; no sample certifies full component or interaction parity.',rows:mergedRows};
await writeFile(resolve(output,'report.json'),JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify({captured:rows.length,samples:mergedRows.length,maxChangedRatio:Math.max(...mergedRows.map(row=>row.changedRatio)),report:resolve(output,'report.json')}));
