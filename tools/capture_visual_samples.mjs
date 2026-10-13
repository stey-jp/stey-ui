import {chromium} from 'playwright';
import {mkdir,writeFile} from 'node:fs/promises';
import {resolve} from 'node:path';
import {PNG} from 'pngjs';
import pixelmatch from 'pixelmatch';
const output=resolve('output/visual-samples');await mkdir(output,{recursive:true});
const badgeVariants=['primary','secondary','error','warning','success','destructive','info','beta','outline','red','green','neutral','orange','purple','teal','tealSubtle','blue'];
const buttonVariants=['primary','secondary','ghost','destructive','secondaryDestructive','outline'];
const samples=[];
for(const variant of buttonVariants)for(const state of ['idle','hover','focus','disabled','loading'])samples.push({component:'button',variant,state});
for(const size of ['xs','sm','base','lg'])for(const shape of ['base','square','circle'])if(size!=='base'||shape!=='base')samples.push({component:'button',variant:'secondary',size,shape});
for(const variant of badgeVariants)for(const appearance of ['filled','dot'])samples.push({component:'badge',variant,appearance});
samples.push({component:'input',variant:'default'});
const browser=await chromium.launch({channel:'chrome',headless:true});const rows=[];
try{
 for(const mode of ['light','dark']){
  for(const sample of samples){
   const context=await browser.newContext({viewport:{width:600,height:160}});
   const reference=await context.newPage(),candidate=await context.newPage();
   const {component,variant,size='base',shape='base',state='idle',appearance='filled'}=sample;
   const id=[component,variant,appearance==='dot'?'dot':null,size!=='base'?size:null,shape!=='base'?shape:null,state!=='idle'?state:null,mode].filter(Boolean).join('-');
   const upstreamVariant=variant==='secondaryDestructive'?'secondary-destructive':variant==='tealSubtle'?'teal-subtle':variant;
   const parameters={variant:upstreamVariant,appearance,mode,size,shape,state};
   await reference.goto('http://127.0.0.1:8767/?'+new URLSearchParams({component,...parameters}),{waitUntil:'networkidle'});
   if(component==='input')await reference.locator('input').waitFor();
   else if(component==='badge')await reference.getByText('Active',{exact:true}).waitFor();
   else await reference.getByRole('button',{name:'Save',exact:true}).waitFor();
   await reference.evaluate(()=>document.fonts.ready);
   await candidate.goto('http://127.0.0.1:8766/?'+new URLSearchParams({sample:component,...parameters,variant}),{waitUntil:'networkidle'});
   if(component==='badge')await candidate.getByText('Active',{exact:true}).waitFor();
   else await candidate.getByRole(component==='input'?'textbox':'button',{name:component==='input'?'Name':'Save',exact:true}).waitFor();
   for(const page of [reference,candidate]){
    await page.mouse.click(20,20);
    if(state==='hover')await page.getByRole('button',{name:'Save',exact:true}).hover();
    if(state==='focus'){
     const button=page.getByRole('button',{name:'Save',exact:true});
     await button.click();await page.keyboard.press('Tab');
     if(page===reference)await page.keyboard.press('Shift+Tab');
     if(!await button.evaluate(element=>element===document.activeElement))throw Error('SAMPLE_KEYBOARD_FOCUS_MISSING');
    }
    await page.evaluate(()=>new Promise(resolve=>requestAnimationFrame(()=>requestAnimationFrame(resolve))));
   }
   const ref=await reference.screenshot({path:resolve(output,id+'-reference.png')});
   const actual=await candidate.screenshot({path:resolve(output,id+'-candidate.png')});
   const a=PNG.sync.read(ref),b=PNG.sync.read(actual),diff=new PNG({width:a.width,height:a.height});
   const changed=pixelmatch(a.data,b.data,diff.data,a.width,a.height,{threshold:.1,includeAA:true});
   await writeFile(resolve(output,id+'-diff.png'),PNG.sync.write(diff));
   rows.push({id,state,changedPixels:changed,totalPixels:a.width*a.height,changedRatio:changed/(a.width*a.height),animationPhaseAligned:state==='loading'?false:null});
   await context.close();
   if(rows.length%20===0)console.log(JSON.stringify({completed:rows.length,total:samples.length*2}));
  }
 }
}finally{await browser.close();}
const report={upstreamSha:'f46e8bc9922c37dc1d3e7da779e589fe171df306',source:'Exact upstream source rendered in a temporary Vite fixture',note:'Diagnostic samples only. Loading timelines are not phase-aligned; no sample certifies full component or interaction parity.',rows};
await writeFile(resolve(output,'report.json'),JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify({samples:rows.length,maxChangedRatio:Math.max(...rows.map(row=>row.changedRatio)),report:resolve(output,'report.json')}));
