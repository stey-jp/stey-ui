import { readFile, mkdir, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { PNG } from 'pngjs';
import pixelmatch from 'pixelmatch';

// Official fixtures must have a pinned upstream SHA and matching dimensions.
// Missing baselines are a failed gate, never a successful "no differences" result.
const required=process.argv.includes('--require-upstream');
const output=resolve('output/visual');await mkdir(output,{recursive:true});
const manifest=JSON.parse(await readFile('upstream/visual-fixtures.json','utf8'));
const rows=[];
for(const fixture of manifest.fixtures){
  const reference=PNG.sync.read(await readFile(fixture.reference));
  const candidate=PNG.sync.read(await readFile(fixture.candidate));
  if(reference.width!==candidate.width||reference.height!==candidate.height)throw Error('VISUAL_DIMENSIONS_MISMATCH');
  const diff=new PNG({width:reference.width,height:reference.height});
  const changed=pixelmatch(reference.data,candidate.data,diff.data,reference.width,reference.height,{threshold:fixture.threshold??0.1,includeAA:true});
  const ratio=changed/(reference.width*reference.height);
  rows.push({id:fixture.id,changedPixels:changed,ratio,success:ratio<=(fixture.maxChangedRatio??0)});
  await writeFile(resolve(output,fixture.id+'-diff.png'),PNG.sync.write(diff));
}
const success=manifest.fixtures.length>0&&rows.every(row=>row.success);
const report={upstream_sha:manifest.upstream_sha,success,fixtures:rows,
  missing:manifest.fixtures.length===0?'Pinned official reference fixtures have not been approved.':null};
await writeFile(resolve(output,'report.json'),JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify(report));
if(required&&!success)process.exitCode=1;
