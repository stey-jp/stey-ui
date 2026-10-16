import assert from 'node:assert/strict';
import {chromium} from 'playwright';
import {mkdir,writeFile} from 'node:fs/promises';
const output='output/playwright/dropdown-rtl';await mkdir(output,{recursive:true});
const browser=await chromium.launch({channel:'chrome',headless:true}),checks=[],issues=[],errors=[];
try{
 for(const [width,mode] of [[1280,'light'],[1280,'dark'],[320,'light'],[320,'dark'],[390,'light']]){
  const context=await browser.newContext({viewport:{width,height:1000},colorScheme:mode,isMobile:width<500,hasTouch:width<500});
  const page=await context.newPage(),cdp=await context.newCDPSession(page);
  cdp.on('Audits.issueAdded',({issue})=>issues.push({width,mode,...issue}));await cdp.send('Audits.enable');
  page.on('pageerror',e=>errors.push({width,mode,message:e.message}));
  await page.goto(`http://127.0.0.1:8766/?component=dropdown&mode=${mode}`,{waitUntil:'networkidle'});
  const switcher=page.getByRole('button',{name:'表示方向：左から右',exact:true});await switcher.click();
  await page.getByRole('button',{name:'表示方向：右から左',exact:true}).waitFor();
  const trigger=page.getByRole('button',{name:'操作メニュー',exact:true});await trigger.click();
  const menu=page.getByRole('menu',{name:'操作メニュー',exact:true});await menu.waitFor();await page.waitForTimeout(180);
  assert.equal(await menu.getByRole('group').count(),2);
  const checkbox=menu.getByRole('menuitemcheckbox',{name:'通知を受け取る',exact:true});await checkbox.click();
  await checkbox.and(page.locator('[aria-checked="false"]')).waitFor();
  const radio=menu.getByRole('menuitemradio',{name:'ステージング',exact:true});await radio.click();await radio.and(page.locator('[aria-checked="true"]')).waitFor();
  await page.screenshot({path:`${output}/japanese-rtl-${width}-${mode}.png`});
  checks.push(`${width}px ${mode}: Japanese RTL switch preserves checkbox/radio roles and controlled state`);
  await menu.getByRole('menuitem',{name:'移動',exact:true}).focus();await page.keyboard.press('ArrowLeft');
  await page.getByRole('menuitem',{name:'個人アカウント',exact:true}).and(page.locator(':focus')).waitFor();assert.equal(await page.getByRole('menu').count(),2);
  await page.keyboard.press('ArrowRight');await page.getByRole('menuitem',{name:'個人アカウント',exact:true}).waitFor({state:'hidden'});
  assert.equal(await page.getByRole('menu').count(),1);await page.keyboard.press('Escape');await menu.waitFor({state:'hidden'});
  await page.getByRole('button',{name:'表示方向：右から左',exact:true}).click();await trigger.click();await menu.waitFor();
  assert.equal(await menu.getByRole('menuitemcheckbox',{name:'通知を受け取る',exact:true}).getAttribute('aria-checked'),'false');
  assert.equal(await menu.getByRole('menuitemradio',{name:'ステージング',exact:true}).getAttribute('aria-checked'),'true');
  await page.keyboard.press('Escape');await menu.waitFor({state:'hidden'});
  checks.push(`${width}px ${mode}: RTL ArrowLeft opens / ArrowRight returns; LTR switch retains selection and Escape`);
  await context.close();
 }
 assert.deepEqual(errors,[]);
 await writeFile(`${output}/behavior.json`,JSON.stringify({checkedAt:new Date().toISOString(),browser:browser.version(),checks,issues,errors,success:true},null,2)+'\n');
 console.log(JSON.stringify({checks:checks.length,issues:issues.length,errors:errors.length,success:true}));
}finally{await browser.close();}
