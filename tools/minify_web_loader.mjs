import {readFile,writeFile} from 'node:fs/promises';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {minify} from 'terser';

// Minify generated glue and the app bootstrap, retaining their complete source.
// Flutter SDK files and binaries remain intact.
const root=resolve(dirname(fileURLToPath(import.meta.url)),'..');
for(const [filename,module] of [['main.dart.mjs',true],['flutter_bootstrap.js',false]]){
const path=resolve(root,'apps/demo/build/web',filename);
const code=await readFile(path,'utf8');
if(code.trimEnd().endsWith('//# sourceMappingURL='+filename+'.map')){
  console.log(JSON.stringify({file:filename,loader_minified:true,reused:true}));
}else{
  const result=await minify({[filename+'.generated']:code},{
    module,
    format:{comments:/@license|@preserve|copyright/i},
    sourceMap:{filename,url:filename+'.map',includeSources:true},
  });
  if(!result.code||!result.map)throw Error('WASM_LOADER_MINIFICATION_FAILED');
  await writeFile(path+'.map',result.map+'\n');
  await writeFile(path,result.code+'\n');
  console.log(JSON.stringify({file:filename,loader_minified:true,before:Buffer.byteLength(code),after:Buffer.byteLength(result.code)}));
}
}
