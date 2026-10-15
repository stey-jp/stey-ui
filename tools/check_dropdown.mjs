import assert from 'node:assert/strict';
import {mkdir,writeFile} from 'node:fs/promises';
import {chromium} from 'playwright';

const base=process.env.DEMO_URL ?? 'http://127.0.0.1:8766/';
const output='output/dropdown';
await mkdir(output,{recursive:true});
const browser=await chromium.launch({channel:'chrome',headless:true});
const checks=[],issues=[],errors=[];
try {
 for(const [width,mode] of [[1280,'light'],[1280,'dark'],[320,'light'],[320,'dark'],[390,'light']]) {
  console.log(JSON.stringify({checking:width,mode}));
  const context=await browser.newContext({viewport:{width,height:900},isMobile:width<500,hasTouch:width<500,colorScheme:mode});
  const page=await context.newPage(),cdp=await context.newCDPSession(page);
  cdp.on('Audits.issueAdded',event=>issues.push({width,mode,...event.issue}));
  page.on('pageerror',error=>errors.push({width,mode,message:error.message}));
  await cdp.send('Audits.enable');
  await page.goto(`${base}?component=dropdown&mode=${mode}`,{waitUntil:'networkidle'});
  const trigger=page.getByRole('button',{name:'操作メニュー',exact:true});
  await trigger.waitFor();
  await trigger.click();
  const menu=page.getByRole('menu',{name:'操作メニュー',exact:true});
  await menu.waitFor();
  const item=(name,role='menuitem')=>menu.getByRole(role,{name,exact:true});
  const waitChecked=(locator,value)=>locator.and(page.locator(`[aria-checked="${value}"]`)).waitFor();
  assert.equal(await menu.getByRole('group').count(),2);
  assert.equal(await item('利用不可').isDisabled(),true);
  await page.screenshot({path:`${output}/root-${width}-${mode}.png`});
  await item('通知を受け取る','menuitemcheckbox').click();
  await waitChecked(item('通知を受け取る','menuitemcheckbox'),false);
  assert.equal(await item('通知を受け取る','menuitemcheckbox').getAttribute('aria-checked'),'false');
  await item('ステージング','menuitemradio').click();
  await waitChecked(item('ステージング','menuitemradio'),true);
  assert.equal(await item('ステージング','menuitemradio').getAttribute('aria-checked'),'true');
  assert.equal(await item('本番','menuitemradio').getAttribute('aria-checked'),'false');
  checks.push(`${width}px ${mode}: trigger, disabled, checkbox and exclusive radio states`);
  await item('移動').click();
  const personal=page.getByRole('menuitem',{name:'個人アカウント',exact:true});
  await personal.waitFor();
  assert.equal(await page.getByRole('menu').count(),2);
  await page.screenshot({path:`${output}/submenu-${width}-${mode}.png`});
  for(const popup of await page.getByRole('menu').all()) {
   const box=await popup.boundingBox();
   assert(box.x>=0&&box.x+box.width<=width&&box.y>=0&&box.y+box.height<=900);
  }
  await page.getByRole('menuitem',{name:'詳細',exact:true}).click();
  await page.getByRole('menuitem',{name:'新しいフォルダー',exact:true}).click();
  await menu.waitFor({state:'hidden'});
  await page.getByText('最後の操作：フォルダーを作成（1回）',{exact:true}).waitFor();
  checks.push(`${width}px ${mode}: three-level nested action once, all menus dismissed, popup bounds`);
  await trigger.click();
  await menu.waitFor();
  assert.equal(await item('通知を受け取る','menuitemcheckbox').getAttribute('aria-checked'),'false');
  assert.equal(await item('ステージング','menuitemradio').getAttribute('aria-checked'),'true');
  await page.keyboard.press('Escape');
  await menu.waitFor({state:'hidden'});
  if(width===1280) {
   await trigger.focus();
   await page.keyboard.press('ArrowDown');
   await menu.waitFor();
   await page.keyboard.press('End');
   await page.keyboard.press('Enter');
   await page.getByText('最後の操作：削除（2回）',{exact:true}).waitFor();
   checks.push(`${width}px ${mode}: state retained across reopening, Escape, ArrowDown, End and Enter`);
  }
  await context.close();
 }
 assert.deepEqual(errors,[]);
 const report={checkedAt:new Date().toISOString(),browser:browser.version(),checks,issues,errors,success:true};
 await writeFile(`${output}/behavior.json`,JSON.stringify(report,null,2)+'\n');
 console.log(JSON.stringify({success:true,checks:checks.length,issues:issues.length,errors:errors.length}));
} finally {await browser.close();}
