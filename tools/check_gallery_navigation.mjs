import assert from 'node:assert/strict';
import {chromium} from 'playwright';
import {mkdir, writeFile} from 'node:fs/promises';

const base=process.env.DEMO_URL ?? 'http://127.0.0.1:8766/';
const browser=await chromium.launch({channel:'chrome',headless:true});
try {
  const page=await browser.newPage({viewport:{width:1280,height:900}});
  await page.goto(base+'?component=button&mode=light',{waitUntil:'networkidle'});
  await page.getByRole('heading',{name:'Button',exact:true}).waitFor();
  await page.getByRole('button',{name:'Badge',exact:true}).click();
  await page.waitForURL(url=>url.searchParams.get('component')==='badge');
  await page.getByRole('heading',{name:'Badge',exact:true}).waitFor();
  await page.getByRole('button',{name:'Switch to dark mode',exact:true}).click();
  await page.waitForURL(url=>url.searchParams.get('mode')==='dark');
  await page.getByRole('button',{name:'Switch to light mode',exact:true}).waitFor();
  await page.goBack();
  await page.getByRole('button',{name:'Switch to dark mode',exact:true}).waitFor();
  assert.equal(new URL(page.url()).searchParams.get('component'),'badge');
  await page.goBack();
  await page.getByRole('heading',{name:'Button',exact:true}).waitFor();
  await page.goForward();
  await page.getByRole('heading',{name:'Badge',exact:true}).waitFor();
  const missingIds=await page.locator('input[data-semantics-role="text-field"],textarea[data-semantics-role="text-field"]').evaluateAll(fields=>fields.filter(field=>!field.id).length);
  assert.equal(missingIds,0);
  await mkdir('output/web-audit',{recursive:true});
  const report={success:true,browser:'Real Google Chrome',url:base,checks:['component URL','theme URL','back','forward','semantic input identities']};
  await writeFile('output/web-audit/navigation.json',JSON.stringify(report,null,2)+'\n');
  console.log(JSON.stringify(report));
} finally { await browser.close(); }
