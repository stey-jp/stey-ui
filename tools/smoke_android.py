"""Exercise the release demo on an explicitly selected Android emulator."""
import argparse
import hashlib
import json
import os
import re
import subprocess
import time
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = 'jp.stey.stey_ui_demo'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--device', required=True)
    args = parser.parse_args()
    sdk = os.environ.get('ANDROID_HOME') or os.environ.get('ANDROID_SDK_ROOT')
    if not sdk:
        raise ValueError('ANDROID_SDK_LOCATION_MISSING')
    executable = Path(sdk) / 'platform-tools' / ('adb.exe' if os.name == 'nt' else 'adb')
    prefix = [str(executable), '-s', args.device]

    def adb(*arguments):
        return subprocess.check_output([*prefix, *arguments], text=True, encoding='utf-8', timeout=30).strip()

    if adb('shell', 'getprop', 'ro.kernel.qemu') != '1':
        raise ValueError('SMOKE_TEST_REQUIRES_AN_EMULATOR')
    apk = ROOT / 'apps/demo/build/app/outputs/flutter-apk/app-release.apk'
    output = ROOT / 'output/android-smoke'
    output.mkdir(parents=True, exist_ok=True)
    adb('install', '-r', str(apk))
    adb('shell', 'am', 'force-stop', PACKAGE)
    adb('shell', 'am', 'start', '-W', '-n', PACKAGE+'/.MainActivity')

    def snapshot():
        adb('shell', 'uiautomator', 'dump', '/sdcard/stey-ui-smoke.xml')
        adb('pull', '/sdcard/stey-ui-smoke.xml', str(output / 'window.xml'))
        return list(ET.parse(output / 'window.xml').iter('node'))

    def label(node):
        return ' '.join((node.get('content-desc') or node.get('text') or '').split())

    def find(text):
        for _ in range(5):
            for node in snapshot():
                if label(node) == text:
                    return node
            time.sleep(.2)
        raise ValueError('ANDROID_NODE_MISSING:'+text)

    def tap(text):
        node = find(text)
        left, top, right, bottom = map(int, re.findall(r'\d+', node.get('bounds', '')))
        adb('shell', 'input', 'tap', str((left+right)//2), str((top+bottom)//2))

    def screenshot(name):
        with (output / name).open('wb') as image:
            subprocess.run([*prefix, 'exec-out', 'screencap', '-p'], stdout=image, check=True, timeout=30)

    find('Interactive preview')
    tap('primary')
    find('Activated 1 times')
    tap('Disabled')
    tap('Loading Saving')
    find('Activated 1 times')
    screenshot('light.png')
    tap('Switch to dark mode')
    find('Switch to light mode')
    tap('primary')
    find('Activated 2 times')
    screenshot('dark.png')
    pid = adb('shell', 'pidof', PACKAGE)
    if not pid:
        raise ValueError('ANDROID_APP_NOT_RUNNING')
    logs = adb('logcat', '--pid='+pid, '-d', '-v', 'brief')
    (output / 'app.log').write_text(logs, encoding='utf-8')
    if any(marker in logs for marker in ('FATAL EXCEPTION', 'Unhandled Exception', 'E/flutter')):
        raise ValueError('ANDROID_RUNTIME_ERROR')
    report = {
        'success': True, 'device': args.device,
        'api': adb('shell', 'getprop', 'ro.build.version.sdk'),
        'apk_sha256': hashlib.sha256(apk.read_bytes()).hexdigest(),
        'tested_source_sha': subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
        'checks': ['release launch', 'button activation', 'disabled inert', 'loading inert', 'light/dark', 'state retained', 'no app runtime error'],
    }
    (output / 'report.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
    print(json.dumps(report))


if __name__ == '__main__':
    main()
