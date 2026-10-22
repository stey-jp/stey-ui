import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {mkdir,readFile,writeFile} from 'node:fs/promises';
import {chromium} from 'playwright';
import {PNG} from 'pngjs';
import pixelmatch from 'pixelmatch';

const folder=process.env.TEXT_OUTPUT??'output/playwright/text';await mkdir(folder,{recursive:true});
const hash=async()=>createHash('sha256').update(await readFile('apps/demo/build/web/main.dart.wasm')).digest('hex');
const artifactHash=await hash(),copy=['body','secondary','success','error'];
const variants=[...copy.flatMap(variant=>['xs','sm','base','lg'].map(size=>({variant,size}))),
 ...['heading','heading1','heading2','heading3','mono','monoSecondary'].flatMap(variant=>[{variant},{variant,size:'lg'}]),
 ...copy.map(variant=>({variant,bold:'true'})),{inheritBold:'true'},
 {host:'120',content:'Workers process requests across the network'},
 {host:'120',content:'Workers process requests across the network',truncate:'true'},
 {direction:'rtl',host:'120',content:'مرحبا Workers requests',truncate:'true'},
 {direction:'rtl',host:'180',content:'مرحبا Workers requests'},
 {variant:'body',line:'32',size:'xs'}, {variant:'mono',line:'32'},
 {rich:'true'}, {rich:'true',host:'120',truncate:'true'},
 {variant:'heading',level:'2'}, {variant:'body',level:'4'},
 {scale:'2',host:'200',content:'Workers process requests across the network'},
 {scale:'2',host:'160',truncate:'true'}, {variant:'heading',size:'lg',scale:'2'},
 {content:''}];
const cases=['light','dark'].flatMap(mode=>variants.map(v=>({mode,...v}))),only=process.argv.find(a=>a.startsWith('--case='));
const selected=cases.map((item,index)=>({item,index})).filter(r=>!only||r.index===Number(only.split('=')[1]));
const results=[],issues=[],errors=[];let complete=false,version;
const browser=await chromium.launch({channel:'chrome',headless:true});
try {
 version=browser.version();const c=await browser.newContext({viewport:{width:1100,height:800}}),pages={};
 for(const target of ['reference','flutter']) {
  const p=await c.newPage(),cdp=await c.newCDPSession(p);p.setDefaultTimeout(15000);pages[target]=p;
  await cdp.send('Audits.enable');cdp.on('Audits.issueAdded',({issue})=>issues.push({target,...issue}));
  p.on('pageerror',e=>errors.push({target,message:e.message,stack:e.stack}));
 }
 for(const {item,index}of selected) {
  console.log(JSON.stringify({index,...item}));const captures={};
  for(const target of ['reference','flutter']) {
   const p=pages[target],q=new URLSearchParams(item);q.set(target==='reference'?'component':'sample','text');
   await p.bringToFront();await p.goto('http://127.0.0.1:'+(target==='reference'?8767:8766)+'/?'+q,{waitUntil:'networkidle'});
   // With no semantic text child, the SDK exposes the named preview as text
   // rather than a group. This is a fixture boundary, not a product DOM patch.
   const g=item.content===''&&target==='flutter'?p.getByText('Text preview',{exact:true}):p.getByRole('group',{name:'Text preview',exact:true,includeHidden:item.content===''});await g.waitFor({state:item.content===''?'attached':'visible'});await p.evaluate(()=>document.fonts.ready);
   await p.waitForTimeout(80);const frame=await g.boundingBox(),path=`${folder}/${index}-${target}.png`;
   await p.screenshot({path});
   const headings=await g.getByRole('heading').evaluateAll(es=>es.map(e=>({text:e.textContent,level:e.getAttribute('aria-level')||e.tagName.replace('H','')})));
   const text=item.rich==='true'?'Workers process requests':item.content??'Workers process requests';
   let content;
   if(target==='reference')content=await g.locator(':scope > div > *').innerText();
   else content=(await g.ariaSnapshot()).includes(text)||text===''?text:await g.innerText();
   const computed=target==='reference'?await g.locator(':scope > div > *').evaluate(e=>{const s=getComputedStyle(e);return Object.fromEntries(['fontFamily','fontSize','fontWeight','lineHeight','color','whiteSpace','overflow','textOverflow'].map(k=>[k,s[k]]));}):null;
   captures[target]={frame,path,headings,content,computed,accessibilitySnapshot:await g.ariaSnapshot()};
  }
  const a=captures.reference,c=captures.flutter,frameDelta=Object.fromEntries(['x','y','width','height'].map(k=>[k,Math.abs(a.frame[k]-c.frame[k])])),geometryPass=Math.max(...Object.values(frameDelta))<=1;
  const behaviorPass=a.content===c.content&&JSON.stringify(a.headings)===JSON.stringify(c.headings);
  const [pa,pb]=await Promise.all([a,c].map(async r=>PNG.sync.read(await readFile(r.path))));
  const x=Math.floor(Math.min(a.frame.x,c.frame.x))-4,y=Math.floor(Math.min(a.frame.y,c.frame.y))-4,width=Math.ceil(Math.max(a.frame.x+a.frame.width,c.frame.x+c.frame.width))+4-x,height=Math.ceil(Math.max(a.frame.y+a.frame.height,c.frame.y+c.frame.height))+4-y;
  const crop=p=>{const q=new PNG({width,height});PNG.bitblt(p,q,x,y,width,height,0,0);return q;},ca=crop(pa),cb=crop(pb),diff=new PNG({width,height});
  const pixelDifferenceRatio=pixelmatch(ca.data,cb.data,diff.data,width,height,{threshold:.1})/(width*height),diffPath=`${folder}/${index}-diff.png`;await writeFile(diffPath,PNG.sync.write(diff));
  results.push({index,...item,reference:a,candidate:c,frameDelta,geometryPass,behaviorPass,pixelDifferenceRatio,diffPath,region:{x,y,width,height}});
  if(!geometryPass||!behaviorPass)console.log(JSON.stringify({mismatch:index,geometryPass,behaviorPass,frameDelta,reference:a,candidate:c}));
 }complete=true;
}finally {
 await browser.close();const candidateArtifactUnchanged=artifactHash===await hash();
 await writeFile(folder+'/comparison.json',JSON.stringify({success:complete&&candidateArtifactUnchanged&&results.length===selected.length&&!errors.length&&results.every(r=>r.geometryPass&&r.behaviorPass),fullRun:!only,referenceSha:'947065ad39694fdc688b1128cc9c360f566a4f73',browser:version,candidateArtifactSha256:artifactHash,candidateArtifactUnchanged,geometryContract:'Outer bounds within1px; full text and requested heading levels compared. Typography computed styles are recorded from exact upstream source. Pixels diagnostic; native bundled Roboto Mono differs from upstream platform monospace. HTML element tags/inline formatting/whitespace/selection and full physical screen-reader states are not certified.',fullVisualParity:false,results,issues,errors},null,2)+'\n');
}
console.log(JSON.stringify({contexts:results.length,issues:issues.length,errors:errors.length,mismatches:results.filter(r=>!r.geometryPass||!r.behaviorPass).map(r=>r.index)}));
assert.equal(errors.length,0);assert(results.every(r=>r.geometryPass&&r.behaviorPass));
