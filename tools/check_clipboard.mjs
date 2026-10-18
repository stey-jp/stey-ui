import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {mkdir,readFile,writeFile} from 'node:fs/promises';
import {chromium} from 'playwright';
import {PNG} from 'pngjs';
import pixelmatch from 'pixelmatch';

const folder='output/playwright/clipboard';await mkdir(folder,{recursive:true});
const cases=[];
for(const mode of ['light','dark']){
 for(const fieldSize of ['sm','base','lg'])for(const direction of ['ltr','rtl'])for(const viewport of [390,1200])cases.push({mode,fieldSize,direction,viewport,scenario:'keyboard'});
 for(const side of ['top','bottom','left','right'])cases.push({mode,side,viewport:390,tooltip:'true',scenario:'tooltip'});
 cases.push({mode,viewport:390,text:'namespace-'.repeat(18),host:'180',scenario:'long'});
 cases.push({mode,viewport:390,text:'short-id',value:'\tcomplete\r\n日本語\n',scenario:'raw'});
 for(const [side,offsetY]of [['top','-410'],['bottom','410']])cases.push({mode,side,offsetY,viewport:390,tooltip:'true',scenario:'edge'});
}
const selected=process.argv.find(a=>a.startsWith('--case='));
const todo=cases.map((item,index)=>({item,index})).filter(c=>!selected||c.index===Number(selected.split('=')[1]));
const results=[],issues=[],errors=[];let version,currentTarget;
const browser=await chromium.launch({channel:'chrome',headless:true});
try{
 version=browser.version();const context=await browser.newContext({permissions:['clipboard-read','clipboard-write']});
 await context.addInitScript(()=>{
  if(!navigator.clipboard)return;
  globalThis.__steyClipboardWrites=[];globalThis.__steyClipboardCompleted=0;
  const write=navigator.clipboard.writeText.bind(navigator.clipboard);
  navigator.clipboard.writeText=async value=>{globalThis.__steyClipboardWrites.push(value);const result=await write(value);globalThis.__steyClipboardCompleted++;return result;};
 });
 // A single foreground page avoids background-tab Clipboard API failures.
 const page=await context.newPage(),cdp=await context.newCDPSession(page);await cdp.send('Audits.enable');
 cdp.on('Audits.issueAdded',({issue})=>issues.push({target:currentTarget,...issue}));page.on('pageerror',e=>errors.push({target:currentTarget,message:e.message}));
 const button=()=>page.getByRole('button',{name:'Copy to clipboard',exact:true});
 const feedback=()=>currentTarget==='reference'
  ?page.getByRole('group',{name:'Clipboard preview',exact:true}).locator('span[aria-live="polite"]').filter({hasText:/^Copied$/})
  :page.getByRole('group',{name:'Clipboard preview',exact:true}).getByText('Copied',{exact:true}).and(page.locator(':not([role="status"]):not([role="status"] *)'));
 const visibleText=async text=>{
  if(currentTarget==='flutter'&&text==='Copied'){
   const status=page.getByRole('status',{name:'Copied',exact:true});
   if(await status.count()){const box=await status.boundingBox();if(box&&box.width>5&&box.height>5)return {box,role:'status'};}
  }
  const items=page.getByText(text,{exact:true});
  for(let n=0;n<await items.count();n++){const box=await items.nth(n).boundingBox();if(box&&box.width>5&&box.height>5)return {box,index:n};}
  return null;
 };
 for(const {item,index}of todo){
  console.log(JSON.stringify({index,...item}));const capturesByTarget={};
  for(const target of ['reference','flutter']){
   currentTarget=target;const snapshots=[];
   const capture=async step=>{
    const box=await button().boundingBox(),frame=await page.getByRole('group',{name:'Clipboard preview',exact:true}).boundingBox();assert(box&&frame);
    const textBox=await page.getByText(item.text??'namespace-id',{exact:true}).evaluate((el,target)=>{
     const node=target==='flutter'?el.closest('flt-semantics'):el;
     const {x,y,width,height}=node.getBoundingClientRect();return {x,y,width,height};
    },target);
    const path=folder+'/'+index+'-'+step+'-'+target+'.png';await page.screenshot({path});
    snapshots.push({step,target,box,frame,textBox,path,feedbackCount:await feedback().count(),popup:await visibleText(step==='hover'||step==='focus'?'Copy':'Copied')});
   };
   await page.setViewportSize({width:item.viewport,height:900});const url=new URL('http://127.0.0.1:'+(target==='flutter'?8766:8767)+'/');url.searchParams.set(target==='flutter'?'sample':'component','clipboard-text');
   for(const [key,value]of Object.entries(item))if(!['viewport','scenario'].includes(key))url.searchParams.set(key,String(value));
   await page.goto(url.href,{waitUntil:'networkidle'});await button().waitFor();await page.mouse.move(1,1);await page.waitForTimeout(220);await capture('idle');
   await button().hover();await page.waitForTimeout(750);await capture('hover');
   if(item.tooltip==='true')assert(await visibleText('Copy'),index+' '+target+' tooltip');
   if(item.scenario==='keyboard'){
    if(target==='flutter')assert.equal(await page.getByRole('group',{name:'Clipboard preview',exact:true}).locator('[tabindex="0"]').count(),1,index+' no extra text Tab stop');
    await page.mouse.move(1,1);await page.keyboard.press('Tab');await page.waitForTimeout(80);
    assert(await button().evaluate(el=>el===document.activeElement),index+' '+target+' Tab');await capture('focus');
    await page.keyboard.down('Space');await page.waitForTimeout(30);assert.equal(await feedback().count(),0);await page.keyboard.up('Space');
   }else await button().click();
   await feedback().waitFor({state:'attached'});await page.waitForFunction(()=>globalThis.__steyClipboardCompleted===1);
   assert.equal(await page.evaluate(()=>globalThis.__steyClipboardWrites.length),1,index+' '+target+' one write');
   const text=await page.evaluate(()=>navigator.clipboard.readText()),expected=item.value??item.text??'namespace-id';assert.equal(text.replace(/\r\n/g,'\n'),expected.replace(/\r\n/g,'\n'));
   await page.waitForTimeout(220);await capture('copied');
   if(item.tooltip==='true')assert(await visibleText('Copied'),index+' '+target+' success toast');
   if(item.scenario==='keyboard'||item.scenario==='tooltip'){
    await page.waitForTimeout(550);
    if(item.scenario==='keyboard')await page.keyboard.press('Enter');else await button().click();
    await page.waitForFunction(()=>globalThis.__steyClipboardCompleted===2);await page.waitForTimeout(850);
    assert.equal(await feedback().count(),1,index+' '+target+' renewed feedback');assert.equal(await page.evaluate(()=>globalThis.__steyClipboardWrites.length),2);
   }
   await feedback().waitFor({state:'detached'});await page.waitForTimeout(220);await capture('reset');
   snapshots.at(-1).clipboard={target,text};capturesByTarget[target]=snapshots;
  }
  const states=[];
  for(const [n,a]of capturesByTarget.reference.entries()){
   const b=capturesByTarget.flutter[n];assert.equal(a.step,b.step);const images=await Promise.all([a,b].map(async c=>PNG.sync.read(await readFile(c.path))));
   const [i,j]=images,diff=new PNG({width:i.width,height:i.height});const ratio=pixelmatch(i.data,j.data,diff.data,i.width,i.height,{threshold:.1})/(i.width*i.height);await writeFile(folder+'/'+index+'-'+a.step+'-diff.png',PNG.sync.write(diff));
   const delta=field=>Object.fromEntries(Object.keys(a[field]).map(k=>[k,Math.abs(a[field][k]-b[field][k])]));
   const buttonDelta=delta('box'),frameDelta=delta('frame'),textDelta={height:Math.abs(a.textBox.height-b.textBox.height),y:Math.abs(a.textBox.y-b.textBox.y)};
   assert(Math.max(...Object.values(buttonDelta),...Object.values(frameDelta),...Object.values(textDelta))<=1,index+' '+a.step+' geometry '+JSON.stringify({buttonDelta,frameDelta,textDelta}));
   states.push({step:a.step,captures:[a,b],buttonGeometryDelta:buttonDelta,frameGeometryDelta:frameDelta,textLineGeometryDelta:textDelta,pixelDifferenceRatio:ratio});
  }
  results.push({index,...item,states});
 }
 await context.close();
}finally{
 await browser.close();await writeFile(folder+'/comparison.json',JSON.stringify({success:results.length===todo.length&&errors.length===0,fullRun:todo.length===cases.length,browser:version,referenceSha:'7e0ff40546f08405d05bc9754f0ff0fd009ece0a',candidateArtifactSha256:createHash('sha256').update(await readFile('apps/demo/build/web/main.dart.wasm')).digest('hex'),execution:'One foreground Chrome page; reference and Flutter states captured sequentially; actual Clipboard API completion and OS content verified.',fullVisualParity:false,results,issues,errors},null,2)+'\n');
}
assert.equal(errors.length,0);console.log(JSON.stringify({contexts:results.length,states:results.reduce((n,r)=>n+r.states.length,0),issues:issues.length,errors:errors.length}));
