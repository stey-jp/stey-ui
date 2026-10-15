import assert from 'node:assert/strict';
import {chromium} from 'playwright';
import {mkdir,writeFile} from 'node:fs/promises';
const output='output/flow-wrap';await mkdir(output,{recursive:true});
const browser=await chromium.launch({channel:'chrome',headless:true}),checks=[],issues=[],errors=[],layouts=[];
try{
 for(const [width,mode]of [[1280,'light'],[1280,'dark'],[320,'light'],[320,'dark'],[390,'light']]){
  const context=await browser.newContext({viewport:{width,height:1000},isMobile:width<500,hasTouch:width<500,colorScheme:mode});
  const page=await context.newPage(),cdp=await context.newCDPSession(page);
  cdp.on('Audits.issueAdded',({issue})=>issues.push({width,mode,...issue}));await cdp.send('Audits.enable');
  page.on('pageerror',e=>errors.push({width,mode,message:e.message}));
  await page.goto(`http://127.0.0.1:8766/?component=flow&mode=${mode}`,{waitUntil:'networkidle'});
  const group=page.getByRole('group',{name:'折り返しプレビュー',exact:true});await group.waitFor();
  await page.mouse.move(width-8,500);await page.mouse.wheel(0,1100);await page.waitForTimeout(150);
  const item=group.getByRole('listitem').filter({has:page.getByText('保存する前に、入力内容とアクセス権限を確認してください。',{exact:true})});
  await item.scrollIntoViewIfNeeded();const narrow=await item.boundingBox();
  await page.getByRole('button',{name:'最大幅：120px',exact:true}).click();
  await page.getByRole('button',{name:'最大幅：240px',exact:true}).waitFor();await page.waitForTimeout(100);
  const wide=await item.boundingBox();assert.ok(wide.width>narrow.width);assert.ok(wide.height<narrow.height);
  await page.getByRole('button',{name:'説明を短くする',exact:true}).click();
  const short=group.getByRole('listitem').filter({has:page.getByText('入力を確認',{exact:true})});await short.waitFor();
  assert.ok((await short.boundingBox()).width<wide.width);
  checks.push(`${width}px ${mode}: wider cap reduces wrapped height and short content keeps natural width`);
  await page.getByRole('button',{name:'説明を長くする',exact:true}).click();await item.waitFor();
  await page.getByRole('button',{name:'最大幅：240px',exact:true}).click();
  await page.getByRole('button',{name:'最大幅：120px',exact:true}).waitFor();await page.waitForTimeout(100);
  const restored=await item.boundingBox();assert.ok(Math.abs(restored.width-narrow.width)<.1&&Math.abs(restored.height-narrow.height)<.1);
  await page.getByRole('button',{name:'配置方向：縦',exact:true}).click();
  await page.getByRole('button',{name:'配置方向：横',exact:true}).waitFor();
  await page.getByRole('button',{name:'配置方向：横',exact:true}).click();
  await page.getByRole('button',{name:'配置方向：縦',exact:true}).waitFor();
  assert.equal(await group.getByRole('listitem').count(),4);
  await page.screenshot({path:`${output}/wrapped-${width}-${mode}.png`});layouts.push({width,mode,narrow,wide,restored});
  checks.push(`${width}px ${mode}: cap/content shrink and orientation changes retain all four nodes`);
  await context.close();
 }
 assert.deepEqual(errors,[]);
 await writeFile(`${output}/behavior.json`,JSON.stringify({checkedAt:new Date().toISOString(),browser:browser.version(),checks,layouts,issues,errors,success:true},null,2)+'\n');
 console.log(JSON.stringify({checks:checks.length,issues:issues.length,errors:errors.length,success:true}));
}finally{await browser.close();}
