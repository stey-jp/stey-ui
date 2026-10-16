import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {mkdir,readFile,writeFile} from 'node:fs/promises';
import {chromium} from 'playwright';
import {PNG} from 'pngjs';
import pixelmatch from 'pixelmatch';

const output='output/playwright/dropdown-tracking';await mkdir(output,{recursive:true});
const browser=await chromium.launch({channel:'chrome',headless:true}),results=[],issues=[],errors=[];
const only=process.env.DROPDOWN_TRACKING_CONTEXT ? Number(process.env.DROPDOWN_TRACKING_CONTEXT) : null;
const previous=only===null?null:JSON.parse(await readFile(`${output}/comparison.json`,'utf8'));
if(previous) {
  assert.equal(previous.candidateArtifactSha256,createHash('sha256').update(await readFile('apps/demo/build/web/main.dart.wasm')).digest('hex'));
  issues.push(...previous.issues.filter(row=>row.index!==only));errors.push(...previous.errors.filter(row=>row.index!==only));
}
const surface=async (menu,native)=>{
  if(!native)return menu.boundingBox();
  return menu.evaluate(e=>{
    for(let p=e.parentElement;p;p=p.parentElement) {
      if(p.tagName==='FLT-SEMANTICS'&&/hidden|auto|scroll|clip/.test(getComputedStyle(p).overflow)) {
        const r=p.getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height};
      }
    }
    const r=e.getBoundingClientRect();return {x:r.x-6,y:r.y-6,width:r.width+12,height:r.height+12};
  });
};
const equal=(a,b)=>['x','y','width','height'].every(key=>Math.abs(a[key]-b[key])<=.1);
const names={root:'Duplicate',submenu:'Personal account',deep:'New folder'};
try{
 for(const mode of ['light','dark']) for(const direction of ['ltr','rtl']) for(const width of [1200,390]) {
  const index=results.length,states=[],pages=[];
  if(only!==null&&index!==only){results.push(previous.results[index]);continue;}
  console.log(JSON.stringify({index,mode,direction,width}));
  for(const target of ['reference','flutter']) {
    const native=target==='flutter';
    const page=await browser.newPage({viewport:{width,height:1000},colorScheme:mode});pages.push({page,target,native});
    const cdp=await page.context().newCDPSession(page);
    cdp.on('Audits.issueAdded',({issue})=>issues.push({index,target,...issue}));await cdp.send('Audits.enable');
    page.on('pageerror',error=>errors.push({index,target,message:error.message}));
    const query=new URLSearchParams({[native?'sample':'component']:'dropdown-tracking',mode,direction});
    await page.goto(`http://127.0.0.1:${native?8766:8767}/?${query}`,{waitUntil:'networkidle'});
    await page.mouse.move(2,2);
    const trigger=page.getByRole('button',{name:'Actions',exact:true});await trigger.focus();await page.keyboard.press('ArrowDown');
    await page.getByRole('menu').waitFor();await page.waitForTimeout(200);
    await page.getByRole('menuitemcheckbox',{name:'Receive alerts',exact:true}).focus();await page.keyboard.press('Space');
    const move=page.getByRole('menuitem',{name:'Move',exact:true});await move.focus();
    await page.keyboard.press(direction==='rtl'?'ArrowLeft':'ArrowRight');
    await page.getByRole('menuitem',{name:'Personal account',exact:true}).waitFor();
    await page.waitForTimeout(200);
    if(width===1200) {
      await page.getByRole('menuitem',{name:'More',exact:true}).focus();await page.keyboard.press(direction==='rtl'?'ArrowLeft':'ArrowRight');
      await page.getByRole('menuitem',{name:'New folder',exact:true}).waitFor();
    }
  }
  for(const step of ['initial','translate','scroll','resize','content']) {
    const captures=[];
    for(const {page,target,native} of pages) {
      if(step==='translate')await page.keyboard.press('Control+Alt+m');
      if(step==='scroll')await page.keyboard.press('Control+Alt+s');
      if(step==='resize')await page.setViewportSize({width:width===1200?320:1200,height:600});
      if(step==='content') {
        if(width===1200) {
          await page.keyboard.press(direction==='rtl'?'ArrowRight':'ArrowLeft');
          await page.getByRole('menuitem',{name:'New folder',exact:true}).waitFor({state:'hidden'});
        }
        await page.getByRole('menuitem',{name:'Personal account',exact:true}).focus();
        await page.keyboard.press('Control+Alt+c');
      }
      await page.waitForTimeout(700);
      await page.evaluate(()=>new Promise(resolve=>requestAnimationFrame(()=>requestAnimationFrame(resolve))));
      const count=width===1200&&step!=='content'?3:2;
      assert.equal(await page.getByRole('menu').count(),count,`${target} ${step}: open menus retained`);
      assert.equal(await page.getByRole('menuitemcheckbox',{name:'Receive alerts',exact:true}).getAttribute('aria-checked'),'false');
      const boxes={};
      for(const part of count===3?['root','submenu','deep']:['root','submenu']) {
        const menu=page.getByRole('menu').filter({has:page.getByRole('menuitem',{name:names[part],exact:true})});
        boxes[part]=await surface(menu,native);
      }
      const viewport=page.viewportSize(),path=`${output}/${index}-${step}-${target}.png`;
      await page.screenshot({path});
      captures.push({target,boxes,viewport,path,selectionRetained:true,menuCount:count,
        moveAnchor:await page.getByRole('menuitem',{name:'Move',exact:true}).boundingBox(),
        rootScrollTop:native?null:await page.getByRole('menu').filter({has:page.getByRole('menuitem',{name:'Duplicate',exact:true})}).evaluate(e=>e.scrollTop)});
    }
    const matches=Object.keys(captures[0].boxes).every(part=>equal(captures[0].boxes[part],captures[1].boxes[part]));
    const crops=[];
    for(let i=0;i<pages.length;i++) {
      const {page,target}=pages[i],box=captures[0].boxes.submenu;
      const clip={x:Math.max(0,Math.round(box.x)-4),y:Math.max(0,Math.round(box.y)-4),width:Math.round(box.width)+8,height:Math.round(box.height)+8};
      clip.width=Math.min(clip.width,page.viewportSize().width-clip.x);clip.height=Math.min(clip.height,page.viewportSize().height-clip.y);
      const path=`${output}/${index}-${step}-${target}-submenu.png`,data=await page.screenshot({clip});
      await writeFile(path,data);captures[i].cropPath=path;crops.push(PNG.sync.read(data));
    }
    const p=crops[0],q=crops[1],diff=new PNG({width:p.width,height:p.height});
    assert.equal(p.width,q.width);assert.equal(p.height,q.height);
    const changed=pixelmatch(p.data,q.data,diff.data,p.width,p.height,{threshold:.1});
    await writeFile(`${output}/${index}-${step}-diff.png`,PNG.sync.write(diff));
    states.push({step,matches,captures,pixels:{changed,total:p.width*p.height,ratio:changed/(p.width*p.height)}});
  }
  for(const {page} of pages){await page.keyboard.press('Escape');await page.keyboard.press('Escape');await page.getByRole('menu').waitFor({state:'hidden'});await page.close();}
  results.push({index,mode,direction,width,states});
 }
}finally{await browser.close();}
const report={checkedAt:new Date().toISOString(),browser:browser.version(),referenceSha:'7e0ff40546f08405d05bc9754f0ff0fd009ece0a',candidateArtifactSha256:createHash('sha256').update(await readFile('apps/demo/build/web/main.dart.wasm')).digest('hex'),results,issues,errors,success:errors.length===0&&results.every(row=>row.states.every(state=>state.matches))};
await writeFile(`${output}/comparison.json`,JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify({success:report.success,contexts:results.length,states:results.reduce((n,r)=>n+r.states.length,0),issues:issues.length,errors:errors.length,mismatches:results.flatMap(r=>r.states.filter(s=>!s.matches).map(s=>({index:r.index,mode:r.mode,direction:r.direction,width:r.width,...s})))}));
assert(report.success,'Dynamic dropdown geometry matches the reference');
