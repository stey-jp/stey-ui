"""Local production-like demo server with compression and conditional caching."""
import argparse
import gzip
import hashlib
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


class Handler(SimpleHTTPRequestHandler):
    cross_origin_isolated = False

    def log_message(self, format, *args):
        pass

    def do_GET(self):
        path=Path(self.translate_path(self.path))
        if path.is_dir(): path=path/'index.html'
        if not path.is_file(): return super().do_GET()
        data=path.read_bytes()
        tag='"'+hashlib.sha256(data).hexdigest()+'"'
        if self.headers.get('If-None-Match')==tag:
            self.send_response(304);self.send_header('ETag',tag);self.end_headers();return
        mime=self.guess_type(str(path))
        compress=('gzip' in self.headers.get('Accept-Encoding','') and
                  (mime.startswith('text/') or path.suffix in ('.js','.json','.wasm','.map')))
        if compress:data=gzip.compress(data)
        self.send_response(200)
        self.send_header('Content-Type',mime)
        self.send_header('Content-Length',str(len(data)))
        self.send_header('ETag',tag)
        self.send_header('Cache-Control','public, max-age=31536000, immutable' if
                         path.name.startswith(('canvaskit','skwasm')) or path.name.endswith(('.ttf','.otf','.png')) else 'no-cache')
        self.send_header('X-Content-Type-Options','nosniff')
        self.send_header('Vary','Accept-Encoding')
        if self.cross_origin_isolated:
            self.send_header('Cross-Origin-Opener-Policy','same-origin')
            self.send_header('Cross-Origin-Embedder-Policy','credentialless')
        if compress:self.send_header('Content-Encoding','gzip')
        self.end_headers();self.wfile.write(data)


if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--port',type=int,default=8766)
    parser.add_argument('--directory',default='apps/demo/build/web')
    parser.add_argument('--cross-origin-isolated',action='store_true');args=parser.parse_args()
    Handler.cross_origin_isolated=args.cross_origin_isolated
    from functools import partial
    server=ThreadingHTTPServer(('127.0.0.1',args.port),partial(Handler,directory=args.directory))
    print('{"port":'+str(server.server_port)+'}',flush=True)
    server.serve_forever()
