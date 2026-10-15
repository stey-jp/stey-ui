import assert from 'node:assert/strict';
import {chromium} from 'playwright';
import {mkdir,writeFile} from 'node:fs/promises';
const output='output/flow-canvas';await mkdir(output,{recursive:true});
const browser=await chromium.launch({channel:'chrome',headless:true}),checks=[],issues=[],errors=[];
try{
 for(const [width,mode]of [[1280,'light'],[1280,'dark'],[320,'light'],[320,'dark'],[390,'light']]){
  const context=await browser.newContext({viewport:{width,height:1000},isMobile:width<500,hasTouch:width<500,colorScheme:mode});
  const page=await context.newPage(),cdp=await context.newCDPSession(page);
  cdp.on('Audits.issueAdded',({issue})=>issues.push({width,mode,...issue}));await cdp.send('Audits.enable');
  page.on('pageerror',e=>errors.push({width,mode,message:e.message}));
  await page.goto(`http://127.0.0.1:8766/?component=flow&mode=${mode}`,{waitUntil:'networkidle'});
  const group=page.getByRole('group',{name:'フローの移動プレビュー',exact:true});await group.scrollIntoViewIfNeeded();
  await page.mouse.move(width-8,500);await page.mouse.wheel(0,600);await page.waitForTimeout(150);
  await page.locator('flt-semantics').getByText('はみ出し：横あり・縦あり／確認 0回',{exact:true}).waitFor();
  const node=group.getByRole('button',{name:'受信を確認',exact:true});await node.click();
  await page.locator('flt-semantics').getByText('はみ出し：横あり・縦あり／確認 1回',{exact:true}).waitFor();
  const box=await group.boundingBox(),before=await node.boundingBox();
  await page.mouse.move(box.x+box.width-20,box.y+8);await page.mouse.down();
  await page.mouse.move(box.x+box.width-30,box.y+8);await page.mouse.move(box.x+box.width-40,box.y+8);await page.mouse.up();
  await page.waitForTimeout(100);const moved=await node.boundingBox();assert.ok(moved.x<before.x-5,JSON.stringify({width,mode,before,moved,box}));
  await page.mouse.wheel(-10000,-10000);await page.waitForTimeout(100);
  const reset=await node.boundingBox();assert.ok(Math.abs(reset.x-before.x)<.1);
  await page.mouse.move(reset.x+reset.width/2,reset.y+reset.height/2);await page.mouse.down();
  await page.mouse.move(reset.x+reset.width/2+120,reset.y+reset.height/2+10,{steps:3});await page.mouse.up();
  await page.waitForTimeout(100);assert.ok(Math.abs((await node.boundingBox()).x-reset.x)<.1);
  checks.push(`${width}px ${mode}: background drag pans, wheel returns to start, node drag keeps canvas still and click works`);
  await page.mouse.move(box.x+box.width-20,box.y+8);await page.mouse.wheel(10000,10000);await page.waitForTimeout(100);
  await page.getByRole('button',{name:'分岐を減らす',exact:true}).click();
  await page.locator('flt-semantics').getByText('はみ出し：横なし・縦なし／確認 1回',{exact:true}).waitFor();
  await node.click();await page.locator('flt-semantics').getByText('はみ出し：横なし・縦なし／確認 2回',{exact:true}).waitFor();
  await page.screenshot({path:`${output}/compact-${width}-${mode}.png`});
  await page.getByRole('button',{name:'分岐を増やす',exact:true}).click();
  await page.locator('flt-semantics').getByText('はみ出し：横あり・縦あり／確認 2回',{exact:true}).waitFor();
  assert.equal(await group.getByRole('list').count(),1);
  checks.push(`${width}px ${mode}: content shrink clamps pan, overflow callback changes, button state and list survive expansion`);
  await context.close();
 }
 assert.deepEqual(errors,[]);
 await writeFile(`${output}/behavior.json`,JSON.stringify({checkedAt:new Date().toISOString(),browser:browser.version(),checks,issues,errors,success:true},null,2)+'\n');
 console.log(JSON.stringify({checks:checks.length,issues:issues.length,errors:errors.length,success:true}));
}finally{await browser.close();}
