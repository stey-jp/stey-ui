import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {mkdir, readFile, writeFile} from 'node:fs/promises';
import {chromium} from 'playwright';
import {PNG} from 'pngjs';
import pixelmatch from 'pixelmatch';

const output = 'output/playwright/dropdown-positioning';
await mkdir(output, {recursive:true});
const reference = process.env.KUMO_REFERENCE_URL ?? 'http://127.0.0.1:8767/';
const candidate = process.env.DEMO_URL ?? 'http://127.0.0.1:8766/';
const sourceOnly = process.env.REFERENCE_ONLY === '1';
const cachedSource = !sourceOnly && process.env.KUMO_SOURCE_REPORT
  ? JSON.parse(await readFile(process.env.KUMO_SOURCE_REPORT, 'utf8')) : null;
const selected = process.env.DROPDOWN_CASES
  ? new Set(process.env.DROPDOWN_CASES.split(',').map(Number)) : null;
const previous = selected ? JSON.parse(await readFile(`${output}/comparison.json`, 'utf8')) : null;
const cases = [
  {width:1200,height:1000}, {width:700,height:1000},
  {width:600,height:1000}, {width:320,height:1000},
  {width:320,height:1000,extraItems:12},
  {width:320,height:1000,extraItems:24},
  {width:1200,height:500}, {width:320,height:400},
  {width:390,height:500,extraItems:5},
  {width:1200,height:1000,anchorY:300,extraItems:12},
  {width:600,height:1000,anchorY:300,extraItems:12},
  {width:320,height:1000,anchorY:-350},
];
const browser = await chromium.launch({channel:'chrome',headless:true});
const results=[], issues=[], errors=[];
if(previous) {
  assert(!sourceOnly, 'Partial recheck requires an existing candidate comparison');
  assert.equal(previous.candidateArtifactSha256,createHash('sha256').update(await readFile('apps/demo/build/web/main.dart.wasm')).digest('hex'));
  issues.push(...previous.issues.filter(row=>!selected.has(row.index)));
  errors.push(...previous.errors.filter(row=>!selected.has(row.index)));
}
const surface = async (menu, native) => {
  const box=await menu.boundingBox();
  assert(box, 'menu has bounds');
  if(!native) return box;
  const viewport=await menu.evaluate(e=>{
    for(let parent=e.parentElement;parent;parent=parent.parentElement) {
      if(parent.tagName==='FLT-SEMANTICS'&&/hidden|auto|scroll|clip/.test(getComputedStyle(parent).overflow)) {
        const r=parent.getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height};
      }
    }
    return null;
  });
  return viewport ?? {x:box.x-6,y:box.y-6,width:box.width+12,height:box.height+12};
};
try {
  for (const mode of ['light','dark']) for (const direction of ['ltr','rtl']) for (const test of cases) {
    const index=results.length, captures=[];
    if(selected && !selected.has(index)) {results.push(previous.results[index]);continue;}
    console.log(JSON.stringify({index,mode,direction,...test}));
    for (const target of sourceOnly ? ['reference'] : ['reference','flutter']) {
      if(target==='reference' && cachedSource) {
        const cached=cachedSource.results[index];
        assert.equal(cached.mode,mode); assert.equal(cached.direction,direction);
        for(const key of ['width','height','extraItems','anchorY']) assert.equal(cached[key],test[key]);
        captures.push(cached.captures[0]); continue;
      }
      const native=target==='flutter';
      const page=await browser.newPage({viewport:{width:test.width,height:test.height},colorScheme:mode});
      const cdp=await page.context().newCDPSession(page);
      cdp.on('Audits.issueAdded',({issue})=>issues.push({index,target,...issue}));
      await cdp.send('Audits.enable');
      page.on('pageerror',error=>errors.push({index,target,message:error.message}));
      const query=new URLSearchParams({[native?'sample':'component']:'dropdown',mode,direction,anchorY:String(test.anchorY??0),extraItems:String(test.extraItems??0)});
      await page.goto(`${native?candidate:reference}?${query}`,{waitUntil:'networkidle'});
      if(!native) await page.evaluate(()=>document.fonts.ready);
      await page.getByRole('button',{name:'Actions',exact:true}).click();
      const root=page.getByRole('menu').first();
      await root.waitFor(); await page.waitForTimeout(180);
      const rootBox=await surface(root,native);
      const move=page.getByRole('menuitem',{name:'Move',exact:true});
      const anchor=await move.boundingBox();
      await move.focus(); await page.keyboard.press(direction==='rtl'?'ArrowLeft':'ArrowRight');
      const submenu=page.getByRole('menu').filter({has:page.getByRole('menuitem',{name:'Personal account',exact:true})});
      await submenu.waitFor(); await page.waitForTimeout(400);
      const box=await surface(submenu,native);
      const side=box.y>=anchor.y+anchor.height ? 'bottom' : box.y+box.height<=anchor.y ? 'top' : box.x>=anchor.x+anchor.width ? 'right' : 'left';
      const path=`${output}/${index}-${target}.png`;
      await page.screenshot({path});
      const crop=await page.screenshot({clip:{x:Math.max(0,Math.floor(box.x-4)),y:Math.max(0,Math.floor(box.y-4)),width:Math.min(test.width,Math.ceil(box.width+8)),height:Math.min(test.height-Math.max(0,Math.floor(box.y-4)),Math.ceil(box.height+8))}});
      const cropPath=`${output}/${index}-${target}-surface.png`;
      await writeFile(cropPath,crop);
      const styles=native?null:await submenu.evaluate(e=>({side:e.dataset.side,align:e.dataset.align,origin:getComputedStyle(e).transformOrigin,availableHeight:e.parentElement.style.getPropertyValue('--available-height'),documentMode:document.compatMode}));
      await page.keyboard.press(direction==='rtl'?'ArrowRight':'ArrowLeft');
      await submenu.waitFor({state:'hidden'});
      assert.equal(await page.getByRole('menu').count(),1);
      await page.keyboard.press('Escape'); await root.waitFor({state:'hidden'});
      captures.push({target,root:rootBox,anchor,box,side,styles,path,cropPath,keyboardBack:true});
      await page.close();
    }
    const a=captures[0],b=captures[1];
    const equal=(x,y)=>['x','y','width','height'].every(key=>Math.abs(x[key]-y[key])<=.1);
    let pixels=null;
    if(b) {
      const p=PNG.sync.read(await readFile(a.cropPath)),q=PNG.sync.read(await readFile(b.cropPath));
      if(p.width===q.width&&p.height===q.height) {
        const diff=new PNG({width:p.width,height:p.height});
        const count=pixelmatch(p.data,q.data,diff.data,p.width,p.height,{threshold:.1});
        await writeFile(`${output}/${index}-diff.png`,PNG.sync.write(diff));
        pixels={different:count,total:p.width*p.height,ratio:count/(p.width*p.height)};
      }
    }
    results.push({index,mode,direction,...test,captures,rootMatches:b?equal(a.root,b.root):null,submenuMatches:b?equal(a.box,b.box):null,sideMatches:b?a.side===b.side:null,pixels});
  }
} finally {await browser.close();}
const report={checkedAt:new Date().toISOString(),browser:browser.version(),referenceSha:'7e0ff40546f08405d05bc9754f0ff0fd009ece0a',candidateArtifactSha256:sourceOnly?null:createHash('sha256').update(await readFile('apps/demo/build/web/main.dart.wasm')).digest('hex'),results,issues,errors,success:errors.length===0&&results.every(r=>sourceOnly||r.rootMatches&&r.submenuMatches&&r.sideMatches)};
await writeFile(`${output}/${sourceOnly?'source-layout':'comparison'}.json`,JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify({success:report.success,cases:results.length,issues:issues.length,errors:errors.length,mismatches:results.filter(r=>!sourceOnly&&(!r.rootMatches||!r.submenuMatches||!r.sideMatches)).map(r=>({index:r.index,rootMatches:r.rootMatches,submenuMatches:r.submenuMatches,captures:r.captures}))}));
assert(report.success,'Dropdown positioning matches reference');
