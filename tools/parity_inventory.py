"""Extract review evidence from the pinned Kumo source without an AI API.

This is a declaration inventory, not a TypeScript type checker: inherited APIs,
conditional types, defaults and runtime behavior still require source review.
"""
import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LEX = re.compile(r'//[^\n]*|/\*[\s\S]*?\*/|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|`(?:\\.|[^`\\])*`|[A-Za-z_$][\w$]*|[^\s]')


def tokens(text):
    return [(m.group(), m.start(), m.end()) for m in LEX.finditer(text)
            if not m.group().startswith(('//', '/*'))]


def closing(items, start):
    depth = 0
    for index in range(start, len(items)):
        token = items[index][0]
        if token == '{': depth += 1
        if token == '}':
            depth -= 1
            if depth == 0: return index
    raise ValueError('UNCLOSED_SOURCE_DECLARATION')


def declarations(text):
    items = tokens(text)
    result = []
    for i, (token, start, _) in enumerate(items):
        if token != 'export' or i + 2 >= len(items): continue
        kind, name = items[i+1][0], items[i+2][0]
        if kind not in ('interface', 'type', 'const', 'function', 'class'): continue
        if not re.fullmatch(r'[A-Za-z_$][\w$]*', name): continue
        row = {'name': name, 'kind': kind, 'line': text.count('\n', 0, start)+1}
        if kind in ('type', 'interface'):
            end = i+3
            while end < len(items) and items[end][0] not in ('{', ';', 'export'):
                end += 1
            row['declaration_prefix'] = ' '.join(text[items[i+3][1]:items[end][1]].split()) if end < len(items) else ''
            row['direct_properties'] = []
            if end < len(items) and items[end][0] == '{':
                last = closing(items, end)
                depth = 0
                for j in range(end+1, last):
                    value = items[j][0]
                    if value in ('{', '(', '[', '<'): depth += 1
                    elif value in ('}', ')', ']', '>'): depth = max(0, depth-1)
                    if depth or not re.fullmatch(r'[A-Za-z_$][\w$]*|"[^"\n]+"|\'[^\'\n]+\'', value): continue
                    next_value = items[j+1][0]
                    optional = next_value == '?'
                    if next_value == ':' or (optional and items[j+2][0] == ':'):
                        row['direct_properties'].append({'name': value.strip('"\''), 'optional': optional,
                            'line': text.count('\n', 0, items[j][1])+1})
            row['inherited_or_conditional_review'] = 'pending'
        result.append(row)
    return result


def generate(source):
    inventory = json.loads((ROOT/'upstream/inventory.json').read_text(encoding='utf-8'))
    sha = subprocess.check_output(['git', '-C', str(source), 'rev-parse', 'HEAD'], text=True).strip()
    if sha != inventory['inspected_sha']: raise ValueError('PINNED_UPSTREAM_SHA_MISMATCH')
    if subprocess.check_output(['git', '-C', str(source), 'status', '--porcelain', '--untracked-files=no'], text=True).strip():
        raise ValueError('UPSTREAM_TRACKED_FILES_MODIFIED')
    rows = []
    for component in inventory['components']:
        files = []
        for name in component['source_files']:
            if not name.endswith(('.ts', '.tsx')): continue
            text = (source/name).read_text(encoding='utf-8')
            evidence = {'path': name, 'normalized_text_sha256': hashlib.sha256(text.encode()).hexdigest()}
            if '.test.' in name:
                evidence['test_titles'] = [{'title': match[3], 'line': text.count('\n', 0, match.start())+1}
                    for match in re.finditer(r'\b(it|test)\s*\(\s*(["\'])(.*?)\2', text)]
                # Titles are evidence to review, never assertions run by Flutter.
            else:
                evidence['exports'] = declarations(text)
                evidence['dependency_imports'] = sorted(set(re.findall(r'from\s+["\'](@[^"\']+)["\']', text)))
            files.append(evidence)
        rows.append({'component': component['id'], 'kind': component['kind'], 'files': files,
            'api_review': 'pending', 'behavior_review': 'pending', 'visual_review': 'pending'})
    result = {'upstream_sha': sha, 'source_license': 'Cloudflare Kumo MIT; see THIRD_PARTY_NOTICES.md',
        'method': 'Lexical inventory of direct declarations and literal test titles; not a type checker.',
        'limits': 'Inherited Base UI/DOM/React props, re-export closure, conditional/generic types and dynamic tests require review. Extraction does not certify parity.',
        'required_matrix': {'themes': ['light', 'dark'], 'widths': [320, 390, 768, 1280],
            'text_directions': ['ltr', 'rtl'], 'input': ['pointer', 'touch', 'keyboard'],
            'common_checks': ['defaults and every variant', 'controlled and uncontrolled behavior where supported',
                'empty, disabled, read-only, invalid and busy states where supported', 'accessible name, role, state, focus and screen reader',
                'overflow, text scale and responsive behavior', 'compound parts and event details',
                'full painted bounds, focus/hover and phase-aligned animation comparison']},
        'components': rows}
    (ROOT/'upstream/api-inventory.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    print(json.dumps({'groups': len(rows), 'exports': sum(len(file.get('exports', [])) for row in rows for file in row['files'])}))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('source', type=Path)
    generate(parser.parse_args().source)
