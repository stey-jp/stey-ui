import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {mkdir,readFile,writeFile} from 'node:fs/promises';
import {chromium} from 'playwright';
import {PNG} from 'pngjs';
import pixelmatch from 'pixelmatch';

const output='output/playwright/code';await mkdir(output,{recursive:true});
const snippets={
 javascript:'const greeting = "Hello";\nconsole.log(greeting);',
 typescript:'interface Worker { name: string }\nconst worker: Worker = { name: "Stey" };',
 jsx:'const view = <button disabled={false}>Save</button>;\nexport default view;',
 tsx:'const view = (name: string) => <h1>{name}</h1>;\nexport default view;',
 json:'{\n  "name": "Stey",\n  "enabled": true\n}',
 jsonc:'{\n  // Worker settings\n  "enabled": true\n}',
 html:'<main>\n  <button type="button">Save</button>\n</main>',
 css:'.button {\n  color: #005cc5;\n  padding: 16px;\n}',
 python:'def greet(name):\n    return f"Hello, {name}"\nprint(greet("Stey"))',
 yaml:'name: Stey\nworkers:\n  - enabled: true',
 markdown:'# Stey UI\n\n**Native Flutter** components with `code`.',
 graphql:'query Worker {\n  worker(id: "stey") { name }\n}',
 sql:'SELECT name, enabled\nFROM workers\nWHERE enabled = true;',
 bash:'# Deploy a Worker\nexport NAME="stey"\necho "$NAME"',
 shell:'$ echo "Stey"\nStey',
 diff:'--- before\n+++ after\n-old value\n+new value',
 hcl:'resource "worker" "stey" {\n  enabled = true\n  count = 2\n}',
 toml:'[worker]\nname = "stey"\nenabled = true',
};
const cases=[];
for(const mode of ['light','dark']) {
 for(const [lang,code] of Object.entries(snippets))cases.push({mode,lang,code,width:480,viewport:1200});
 for(const viewport of [320,390,1200])for(const scenario of ['single','plain','no-numbers','overflow','fallback'])cases.push({
  mode,lang:scenario==='fallback'?'unknown':'js',code:scenario==='single'?'const answer = 42;':scenario==='overflow'?`const long = "${'abcdefghij'.repeat(15)}";\nconst end = 1;`:snippets.javascript,
  viewport,width:480,scenario,variant:scenario==='plain'?'plain':'default',numbers:scenario==='no-numbers'?'false':'true',fallback:scenario==='fallback'?'true':'false',
 });
}
const results=[],issues=[],errors=[];
const browser=await chromium.launch({channel:'chrome',headless:true});
let version;
try {
 version=browser.version();
 const context=await browser.newContext({viewport:{width:1200,height:900},permissions:['clipboard-read','clipboard-write']});
 const pages=[];
 for(const target of ['reference','flutter']) {
  const page=await context.newPage(),cdp=await context.newCDPSession(page);
  cdp.on('Audits.issueAdded',({issue})=>issues.push({target,...issue}));await cdp.send('Audits.enable');
  page.on('pageerror',error=>errors.push({target,message:error.message}));pages.push({target,page});
 }
 for(const [index,scenario] of cases.entries()) {
  console.log(JSON.stringify({index,mode:scenario.mode,lang:scenario.lang,scenario:scenario.scenario??'language',viewport:scenario.viewport}));
  const captures=[],images=[];
  for(const {target,page} of pages) {
   const native=target==='flutter';await page.setViewportSize({width:scenario.viewport,height:900});
   const url=new URL(`http://127.0.0.1:${native?8766:8767}/`);
   url.searchParams.set(native?'sample':'component','code-highlighted');
   for(const [key,value] of Object.entries(scenario))if(key!=='viewport'&&key!=='scenario')url.searchParams.set(key,String(value));
   await page.goto(url.href,{waitUntil:'networkidle'});
   const surface=page.getByRole('group',{name:'Code preview',exact:true});
   // Flutter emits the labelled container without an explicit group role.
   const frame=native?page.getByLabel('Code preview',{exact:true}):surface;
   await frame.waitFor();
   if(!native&&scenario.fallback!=='true')await page.locator('.kumo-shiki').waitFor();
   await page.mouse.move(1,1);await page.waitForTimeout(80);
   const box=await frame.boundingBox();assert(box,`${index} ${target} surface`);
   const text=native?await frame.locator('flt-semantics:not([role])').first().textContent():await frame.locator('pre code').textContent();
   assert.equal(text,scenario.code,`${index} ${target} original source`);
   const button=page.getByRole('button',{name:'Copy',exact:true});assert.equal(await button.count(),1);
   const numbers=native?await frame.locator('flt-semantics').filter({hasText:/^1\n2/}).count():await frame.locator('.kumo-line-numbers').count();
   if(!native)assert.equal(numbers,scenario.code.includes('\n')&&scenario.numbers!=='false'?1:0);
   const path=`${output}/${index}-${target}.png`;
   images.push(PNG.sync.read(await page.screenshot({path})));
   captures.push({target,url:url.href,box,source:text,path});
   // Exercise actual clipboard and feedback in each layout; language cases also
   // prove that copying does not include gutter numbers or highlighted markup.
   await page.mouse.move(box.x+Math.min(30,box.width/2),box.y+8);
   await button.click();await page.getByRole('button',{name:'Copied!',exact:true}).waitFor();
   const clipboard=await page.evaluate(()=>navigator.clipboard.readText());
   // Windows Chrome converts LF to CRLF at the OS clipboard boundary. Retain
   // the observed text and allow only that platform newline conversion.
   captures.at(-1).clipboard=clipboard;
   assert.equal(clipboard.replace(/\r\n/g,'\n'),scenario.code.replace(/\r\n/g,'\n'),`${index} ${target} clipboard`);
  }
  const [a,b]=images,diff=new PNG({width:a.width,height:a.height});
  const pixelDifferenceRatio=pixelmatch(a.data,b.data,diff.data,a.width,a.height,{threshold:.1})/(a.width*a.height);
  await writeFile(`${output}/${index}-diff.png`,PNG.sync.write(diff));
  const maximumGeometryDelta=Math.max(...Object.keys(captures[0].box).map(key=>Math.abs(captures[0].box[key]-captures[1].box[key])));
  assert(maximumGeometryDelta<=1,`${index} frame geometry: ${maximumGeometryDelta}`);
  results.push({index,...scenario,captures,maximumGeometryDelta,pixelDifferenceRatio,clipboardVerified:true});
 }
 await context.close();
} finally {
 await browser.close();
 await writeFile(`${output}/comparison.json`,JSON.stringify({success:results.length===cases.length&&errors.length===0,browser:version,
  referenceSha:'7e0ff40546f08405d05bc9754f0ff0fd009ece0a',referenceHighlighter:'Shiki 4.0.2, JavaScript engine, github-light / vesper',
  candidateArtifactSha256:createHash('sha256').update(await readFile('apps/demo/build/web/main.dart.wasm')).digest('hex'),
  pixelThreshold:.1,fullVisualParity:false,results,issues,errors},null,2)+'\n');
}
assert.equal(errors.length,0);
console.log(JSON.stringify({contexts:results.length,maximumGeometryDelta:Math.max(...results.map(r=>r.maximumGeometryDelta)),errors:errors.length,issues:issues.length}));
