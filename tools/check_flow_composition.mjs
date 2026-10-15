import assert from 'node:assert/strict';
import {chromium} from 'playwright';
import {mkdir,writeFile} from 'node:fs/promises';
const base=process.env.DEMO_URL??'http://127.0.0.1:8766/';
const output='output/flow-composition';await mkdir(output,{recursive:true});
const browser=await chromium.launch({channel:'chrome',headless:true}),checks=[],issues=[],errors=[],layouts=[];
try{
 for(const [width,mode]of [[1280,'light'],[1280,'dark'],[320,'light'],[320,'dark'],[390,'light']]){
  const context=await browser.newContext({viewport:{width,height:900},isMobile:width<500,hasTouch:width<500,colorScheme:mode});
  const page=await context.newPage(),cdp=await context.newCDPSession(page);await cdp.send('Audits.enable');
  cdp.on('Audits.issueAdded',({issue})=>issues.push({width,mode,...issue}));page.on('pageerror',e=>errors.push({width,mode,message:e.message}));
  await page.goto(`${base}?component=flow&mode=${mode}`,{waitUntil:'networkidle'});
  const diagram=page.getByRole('list',{name:'5個のノードと5本の接続を持つフロー図',exact:true});await diagram.waitFor();
  assert.equal(await diagram.getByRole('listitem').count(),5);
  const item=diagram.getByRole('listitem').filter({has:page.getByText('入力を確認',{exact:true})});
  const before=await item.boundingBox();
  await page.getByRole('button',{name:'処理内容を長くする',exact:true}).click();
  const long=diagram.getByRole('listitem').filter({has:page.getByText('入力とアクセス権限を確認する',{exact:true})});await long.waitFor();
  const after=await long.boundingBox();assert.ok(after.width>before.width);
  await page.getByRole('button',{name:'方向：横',exact:true}).click();await page.getByRole('button',{name:'方向：縦',exact:true}).waitFor();
  await page.getByRole('button',{name:'配置：先頭',exact:true}).click();await page.getByRole('button',{name:'配置：中央',exact:true}).waitFor();
  await page.getByRole('button',{name:'分岐：先頭揃え',exact:true}).click();await page.getByRole('button',{name:'分岐：末尾揃え',exact:true}).waitFor();
  await page.screenshot({path:`${output}/vertical-${width}-${mode}.png`});
  layouts.push({width,mode,before,after});checks.push(`${width}px ${mode}: five auto-sized nodes, content resize, vertical, center and end alignment`);
  await page.getByRole('button',{name:'処理内容を短くする',exact:true}).click();await item.waitFor();
  await page.getByRole('button',{name:'方向：縦',exact:true}).click();await page.getByRole('button',{name:'方向：横',exact:true}).waitFor();
  assert.equal(await diagram.getByRole('listitem').count(),5);
  checks.push(`${width}px ${mode}: content shrink and return to horizontal retain all five nodes`);
  await context.close();
 }
 assert.deepEqual(errors,[]);
 await writeFile(`${output}/behavior.json`,JSON.stringify({checkedAt:new Date().toISOString(),browser:browser.version(),checks,layouts,issues,errors,success:true},null,2)+'\n');
 console.log(JSON.stringify({checks:checks.length,issues:issues.length,errors:errors.length,success:true}));
}finally{await browser.close();}
