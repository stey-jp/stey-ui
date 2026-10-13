import {readFile,writeFile} from 'node:fs/promises';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {minify} from 'terser';

// Only the generated Dart-to-Wasm JavaScript glue is processed. Flutter SDK
// binaries remain intact, and an actual source map retains the original glue.
const root=resolve(dirname(fileURLToPath(import.meta.url)),'..');
const path=resolve(root,'apps/demo/build/web/main.dart.mjs');
const code=await readFile(path,'utf8');
if(/sourceMappingURL=main\.dart\.mjs\.map\s*$/.test(code)){
  console.log(JSON.stringify({loader_minified:true,reused:true}));
}else{
  const result=await minify({'main.dart.generated.mjs':code},{
    module:true,
    format:{comments:/@license|@preserve|copyright/i},
    sourceMap:{filename:'main.dart.mjs',url:'main.dart.mjs.map',includeSources:true},
  });
  if(!result.code||!result.map)throw Error('WASM_LOADER_MINIFICATION_FAILED');
  await writeFile(path+'.map',result.map+'\n');
  await writeFile(path,result.code+'\n');
  console.log(JSON.stringify({loader_minified:true,before:Buffer.byteLength(code),after:Buffer.byteLength(result.code)}));
}
