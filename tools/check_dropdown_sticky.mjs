import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {mkdir,readFile,writeFile} from 'node:fs/promises';
import {chromium} from 'playwright';
import {PNG} from 'pngjs';
import pixelmatch from 'pixelmatch';

const output='output/playwright/dropdown-sticky';await mkdir(output,{recursive:true});
const browser=await chromium.launch({channel:'chrome',headless:true}),results=[],issues=[],errors=[];
const surface=async(menu,native)=>native?menu.evaluate(e=>{
  for(let p=e.parentElement;p;p=p.parentElement)if(p.tagName==='FLT-SEMANTICS'&&(p.getAttribute('role')==='group'||/hidden|auto|scroll|clip/.test(getComputedStyle(p).overflow))){
    const r=p.getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height};
  }
  const r=e.getBoundingClientRect();return {x:r.x-6,y:r.y-6,width:r.width+12,height:r.height+12};
}):menu.boundingBox();
const visible=(box,width)=>box&&box.x+box.width>0&&box.y+box.height>0&&box.x<width&&box.y<800?
  {x:Math.max(0,box.x),y:Math.max(0,box.y),width:Math.min(width,box.x+box.width)-Math.max(0,box.x),height:Math.min(800,box.y+box.height)-Math.max(0,box.y)}:null;
try {
 for(const mode of ['light','dark']) for(const direction of ['ltr','rtl']) for(const config of [
  {width:800}, {width:390,boundary:'40,100,310,600'},
  {width:800,boundary:'120,300,560,200'}, {width:800,anchorY:'300'},
 ]) {
  const {width,...parameters}=config;
  const index=results.length,pages=[],states=[];console.log(JSON.stringify({index,mode,direction,...config}));
  for(const target of ['reference','flutter']) {
   const native=target==='flutter',page=await browser.newPage({viewport:{width,height:800},colorScheme:mode});pages.push({page,target,native});
   const cdp=await page.context().newCDPSession(page);cdp.on('Audits.issueAdded',({issue})=>issues.push({index,target,...issue}));await cdp.send('Audits.enable');
   page.on('pageerror',error=>errors.push({index,target,message:error.message}));
   const query=new URLSearchParams({[native?'sample':'component']:'dropdown-tracking',mode,direction,sticky:'true',...parameters});
   await page.goto(`http://127.0.0.1:${native?8766:8767}/?${query}`,{waitUntil:'networkidle'});await page.mouse.move(2,2);
   await page.getByRole('button',{name:'Actions',exact:true}).focus();await page.keyboard.press('ArrowDown');await page.waitForTimeout(200);
   // Use application keyboard focus, including the real scrolling caused by
   // selecting an item in a short popup, rather than focusing a DOM surrogate.
   // Base UI treats Space as part of typeahead until its 500ms search expires.
   await page.keyboard.press('r');await page.waitForTimeout(600);
   await page.keyboard.press('Space');await page.waitForTimeout(100);
   await page.keyboard.press('Home');await page.waitForTimeout(60);
   for(let i=0;i<2;i++){await page.keyboard.press('ArrowDown');await page.waitForTimeout(60);}
   await page.keyboard.press(direction==='rtl'?'ArrowLeft':'ArrowRight');
   await page.getByRole('menuitem',{name:'Personal account',exact:true}).waitFor();await page.waitForTimeout(200);
  }
  for(const step of ['initial','partial','hidden','far-hidden','sticky-off','sticky-on','restored','horizontal','horizontal-restored','content','boundary']) {
   const captures=[],images=[];
   for(const {page,target,native} of pages) {
    if(step==='boundary')await page.keyboard.press('Control+Alt+b');
    if(['partial','hidden','far-hidden','restored'].includes(step))await page.keyboard.press('Control+Alt+h');
    if(['sticky-off','sticky-on'].includes(step))await page.keyboard.press('Control+Alt+t');
    if(['horizontal','horizontal-restored'].includes(step))await page.keyboard.press('Control+Alt+x');
    if(step==='content')await page.keyboard.press('Control+Alt+c');
    await page.waitForTimeout(step.startsWith('horizontal')?1300:350);
    // Flutter clips semantics to the viewport and omits completely offscreen
    // nodes. Recovery to two menus verifies that their state stayed mounted.
    const menuCount=await page.getByRole('menu').count();
    if(step!=='sticky-off')assert(menuCount>0,`${index} ${step} ${target}: root remains open`);
    if(step==='initial'||step==='restored')assert.equal(menuCount,2);
    const checkbox=page.getByRole('menuitemcheckbox',{name:'Receive alerts',exact:true});
    if(await checkbox.count())assert.equal(await checkbox.getAttribute('aria-checked'),'false',`${index} ${step} ${target}: selection retained`);
    const boxes={};
    for(const part of ['root','submenu']) {
     const menus=page.getByRole('menu');
     // Offscreen item semantics may be absent and Flutter's traversal order
     // follows geometry. Identify the root by its persistent menu label.
     const menu=native?(part==='root'?page.getByRole('menu',{name:'Actions',exact:true}):page.locator('[role=menu]:not([aria-label="Actions"])')):menus.nth(part==='root'?0:1);
     boxes[part]=await menu.count()?visible(await surface(menu,native),width):null;
    }
    const path=`${output}/${index}-${step}-${target}.png`,data=await page.screenshot({path});images.push(PNG.sync.read(data));
    captures.push({target,boxes,path,selectionRetained:true,menuCount,
      anchorHidden:native?null:await page.locator('[data-kumo-part=positioner]').first().getAttribute('data-anchor-hidden')!==null});
   }
   const deltas=Object.keys(captures[0].boxes).flatMap(part=>{
    const a=captures[0].boxes[part],b=captures[1].boxes[part];
    return a&&b?['x','y','width','height'].map(key=>({part,key,delta:Math.abs(a[key]-b[key])})):[{part,key:'visibility',delta:a===b?0:Infinity}];
   });
   const [p,q]=images,diff=new PNG({width:p.width,height:p.height}),changed=pixelmatch(p.data,q.data,diff.data,p.width,p.height,{threshold:.1});
   await writeFile(`${output}/${index}-${step}-diff.png`,PNG.sync.write(diff));
   states.push({step,matches:deltas.every(row=>row.delta<=.1),maxDelta:Math.max(...deltas.map(row=>row.delta)),captures,pixels:{changed,total:p.width*p.height,ratio:changed/(p.width*p.height)}});
  }
  for(const {page} of pages){await page.keyboard.press('Escape');await page.waitForTimeout(200);await page.keyboard.press('Escape');await page.getByRole('menu').first().waitFor({state:'hidden'});await page.close();}
  results.push({index,mode,direction,...config,states});
  console.log(JSON.stringify({index,matched:states.every(s=>s.matches),mismatches:states.filter(s=>!s.matches).map(s=>({step:s.step,maxDelta:s.maxDelta}))}));
 }
}finally{await browser.close();}
const report={checkedAt:new Date().toISOString(),browser:browser.version(),referenceSha:'7e0ff40546f08405d05bc9754f0ff0fd009ece0a',candidateArtifactSha256:createHash('sha256').update(await readFile('apps/demo/build/web/main.dart.wasm')).digest('hex'),results,issues,errors,success:errors.length===0&&results.every(row=>row.states.every(state=>state.matches))};
await writeFile(`${output}/comparison.json`,JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify({success:report.success,contexts:results.length,states:results.flatMap(r=>r.states).length,issues:issues.length,errors:errors.length,mismatches:results.flatMap(r=>r.states.filter(s=>!s.matches).map(s=>({index:r.index,...s})))}));
assert(report.success,'Sticky boundary geometry matches the official source');
