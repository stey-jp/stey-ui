import { chromium } from 'playwright';
import { readFile, mkdir, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';

const base = process.env.DEMO_URL ?? 'http://127.0.0.1:8765/';
const inventory = JSON.parse(await readFile('upstream/inventory.json', 'utf8'));
const output = resolve('output/web-audit');
await mkdir(output, {recursive: true});
const browser = await chromium.launch({channel:'chrome',headless:true});
const results=[];
try {
  for (const mode of ['light','dark']) {
    const context=await browser.newContext({viewport:{width:1280,height:900},colorScheme:mode});
    for (const item of inventory.components) {
      const page=await context.newPage();
      const cdp=await context.newCDPSession(page);
      const issues=[],errors=[];
      cdp.on('Audits.issueAdded',event=>issues.push(event.issue));
      page.on('pageerror',error=>errors.push(error.message));
      await cdp.send('Audits.enable');
      const url=new URL(base);url.searchParams.set('component',item.id);url.searchParams.set('mode',mode);
      await page.goto(url.href,{waitUntil:'networkidle'});
      await page.getByText('Interactive preview',{exact:true}).waitFor({timeout:30000});
      results.push({url:url.href,component:item.id,mode,issues:[...issues],errors:[...errors]});
      if(['button','input','chart'].includes(item.id))await page.screenshot({path:resolve(output,`${item.id}-${mode}.png`)});
      await page.close();
    }
    await context.close();
  }
  const mobile=await browser.newContext({viewport:{width:390,height:844},isMobile:true,deviceScaleFactor:1});
  const page=await mobile.newPage();await page.goto(base,{waitUntil:'networkidle'});
  await page.getByText('Interactive preview',{exact:true}).waitFor({timeout:30000});
  await page.screenshot({path:resolve(output,'mobile.png')});
  await mobile.close();
} finally { await browser.close(); }
const report={auditedAt:new Date().toISOString(),browser:'Real Google Chrome',results,
  issueCount:results.reduce((sum,r)=>sum+r.issues.length,0),errorCount:results.reduce((sum,r)=>sum+r.errors.length,0)};
await writeFile(resolve(output,'report.json'),JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify({urls:results.length,issues:report.issueCount,errors:report.errorCount}));
if(report.issueCount||report.errorCount)process.exitCode=1;
