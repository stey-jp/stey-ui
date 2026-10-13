import {chromium} from 'playwright';
import {mkdir,writeFile} from 'node:fs/promises';
import {resolve} from 'node:path';
import {PNG} from 'pngjs';
import pixelmatch from 'pixelmatch';

const output=resolve('output/visual-samples');await mkdir(output,{recursive:true});
const browser=await chromium.launch({channel:'chrome',headless:true});
const rows=[];
try{
  for(const mode of ['light','dark']){
    const context=await browser.newContext({viewport:{width:600,height:160}});
    for(const [component,variants] of [['button',['primary','secondary','ghost','destructive','outline']],['badge',['secondary','success','red','blue']],['input',['default']]]){
      for(const variant of variants){
        const id=`${component}-${variant}-${mode}`;
        const reference=await context.newPage(),candidate=await context.newPage();
        await reference.goto(`http://127.0.0.1:8767/?component=${component}&variant=${variant}&mode=${mode}`,{waitUntil:'networkidle'});
        if(component==='input')await reference.locator('input').waitFor();
        else await reference.getByText(component==='badge'?'Active':'Save',{exact:true}).waitFor({timeout:30000});
        await reference.evaluate(()=>document.fonts.ready);
        await candidate.goto(`http://127.0.0.1:8766/?sample=${component}&variant=${variant}&mode=${mode}`,{waitUntil:'networkidle'});
        if(component==='badge')await candidate.getByText('Active',{exact:true}).waitFor();
        else await candidate.getByRole(component==='input'?'textbox':'button',{name:component==='input'?'Name':'Save',exact:true}).waitFor({timeout:30000});
        const ref=await reference.screenshot({path:resolve(output,id+'-reference.png')});
        const actual=await candidate.screenshot({path:resolve(output,id+'-candidate.png')});
        const a=PNG.sync.read(ref),b=PNG.sync.read(actual),diff=new PNG({width:a.width,height:a.height});
        const changed=pixelmatch(a.data,b.data,diff.data,a.width,a.height,{threshold:.1,includeAA:true});
        await writeFile(resolve(output,id+'-diff.png'),PNG.sync.write(diff));
        rows.push({id,changedPixels:changed,totalPixels:a.width*a.height,changedRatio:changed/(a.width*a.height)});
        await reference.close();await candidate.close();
      }
    }
    await context.close();
  }
}finally{await browser.close();}
const report={upstreamSha:'f46e8bc9922c37dc1d3e7da779e589fe171df306',source:'Exact upstream source rendered in a temporary Vite fixture',
  note:'Diagnostic samples only; these do not certify every component or interaction.',rows};
await writeFile(resolve(output,'report.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(rows));
