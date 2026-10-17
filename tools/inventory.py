"""Generate source inventory and semantic colors without using an AI API."""
import argparse
import json
import math
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def split_args(value):
    depth = 0
    for i, char in enumerate(value):
        depth += (char == '(') - (char == ')')
        if char == ',' and depth == 0:
            return value[:i].strip(), value[i + 1:].strip()
    raise ValueError(value)


def resolve_color(value, primitives):
    value = value.strip()
    if not value.startswith('var('):
        return value
    name, fallback = split_args(value[4:-1])
    return resolve_color(primitives.get(name.removeprefix('--'), fallback), primitives)


def color(value):
    if value.startswith('var('):
        return color(split_args(value[4:-1])[1])
    if value.startswith('color-mix('):
        match = re.search(r'oklch\(([^)]+)\)', value)
        numbers = [float(x) for x in match[1].split()]
        numbers[0] *= .9
        numbers[1] *= .9
        return color('oklch(' + ' '.join(map(str, numbers)) + ')')
    if value.startswith('#'):
        hexa = value[1:]
        if len(hexa) == 3:
            hexa = ''.join(x * 2 for x in hexa)
        return 'ff' + hexa.lower()
    if not value.startswith('oklch('):
        raise ValueError(value)
    parts = value[6:-1].replace('/', ' ').split()
    light = float(parts[0].rstrip('%')) / (100 if '%' in parts[0] else 1)
    chroma, hue = float(parts[1]), math.radians(0 if parts[2] == 'none' else float(parts[2]))
    alpha = float(parts[3]) if len(parts) > 3 else 1
    a, b = chroma * math.cos(hue), chroma * math.sin(hue)
    l = (light + .3963377774 * a + .2158037573 * b) ** 3
    m = (light - .1055613458 * a - .0638541728 * b) ** 3
    s = (light - .0894841775 * a - 1.2914855480 * b) ** 3
    rgb = (4.0767416621*l-3.3077115913*m+.2309699292*s,
           -1.2684380046*l+2.6097574011*m-.3413193965*s,
           -.0041960863*l-.7034186147*m+1.7076147010*s)
    def channel(v):
        v = max(0, min(1, v))
        return round(255 * (12.92*v if v <= .0031308 else 1.055*v**(1/2.4)-.055))
    return f'{round(alpha*255):02x}' + ''.join(f'{channel(v):02x}' for v in rgb)


def oklch_values(value):
    if value.startswith('var('): return oklch_values(split_args(value[4:-1])[1])
    match=re.search(r'oklch\(([^)]+)\)',value)
    parts=match[1].split()
    values=[float(parts[0].rstrip('%'))/(100 if '%' in parts[0] else 1),float(parts[1]),float(parts[2])]
    if value.startswith('color-mix('): values[0]*=.9;values[1]*=.9
    return values


FIELDS = {
    'canvas':'color-kumo-canvas', 'base':'color-kumo-base',
    'elevated':'color-kumo-elevated', 'recessed':'color-kumo-recessed',
    'tint':'color-kumo-tint', 'fill':'color-kumo-fill', 'overlay':'color-kumo-overlay',
    'control':'color-kumo-control', 'contrast':'color-kumo-contrast',
    'brand':'color-kumo-brand', 'line':'color-kumo-line',
    'hairline':'color-kumo-hairline', 'focus':'color-kumo-focus',
    'text':'text-color-kumo-default', 'inverse':'text-color-kumo-inverse',
    'strong':'text-color-kumo-strong',
    'subtle':'text-color-kumo-subtle', 'link':'text-color-kumo-link',
    'placeholder':'text-color-kumo-placeholder',
    'danger':'color-kumo-danger', 'dangerText':'text-color-kumo-danger',
    'success':'color-kumo-success',
    'successText':'text-color-kumo-success', 'warningText':'text-color-kumo-warning',
    'infoTint':'color-kumo-info-tint', 'successTint':'color-kumo-success-tint',
    'warningTint':'color-kumo-warning-tint', 'dangerTint':'color-kumo-danger-tint',
    'badgeRed':'color-kumo-badge-red','badgeGreen':'color-kumo-badge-green',
    'badgeOrange':'color-kumo-badge-orange','badgePurple':'color-kumo-badge-purple',
    'badgeTeal':'color-kumo-badge-teal','badgeBlue':'color-kumo-badge-blue',
    'badgeNeutral':'color-kumo-badge-neutral','badgeInverted':'color-kumo-badge-inverted',
    'badgeInverseText':'text-color-kumo-badge-inverted',
    'badgeOrangeText':'text-color-kumo-badge-orange-subtle',
    'badgeTealText':'text-color-kumo-badge-teal-subtle',
    'badgeNeutralText':'text-color-kumo-badge-neutral-subtle',
    'shadowEdge':'color-kumo-shadow-edge', 'shadowDrop':'color-kumo-shadow-drop',
    'interact':'color-kumo-interact',
}

# Switch uses upstream primitive utilities in addition to semantic tokens.
SWITCH_COLORS = {
    'switchTrackOff': ('color-neutral-200', 'color-neutral-700'),
    'switchTrackOn': ('color-blue-500', 'color-blue-600'),
    'switchRingOff': ('color-neutral-300', 'color-neutral-600'),
    'switchRingOn': ('color-blue-600', 'color-blue-500'),
    'switchThumbOn': ('color-white', 'color-blue-300'),
    'switchNeutralTrackOn': ('color-neutral-500', '@base'),
    'switchNeutralRingOn': ('color-neutral-600', 'color-neutral-700'),
    'switchNeutralThumbOn': ('color-white', 'color-neutral-400'),
}


def generate(source, tokens_only=False, tailwind_theme=None):
    css = (source / 'packages/kumo/src/styles/theme-kumo.css').read_text()
    tokens = dict(re.findall(r'--([\w-]+):\s*light-dark\((.*?)\);', css, re.S))
    # CSS uses the referenced primitive when present, not the var() fallback.
    # The pinned Tailwind palette is data only; Flutter has no Tailwind runtime.
    version = re.search(r'\n    tailwindcss:\n      specifier: [^\n]+\n      version: ([^\n]+)',
                        (source / 'pnpm-lock.yaml').read_text()).group(1)
    palette_path = ROOT / 'upstream/color-primitives.json'
    if tailwind_theme:
        package = json.loads((tailwind_theme.parent / 'package.json').read_text())
        if package['version'] != version:
            raise ValueError('Tailwind palette does not match the upstream lockfile')
        palette = dict(re.findall(r'--(color-[\w-]+):\s*([^;]+);', tailwind_theme.read_text()))
        referenced = set(re.findall(r'var\(--(color-[\w-]+)', css))
        referenced.update(value for values in SWITCH_COLORS.values() for value in values if value != '@base')
        palette = {name: value for name, value in palette.items() if name in referenced}
        palette_path.write_text(json.dumps({'tailwind_version': version,
            'source': 'tailwindcss/theme.css (MIT, Tailwind Labs, Inc.)',
            'colors': palette}, indent=2) + '\n')
    else:
        cached = json.loads(palette_path.read_text())
        if cached['tailwind_version'] != version:
            raise ValueError('Refresh the pinned palette with --tailwind-theme')
        palette = cached['colors']
    binding = (source / 'packages/kumo/src/styles/kumo-binding.css').read_text()
    palette.update(dict(re.findall(r'--(color-[\w-]+):\s*(oklch\([^;]+|#[^;]+);', binding)))
    lines = ['// Generated from Cloudflare Kumo (MIT). See THIRD_PARTY_NOTICES.md.',
             "import 'package:flutter/material.dart';", '', 'class SteyColors {',
             '  const SteyColors(this.brightness);', '  final Brightness brightness;',
             '  bool get dark => brightness == Brightness.dark;']
    for name, token in FIELDS.items():
        light, dark = [resolve_color(value, palette) for value in split_args(tokens[token])]
        lines.append(f'  Color get {name} => Color(dark ? 0x{color(dark)} : 0x{color(light)});')
    for name, values in SWITCH_COLORS.items():
        resolved = [resolve_color(split_args(tokens['color-kumo-base'])[index], palette)
                    if value == '@base' else palette[value] for index, value in enumerate(values)]
        light, dark = resolved
        lines.append(f'  Color get {name} => Color(dark ? 0x{color(dark)} : 0x{color(light)});')
    for tone in ('brand','danger'):
        for state,fraction,target in [('EmphasisStart',.15,1),('EmphasisHover',.3,1),('EmphasisRing',.1,0)]:
            values=[]
            for value in split_args(tokens['color-kumo-'+tone]):
                l,c,h=oklch_values(resolve_color(value, palette))
                values.append(color(f'oklch({l*(1-fraction)+target*fraction} {c*(1-fraction)} {h})'))
            lines.append(f'  Color get {tone}{state} => Color(dark ? 0x{values[1]} : 0x{values[0]});')
    lines.append('}')
    (ROOT/'packages/stey_ui_modern/lib/src/tokens.g.dart').write_text('\n'.join(lines)+'\n')
    if tokens_only:
        print(f'Generated {len(FIELDS)} semantic colors.')
        return
    sha = subprocess.check_output(['git','-C',str(source),'rev-parse','HEAD'],text=True).strip()
    inventory = []
    for kind in ('components', 'blocks'):
        for folder in sorted((source/f'packages/kumo/src/{kind}').iterdir()):
            if not folder.is_dir():
                continue
            files = sorted(str(p.relative_to(source)).replace('\\','/') for p in folder.rglob('*') if p.is_file())
            inventory.append({'id':folder.name, 'kind':kind, 'source_files':files,
                              'implementation_files':[], 'status':'pending',
                              'visual_verified':False, 'behavior_verified':False})
            if kind == 'components' and folder.name == 'code':
                prefix = 'packages/kumo/src/code/'
                inventory[-1]['source_prefixes'] = [prefix]
                extra = source/prefix
                if extra.is_dir():
                    inventory[-1]['source_files'] = sorted(files + [p.relative_to(source).as_posix() for p in extra.rglob('*') if p.is_file()])
    (ROOT/'upstream').mkdir(exist_ok=True)
    (ROOT/'upstream/inventory.json').write_text(json.dumps({'inspected_sha':sha,'components':inventory},indent=2)+'\n')
    print(f'Inventoried {len(inventory)} component groups; generated {len(FIELDS)} semantic colors.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('source',type=Path)
    parser.add_argument('--tokens-only',action='store_true')
    parser.add_argument('--tailwind-theme',type=Path)
    args=parser.parse_args()
    generate(args.source,args.tokens_only,args.tailwind_theme)
