"""Complete generated debugging artifacts without changing application execution."""
import json
import gzip
import shutil
from pathlib import Path
from urllib.parse import urlparse, unquote
from urllib.request import url2pathname

ROOT = Path(__file__).resolve().parents[1]


def resolve_source(uri, sdk, map_path):
    parsed = urlparse(uri)
    if parsed.scheme == 'file':
        return Path(url2pathname(unquote(parsed.path))).resolve()
    if parsed.scheme == 'org-dartlang-sdk':
        relative = parsed.path.lstrip('/')
        if relative.startswith('dart-sdk/'):
            relative = relative[len('dart-sdk/'):]
        source = (sdk / 'bin/cache/dart-sdk' / relative).resolve()
        if not source.is_file() and relative.startswith('lib/'):
            source = (sdk / 'bin/cache/flutter_web_sdk' / relative).resolve()
        return source
    if not parsed.scheme:
        return (map_path.parent / unquote(uri)).resolve()
    raise ValueError('UNSUPPORTED_SOURCE_MAP_URI')


def prepare():
    flutter = shutil.which('flutter')
    if not flutter:
        raise ValueError('FLUTTER_NOT_FOUND')
    sdk = Path(flutter).resolve().parent.parent
    build = ROOT / 'apps/demo/build/web'
    loader_map = sdk / 'bin/cache/flutter_web_sdk/flutter_js/flutter.js.map'
    if not loader_map.is_file():
        raise ValueError('FLUTTER_LOADER_SOURCE_MAP_MISSING')
    shutil.copyfile(loader_map, build / 'flutter.js.map')
    package_file = ROOT / '.dart_tool/package_config.json'
    packages = json.loads(package_file.read_text(encoding='utf-8'))['packages']
    roots = [ROOT, sdk]
    for package in packages:
        uri = package['rootUri']
        roots.append(resolve_source(uri, sdk, package_file))
    completed = 0
    for map_path in build.glob('main.dart.*.map'):
        mapping = json.loads(map_path.read_text(encoding='utf-8'))
        origin = map_path
        if any(not urlparse(uri).scheme for uri in mapping['sources']):
            origins = []
            for cached in (ROOT / 'apps/demo/.dart_tool/flutter_build').glob('*/' + map_path.name):
                candidate = json.loads(cached.read_text(encoding='utf-8'))
                if candidate['sources'] == mapping['sources'] and candidate['mappings'] == mapping['mappings']:
                    origins.append(cached)
            if not origins:
                raise ValueError('ORIGINAL_SOURCE_MAP_MISSING')
            origin = origins[0]
        content = list(mapping.get('sourcesContent', [None] * len(mapping['sources'])))
        if len(content) != len(mapping['sources']):
            raise ValueError('SOURCE_MAP_CONTENT_LENGTH_MISMATCH')
        for index, uri in enumerate(mapping['sources']):
            if content[index] is not None:
                continue
            source = resolve_source(uri, sdk, origin)
            if not any(source.is_relative_to(root) for root in roots):
                raise ValueError('SOURCE_MAP_PATH_OUTSIDE_BUILD_INPUTS')
            content[index] = source.read_text(encoding='utf-8')
            completed += 1
        mapping['sourcesContent'] = content
        map_path.write_text(json.dumps(mapping, separators=(',', ':')), encoding='utf-8')
    for asset in build.rglob('*'):
        if asset.is_file() and asset.suffix in ('.html','.js','.mjs','.wasm','.map','.json','.ttf','.otf'):
            asset.with_name(asset.name+'.gz').write_bytes(gzip.compress(asset.read_bytes(),mtime=0))
    print(json.dumps({'loader_source_map': True, 'embedded_sources': completed}))


if __name__ == '__main__':
    prepare()
