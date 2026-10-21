import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {mkdir,readFile,writeFile} from 'node:fs/promises';
import {chromium} from 'playwright';
import {PNG} from 'pngjs';
import pixelmatch from 'pixelmatch';

const folder=process.env.PAGINATION_OUTPUT??'output/playwright/pagination';
await mkdir(folder,{recursive:true});
const cases=[];
for(const mode of ['light','dark'])for(const extra of [
 {page:'1'},{page:'3'},{page:'10'},{page:'1',total:'0'},{page:'14'},
 {controls:'simple'},{unknown:'true',next:'true'},{unknown:'true',next:'false'},
 {unknown:'true'},{selector:'dropdown'},{compound:'true'},
 {direction:'rtl'},{host:'320'},
])cases.push({mode,...extra});
const only=process.argv.find(s=>s.startsWith('--case='));
const selected=cases.map((item,index)=>({item,index})).filter(({index})=>!only||index===Number(only.split('=')[1]));
const results=[],issues=[],errors=[];
const browser=await chromium.launch({channel:'chrome',headless:true});let version;
const status=async page=>{
 const e=page.getByText(/^Page: \d+; Calls: \d+$/,{exact:true}).or(page.locator('[aria-label^="Page: "]')).first();
 const raw=(await e.textContent())||(await e.getAttribute('aria-label'));
 const [,pageNumber,calls]=raw.match(/Page: (\d+); Calls: (\d+)/);return{page:Number(pageNumber),calls:Number(calls)};
};
const settled=async(page,check)=>{for(let n=0;n<50;n++){if(await check())return;await page.waitForTimeout(20);}assert.fail('State did not settle');};
const edit=async(page,field,value)=>{await field.click();await page.keyboard.press('Control+a');await page.keyboard.press('Backspace');if(value)await page.keyboard.insertText(value);await page.waitForTimeout(60);assert.equal(await field.inputValue(),value,'Draft must reach the live input before committing');};
try{
 version=browser.version();const context=await browser.newContext({viewport:{width:1000,height:400}}),pages={};
 for(const target of ['reference','flutter']){
  const page=await context.newPage(),cdp=await context.newCDPSession(page);pages[target]=page;page.setDefaultTimeout(10000);
  await cdp.send('Audits.enable');cdp.on('Audits.issueAdded',({issue})=>issues.push({target,...issue}));page.on('pageerror',e=>errors.push({target,message:e.message}));
 }
 for(const {item,index}of selected){
  console.log(JSON.stringify({index,...item}));const captures={};
  for(const target of ['reference','flutter']){
   const page=pages[target],url=new URL('http://127.0.0.1:'+(target==='reference'?8767:8766)+'/');
   url.searchParams.set(target==='reference'?'component':'sample','pagination');for(const[k,v]of Object.entries(item))url.searchParams.set(k,v);
   await page.goto(url.href,{waitUntil:'networkidle'});const group=page.getByRole('group',{name:'Pagination preview',exact:true});await group.waitFor();await page.evaluate(()=>document.fonts.ready);
   const nav=group.getByRole('navigation',{name:'Pagination',exact:true});await nav.waitFor();
   const known=item.unknown!=='true',full=item.controls!=='simple'&&!(item.unknown==='true'&&item.next!==undefined),number=Number(item.page??3),max=Math.max(1,Math.ceil(Number(item.total??100)/10));
   const names=full?['First page','Previous page','Next page','Last page']:['Previous page','Next page'];
   for(const name of names){
    const expected=name==='First page'||name==='Previous page'?number<=1:known?number>=max:item.next!=='true';
    assert.equal(await nav.getByRole('button',{name,exact:true}).isDisabled(),expected,`${target} ${index} ${name}`);
   }
   assert.equal(await nav.getByRole('button').count(),names.length+(full&&item.selector==='dropdown'&&target==='flutter'?1:0));
   const rows=[],capture=async step=>{
    const path=`${folder}/${index}-${step}-${target}.png`,bounds=await nav.boundingBox(),frame=await group.boundingBox(),controls={};
    for(const name of names)controls[name]=await nav.getByRole('button',{name,exact:true}).boundingBox();
    const field=nav.getByRole('textbox',{name:'Page number',exact:true});if(await field.count())controls.input=await field.boundingBox();
    await page.screenshot({path});rows.push({step,path,bounds,frame,controls,status:await status(page)});
   };
   await page.mouse.move(1,1);await capture('idle');
   const hover=nav.getByRole('button',{name:number<=1?'Next page':'Previous page',exact:true});await hover.hover();await capture('hover');
   if(item.page==='3'){
    const field=nav.getByRole('textbox',{name:'Page number',exact:true});
    await field.click();
    for(const value of ['abc','2.5','0x10','1e1','-2','+3','','  ','１２','٣']){
     await edit(page,field,value);await field.press('Enter');await page.waitForTimeout(100);await settled(page,async()=>await field.inputValue()==='3');assert.deepEqual(await status(page),{page:3,calls:0},`${target} invalid ${value}`);
    }
    for(const [value,expected]of [[' 007 ',7],['999',10],['0',1]]){
     await edit(page,field,value);await field.press('Enter');await settled(page,async()=>(await status(page)).page===expected);assert.equal(await field.inputValue(),String(expected));
    }
    await edit(page,field,'2.5');await field.press('Tab');await settled(page,async()=>await field.inputValue()==='1');assert.equal((await status(page)).calls,3);
    await capture('validated');
    await nav.getByRole('button',{name:'Next page',exact:true}).click();await settled(page,async()=>(await status(page)).page===2);
    await page.keyboard.press('Tab');await page.keyboard.press('Enter');await settled(page,async()=>(await status(page)).page===10);await capture('keyboard-last');
   }
   if(item.selector==='dropdown'){
    const select=target==='reference'?nav.getByRole('combobox',{name:'Page number',exact:true}):nav.getByRole('button',{name:/^Page number/});
    await select.click();await capture('page-menu');await page.getByRole('option',{name:'5',exact:true}).or(page.getByRole('button',{name:'5',exact:true})).click();await settled(page,async()=>(await status(page)).page===5);await capture('page-selected');
   }
   if(item.compound==='true'){
    await group.getByText('Showing 21-30 of 100',{exact:true}).waitFor();
    const select=target==='reference'?group.getByRole('combobox',{name:'Page size',exact:true}):group.getByRole('button',{name:/^Page size/});
    await select.click();await page.getByRole('option',{name:'25',exact:true}).or(page.getByRole('button',{name:'25',exact:true})).click();await group.getByText('Showing 51-75 of 100',{exact:true}).waitFor();assert.deepEqual(await status(page),{page:3,calls:0});await capture('page-size');
   }
   captures[target]=rows;
  }
  const states=[];
  for(const [n,a]of captures.reference.entries()){
   const b=captures.flutter[n];assert.equal(a.step,b.step);assert.deepEqual(a.status,b.status);
   const delta=(a,b)=>Object.fromEntries(['x','y','width','height'].map(k=>[k,Math.abs(a[k]-b[k])]));
   const navDelta=delta(a.bounds,b.bounds),frameDelta=delta(a.frame,b.frame),controlDeltas=Object.fromEntries(Object.keys(a.controls).map(k=>[k,delta(a.controls[k],b.controls[k])]));
   const geometryPass=Math.max(...Object.values(navDelta),...Object.values(frameDelta),...Object.values(controlDeltas).flatMap(Object.values))<=1;
   const [pa,pb]=await Promise.all([a,b].map(async c=>PNG.sync.read(await readFile(c.path))));
   const x=Math.floor(Math.min(a.bounds.x,b.bounds.x))-4,y=Math.floor(Math.min(a.bounds.y,b.bounds.y))-4,w=Math.ceil(Math.max(a.bounds.x+a.bounds.width,b.bounds.x+b.bounds.width))+4-x,h=Math.ceil(Math.max(a.bounds.y+a.bounds.height,b.bounds.y+b.bounds.height))+4-y;
   const crop=p=>{const q=new PNG({width:w,height:h});PNG.bitblt(p,q,x,y,w,h,0,0);return q;},ca=crop(pa),cb=crop(pb),diff=new PNG({width:w,height:h});
   const ratio=pixelmatch(ca.data,cb.data,diff.data,w,h,{threshold:.1})/(w*h),diffPath=`${folder}/${index}-${a.step}-diff.png`;await writeFile(diffPath,PNG.sync.write(diff));
   states.push({step:a.step,reference:a,candidate:b,navDelta,frameDelta,controlDeltas,geometryPass,pixelDifferenceRatio:ratio,diffPath,region:{x,y,width:w,height:h}});
  }
  results.push({index,...item,states});
 }
}finally{
 await browser.close();await writeFile(folder+'/comparison.json',JSON.stringify({success:results.length===selected.length&&!errors.length,fullRun:selected.length===cases.length,browser:version,referenceSha:'947065ad39694fdc688b1128cc9c360f566a4f73',dependencyReviewSha:'7e0ff40546f08405d05bc9754f0ff0fd009ece0a',candidateArtifactSha256:createHash('sha256').update(await readFile('apps/demo/build/web/main.dart.wasm')).digest('hex'),geometryContract:'Within1px diagnosis for nav/host/controls. Dropdown and compound sizing inherit existing Select differences. Pixel diagnostics include native font/icon/focus differences and are not visual certification.',fullVisualParity:false,results,issues,errors},null,2)+'\n');
}
assert.equal(errors.length,0);const mismatches=results.flatMap(r=>r.states.filter(s=>!s.geometryPass).map(s=>({index:r.index,step:s.step,navDelta:s.navDelta,controlDeltas:s.controlDeltas})));
console.log(JSON.stringify({contexts:results.length,states:results.reduce((n,r)=>n+r.states.length,0),issues:issues.length,errors:errors.length,geometryMismatches:mismatches}));
assert.equal(mismatches.filter(s=>!cases[s.index].selector&&!cases[s.index].compound).length,0);
