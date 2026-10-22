import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {mkdir,readFile,writeFile} from 'node:fs/promises';
import {chromium} from 'playwright';
import {PNG} from 'pngjs';
import pixelmatch from 'pixelmatch';

const folder=process.env.LABEL_OUTPUT??'output/playwright/label';await mkdir(folder,{recursive:true});
const hash=async()=>createHash('sha256').update(await readFile('apps/demo/build/web/main.dart.wasm')).digest('hex');
const artifactHash=await hash();
const variants=[{}, {optional:'true'}, {help:'true'}, {optional:'true',help:'true'},
 {optional:'true',optionalLabel:'(your choice)'}, {optional:'true',optionalLabel:''},
 {inherit:'true',font:'20'}, {inherit:'true',font:'20',optional:'true',help:'true'},
 {rich:'true',optional:'true',help:'true'},
 {host:'120',content:'Project name with longer text',optional:'true',help:'true'},
 {direction:'rtl',optional:'true',help:'true'},
 {host:'180',scale:'2',optional:'true',help:'true'},
 {host:'180',scale:'2',inherit:'true',font:'16',help:'true'},
 {content:'اسم المشروع',direction:'rtl',optional:'true',help:'true'}];
const cases=['light','dark'].flatMap(mode=>variants.map(v=>({mode,...v}))),only=process.argv.find(a=>a.startsWith('--case='));
const selected=cases.map((item,index)=>({item,index})).filter(r=>!only||r.index===Number(only.split('=')[1]));
const results=[],issues=[],errors=[];let complete=false,version;
const browser=await chromium.launch({channel:'chrome',headless:true});
try {
 version=browser.version();const context=await browser.newContext({viewport:{width:1100,height:800}}),pages={};
 for(const target of ['reference','flutter']) {
  const p=await context.newPage(),cdp=await context.newCDPSession(p);pages[target]=p;p.setDefaultTimeout(15000);
  await cdp.send('Audits.enable');cdp.on('Audits.issueAdded',({issue})=>issues.push({target,...issue}));
  p.on('pageerror',e=>errors.push({target,message:e.message,stack:e.stack}));
 }
 for(const {item,index}of selected) {
  console.log(JSON.stringify({index,...item}));const captures={};
  for(const target of ['reference','flutter']) {
   const p=pages[target],q=new URLSearchParams(item);q.set(target==='reference'?'component':'sample','label');
   await p.bringToFront();await p.goto('http://127.0.0.1:'+(target==='reference'?8767:8766)+'/?'+q,{waitUntil:'networkidle'});
   const group=p.getByRole('group',{name:'Label content',exact:true}),preview=p.getByRole('group',{name:'Label preview',exact:true});
   await group.waitFor();await p.evaluate(()=>document.fonts.ready);await p.waitForTimeout(100);
   const states={},help=item.help==='true',phases=help?['idle','hover','focus']:['idle'];
   for(const state of phases) {
    if(state==='hover') {await group.getByRole('button',{name:item.rich==='true'?'詳しい情報':'More information',exact:true}).hover();await p.waitForTimeout(850);}
    if(state==='focus') {
     await p.mouse.move(0,0);await p.waitForTimeout(200);
     await p.keyboard.press('Tab');await p.waitForTimeout(250);
    }
    const frame=await group.boundingBox(),path=`${folder}/${index}-${target}-${state}.png`;
    await p.screenshot({path});
    const popupLocator=target==='flutter'?p.locator('flt-semantics-host').getByText('Helpful context',{exact:true}):p.getByText('Helpful context',{exact:true});
    const popupText=help&&state!=='idle'&&await popupLocator.count()?await popupLocator.boundingBox():null;
    // Record invisible hover content as a mismatch instead of dropping the
    // remaining conditions; overflow hit testing is not certified.
    const computed=target==='reference'?await group.locator('label,span').first().evaluate(e=>{const s=getComputedStyle(e);return Object.fromEntries(['fontSize','fontWeight','lineHeight','color','gap','display'].map(k=>[k,s[k]]));}):null;
    states[state]={frame,path,popupText,computed,accessibilitySnapshot:await group.ariaSnapshot()};
   }
   if(help) {
    await p.keyboard.press('Escape');await p.waitForTimeout(200);assert.equal(await (target==='flutter'?p.locator('flt-semantics-host'):p).getByText('Helpful context',{exact:true}).count(),0,'Escape closes');
    // A focus transition after Escape must not trap the next editor.
    await p.keyboard.press('Tab');await p.waitForTimeout(100);
    assert(await preview.getByRole('textbox',{name:'Editor',exact:true}).evaluate(e=>e===document.activeElement),'Tab reaches editor');
   }
   // Start from the neighboring action to distinguish normal association from
   // the known Flutter Web already-editing refocus limitation.
   await preview.getByRole('button',{name:'Next action',exact:true}).focus();await p.waitForTimeout(100);
   const labelBox=await group.boundingBox();
   await p.mouse.click(item.direction==='rtl'?labelBox.x+labelBox.width-4:labelBox.x+4,labelBox.y+labelBox.height/2);await p.waitForTimeout(100);
   const editorDomFocused=await preview.getByRole('textbox',{name:'Editor',exact:true}).evaluate(e=>e===document.activeElement);
   await p.keyboard.type('project');await p.waitForTimeout(100);
   assert.equal(await preview.getByRole('textbox',{name:'Editor',exact:true}).inputValue(),'project','label association receives physical keyboard input');
   states.idle.editorDomFocusedAfterLabel=editorDomFocused;
   await p.mouse.click(item.direction==='rtl'?labelBox.x+labelBox.width-4:labelBox.x+4,labelBox.y+labelBox.height/2);
   await p.waitForTimeout(100);await p.keyboard.type('x');await p.waitForTimeout(100);
   states.idle.repeatedAssociationValue=await preview.getByRole('textbox',{name:'Editor',exact:true}).inputValue();
   states.idle.repeatedAssociationPass=states.idle.repeatedAssociationValue==='projectx';
   await preview.getByRole('button',{name:'Next action',exact:true}).click();await p.waitForTimeout(100);
   assert(await preview.getByText('Next: 1',{exact:true}).count(),'neighbor remains usable');
   captures[target]=states;
  }
  for(const state of Object.keys(captures.reference)) {
   const a=captures.reference[state],b=captures.flutter[state];
   const frameDelta=Object.fromEntries(['x','y','width','height'].map(k=>[k,Math.abs(a.frame[k]-b.frame[k])]));
   const geometryPass=Math.max(...Object.values(frameDelta))<=1;
   const [pa,pb]=await Promise.all([a,b].map(async r=>PNG.sync.read(await readFile(r.path))));
   const x=Math.floor(Math.min(a.frame.x,b.frame.x))-4,y=Math.floor(Math.min(a.frame.y,b.frame.y))-65,width=Math.ceil(Math.max(a.frame.x+a.frame.width,b.frame.x+b.frame.width))+4-x,height=Math.ceil(Math.max(a.frame.y+a.frame.height,b.frame.y+b.frame.height))+4-y;
   const crop=p=>{const out=new PNG({width,height});PNG.bitblt(p,out,x,y,width,height,0,0);return out;};
   const ca=crop(pa),cb=crop(pb),diff=new PNG({width,height});
   const pixelDifferenceRatio=pixelmatch(ca.data,cb.data,diff.data,width,height,{threshold:.1})/(width*height),diffPath=`${folder}/${index}-${state}-diff.png`;await writeFile(diffPath,PNG.sync.write(diff));
   results.push({index,...item,state,reference:a,candidate:b,frameDelta,geometryPass,behaviorPass:true,tooltipVisibilityPass:Boolean(a.popupText)===Boolean(b.popupText),repeatedAssociationPass:captures.reference.idle.repeatedAssociationPass===captures.flutter.idle.repeatedAssociationPass,pixelDifferenceRatio,diffPath,region:{x,y,width,height}});
   if(!geometryPass)console.log(JSON.stringify({mismatch:index,state,frameDelta}));
  }
 }complete=true;
}finally {
 await browser.close();const candidateArtifactUnchanged=artifactHash===await hash();
 await writeFile(folder+'/comparison.json',JSON.stringify({executionComplete:complete,success:complete&&candidateArtifactUnchanged&&!errors.length&&results.every(r=>r.geometryPass&&r.behaviorPass&&r.tooltipVisibilityPass&&r.repeatedAssociationPass),fullRun:!only,referenceSha:'947065ad39694fdc688b1128cc9c360f566a4f73',browser:version,candidateArtifactSha256:artifactHash,candidateArtifactUnchanged,geometryContract:'Label outer bounds within1px;keyboard hover/Escape/editor association and neighbor operation. Tooltip pixels and text bounds recorded;full collision,BaseUI safePolygon,click/touch and ARIA association are not certified. Native legacy click-to-open differs from BaseUI closeOnClick. Repeated already-editing association is explicitly compared and a known native Web mismatch;success remains false when it differs.',fullVisualParity:false,results,issues,errors},null,2)+'\n');
}
console.log(JSON.stringify({frames:results.length,issues:issues.length,errors:errors.length,mismatches:results.filter(r=>!r.geometryPass||!r.behaviorPass).map(r=>[r.index,r.state]),repeatedAssociationMismatches:results.filter(r=>!r.repeatedAssociationPass).map(r=>[r.index,r.state]),geometryMismatchIndices:results.filter(r=>!r.geometryPass||!r.behaviorPass).map(r=>[r.index,r.state])}));
assert.equal(errors.length,0);assert(results.every(r=>r.geometryPass&&r.behaviorPass&&r.tooltipVisibilityPass&&r.repeatedAssociationPass));
