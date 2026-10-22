import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {mkdir,readFile,writeFile} from 'node:fs/promises';
import {chromium} from 'playwright';
import {PNG} from 'pngjs';
import pixelmatch from 'pixelmatch';

const folder=process.env.TAG_INPUT_OUTPUT??'output/playwright/tag-input';
await mkdir(folder,{recursive:true});
const hash=async()=>createHash('sha256').update(await readFile('apps/demo/build/web/main.dart.wasm')).digest('hex');
const artifactHash=await hash();
const variants=[{}, {state:'hover'}, {state:'focus'}, {host:'160'}, {host:'280'},
  {host:'160',values:'an-extremely-long-tag-that-must-truncate|three'},
  {direction:'rtl'}, {direction:'rtl',host:'160'}, {values:''}, {disabled:'true'},
  {readOnly:'true',scenario:'readonly'}, {label:'true',description:'true',required:'true'},
  {description:'true'}, {error:'true'}, {error:'true',variant:'default'},
  {scenario:'enter'}, {scenario:'comma'}, {scenario:'tab'}, {scenario:'backspace'},
  {scenario:'remove'}, {scenario:'blur'}, {scenario:'limit',max:'3'},
  {scenario:'invalid',validate:'true',values:'first@x'},
  {scenario:'paste-caret'}, {scenario:'paste-selection'}, {scenario:'paste-plain'},
  {scenario:'paste-newline',values:''}, {scenario:'enter',frozen:'true'},
  {scenario:'enter',uncontrolled:'true'}, {scenario:'label',label:'true'},
  {scenario:'remove',direction:'rtl'}, {scenario:'limit',max:'0',values:''}, {scenario:'empty-enter',values:''}];
const cases=['light','dark'].flatMap(mode=>variants.map(v=>({mode,...v})));
const only=process.argv.find(a=>a.startsWith('--case='));
const selected=cases.map((item,index)=>({item,index})).filter(r=>!only||r.index===Number(only.split('=')[1]));
const results=[],issues=[],errors=[];
let complete=false,version;
const browser=await chromium.launch({channel:'chrome',headless:true});
const status=async p=>JSON.parse(await p.getByText(/^\{"values":/).last().innerText());
const delta=(a,b)=>Object.fromEntries(['x','y','width','height'].map(k=>[k,Math.abs(a[k]-b[k])]));
try {
  version=browser.version();
  const context=await browser.newContext({viewport:{width:1100,height:800},permissions:['clipboard-read','clipboard-write']});
  const pages={};
  for(const target of ['reference','flutter']) {
    const p=await context.newPage(),cdp=await context.newCDPSession(p);
    p.setDefaultTimeout(15000);pages[target]=p;
    await cdp.send('Audits.enable');
    cdp.on('Audits.issueAdded',({issue})=>issues.push({target,...issue}));
    p.on('pageerror',e=>errors.push({target,message:e.message,stack:e.stack}));
  }
  for(const {item,index} of selected) {
    console.log(JSON.stringify({index,...item}));const captures={};
    for(const target of ['reference','flutter']) {
      const p=pages[target],q=new URLSearchParams(item);q.set(target==='reference'?'component':'sample','tag-input');
      await p.bringToFront();
      await p.goto('http://127.0.0.1:'+(target==='reference'?8767:8766)+'/?'+q,{waitUntil:'networkidle'});
      const neighbor=p.getByRole('button',{name:'After tags',exact:true});await neighbor.waitFor();
      await p.evaluate(()=>document.fonts.ready);await p.mouse.move(5,5);
      const initialFocus=await p.evaluate(()=>({tag:document.activeElement?.tagName,label:document.activeElement?.getAttribute('aria-label')}));
      await neighbor.focus();await p.waitForTimeout(80);
      const g=p.getByRole('group',{name:'Tag input preview',exact:true});
      const edit=item.disabled==='true'&&target==='flutter'
        ? p.locator('input,textarea') : p.getByRole('textbox');
      const fill=async value=>{await edit.click();await p.waitForTimeout(80);await edit.fill(value);await p.waitForTimeout(80);};
      const steps=[{stage:'initial',...await status(p),draft:await edit.inputValue()}];
      if(item.state==='hover')await g.hover();
      if(item.state==='focus')await edit.click();
      const scenario=item.scenario;
      if(['enter','comma','tab','blur','remove','limit','invalid'].includes(scenario)) {
        await fill(scenario==='remove'?'draft':scenario==='limit'?'three,four':scenario==='invalid'?'good@x,bad,later@x':'three');
        if(scenario==='blur')await neighbor.click();
        else if(scenario==='remove')await p.getByRole('button',{name:'Remove one',exact:true}).click();
        else await p.keyboard.press(scenario==='comma'?'Comma':scenario==='tab'?'Tab':'Enter');
      }
      if(scenario==='empty-enter'){await edit.click();await p.keyboard.press('Enter');}
      if(scenario==='backspace'){await edit.click();await p.keyboard.press('Backspace');}
      if(scenario==='label') {
        const r=await p.getByText('Tags',{exact:true}).boundingBox();
        await p.mouse.click(r.x+r.width/2,r.y+r.height/2);
      }
      if(scenario==='readonly') {
        await edit.click();await p.keyboard.press('Backspace');await p.keyboard.type('no');
        await p.keyboard.press('Enter');await neighbor.click();
      }
      if(scenario?.startsWith('paste-')) {
        const text=scenario==='paste-caret'?', bob':scenario==='paste-selection'?'i, bob, al':scenario==='paste-newline'?' one\n two,one ':'ce';
        await edit.click();await p.waitForTimeout(80);await p.keyboard.type(scenario==='paste-selection'?'alXXce':scenario==='paste-newline'?'':scenario==='paste-plain'?'ali':'alice',{delay:10});await p.waitForTimeout(80);
        if(scenario==='paste-selection') {
          await p.keyboard.press('Home');await p.keyboard.press('ArrowRight');await p.keyboard.press('ArrowRight');
          await p.keyboard.press('Shift+ArrowRight');await p.keyboard.press('Shift+ArrowRight');
          await p.waitForTimeout(80);assert.deepEqual(await edit.evaluate(e=>[e.selectionStart,e.selectionEnd]),[2,4],target+' selected range');
        }
        await p.evaluate(text=>navigator.clipboard.writeText(text),text);await p.keyboard.press('Control+v');
      }
      await p.waitForTimeout(150);
      // An inactive SDK DOM proxy can retain its old text. Refocus both targets
      // to read the actual editor draft after blur or Field insertion.
      if(['blur','limit','invalid'].includes(scenario)){await edit.click();await p.waitForTimeout(80);}
      steps.push({stage:scenario??item.state??'idle',...await status(p),draft:await edit.inputValue()});
      const frame=await g.boundingBox(),path=`${folder}/${index}-${target}.png`;
      await p.screenshot({path});
      captures[target]={frame,path,initialFocus,steps,
        editor:{rect:await edit.boundingBox(),attrs:await edit.evaluate(e=>Object.fromEntries(['type','aria-label','aria-invalid','aria-required','readonly','disabled'].map(k=>[k,e.getAttribute(k)])))},
        buttons:await g.getByRole('button').evaluateAll(es=>es.map(e=>({name:e.getAttribute('aria-label')||e.textContent,rect:e.getBoundingClientRect().toJSON()}))),
        focus:await p.evaluate(()=>({tag:document.activeElement?.tagName,label:document.activeElement?.getAttribute('aria-label')}))};
    }
    const a=captures.reference,c=captures.flutter,frameDelta=delta(a.frame,c.frame);
    const behaviorPass=JSON.stringify(c.steps)===JSON.stringify(a.steps),geometryPass=Math.max(...Object.values(frameDelta))<=1;
    const [pa,pb]=await Promise.all([a,c].map(async r=>PNG.sync.read(await readFile(r.path))));
    const x=Math.floor(Math.min(a.frame.x,c.frame.x))-4,y=Math.floor(Math.min(a.frame.y,c.frame.y))-4;
    const width=Math.ceil(Math.max(a.frame.x+a.frame.width,c.frame.x+c.frame.width))+4-x;
    const height=Math.ceil(Math.max(a.frame.y+a.frame.height,c.frame.y+c.frame.height))+4-y;
    const crop=p=>{const q=new PNG({width,height});PNG.bitblt(p,q,x,y,width,height,0,0);return q;};
    const ca=crop(pa),cb=crop(pb),diff=new PNG({width,height});
    const pixelDifferenceRatio=pixelmatch(ca.data,cb.data,diff.data,width,height,{threshold:.1})/(width*height);
    const diffPath=`${folder}/${index}-diff.png`;await writeFile(diffPath,PNG.sync.write(diff));
    results.push({index,...item,reference:a,candidate:c,frameDelta,behaviorPass,geometryPass,pixelDifferenceRatio,diffPath,region:{x,y,width,height}});
    if(!behaviorPass||!geometryPass)console.log(JSON.stringify({mismatch:index,behaviorPass,frameDelta,reference:a.steps,candidate:c.steps}));
  }
  complete=true;
}finally {
  await browser.close();const candidateArtifactUnchanged=artifactHash===await hash();
  await writeFile(folder+'/comparison.json',JSON.stringify({success:complete&&candidateArtifactUnchanged&&results.length===selected.length&&!errors.length&&results.every(r=>r.geometryPass&&r.behaviorPass),fullRun:!only,referenceSha:'947065ad39694fdc688b1128cc9c360f566a4f73',baseUiVersion:'1.9.0',browser:version,candidateArtifactSha256:artifactHash,candidateArtifactUnchanged,geometryContract:'Outer bounds within1px. Accepted values, notification counts and draft compared; paste uses real native Clipboard API and real keyboard/caret selection. Pixels and DOM attributes diagnostic. Full native HTML Form/ValidityState,IME229,all screen readers/physical platforms remain uncertified.',fullVisualParity:false,results,issues,errors},null,2)+'\n');
}
console.log(JSON.stringify({contexts:results.length,issues:issues.length,errors:errors.length,mismatches:results.filter(r=>!r.geometryPass||!r.behaviorPass).map(r=>r.index)}));
assert.equal(errors.length,0);assert(results.every(r=>r.geometryPass&&r.behaviorPass));
