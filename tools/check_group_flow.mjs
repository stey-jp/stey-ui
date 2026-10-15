import assert from 'node:assert/strict';
import {chromium} from 'playwright';
import {mkdir,writeFile} from 'node:fs/promises';
const base=process.env.DEMO_URL??'http://127.0.0.1:8766/';
const output='output/group-flow';await mkdir(output,{recursive:true});
const browser=await chromium.launch({channel:'chrome',headless:true}),checks=[],issues=[],errors=[],groups=[];
try{
 for(const [width,mode] of [[1280,'light'],[1280,'dark'],[320,'light'],[320,'dark'],[390,'light']]){
  const context=await browser.newContext({viewport:{width,height:900},isMobile:width<500,hasTouch:width<500,colorScheme:mode});
  const page=await context.newPage(),cdp=await context.newCDPSession(page);await cdp.send('Audits.enable');
  cdp.on('Audits.issueAdded',({issue})=>issues.push({width,mode,...issue}));page.on('pageerror',e=>errors.push({width,mode,message:e.message}));
  await page.goto(`${base}?component=button-group&mode=${mode}`,{waitUntil:'networkidle'});
  const group=page.locator('[aria-label="デプロイ操作"]');await group.waitFor();
  groups.push({width,mode,role:await group.getAttribute('role')});
  await page.getByRole('button',{name:'デプロイ',exact:true}).click();await page.locator('flt-semantics-host').getByText('本番へデプロイしました',{exact:true}).waitFor();
  await page.getByRole('button',{name:'デプロイ先を選択',exact:true}).click();
  await page.getByRole('menuitem',{name:'ステージングへデプロイ',exact:true}).click();
  await page.locator('flt-semantics-host').getByText('ステージングへデプロイしました',{exact:true}).waitFor();
  await page.getByRole('button',{name:'右端',exact:true}).click();await page.locator('flt-semantics-host').getByText('右端を選択しました',{exact:true}).waitFor();
  await page.screenshot({path:`${output}/group-${width}-${mode}.png`});
  checks.push(`${width}px ${mode}: named related controls, split-menu selection and RTL actions`);
  if(width===1280){const save=page.getByRole('button',{name:'保存',exact:true});await save.focus();await page.keyboard.press('Enter');await page.locator('flt-semantics-host').getByText('変更を保存しました',{exact:true}).waitFor();checks.push(`${mode}: keyboard action in joined controls`);}
  await page.goto(`${base}?component=flow&mode=${mode}`,{waitUntil:'networkidle'});
  const flow=page.getByRole('list',{name:'3個のノードと2本の接続を持つフロー図',exact:true});await flow.waitFor();assert.equal(await flow.getByRole('listitem').count(),3);
  await page.getByRole('button',{name:'外側余白：-4px',exact:true}).click();
  await page.getByRole('button',{name:'外側余白：20px',exact:true}).waitFor();
  await page.getByRole('button',{name:'内容を展開',exact:true}).click();await page.getByRole('button',{name:'内容を折りたたむ',exact:true}).waitFor();
  await page.getByRole('button',{name:'接続を無効にする',exact:true}).click();await page.getByRole('button',{name:'接続を有効にする',exact:true}).waitFor();
  await page.screenshot({path:`${output}/flow-${width}-${mode}.png`});
  await page.getByRole('button',{name:'内容を折りたたむ',exact:true}).click();await page.getByRole('button',{name:'内容を展開',exact:true}).waitFor();
  checks.push(`${width}px ${mode}: margined anchors, expand/collapse, disabled connection`);
  await context.close();
 }
 assert.deepEqual(errors,[]);
 await writeFile(`${output}/behavior.json`,JSON.stringify({checkedAt:new Date().toISOString(),browser:browser.version(),checks,groups,issues,errors,success:true},null,2)+'\n');
 console.log(JSON.stringify({checks:checks.length,groups,issues:issues.length,errors:errors.length,success:true}));
}finally{await browser.close();}
