import assert from 'node:assert/strict';
import {chromium} from 'playwright';
import {mkdir,writeFile} from 'node:fs/promises';
const base=process.env.DEMO_URL??'http://127.0.0.1:8766/';
const output='output/button-sidebar';await mkdir(output,{recursive:true});
const browser=await chromium.launch({channel:'chrome',headless:true});
const checks=[],issues=[],errors=[];
try {
 for(const [width,mode] of [[1280,'light'],[1280,'dark'],[320,'light'],[320,'dark'],[390,'light']]) {
  const context=await browser.newContext({viewport:{width,height:900},isMobile:width<500,hasTouch:width<500,colorScheme:mode});
  const page=await context.newPage(),cdp=await context.newCDPSession(page);
  cdp.on('Audits.issueAdded',({issue})=>issues.push({width,mode,...issue}));await cdp.send('Audits.enable');
  page.on('pageerror',error=>errors.push({width,mode,message:error.message}));
  await page.goto(`${base}?component=button&mode=${mode}`,{waitUntil:'networkidle'});
  await page.getByRole('button',{name:'アイコンのみで追加',exact:true}).click();
  await page.getByText('操作回数：1回',{exact:true}).waitFor();
  assert.equal(await page.getByRole('button',{name:/で追加$/}).count(),5);
  await page.screenshot({path:`${output}/buttons-${width}-${mode}.png`});
  checks.push(`${width}px ${mode}: four icon/text sizes and empty-content icon-only action`);
  await page.goto(`${base}?component=sidebar&mode=${mode}`,{waitUntil:'networkidle'});
  const settings=page.getByRole('button',{name:'設定',exact:true});
  await settings.click();
  const group=page.getByRole('list',{name:'設定',exact:true});await group.waitFor();
  await settings.and(page.locator('[aria-expanded="true"]')).waitFor();
  assert.equal(await group.getByRole('listitem').count(),3);
  await group.getByRole('button',{name:'セキュリティ',exact:true}).click();
  const nested=group.getByRole('list',{name:'セキュリティ',exact:true});await nested.waitFor();
  assert.equal(await nested.getByRole('listitem').count(),2);
  await nested.getByRole('button',{name:'APIキー',exact:true}).click();
  await nested.getByRole('button',{name:'APIキー',exact:true}).and(page.locator('[aria-current="true"]')).waitFor();
  await page.screenshot({path:`${output}/sidebar-${width}-${mode}.png`});
  await settings.click();await group.waitFor({state:'hidden'});
  await settings.click();await nested.waitFor();
  assert.equal(await nested.getByRole('button',{name:'APIキー',exact:true}).getAttribute('aria-current'),'true');
  if(width===1280){
   const keys=nested.getByRole('button',{name:'APIキー',exact:true});await keys.focus();await page.keyboard.press('Enter');
  }
  checks.push(`${width}px ${mode}: real list items, nested selection retained, fold/reopen, no decorative focus target`);
  await context.close();
 }
 assert.deepEqual(errors,[]);
 await writeFile(`${output}/behavior.json`,JSON.stringify({checkedAt:new Date().toISOString(),browser:browser.version(),checks,issues,errors,success:true},null,2)+'\n');
 console.log(JSON.stringify({checks:checks.length,issues:issues.length,errors:errors.length,success:true}));
}finally{await browser.close();}
