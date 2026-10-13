import { readFile, mkdir, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { PNG } from 'pngjs';
import pixelmatch from 'pixelmatch';
import {chromium} from 'playwright';
import {spawn} from 'node:child_process';
import {createHash} from 'node:crypto';

// Official fixtures must have a pinned upstream SHA and matching dimensions.
// Missing baselines are a failed gate, never a successful "no differences" result.
const required=process.argv.includes('--require-upstream');
const output=resolve('output/visual');await mkdir(output,{recursive:true});
const manifest=JSON.parse(await readFile('upstream/visual-fixtures.json','utf8'));
const inventory=JSON.parse(await readFile('upstream/inventory.json','utf8'));
if(!/^[0-9a-f]{40}$/.test(manifest.upstream_sha))throw Error('VISUAL_UPSTREAM_SHA_INVALID');
const ids=new Set(),coverage=new Set();
for(const fixture of manifest.fixtures){
  if(ids.has(fixture.id))throw Error('VISUAL_FIXTURE_ID_DUPLICATE');
  if(!inventory.components.some(item=>item.id===fixture.component))throw Error('VISUAL_COMPONENT_UNKNOWN');
  if(!['light','dark'].includes(fixture.mode))throw Error('VISUAL_MODE_INVALID');
  if(!Number.isInteger(fixture.width)||fixture.width<1||!Number.isInteger(fixture.height)||fixture.height<1)throw Error('VISUAL_VIEWPORT_INVALID');
  ids.add(fixture.id);coverage.add(`${fixture.component}-${fixture.mode}`);
}
const missingCoverage=inventory.components.flatMap(item=>['light','dark'].map(mode=>`${item.id}-${mode}`)).filter(id=>!coverage.has(id));
const rows=[];
let server,browser,port;
try {
if(manifest.fixtures.length){
  server=spawn('python',['tools/serve_demo.py','--port','0','--cross-origin-isolated'],{stdio:['ignore','pipe','ignore']});
  port=await new Promise((resolve,reject)=>{
    let output='';
    const timeout=setTimeout(()=>reject(Error('FRESH_VISUAL_SERVER_TIMEOUT')),15000);
    const fail=()=>{clearTimeout(timeout);reject(Error('FRESH_VISUAL_SERVER_FAILED'));};
    server.on('error',fail);server.on('exit',fail);
    server.stdout.on('data',chunk=>{
      output+=chunk.toString();
      if(output.includes('\n')){
        clearTimeout(timeout);
        try {resolve(JSON.parse(output.split('\n')[0]).port);} catch {fail();}
      }
    });
  });
  browser=await chromium.launch({channel:'chrome',headless:true});
}
for(const fixture of manifest.fixtures){
  if(!/^[a-z0-9-]+$/.test(fixture.id) || !/^[a-z0-9-]+$/.test(fixture.component))throw Error('VISUAL_FIXTURE_ID_INVALID');
  const referenceBytes=await readFile(fixture.reference);
  if(createHash('sha256').update(referenceBytes).digest('hex')!==fixture.reference_sha256)throw Error('VISUAL_REFERENCE_HASH_MISMATCH');
  const reference=PNG.sync.read(referenceBytes);
  const page=await browser.newPage({viewport:{width:fixture.width,height:fixture.height},colorScheme:fixture.mode??'light',deviceScaleFactor:1});
  const url=new URL(`http://127.0.0.1:${port}/`);
  url.searchParams.set('fixture','1');url.searchParams.set('component',fixture.component);url.searchParams.set('mode',fixture.mode??'light');
  const errors=[];page.on('pageerror',error=>errors.push(error.message));
  await page.goto(url.href,{waitUntil:'networkidle'});
  await page.locator('flt-semantics[role]').first().waitFor();
  if(errors.length)throw Error('VISUAL_CANDIDATE_RUNTIME_ERROR');
  const candidate=PNG.sync.read(await page.screenshot({path:resolve(output,fixture.id+'-candidate.png')}));
  await page.close();
  if(reference.width!==candidate.width||reference.height!==candidate.height)throw Error('VISUAL_DIMENSIONS_MISMATCH');
  const diff=new PNG({width:reference.width,height:reference.height});
  const changed=pixelmatch(reference.data,candidate.data,diff.data,reference.width,reference.height,{threshold:fixture.threshold??0.1,includeAA:true});
  const ratio=changed/(reference.width*reference.height);
  rows.push({id:fixture.id,changedPixels:changed,ratio,success:ratio<=(fixture.maxChangedRatio??0)});
  await writeFile(resolve(output,fixture.id+'-diff.png'),PNG.sync.write(diff));
}
} finally {
  if(browser)await browser.close();
  if(server)server.kill();
}
const success=missingCoverage.length===0&&rows.length>0&&rows.every(row=>row.success);
const report={upstream_sha:manifest.upstream_sha,success,fixtures:rows,
  missing_coverage:missingCoverage,
  missing:manifest.fixtures.length===0?'Pinned official reference fixtures have not been approved.':null};
await writeFile(resolve(output,'report.json'),JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify(report));
if(required&&!success)process.exitCode=1;
