"""CLI entrypoints called by the central shared-ci workflow."""
import argparse
import base64
import json
import os
import subprocess
from pathlib import Path

from sync_engine import (Api, ROOT, SHA, build_requests, collect, digest, new_state,
                         read_json, run, safe_path, stage_proposal, submit, write_json)


def gh(path, method='GET', body=None):
    args = ['gh','api',path,'--method',method]
    if body is not None:
        args += ['--input','-']
    result = subprocess.run(args,input=None if body is None else json.dumps(body),
                            capture_output=True,text=True,encoding='utf-8',check=False)
    if result.returncode:
        raise RuntimeError('GITHUB_API_FAILED:' + path)
    return json.loads(result.stdout) if result.stdout.strip() else None


class StateStore:
    def __init__(self, config, repository):
        if repository != 'stey-jp/stey-ui':
            raise ValueError('SYNC_REPOSITORY_NOT_ALLOWED')
        self.repo, self.config, self.sha = repository,config,None
        self.branch = config['state_branch']

    def read(self):
        refs = gh(f'repos/{self.repo}/git/matching-refs/heads/{self.branch}')
        if not any(ref['ref'] == 'refs/heads/'+self.branch for ref in refs):
            return new_state(self.config)
        file = gh(f'repos/{self.repo}/contents/state.json?ref={self.branch}')
        self.sha = file['sha']
        if file.get('encoding') != 'base64':
            file=gh(f"repos/{self.repo}/git/blobs/{file['sha']}")
        return json.loads(base64.b64decode(file['content']))

    def persist(self, state):
        if self.sha is None:
            refs = gh(f'repos/{self.repo}/git/matching-refs/heads/{self.branch}')
            if refs:
                raise ValueError('STATE_CREATED_CONCURRENTLY')
            tree = gh(f'repos/{self.repo}/git/trees','POST',{'tree':[{
                'path':'state.json','mode':'100644','type':'blob','content':json.dumps(state,indent=2)+'\n'}]})
            commit = gh(f'repos/{self.repo}/git/commits','POST',{'message':'Initialize Kumo synchronization ledger','tree':tree['sha'],'parents':[]})
            gh(f'repos/{self.repo}/git/refs','POST',{'ref':'refs/heads/'+self.branch,'sha':commit['sha']})
            created=gh(f'repos/{self.repo}/contents/state.json?ref={self.branch}')
            self.sha=created['sha']
        body = {'message':'Record Kumo synchronization state','branch':self.branch,
                'content':base64.b64encode((json.dumps(state,indent=2)+'\n').encode()).decode()}
        if self.sha:
            body['sha'] = self.sha
        result = gh(f'repos/{self.repo}/contents/state.json','PUT',body)
        self.sha = result['content']['sha']


def source_at(config, state):
    source = ROOT/'.sync-work/upstream'
    if not source.exists():
        source.parent.mkdir(parents=True,exist_ok=True)
        run('git','clone','--filter=blob:none','--no-checkout','https://github.com/'+config['repository']+'.git',str(source))
    run('git','fetch','origin',config['branch'],cwd=source)
    target = run('git','rev-parse','FETCH_HEAD',cwd=source)
    base = state.get('observed_sha') or state['synchronized_sha'] or state['baseline_sha']
    if not SHA.fullmatch(target) or not SHA.fullmatch(base):
        raise ValueError('INVALID_UPSTREAM_SHA')
    run('git','fetch','origin',base,cwd=source)
    return source,base,target


def reconcile(state, store):
    pending = state['pending']
    if not pending or pending['phase'] != 'pr-open':
        return
    pr = gh(f"repos/{store.repo}/pulls/{pending['pr_number']}")
    if pr.get('merged_at'):
        lock = gh(f'repos/{store.repo}/contents/upstream/lock.json?ref=main')
        synced = json.loads(base64.b64decode(lock['content']))['synchronized_sha']
        if synced != pending['target']:
            raise ValueError('MERGED_LOCK_SHA_MISMATCH')
        state['synchronized_sha'] = synced
        state['observed_sha'] = synced
        state['history'].append({'target':synced,'result':'merged','pr':pr['html_url']})
        state['pending'] = None; store.persist(state)
    elif pr['state'] == 'closed':
        pending['phase'] = 'pr-closed'; store.persist(state)


def apply(output):
    proposal = read_json(Path(output)/'proposal.json')
    for edit in proposal['files']:
        target = safe_path(edit['path'])
        current = digest(target.read_text(encoding='utf-8')) if target.exists() else None
        if current != edit['base_sha256']:
            raise ValueError('PATCH_BASE_CHANGED')
    for edit in proposal['files']:
        target = safe_path(edit['path'])
        target.parent.mkdir(parents=True,exist_ok=True)
        target.write_text(edit['content'],encoding='utf-8')


def create_pr(config, state, store, output):
    pending = state['pending']
    if not pending or pending['phase'] != 'results-ready':
        raise ValueError('PR_PHASE_INVALID')
    report = read_json(Path(output)/'verification.json')
    if report.get('success') is not True or report.get('target') != pending['target']:
        raise ValueError('VERIFICATION_NOT_SUCCESSFUL')
    if report.get('proposal_sha256') != digest(json.dumps(pending['proposal'],sort_keys=True)):
        raise ValueError('VERIFIED_PROPOSAL_MISMATCH')
    if run('git','status','--porcelain'):
        raise ValueError('PR_CHECKOUT_DIRTY')
    run('git','fetch','origin','main')
    head = run('git','rev-parse','HEAD')
    if head != run('git','rev-parse','origin/main') or head != report['base_sha']:
        raise ValueError('PR_BASE_ADVANCED_REVERIFY_REQUIRED')
    branch = 'sync/kumo-'+pending['target'][:12]
    existing = gh(f'repos/{store.repo}/pulls?state=all&head=stey-jp:{branch}')
    if existing:
        pending.update(phase='pr-open',pr_number=existing[0]['number']); store.persist(state); return
    if run('git','ls-remote','--heads','origin',branch):
        raise ValueError('EXISTING_SYNC_BRANCH_REQUIRES_OPERATOR')
    run('git','switch','-c',branch)
    stage_proposal(pending['proposal'],output)
    apply(output)
    write_json(ROOT/'upstream/lock.json',{'synchronized_sha':pending['target'],
                                       'previous_sha':pending['base']})
    paths = [edit['path'] for edit in pending['proposal']['files']] + ['upstream/lock.json']
    run('git','add','--',*paths)
    run('git','-c','user.name=stey-ui-sync[bot]','-c','user.email=stey-ui-sync@users.noreply.github.com',
        'commit','-m','Synchronize Kumo '+pending['target'][:12])
    # Re-read status and the latest remote base before the ordinary push.
    if run('git','status','--porcelain'):
        raise ValueError('UNEXPECTED_UNCOMMITTED_FILES')
    run('git','fetch','origin','main')
    if head != run('git','rev-parse','origin/main'):
        raise ValueError('REMOTE_MAIN_ADVANCED')
    run('git','push','origin','HEAD:refs/heads/'+branch)
    body = 'Updates native Flutter implementation for upstream Kumo '+pending['target']+'.\n\n'
    body += '\n'.join('- '+s for s in pending['proposal']['summaries'])
    body += '\n\nVerification: Flutter analysis, widget tests, release Web build and approved visual comparisons passed. No automatic merge.'
    pr = gh(f'repos/{store.repo}/pulls','POST',{'title':'Sync Kumo '+pending['target'][:12],
                                             'head':branch,'base':'main','body':body})
    pending.update(phase='pr-open',pr_number=pr['number'],pr_url=pr['html_url']); store.persist(state)
    print(pr['html_url'])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('operation',choices=['detect','submit','collect','apply','publish','retry','validation-failed'])
    parser.add_argument('--repository',default=os.environ.get('GITHUB_REPOSITORY','stey-jp/stey-ui'))
    parser.add_argument('--output',default='.sync-work/proposal')
    parser.add_argument('--local-state',type=Path)
    args = parser.parse_args()
    if args.operation == 'apply':
        apply(args.output); return
    config = read_json(ROOT/'upstream/config.json')
    store = StateStore(config,args.repository)
    if args.local_state:
        state = read_json(args.local_state) if args.local_state.exists() else new_state(config)
        persist = lambda state: write_json(args.local_state,state)
    else:
        state,persist = store.read(),store.persist
        reconcile(state,store)
    try:
        if args.operation == 'retry':
            # Explicit bounded retry after known failure; never retry unknown acceptance.
            if not state['pending'] or state['pending']['phase'] != 'failed' or not state['pending'].get('cost_recorded'):
                raise ValueError('RETRY_NOT_SAFE')
            failed=state['pending'].get('failed_requests',[])
            if not failed:
                raise ValueError('RETRY_PARTITION_UNKNOWN_REQUIRES_OPERATOR')
            target=state['pending']['target']
            completed=state['pending'].get('completed_proposals',{})
            batches={}
            for request in failed:
                context=json.loads(request['body']['input'])
                context['previous_failures']=state['pending']['errors']
                request['body']['input']=json.dumps(context,ensure_ascii=False)
                batches.setdefault(request['body']['model'],[]).append(request)
            state['history'].append({'target':target,'result':'failed-request-retry','errors':state['pending']['errors']}); state['pending']=None; persist(state)
            submit(config,state,batches,target,persist,Api(),ROOT/'.sync-work/requests',completed)
            return
        if args.operation == 'validation-failed':
            if state['pending'] and state['pending']['phase']=='results-ready':
                state['pending']['phase']='validation-failed'
                state['pending']['errors']=['Central validation failed; inspect its run before repairing only affected files.']
                persist(state)
            return
        if args.operation in ('detect','submit'):
            if state['pending']:
                print('pending:'+state['pending']['phase']); return
            source,base,target = source_at(config,state)
            if target == base:
                print('unchanged'); return
            batches,changed = build_requests(config,read_json(ROOT/'upstream/inventory.json'),source,base,target)
            if args.operation == 'detect':
                write_json(Path(args.output)/'plan.json',{'base':base,'target':target,'changed':changed,'models':{m:len(v) for m,v in batches.items()}})
                print('changed:'+target); return
            if not batches:
                state['history'].append({'target':target,'result':'non-implementation-change'})
                state['observed_sha']=target; persist(state); return
            submit(config,state,batches,target,persist,Api(),ROOT/'.sync-work/requests')
            print('submitted:'+target)
        elif args.operation == 'collect':
            result = collect(config,state,persist,Api(),args.output) if state['pending'] and state['pending']['phase'] in ('submitted','results-ready') else 'idle'
            if result == 'results-ready':
                stage_proposal(state['pending']['proposal'],args.output)
                write_json(Path(args.output)/'context.json',{'target':state['pending']['target'],'base_sha':run('git','rev-parse','HEAD')})
            if os.environ.get('GITHUB_OUTPUT'):
                with open(os.environ['GITHUB_OUTPUT'],'a') as file:
                    file.write('ready='+str(result=='results-ready').lower()+'\n')
            print(result)
        elif args.operation == 'publish':
            create_pr(config,state,store,args.output)
    except Exception as error:
        reason = str(error).splitlines()[0][:240]
        write_json(ROOT/'.sync-work/failure.json',{'operation':args.operation,'reason':reason})
        if not args.local_state and args.operation != 'detect':
            title = 'Kumo sync needs attention: '+reason.split(':')[0]
            existing = gh(f'repos/{store.repo}/issues?state=open&labels=kumo-sync')
            if not any(issue['title'] == title for issue in existing):
                gh(f'repos/{store.repo}/issues','POST',{'title':title,'body':'Operation: '+args.operation+'\n\nReason: '+reason+'\n\nNo merge was performed. Inspect the synchronization ledger before retrying.','labels':['kumo-sync']})
        raise


if __name__ == '__main__':
    main()
