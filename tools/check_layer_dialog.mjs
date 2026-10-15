import assert from 'node:assert/strict';
import {mkdir, writeFile} from 'node:fs/promises';
import {chromium} from 'playwright';

const base = process.env.DEMO_URL ?? 'http://127.0.0.1:8766/';
const output = 'output/layer-dialog';
await mkdir(output, {recursive:true});
const browser = await chromium.launch({channel:'chrome', headless:true});
const checks = [], issues = [], errors = [];
try {
  for (const [width, mode] of [[1280,'light'],[1280,'dark'],[320,'light'],[320,'dark'],[639,'light'],[640,'light']]) {
    const context = await browser.newContext({viewport:{width,height:900},isMobile:width<640,hasTouch:width<640,colorScheme:mode});
    const page = await context.newPage(), cdp = await context.newCDPSession(page);
    cdp.on('Audits.issueAdded', ({issue}) => issues.push({width,mode,...issue}));
    await cdp.send('Audits.enable');
    page.on('pageerror', error => errors.push({width,mode,message:error.message}));
    await page.goto(`${base}?component=layer-dialog&mode=${mode}`, {waitUntil:'networkidle'});
    const trigger = page.getByRole('button',{name:'多層ダイアログを開く',exact:true});
    await trigger.focus();
    await trigger.click();
    const dialog = page.getByRole('dialog');
    await dialog.waitFor();
    await dialog.getByRole('textbox',{name:'Worker名',exact:true}).fill('example-worker');
    await dialog.getByRole('button',{name:'その他の操作',exact:true}).click();
    await page.getByRole('menuitem',{name:'下書きとして保存',exact:true}).click();
    await dialog.waitFor({state:'hidden'});
    await page.getByText('下書きとして保存しました',{exact:true}).waitFor();
    await trigger.click();
    await dialog.waitFor();
    await page.waitForTimeout(500);
    const box = await page.locator('[flt-semantics-identifier="stey-layer-dialog-content"]').boundingBox();
    assert.ok(Math.abs(box.width-(width<640?width:576))<1, JSON.stringify({width,box}));
    if (width<640) assert.ok(Math.abs(box.y+box.height-900)<1);
    await page.screenshot({path:`${output}/dialog-${width}-${mode}.png`});
    await dialog.getByRole('button',{name:'保存する',exact:true}).click();
    await dialog.waitFor({state:'hidden'});
    await page.getByText('設定を保存しました',{exact:true}).waitFor();
    checks.push(`${width}px ${mode}: edit, split action, save, responsive surface`);

    await page.getByRole('button',{name:'削除の確認',exact:true}).click();
    const alert = page.getByRole('alertdialog');
    await alert.waitFor();
    await page.mouse.click(3,3);
    assert.equal(await alert.count(),1);
    await alert.getByRole('button',{name:'キャンセル',exact:true}).waitFor();
    await page.keyboard.press('Escape');
    await alert.waitFor({state:'hidden'});
    checks.push(`${width}px ${mode}: alert ignores outside press, exposes cancel, Escape closes`);

    await page.getByRole('button',{name:'処理中の終了制御を確認',exact:true}).click();
    await dialog.waitFor();
    assert.equal(await dialog.getByRole('button',{name:'閉じる',exact:true}).isDisabled(),true);
    await page.keyboard.press('Escape');
    await page.mouse.click(3,3);
    assert.equal(await dialog.count(),1);
    await dialog.waitFor({state:'hidden'});
    await page.getByText('処理が完了しました',{exact:true}).waitFor();
    checks.push(`${width}px ${mode}: pending blocks dismissal and programmatically completes`);

    await page.getByRole('button',{name:'閉じるアイコンを確認',exact:true}).click();
    await dialog.waitFor();
    await dialog.getByRole('button',{name:'閉じる',exact:true}).waitFor();
    assert.equal(await dialog.getByRole('button').count(),1);
    await dialog.getByRole('button',{name:'閉じる',exact:true}).click();
    await dialog.waitFor({state:'hidden'});

    await page.getByRole('button',{name:'長い内容を確認',exact:true}).click();
    await dialog.waitFor();
    await page.waitForTimeout(500);
    const title = dialog.getByRole('heading',{name:'Workerを編集',exact:true});
    const save = dialog.getByRole('button',{name:'保存する',exact:true});
    const before = {title:await title.boundingBox(),save:await save.boundingBox()};
    const bounds = await dialog.boundingBox();
    await page.mouse.move(bounds.x+bounds.width/2,bounds.y+bounds.height/2);
    await page.mouse.wheel(0,500);
    await page.waitForTimeout(350);
    const after = {title:await title.boundingBox(),save:await save.boundingBox()};
    assert.ok(Math.abs(after.title.y-before.title.y)<1,JSON.stringify({width,mode,before,after}));
    assert.ok(Math.abs(after.save.y-before.save.y)<1,JSON.stringify({width,mode,before,after}));
    await page.keyboard.press('Escape');
    await dialog.waitFor({state:'hidden'});
    checks.push(`${width}px ${mode}: no-actions close and sticky title/footer during body scroll`);
    await context.close();
  }
  assert.deepEqual(errors,[]);
  await writeFile(`${output}/behavior.json`,JSON.stringify({checkedAt:new Date().toISOString(),browser:browser.version(),checks,issues,errors,success:true},null,2)+'\n');
  console.log(JSON.stringify({checks:checks.length,issues:issues.length,errors:errors.length,success:true}));
} finally {
  await browser.close();
}
