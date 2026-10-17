import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {mkdir,readFile,writeFile} from 'node:fs/promises';
import {chromium} from 'playwright';
import {PNG} from 'pngjs';
import pixelmatch from 'pixelmatch';

const output='output/playwright/dropdown-keyboard';await mkdir(output,{recursive:true});
const sourceOnly=process.env.REFERENCE_ONLY==='1';
const browser=await chromium.launch({channel:'chrome',headless:true}),results=[],issues=[],errors=[];
const surface=async(menu,native)=>native?menu.evaluate(e=>{
 for(let p=e.parentElement;p;p=p.parentElement)if(p.tagName==='FLT-SEMANTICS'&&(p.getAttribute('role')==='group'||/hidden|auto|scroll|clip/.test(getComputedStyle(p).overflow))){
  const r=p.getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height};
 }
 const r=e.getBoundingClientRect();return {x:r.x-6,y:r.y-6,width:r.width+12,height:r.height+12};
}):menu.boundingBox();
try {
 for(const mode of ['light','dark'])for(const direction of ['ltr','rtl'])for(const width of [390,1200]) {
  const index=results.length,pages=[],states=[];console.log(JSON.stringify({index,mode,direction,width}));
  for(const target of sourceOnly?['reference']:['reference','flutter']) {
   console.log(JSON.stringify({index,target}));
   const native=target==='flutter',page=await browser.newPage({viewport:{width,height:900},colorScheme:mode});
   const cdp=await page.context().newCDPSession(page);cdp.on('Audits.issueAdded',({issue})=>issues.push({index,target,...issue}));await cdp.send('Audits.enable');
   page.on('pageerror',error=>errors.push({index,target,message:error.message}));
   await page.goto(`http://127.0.0.1:${native?8766:8767}/?${native?'sample':'component'}=dropdown&mode=${mode}&direction=${direction}`,{waitUntil:'networkidle'});
   await page.mouse.move(2,2);await page.getByRole('button',{name:'Actions',exact:true}).waitFor();
   // Flutter's initially focused DOM semantics surrogate may not yet own
   // application focus. Enter through real Tab, then use only real key events.
   await page.keyboard.press('Tab');await page.waitForTimeout(60);
   await page.keyboard.press('ArrowDown');await page.getByRole('menu').waitFor();await page.waitForTimeout(200);
   pages.push({target,page,native});
  }
  const key=async(value)=>{for(const {page} of pages){await page.keyboard.press(value);await page.waitForTimeout(35);}};
  const pause=async(ms)=>{await Promise.all(pages.map(({page})=>page.waitForTimeout(ms)));};
  const check=async(step,focus,{checked='true',menus=1,capture=false}={})=>{
   const captures=[],images=[];
   for(const {page,target,native} of pages) {
    const active=await page.evaluate(()=>{const e=document.activeElement;return {role:e.getAttribute('role'),label:e.getAttribute('aria-label')||e.textContent,disabled:e.getAttribute('aria-disabled')};});
    // SDK Focusable.update explicitly excludes disabled nodes from DOM focus.
    // Widget tests verify their application focus and disabled/focused flags;
    // keep this known DOM mismatch visible instead of faking enabled semantics.
    const retainedDomFocus=native&&focus==='Unavailable'?(step.startsWith('disabled-search')||step==='disabled-typeahead'?'Edit':'Move'):null;
    assert(active.label?.includes(retainedDomFocus??focus),`${index} ${step} ${target}: ${JSON.stringify(active)}`);
    assert.equal(await page.getByRole('menu').count(),menus,`${step} ${target}: open menus`);
    const checkbox=page.getByRole('menuitemcheckbox',{name:'Receive alerts',exact:true});
    assert.equal(await checkbox.getAttribute('aria-checked'),checked,`${step} ${target}: checked`);
    if(focus==='Unavailable'&&!native)assert.equal(active.disabled,'true');
    const disabled=page.getByRole('menuitem',{name:'Unavailable',exact:true});
    assert.equal(await disabled.isDisabled(),true);
    const path=capture?`${output}/${index}-${step}-${target}.png`:null;
    const boxes={};
    if(capture)for(const [part,label,role] of [['root','Receive alerts','menuitemcheckbox'],...(menus===3?[['child','Personal account','menuitem'],['deep','New folder','menuitem']]:[])]){
     boxes[part]=await surface(page.getByRole('menu').filter({has:page.getByRole(role,{name:label,exact:true})}),native);
    }
    if(path)images.push(PNG.sync.read(await page.screenshot({path})));
    captures.push({target,active,expectedApplicationFocus:focus,disabledFocusDomMismatch:retainedDomFocus!==null,checked,menuCount:menus,boxes,path});
   }
   let pixelDifferenceRatio=null;
   if(capture&&images.length===2) {
    const [a,b]=images,diff=new PNG({width:a.width,height:a.height});
    pixelDifferenceRatio=pixelmatch(a.data,b.data,diff.data,a.width,a.height,{threshold:.1})/(a.width*a.height);
    await writeFile(`${output}/${index}-${step}-diff.png`,PNG.sync.write(diff));
   }
   const maximumGeometryDelta=captures.length===2?Math.max(0,...Object.keys(captures[0].boxes).flatMap(part=>Object.keys(captures[0].boxes[part]).map(k=>Math.abs(captures[0].boxes[part][k]-captures[1].boxes[part][k])))):null;
   if(maximumGeometryDelta!==null)assert(maximumGeometryDelta<=.1,`${index} ${step}: geometry ${maximumGeometryDelta}`);
   states.push({step,captures,pixelDifferenceRatio,maximumGeometryDelta});
  };
  await check('opened','Edit');
  for(let i=0;i<3;i++)await key('ArrowDown');
  await check('disabled-focus','Unavailable',{capture:true});
  await key('Enter');await key('Space');
  await check('disabled-inert','Unavailable');
  await key('r');await check('disabled-space-search-reset','Unavailable');
  await key('r');await check('disabled-space-next-search','Receive alerts');
  await pause(550);
  await key('ArrowUp');await key('ArrowDown');await check('next-row','Receive alerts');
  await key('r');await key('Space');
  await check('search-space','Receive alerts');
  await pause(550);await key('Space');
  await check('expired-search-activates','Receive alerts',{checked:'false'});
  await key('Space');await check('repeated-idle-space-activates','Receive alerts',{capture:true});
  await key('Space');await check('idle-space-activates','Receive alerts',{checked:'false'});
  await pause(550);
  await key('Home');await key('u');
  await check('disabled-typeahead','Unavailable',{checked:'false'});
  await key('Enter');await check('disabled-search-inert','Unavailable',{checked:'false'});
  await pause(550);await key('Home');
  await key('r');await key('e');await key('Space');await key('a');
  await check('multiword-search','Receive alerts',{checked:'false'});
  await key('z');await key('Space');
  await check('unmatched-search-resets','Receive alerts');
  await pause(550);
  await key('Home');await key('d');await check('first-initial','Duplicate');
  await key('d');await check('repeated-initial','Delete');
  await key('d');await check('initial-cycles','Duplicate');
  await pause(550);await key('r');
  for(const {page} of pages)await page.keyboard.down('Space');
  await pause(600);
  for(const {page} of pages)await page.keyboard.up('Space');
  await check('held-search-space','Receive alerts');
  await key('Space');await check('new-space-activates','Receive alerts',{checked:'false'});
  await pause(550);
  await key('r');await key('Home');await key('ArrowDown');await key('ArrowDown');
  const forward=direction==='rtl'?'ArrowLeft':'ArrowRight',back=direction==='rtl'?'ArrowRight':'ArrowLeft';
  await key(forward);await pause(180);
  await check('child-focus','Personal account',{checked:'false',menus:2});
  await key(back);await pause(180);
  await check('parent-focus-restored','Move',{checked:'false'});
  await key('Space');await pause(180);
  await check('return-clears-parent-search','Personal account',{checked:'false',menus:2});
  await key('m');await key(forward);await pause(180);
  await check('deep-child','New folder',{checked:'false',menus:3});
  await key('n');await key('Space');
  await check('deep-search-space','New folder',{checked:'false',menus:3,capture:true});
  await key('Enter');
  for(const {page} of pages)await page.getByRole('menu').first().waitFor({state:'hidden'});
  states.push({step:'deep-enter-closes-all',menus:0});
  for(const {page} of pages){await page.getByRole('button',{name:'Actions',exact:true}).focus();await page.keyboard.press('ArrowDown');await page.waitForTimeout(180);}
  await check('reopened-with-selection','Edit',{checked:'false'});
  await key('Space');
  for(const {page} of pages)await page.getByRole('menu').first().waitFor({state:'hidden'});
  states.push({step:'reopen-search-reset',menus:0});
  results.push({index,mode,direction,width,states});
  for(const {page} of pages)await page.close();
 }
 assert.deepEqual(errors,[]);
 const candidateArtifactSha256=createHash('sha256').update(await readFile('apps/demo/build/web/main.dart.wasm')).digest('hex');
 await writeFile(`${output}/${sourceOnly?'reference':'comparison'}.json`,JSON.stringify({checkedAt:new Date().toISOString(),browser:browser.version(),referenceSha:'7e0ff40546f08405d05bc9754f0ff0fd009ece0a',sourceOnly,results,issues,errors,candidateArtifactSha256:sourceOnly?null:candidateArtifactSha256,success:true},null,2)+'\n');
 console.log(JSON.stringify({contexts:results.length,states:results.flatMap(r=>r.states).length,issues:issues.length,errors:errors.length,success:true}));
}finally{await browser.close();}
