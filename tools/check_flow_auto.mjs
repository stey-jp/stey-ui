import assert from 'node:assert/strict';
import {chromium} from 'playwright';
import {mkdir,writeFile} from 'node:fs/promises';
const output='output/flow-auto';await mkdir(output,{recursive:true});
const browser=await chromium.launch({channel:'chrome',headless:true}),checks=[],issues=[],errors=[],layouts=[];
try{
 for(const [width,mode]of [[1280,'light'],[1280,'dark'],[320,'light'],[320,'dark'],[390,'light']]){
  const context=await browser.newContext({viewport:{width,height:1000},isMobile:width<500,hasTouch:width<500,colorScheme:mode});
  const page=await context.newPage(),cdp=await context.newCDPSession(page);
  cdp.on('Audits.issueAdded',({issue})=>issues.push({width,mode,...issue}));await cdp.send('Audits.enable');
  page.on('pageerror',e=>errors.push({width,mode,message:e.message}));
  await page.goto(`http://127.0.0.1:8766/?component=flow&mode=${mode}`,{waitUntil:'networkidle'});
  await page.mouse.move(width-8,500);await page.mouse.wheel(0,2000);await page.waitForTimeout(200);
  const group=page.getByRole('group',{name:'自動幅プレビュー',exact:true});await group.waitFor();
  const item=group.getByRole('listitem').filter({has:page.getByText('保存する前に、入力内容とアクセス権限を確認してください。',{exact:true})});
  await item.scrollIntoViewIfNeeded();const initial=await item.boundingBox();
  await page.getByRole('button',{name:'親幅：狭い',exact:true}).click();await page.getByRole('button',{name:'親幅：広い',exact:true}).waitFor();await page.waitForTimeout(100);
  const retained=await item.boundingBox();assert.ok(Math.abs(retained.width-initial.width)<.1&&Math.abs(retained.height-initial.height)<.1);
  await page.getByRole('button',{name:'図を作り直す',exact:true}).click();await page.waitForTimeout(100);
  const resetWide=await item.boundingBox();assert.ok(resetWide.width>initial.width);assert.ok(resetWide.height<initial.height);
  await page.getByRole('button',{name:'親幅：広い',exact:true}).click();await page.getByRole('button',{name:'親幅：狭い',exact:true}).waitFor();await page.waitForTimeout(100);
  const clipped=await item.boundingBox();assert.ok(Math.abs(clipped.height-resetWide.height)<.1);
  await page.getByRole('button',{name:'図を作り直す',exact:true}).click();await page.waitForTimeout(100);
  const resetNarrow=await item.boundingBox();assert.ok(Math.abs(resetNarrow.width-initial.width)<.1&&Math.abs(resetNarrow.height-initial.height)<.1);
  checks.push(`${width}px ${mode}: initial width survives both host resize directions; remount measures current width`);
  await page.getByRole('button',{name:'自動測定の説明を短くする',exact:true}).click();
  const short=group.getByRole('listitem').filter({has:page.getByText('処理',{exact:true})});await short.waitFor();
  assert.ok((await short.boundingBox()).height<initial.height);
  await page.getByRole('button',{name:'自動測定の説明を長くする',exact:true}).click();await item.waitFor();
  await page.getByRole('button',{name:'図を作り直す',exact:true}).click();await page.waitForTimeout(100);
  assert.equal(await group.getByRole('listitem').count(),4);
  await page.screenshot({path:`${output}/auto-${width}-${mode}.png`});layouts.push({width,mode,initial,retained,resetWide,clipped,resetNarrow});
  checks.push(`${width}px ${mode}: content changes and reset retain all four nodes and restore initial measurement`);
  await context.close();
 }
 assert.deepEqual(errors,[]);
 await writeFile(`${output}/behavior.json`,JSON.stringify({checkedAt:new Date().toISOString(),browser:browser.version(),checks,layouts,issues,errors,success:true},null,2)+'\n');
 console.log(JSON.stringify({checks:checks.length,issues:issues.length,errors:errors.length,success:true}));
}finally{await browser.close();}
