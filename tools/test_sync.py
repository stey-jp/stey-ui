import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import sync_engine as sync
import sync as cli


class SyncTests(unittest.TestCase):
    def setUp(self):
        self.config=sync.read_json(sync.ROOT/'upstream/config.json')
        self.state=sync.new_state(self.config)

    def request(self, root):
        path='packages/stey_ui_modern/lib/src/example.dart'
        (root/path).parent.mkdir(parents=True,exist_ok=True)
        (root/path).write_text('old')
        return {'custom_id':'button','body':{'model':self.config['models']['simple']['id'],
            'max_output_tokens':100,'input':json.dumps({'local_files':{path:{'sha256':sync.digest('old')}}})}},path

    def result(self, request, path):
        return json.dumps({'custom_id':request['custom_id'],'response':{'status_code':200,'body':{
            'status':'completed','usage':{'input_tokens':100,'output_tokens':50},
            'output':[{'type':'message','content':[{'type':'output_text','text':json.dumps({'summary':'Update button','files':[
                {'path':path,'base_sha256':sync.digest('old'),'content':'new'}]})}]}]}}})

    def test_path_allowlist(self):
        for path in ['.github/workflows/sync.yml','packages/stey_ui_modern/lib/../../secret.dart',
                     '/tmp/file.dart','apps/demo/lib/x.py','apps/demo/lib/x.dart/../a.dart','C:/secret.dart']:
            with self.assertRaises(ValueError): sync.safe_path(path)

    def test_documentation_only_change_does_not_generate_ai_requests(self):
        with patch.object(sync, 'run', return_value='packages/kumo/README.md\nCHANGELOG.md'):
            batches, changed = sync.build_requests(self.config, {'components': []}, Path('.'), 'a'*40, 'b'*40)
        self.assertEqual(batches, {})
        self.assertEqual(len(changed), 2)

    def test_license_change_stops_without_ai(self):
        with patch.object(sync, 'run', return_value='packages/kumo/LICENSE'):
            with self.assertRaisesRegex(ValueError, 'LICENSE_REVIEW_REQUIRED'):
                sync.build_requests(self.config, {'components': []}, Path('.'), 'a'*40, 'b'*40)

    def test_observed_sha_prevents_reprocessing_documentation_after_a_merge(self):
        self.state.update(synchronized_sha='a'*40, observed_sha='b'*40)
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder); (root/'.sync-work/upstream').mkdir(parents=True)
            commands=[]
            def run(*args, **kwargs):
                commands.append(args)
                return 'b'*40 if args[:2] == ('git','rev-parse') else ''
            with patch.object(cli, 'ROOT', root), patch.object(cli, 'run', run):
                _, base, target = cli.source_at(self.config, self.state)
        self.assertEqual(base, target)
        self.assertIn(('git','fetch','origin','b'*40),commands)

    def test_budget_upper_bound(self):
        config={**self.config,'per_sync_budget_usd':.00001}
        with self.assertRaisesRegex(ValueError,'BUDGET'):
            sync.budget_reservation(config,self.state,[{'body':{'model':config['models']['complex']['id'],'max_output_tokens':16000}}])

    def test_reserve_before_billable_calls(self):
        events=[]
        class MockApi:
            def upload(_,payload):
                self.assertEqual(events[0],'reserved'); events.append('upload'); return {'id':'file-1'}
            def request(_,method,path,body):
                self.assertIn('creating',events); events.append('create'); return {'id':'batch-1'}
        requests=[{'custom_id':'button','body':{'model':self.config['models']['simple']['id'],'max_output_tokens':100}}]
        with tempfile.TemporaryDirectory() as folder:
            sync.submit(self.config,self.state,{requests[0]['body']['model']:requests},'a'*40,
                lambda state:events.append(state['pending']['jobs'][-1]['phase'] if state['pending']['jobs'] else state['pending']['phase']),MockApi(),Path(folder))
        self.assertEqual(self.state['pending']['phase'],'submitted')

    def test_valid_result_and_out_of_order(self):
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder); request,path=self.request(root)
            proposal=sync.validate_results(self.result(request,path),[request],root)
            self.assertEqual(proposal['files'][0]['content'],'new')
            self.assertEqual((root/path).read_text(),'old')  # Parser never executes or applies model output.

    def test_stale_source(self):
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder); request,path=self.request(root); (root/path).write_text('concurrent change')
            with self.assertRaisesRegex(ValueError,'SOURCE_CHANGED'):
                sync.validate_results(self.result(request,path),[request],root)

    def test_duplicate_missing_and_error_results(self):
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder); request,path=self.request(root); line=self.result(request,path)
            for lines in ['',line+'\n'+line,json.dumps({'custom_id':'button','error':{'code':'failed'}})]:
                with self.assertRaises(ValueError): sync.validate_results(lines,[request],root)

    def test_conflicting_patches(self):
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder); request,path=self.request(root); other={**request,'custom_id':'badge'}
            second=json.loads(self.result(other,path))
            text=second['response']['body']['output'][0]['content'][0]
            proposal=json.loads(text['text']);proposal['files'][0]['content']='different'
            text['text']=json.dumps(proposal)
            lines=self.result(request,path)+'\n'+json.dumps(second)
            with self.assertRaisesRegex(ValueError,'CONFLICTING'):
                sync.validate_results(lines,[request,other],root)

    def test_month_and_pending_reservation(self):
        self.state['costs']=[{'month':'2026-10','usd':4.99}]
        self.state['pending']={'reserved_usd':.02}
        with self.assertRaisesRegex(ValueError,'BUDGET'):
            sync.budget_reservation(self.config,self.state,[],sync.date(2026,10,13))

    def test_unknown_acceptance_never_resubmits(self):
        self.state['pending']={'phase':'reserved'}
        with self.assertRaisesRegex(ValueError,'ACCEPTANCE_UNKNOWN'):
            sync.collect(self.config,self.state,lambda state:None,None,Path('.'))

    def test_retry_saves_successful_results_before_a_new_upload(self):
        completed={'button': {'files': [], 'summaries': ['already verified']}}
        requests=[{'custom_id':'badge','body':{'model':self.config['models']['simple']['id'],'max_output_tokens':100}}]
        saved=[]
        class Api:
            def upload(_, payload):
                self.assertEqual(saved[0]['pending']['completed_proposals'],completed)
                raise RuntimeError('upload interrupted')
        with tempfile.TemporaryDirectory() as folder:
            with self.assertRaisesRegex(RuntimeError,'interrupted'):
                sync.submit(self.config,self.state,{requests[0]['body']['model']:requests},'a'*40,
                    lambda state:saved.append(json.loads(json.dumps(state))),Api(),Path(folder),completed)
        self.assertEqual(self.state['pending']['completed_proposals'],completed)

    def test_wait_does_not_sleep(self):
        self.state['pending']={'phase':'submitted','jobs':[{'batch_id':'batch-1'}]}
        class MockApi:
            def request(_,method,path): return {'status':'in_progress'}
        self.assertEqual(sync.collect(self.config,self.state,lambda state:None,MockApi(),Path('.')),'waiting')

    def test_failed_request_preserves_success_and_cost(self):
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder);request,path=self.request(root);other={**request,'custom_id':'badge'}
            model=request['body']['model']
            self.state['pending']={'target':'a'*40,'phase':'submitted','month':'2026-10','reserved_usd':.01,
                'jobs':[{'model':model,'batch_id':'batch-1','requests':[request,other]}]}
            lines=self.result(request,path)+'\n'+json.dumps({'custom_id':'badge','error':{'code':'batch_expired'}})
            class MockApi:
                def request(_,method,path):
                    return {'status':'expired','output_file_id':'file-1'} if path.startswith('batches/') else lines
            with self.assertRaises(ValueError):
                sync.collect(self.config,self.state,lambda state:None,MockApi(),root/'out',root)
            pending=self.state['pending']
            self.assertIn('button',pending['completed_proposals'])
            self.assertEqual([r['custom_id'] for r in pending['failed_requests']],['badge'])
            self.assertEqual(self.state['costs'][0]['usd'],.01)
            self.assertTrue(pending['cost_recorded'])


if __name__=='__main__': unittest.main()
