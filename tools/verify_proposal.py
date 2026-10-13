"""Write a receipt only after all project checks and visual comparisons pass.

The verification environment invokes the project's full commands first and runs this
command only after they succeed. This command checks the visual gate and the
hash of the exact reviewed proposal; it does not independently run full checks.
"""
import argparse
import json
from pathlib import Path
from sync_engine import ROOT, digest, read_json, run, write_json


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--output',default='.sync-work/proposal')
    args=parser.parse_args()
    folder=Path(args.output)
    context=read_json(folder/'context.json')
    proposal=read_json(folder/'proposal.json')
    visuals=read_json(ROOT/'output/visual/report.json')
    if visuals.get('success') is not True or visuals.get('upstream_sha')!=context['target']:
        raise ValueError('UPSTREAM_VISUAL_COMPARISON_NOT_PASSED')
    changed=run('git','diff','--name-only').splitlines()
    changed+=run('git','ls-files','--others','--exclude-standard').splitlines()
    if set(changed)!=set(edit['path'] for edit in proposal['files']):
        raise ValueError('UNEXPECTED_VERIFICATION_DIFF')
    for edit in proposal['files']:
        if digest((ROOT/edit['path']).read_text(encoding='utf-8')) != digest(edit['content']):
            raise ValueError('VERIFICATION_SOURCE_CHANGED')
    write_json(folder/'verification.json',{'success':True,'target':context['target'],
        'base_sha':context['base_sha'],'proposal_sha256':digest(json.dumps(proposal,sort_keys=True)),
        'checks':['flutter-full','upstream-visual-comparison']})


if __name__=='__main__': main()
