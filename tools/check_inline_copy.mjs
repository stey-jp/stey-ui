import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {mkdir,readFile,writeFile} from 'node:fs/promises';
import {chromium} from 'playwright';
import {PNG} from 'pngjs';
import pixelmatch from 'pixelmatch';

const folder='output/playwright/inline-copy';await mkdir(folder,{recursive:true});
const cases=[];
for(const mode of ['light','dark']) {
 for(const direction of ['ltr','rtl'])for(const viewport of [390,1200])cases.push({mode,direction,viewport,scenario:'keyboard',textVariant:'monoSecondary'});
 for(const textVariant of ['body','secondary','success','error','mono'])cases.push({mode,viewport:1200,textVariant,scenario:'variant'});
 for(const textSize of ['xs','sm','lg'])cases.push({mode,viewport:1200,textVariant:'body',textSize,bold:'true',scenario:'size'});
 cases.push({mode,viewport:1200,textVariant:'mono',textSize:'lg',scenario:'mono-large'});
 for(const scenario of ['rich','long','disabled','cancel','group','wrap','unbroken'])cases.push({mode,viewport:390,scenario,
  textVariant:scenario==='rich'?'body':'monoSecondary',
  ...(scenario==='rich'?{rich:'true',textSize:'lg',bold:'true'}:{}),
  ...(scenario==='long'?{text:'namespace-'.repeat(18),value:'complete-resource-id',host:'180'}:{}),
  ...(scenario==='disabled'?{disabled:'true'}:{}),...(scenario==='cancel'?{cancel:'true'}:{}),...(scenario==='group'?{group:'true'}:{}),
  ...(scenario==='wrap'?{text:'Visible resource name with multiple words',textVariant:'body',host:'160',truncate:'false'}:{}),
  ...(scenario==='unbroken'?{text:'namespace'.repeat(12),host:'160',truncate:'false'}:{}),
 });
}
const results=[],issues=[],errors=[];let version;
const browser=await chromium.launch({channel:'chrome',headless:true});
try {
 version=browser.version();const context=await browser.newContext({permissions:['clipboard-read','clipboard-write']}),pages=[];
 for(const target of ['reference','flutter']) {
  const page=await context.newPage(),cdp=await context.newCDPSession(page);
  cdp.on('Audits.issueAdded',({issue})=>issues.push({target,...issue}));await cdp.send('Audits.enable');
  page.on('pageerror',error=>errors.push({target,message:error.message}));pages.push({target,page});
 }
 for(const [index,item] of cases.entries()) {
  console.log(JSON.stringify({index,...item}));const states=[];
  const pause=ms=>Promise.all(pages.map(({page})=>page.waitForTimeout(ms)));
  const snapshot=async(step,label='Copy to clipboard')=>{
   const captures=[],images=[];
   for(const {target,page} of pages){
    const button=page.getByRole('button',{name:label,exact:true}),box=await button.boundingBox();assert(box);
    const frame=await page.getByRole('group',{name:'Inline copy preview',exact:true}).boundingBox();
    const path=`${folder}/${index}-${step}-${target}.png`;images.push(PNG.sync.read(await page.screenshot({path})));
    captures.push({target,box,frame,label,disabled:await button.isDisabled(),path});
   }
   const [a,b]=images,diff=new PNG({width:a.width,height:a.height});
   const ratio=pixelmatch(a.data,b.data,diff.data,a.width,a.height,{threshold:.1})/(a.width*a.height);
   await writeFile(`${folder}/${index}-${step}-diff.png`,PNG.sync.write(diff));
   const delta=Object.fromEntries(Object.keys(captures[0].box).map(key=>[key,Math.abs(captures[0].box[key]-captures[1].box[key])]));
   const layoutException=['unbroken'].includes(item.scenario);
   if(!layoutException){assert(delta.height<=1,`${index} ${step} height ${delta.height}`);assert(delta.y<=1,`${index} ${step} y ${delta.y}`);}
   if(['body','secondary','success','error'].includes(item.textVariant)&&!layoutException)assert(delta.width<=1,`${index} ${step} proportional width ${delta.width}`);
   states.push({step,captures,geometryDelta:delta,layoutException,pixelDifferenceRatio:ratio});
  };
  for(const {target,page} of pages){
   await page.setViewportSize({width:item.viewport,height:900});
   const url=new URL(`http://127.0.0.1:${target==='flutter'?8766:8767}/`);url.searchParams.set(target==='flutter'?'sample':'component','inline-copy-text');
   for(const [key,value]of Object.entries(item))if(!['viewport','scenario'].includes(key))url.searchParams.set(key,String(value));
   await page.goto(url.href,{waitUntil:'networkidle'});await page.getByRole('button',{name:'Copy to clipboard',exact:true}).waitFor();await page.mouse.move(1,1);
  }
  await pause(200);await snapshot('idle');
  for(const {page}of pages)await page.getByRole('button',{name:'Copy to clipboard',exact:true}).hover();
  await pause(200);await snapshot('hover');
  if(item.scenario==='disabled'){
   for(const {page}of pages){const b=page.getByRole('button',{name:'Copy to clipboard',exact:true});assert(await b.isDisabled());const r=await b.boundingBox();await page.mouse.click(r.x+r.width/2,r.y+r.height/2);assert.equal(await page.getByRole('button',{name:'Copied',exact:true}).count(),0);}
  }else if(item.scenario==='cancel'){
   for(const {page}of pages){await page.getByRole('button',{name:'Copy to clipboard',exact:true}).click();await page.waitForTimeout(80);assert.equal(await page.getByRole('button',{name:'Copied',exact:true}).count(),0);}
  }else{
   if(item.scenario==='keyboard'){
    for(const {page,target}of pages){await page.mouse.move(1,1);await page.keyboard.press('Tab');await page.waitForTimeout(80);const active=await page.evaluate(()=>document.activeElement?.getAttribute('aria-label')||document.activeElement?.textContent);assert(active.includes('Copy to clipboard'),`${index} ${target} Tab: ${active}`);}
    await snapshot('focus');
    for(const {page}of pages){await page.keyboard.down('Space');await page.waitForTimeout(40);assert.equal(await page.getByRole('button',{name:'Copied',exact:true}).count(),0);await page.keyboard.up('Space');}
   }else for(const {page}of pages)await page.getByRole('button',{name:'Copy to clipboard',exact:true}).click();
   const clipboards=[];
   for(const {target,page}of pages){await page.getByRole('button',{name:'Copied',exact:true}).waitFor();const text=await page.evaluate(()=>navigator.clipboard.readText());const expected=item.value??(item.rich==='true'?'complete-resource-id':item.text??'namespace-id');assert.equal(text.replace(/\r\n/g,'\n'),expected.replace(/\r\n/g,'\n'));clipboards.push({target,text});}
   await snapshot('copied','Copied');
   if(item.scenario==='keyboard'){
    await pause(700);for(const {page}of pages)await page.keyboard.press('Enter');
    await pause(850);for(const {page}of pages)assert.equal(await page.getByRole('button',{name:'Copied',exact:true}).count(),1);
   }
   for(const {page}of pages)await page.getByRole('button',{name:'Copy to clipboard',exact:true}).waitFor();
   await snapshot('reset');states.at(-1).clipboards=clipboards;
  }
  if(item.scenario==='group'){
   for(const {page}of pages){const r=await page.getByRole('group',{name:'Inline copy preview'}).boundingBox();await page.mouse.move(r.x+4,r.y+4);}
   await pause(200);await snapshot('group-hover');
   for(const {page,target}of pages){await page.mouse.move(1,1);await page.keyboard.press('Tab');await page.waitForTimeout(80);const active=await page.evaluate(()=>document.activeElement?.getAttribute('aria-label')||document.activeElement?.textContent);assert(active.includes('Row action'),`${index} ${target} group focus: ${active}`);}
   await pause(200);await snapshot('group-focus');
  }
  results.push({index,...item,states});
 }
 await context.close();
}finally{
 await browser.close();await writeFile(`${folder}/comparison.json`,JSON.stringify({success:results.length===cases.length&&errors.length===0,browser:version,
  referenceSha:'7e0ff40546f08405d05bc9754f0ff0fd009ece0a',candidateArtifactSha256:createHash('sha256').update(await readFile('apps/demo/build/web/main.dart.wasm')).digest('hex'),
  pixelThreshold:.1,fullVisualParity:false,results,issues,errors},null,2)+'\n');
}
assert.equal(errors.length,0);console.log(JSON.stringify({contexts:results.length,states:results.reduce((n,r)=>n+r.states.length,0),issues:issues.length,errors:errors.length}));
