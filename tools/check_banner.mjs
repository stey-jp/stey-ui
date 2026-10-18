import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {mkdir,readFile,writeFile} from 'node:fs/promises';
import {chromium} from 'playwright';
import {PNG} from 'pngjs';
import pixelmatch from 'pixelmatch';

const folder='output/playwright/banner';await mkdir(folder,{recursive:true});
const cases=[];
for(const mode of ['light','dark']){
 for(const bannerVariant of ['defaultValue','alert','error','secondary']){
  for(const bannerSize of ['base','sm'])for(const viewport of [390,1200])cases.push({mode,bannerVariant,bannerSize,viewport,host:viewport===390?350:480,direction:viewport===390?'rtl':'ltr',scenario:'matrix'});
  for(const actionVariant of ['secondary','ghost'])cases.push({mode,bannerVariant,actionVariant,viewport:1200,scenario:'action-variant'});
 }
 for(const scenario of ['link','compact-link','description-only','title-only','legacy','long','disabled','loading','icon','multiple'])cases.push({mode,viewport:390,host:350,scenario,
  ...(scenario==='link'?{action:'link'}:{}),...(scenario==='compact-link'?{action:'link',bannerSize:'sm'}:{}),
  ...(scenario==='description-only'?{title:'none',bannerSize:'sm',icon:'true'}:{}),...(scenario==='title-only'?{description:'none',action:'link',bannerSize:'sm'}:{}),
  ...(scenario==='legacy'?{legacy:'true',icon:'true'}:{}),...(scenario==='long'?{long:'true',bannerSize:'sm',direction:'rtl',icon:'true'}:{}),
  ...(['disabled','loading'].includes(scenario)?{state:scenario}:{}),...(['icon','multiple'].includes(scenario)?{action:scenario,bannerSize:'sm'}:{}),
 });
}
const only=process.argv.find(x=>x.startsWith('--case='));
const selected=cases.map((item,index)=>({item,index})).filter(({index})=>!only||index===Number(only.split('=')[1]));
const results=[],errors=[],issues=[];let target,version;
const browser=await chromium.launch({channel:'chrome',headless:true});
try{
 version=browser.version();const page=await browser.newPage(),cdp=await page.context().newCDPSession(page);
 await cdp.send('Audits.enable');cdp.on('Audits.issueAdded',({issue})=>issues.push({target,...issue}));page.on('pageerror',e=>errors.push({target,message:e.message}));
 for(const {item,index}of selected){
  console.log(JSON.stringify({index,...item}));const captures={};
  for(target of ['reference','flutter']){
   await page.setViewportSize({width:item.viewport,height:900});const url=new URL('http://127.0.0.1:'+(target==='reference'?8767:8766)+'/');
   url.searchParams.set(target==='reference'?'component':'sample','banner');
   for(const [k,v]of Object.entries(item))if(!['viewport','scenario'].includes(k))url.searchParams.set(k,String(v));
   await page.goto(url.href,{waitUntil:'networkidle'});const group=page.getByRole('group',{name:'Banner preview',exact:true});await group.waitFor();
   const action=item.action==='link'?group.getByRole('link',{name:'Details',exact:true}):group.getByRole('button',{name:item.action==='icon'?'Dismiss':'Details',exact:true});
   const counter=n=>target==='reference'?page.locator('[aria-label="Action calls: '+n+'"]'):page.getByText('Action calls: '+n,{exact:true});
   const legacy=item.legacy==='true';const rows=[];
   const capture=async step=>{
    const titleOnlyLink=item.description==='none'&&item.action==='link';
    const textNode=target==='flutter'&&titleOnlyLink?group.getByRole('group',{name:'Update available',exact:true}):group.getByText(legacy?'Legacy notice':item.title==='none'?(item.long==='true'?'Review access permissions and project settings before saving changes to your account.':'Review your settings before saving.'):'Update available',{exact:!titleOnlyLink}).first();
    const text=await textNode.evaluate((el,flutter)=>{
     const n=flutter?el.closest('flt-semantics'):el;const {x,y,width,height}=n.getBoundingClientRect();return {x,y,width,height};
    },target==='flutter');
    const path=folder+'/'+index+'-'+step+'-'+target+'.png';await page.screenshot({path});
    const actionBox=legacy?null:await action.boundingBox();
    const actionLineBoxHeight=legacy?null:await action.evaluate(el=>getComputedStyle(el).display==='inline'?parseFloat(getComputedStyle(el).lineHeight):el.getBoundingClientRect().height);
    rows.push({step,path,frame:await group.boundingBox(),action:actionBox,actionLineBoxHeight,text,callCount:await counter(1).count()?1:await counter(2).count()?2:0});
   };
   await page.mouse.move(1,1);await capture('idle');
   if(!legacy){
    await action.hover({force:true});await page.waitForTimeout(120);await capture('hover');await page.mouse.move(1,1);
    if(!['disabled','loading'].includes(item.state)){
     await page.keyboard.press('Tab');await page.waitForTimeout(40);assert(await action.evaluate(el=>el===document.activeElement||el.contains(document.activeElement)),index+' '+target+' Tab');await capture('focus');
     if(target==='flutter'&&item.action==='link')assert.equal(await group.locator('[tabindex="0"]').count(),1,index+' one native link Tab stop');
     if(item.action==='link')await page.keyboard.press('Enter');else{
      await page.keyboard.down('Space');assert(await counter(0).count(),index+' '+target+' no Space keydown action');await page.keyboard.up('Space');
     }
     await counter(1).waitFor();await capture('activated');
    }else{
     await action.click({force:true});await page.keyboard.press('Tab');await page.keyboard.press('Enter');await page.waitForTimeout(80);
     assert(await counter(0).count(),index+' '+target+' blocked action');await capture('blocked');
    }
   }
   captures[target]=rows;
  }
  const states=[];
  for(const [n,a]of captures.reference.entries()){
   const b=captures.flutter[n];assert.equal(a.step,b.step);
   const delta=(x,y,keys)=>Object.fromEntries(keys.map(k=>[k,Math.abs(x[k]-y[k])]));
   const frameDelta=delta(a.frame,b.frame,['x','y','width','height']),rawActionDelta=a.action?delta(a.action,b.action,['x','y','width','height']):{};
   // HTML inline anchors expose glyph bounds; Flutter semantics exposes the
   // paragraph line box. Retain raw bounds and compare their actual line height.
   const actionDelta={...rawActionDelta,...(a.action?{height:Math.abs(a.actionLineBoxHeight-b.actionLineBoxHeight)}:{})};
   const textDelta=delta(a.text,b.text,['y','height']);
   const [i,j]=await Promise.all([a,b].map(async c=>PNG.sync.read(await readFile(c.path))));assert.equal(i.width,j.width);assert.equal(i.height,j.height);
   const diff=new PNG({width:i.width,height:i.height}),ratio=pixelmatch(i.data,j.data,diff.data,i.width,i.height,{threshold:.1})/(i.width*i.height);
   await writeFile(folder+'/'+index+'-'+a.step+'-diff.png',PNG.sync.write(diff));
   const geometryPass=Math.max(...Object.values(frameDelta),...Object.values(actionDelta),...Object.values(textDelta))<=1;
   states.push({step:a.step,captures:[a,b],frameGeometryDelta:frameDelta,actionGeometryDelta:actionDelta,rawActionGeometryDelta:rawActionDelta,textLineGeometryDelta:textDelta,pixelDifferenceRatio:ratio,geometryPass});
  }
  results.push({index,...item,states});
 }
}finally{
 await browser.close();await writeFile(folder+'/comparison.json',JSON.stringify({success:results.length===selected.length&&!errors.length&&results.every(r=>r.states.every(s=>s.geometryPass)),fullRun:selected.length===cases.length,browser:version,
 referenceSha:'7e0ff40546f08405d05bc9754f0ff0fd009ece0a',candidateArtifactSha256:createHash('sha256').update(await readFile('apps/demo/build/web/main.dart.wasm')).digest('hex'),geometryContract:'Frame, action position/width and text-line bounds. Inline HTML anchor glyph height is normalized to computed line-height for comparison with Flutter paragraph semantics; raw action bounds are retained.',fullVisualParity:false,results,issues,errors},null,2)+'\n');
}
assert.equal(errors.length,0);const mismatches=results.flatMap(r=>r.states.filter(s=>!s.geometryPass).map(s=>({index:r.index,scenario:r.scenario,step:s.step,frame:s.frameGeometryDelta,action:s.actionGeometryDelta,text:s.textLineGeometryDelta})));
console.log(JSON.stringify({contexts:results.length,states:results.reduce((n,r)=>n+r.states.length,0),issues:issues.length,errors:errors.length,geometryMismatches:mismatches}));assert.equal(mismatches.length,0);
