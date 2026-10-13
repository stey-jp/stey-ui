"""Exercise detection through proposal verification and PR publication locally.

All network/billing endpoints are fakes; the test explicitly does not claim a
successful live OpenAI call or a real upstream synchronization.
"""
import json
import io
from contextlib import redirect_stdout
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
import sync_engine as engine
import sync as cli


class EndToEndTests(unittest.TestCase):
    def test_batch_submission_collection_and_verified_pr(self):
        config=engine.read_json(engine.ROOT/'upstream/config.json')
        state=engine.new_state(config);target='a'*40;base='b'*40
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);path='packages/stey_ui_modern/lib/src/example.dart'
            (root/path).parent.mkdir(parents=True);(root/path).write_text('const value = 1;')
            original=(root/path).read_text()
            request={'custom_id':'example','body':{'model':config['models']['simple']['id'],'max_output_tokens':200,
                'input':json.dumps({'local_files':{path:{'sha256':engine.digest(original),'content':original}}})}}
            proposal={'summary':'Update upstream value','files':[{'path':path,'base_sha256':engine.digest(original),'content':'const value = 2;'}]}
            result=json.dumps({'custom_id':'example','response':{'status_code':200,'body':{'status':'completed',
                'usage':{'input_tokens':120,'output_tokens':80},'output':[{'type':'message','content':[{'type':'output_text','text':json.dumps(proposal)}]}]}}})
            persisted=[]
            class Api:
                def upload(_,payload):
                    self.assertTrue(persisted);return {'id':'file-input'}
                def request(_,method,path,body=None):
                    if method=='POST':return {'id':'batch-1'}
                    if path.startswith('batches/'):return {'status':'completed','output_file_id':'file-output'}
                    return result
            engine.submit(config,state,{request['body']['model']:[request]},target,
                lambda value:persisted.append(json.loads(json.dumps(value))),Api(),root/'requests')
            out=root/'proposal'
            self.assertEqual(engine.collect(config,state,lambda value:None,Api(),out,root),'results-ready')
            self.assertEqual(state['costs'][0]['actual_usd'],.000022)
            context={'target':target,'base_sha':base};engine.write_json(out/'context.json',context)
            engine.write_json(out/'verification.json',{'success':True,'target':target,'base_sha':base,
                'proposal_sha256':engine.digest(json.dumps(state['pending']['proposal'],sort_keys=True))})
            commands=[]
            def run(*args,**kwargs):
                commands.append(args)
                if args[:3]==('git','status','--porcelain'):return ''
                if args[:2]==('git','rev-parse'):return base
                if args[:2]==('git','ls-remote'):return ''
                return ''
            class Store:
                repo='stey-jp/stey-ui'
                def persist(_,value): persisted.append(json.loads(json.dumps(value)))
            def github(path,method='GET',body=None):
                return {'number':9,'html_url':'https://github.com/stey-jp/stey-ui/pull/9'} if method=='POST' else []
            with patch.object(cli,'ROOT',root),patch.object(cli,'run',run),patch.object(cli,'gh',github),patch.object(cli,'safe_path',lambda path:engine.safe_path(path,root)):
                with redirect_stdout(io.StringIO()):
                    cli.create_pr(config,state,Store(),out)
            self.assertEqual((root/path).read_text(),'const value = 2;')
            self.assertEqual(state['pending']['phase'],'pr-open')
            self.assertIsNone(state['synchronized_sha'])
            self.assertTrue(any(command[:2]==('git','push') for command in commands))
            self.assertFalse(any('--force' in command or 'merge' in command for command in commands))

    def test_publication_rejects_unverified_proposal(self):
        config=engine.read_json(engine.ROOT/'upstream/config.json')
        state=engine.new_state(config);state['pending']={'phase':'results-ready','target':'a'*40}
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);engine.write_json(root/'verification.json',{'success':False})
            with self.assertRaisesRegex(ValueError,'VERIFICATION_NOT_SUCCESSFUL'):
                cli.create_pr(config,state,None,root)


if __name__=='__main__':unittest.main()
