import assert from 'node:assert/strict';
import {chromium} from 'playwright';
import {mkdir,writeFile} from 'node:fs/promises';
const output='output/playwright/dropdown-motion';await mkdir(output,{recursive:true});
const browser=await chromium.launch({channel:'chrome',headless:true}),checks=[],issues=[],errors=[],measurements=[];
const click=async(page,locator)=>{const b=await locator.boundingBox();assert(b);await page.mouse.click(b.x+b.width/2,b.y+b.height/2);};
try {
 for(const [width,mode] of [[1280,'light'],[1280,'dark'],[320,'light'],[320,'dark'],[390,'light']]){
  const context=await browser.newContext({viewport:{width,height:1000},colorScheme:mode});
  const page=await context.newPage(),cdp=await context.newCDPSession(page);
  cdp.on('Audits.issueAdded',({issue})=>issues.push({width,mode,...issue}));await cdp.send('Audits.enable');
  page.on('pageerror',e=>errors.push({width,mode,message:e.message}));
  const time=new Date('2026-10-16T00:00:00Z');await page.clock.install({time});
  await page.goto('http://127.0.0.1:8766/?component=dropdown&mode='+mode,{waitUntil:'networkidle'});
  const trigger=page.getByRole('button',{name:'操作メニュー',exact:true});await trigger.waitFor();
  await trigger.scrollIntoViewIfNeeded();await page.clock.pauseAt(new Date(+time+60000));
  const menu=page.getByRole('menu',{name:'操作メニュー',exact:true});
  await click(page,trigger);await page.clock.runFor(208);const settled=await menu.boundingBox();assert(settled);
  await click(page,trigger);await page.clock.runFor(208);assert.equal(await menu.count(),0);
  await click(page,trigger);await page.clock.runFor(16);assert.equal(await menu.count(),1);
  await page.clock.runFor(64);const opening=await menu.boundingBox();assert(opening.width<settled.width&&opening.width>settled.width*.95);
  await page.clock.runFor(96);
  const edit=page.getByRole('menuitem',{name:'編集 ⌘E',exact:true});const bounds=await edit.boundingBox();
  await click(page,edit);await page.clock.runFor(32);assert.equal(await menu.count(),0);
  await page.mouse.click(bounds.x+bounds.width/2,bounds.y+bounds.height/2);await page.clock.runFor(192);
  assert.equal(await page.getByText('最後の操作：編集（1回）',{exact:true}).count(),1);
  checks.push(`${width}px ${mode}: opening semantics exist from the first frame; timed pointer enter; exit immediately removes interaction/semantics and runs action once`);
  await trigger.focus();await page.clock.runFor(16);await page.keyboard.press('Enter');await page.clock.runFor(32);
  const keyboard=await menu.boundingBox();assert(keyboard);assert.ok(Math.abs(keyboard.width-settled.width)<.1);
  await page.keyboard.press('Escape');await page.clock.runFor(32);assert.equal(await menu.count(),0);
  await click(page,trigger);await page.clock.runFor(208);
  await click(page,page.getByRole('menuitem',{name:'移動',exact:true}));await page.clock.runFor(32);await page.clock.runFor(64);
  const menus=page.getByRole('menu');assert.equal(await menus.count(),2);
  await page.clock.runFor(96);assert.ok(Math.abs((await menus.nth(1).boundingBox()).width-settled.width)<.1);await page.keyboard.press('Escape');await page.clock.runFor(32);
  assert.equal(await menus.count(),1);await page.keyboard.press('Escape');await page.clock.runFor(32);assert.equal(await menu.count(),0);
  checks.push(`${width}px ${mode}: keyboard activation is immediate; nested pointer animation and one-level Escape preserve root`);
  measurements.push({width,mode,settled,opening,keyboard});await context.close();
 }
 assert.deepEqual(errors,[]);
 await writeFile(`${output}/behavior.json`,JSON.stringify({checkedAt:new Date().toISOString(),browser:browser.version(),checks,measurements,issues,errors,success:true},null,2)+'\n');
 console.log(JSON.stringify({checks:checks.length,issues:issues.length,errors:errors.length,success:true}));
}finally{await browser.close();}
