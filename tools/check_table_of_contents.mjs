import assert from 'node:assert/strict';
import {chromium} from 'playwright';
import {mkdir, writeFile} from 'node:fs/promises';

const base=process.env.DEMO_URL ?? 'http://127.0.0.1:8766/';
const output='output/table-of-contents';
await mkdir(output,{recursive:true});
const browser=await chromium.launch({channel:'chrome',headless:true});
const checks=[],issues=[],errors=[];
async function audit(page) {
  const cdp=await page.context().newCDPSession(page);
  cdp.on('Audits.issueAdded',event=>issues.push({url:page.url(),...event.issue}));
  page.on('pageerror',error=>errors.push({url:page.url(),message:error.message}));
  await cdp.send('Audits.enable');
}
function nav(page) { return page.getByRole('navigation',{name:'このページの目次',exact:true}); }
async function active(page,name) {
  await nav(page).getByRole('link',{name,exact:true}).and(page.locator('[aria-current="true"]')).waitFor({timeout:10000});
  assert.equal(await nav(page).locator('a[aria-current="true"]').count(),1);
}
async function open(page,hash='') {
  const url=new URL(base);
  url.searchParams.set('component','table-of-contents');
  url.searchParams.set('mode','light');
  url.hash=hash;
  await page.goto(url.href,{waitUntil:'networkidle'});
  await nav(page).waitFor();
}
try {
  const page=await browser.newPage({viewport:{width:1280,height:900}});
  await audit(page);
  await open(page,'#settings');
  await active(page,'設定');
  checks.push('initial deep link');
  const initialInvalid=await browser.newPage();
  await audit(initialInvalid);
  await open(initialInvalid,'#%FF');
  assert.equal(new URL(initialInvalid.url()).hash,'#%FF');
  await initialInvalid.close();
  checks.push('initial invalid UTF-8 fragment is retained without an engine exception');
  assert.equal(await nav(page).getByRole('list').count(),2);
  assert.equal(await nav(page).getByRole('link').count(),5);
  await nav(page).getByRole('link',{name:'Unicode（café）',exact:true}).click();
  await active(page,'Unicode（café）');
  await page.waitForURL(url=>url.hash==='#caf%C3%A9');
  checks.push('nested child selection is not overridden by its group');
  await page.goBack();
  await active(page,'設定');
  await page.goForward();
  await active(page,'Unicode（café）');
  checks.push('browser Back and Forward');
  for(const fragment of ['#%','#%ZZ','#%FF','#unknown']) {
    await page.evaluate(hash=>{location.hash=hash;},fragment);
    await page.waitForTimeout(100);
    await active(page,'Unicode（café）');
    if(fragment==='#%FF')assert.equal(new URL(page.url()).hash,fragment);
  }
  checks.push('malformed percent escapes, invalid UTF-8 and unknown fragments are ignored');
  await page.evaluate(()=>{location.hash='#50%-off';});
  await active(page,'割引（50%）');
  checks.push('raw percent fragment');
  await page.evaluate(()=>{location.hash='#caf%C3%A9';});
  await active(page,'Unicode（café）');
  checks.push('encoded Unicode and later valid hash changes');
  const settings=nav(page).getByRole('link',{name:'設定',exact:true});
  await settings.focus();
  await page.keyboard.press('Enter');
  await active(page,'設定');
  checks.push('keyboard Enter');
  await page.evaluate(()=>{location.hash='#overview';});
  await active(page,'概要');
  await page.waitForTimeout(200);
  const heading=page.getByRole('heading',{name:'概要',exact:true});
  await heading.hover();
  await page.mouse.wheel(0,200);
  await active(page,'分析');
  checks.push('native wheel scrolling updates the first visible heading');
  await page.getByRole('button',{name:'ダークモードに切り替え',exact:true}).click();
  await active(page,'分析');
  await nav(page).getByRole('link',{name:'Unicode（café）',exact:true}).click();
  await active(page,'Unicode（café）');
  assert.equal(new URL(page.url()).searchParams.get('mode'),'dark');
  assert.equal(new URL(page.url()).searchParams.get('component'),'table-of-contents');
  await page.screenshot({path:`${output}/desktop-dark.png`});
  checks.push('theme changes preserve position and anchor navigation retains component and mode');
  await page.close();
  for(const width of [320,390]) for(const mode of ['light','dark']) {
    const context=await browser.newContext({viewport:{width,height:900},isMobile:true,hasTouch:true});
    const mobile=await context.newPage();
    await audit(mobile);
    await mobile.goto(`${base}?component=table-of-contents&mode=${mode}#settings`,{waitUntil:'networkidle'});
    await active(mobile,'設定');
    await nav(mobile).getByRole('link',{name:'割引（50%）',exact:true}).tap();
    await active(mobile,'割引（50%）');
    await mobile.screenshot({path:`${output}/mobile-${width}-${mode}.png`});
    checks.push(`${width}px ${mode}: initial hash and touch selection`);
    await context.close();
  }
  assert.deepEqual(errors,[]);
  const report={checkedAt:new Date().toISOString(),browser:browser.version(),checks,issues,errors,success:true};
  await writeFile(`${output}/behavior.json`,JSON.stringify(report,null,2)+'\n');
  console.log(JSON.stringify({success:true,checks:checks.length,issues:issues.length,errors:errors.length}));
} finally { await browser.close(); }
