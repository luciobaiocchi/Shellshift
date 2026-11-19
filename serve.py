"""Serve Shellshift locally. Run with python3 serve.py, then open the printed URL."""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

if __name__ == '__main__':
    directory = Path(__file__).resolve().parent
    handler = partial(SimpleHTTPRequestHandler, directory=str(directory))
    with ThreadingHTTPServer(('127.0.0.1', 8000), handler) as server:
        print('Shellshift · http://127.0.0.1:8000', flush=True)
        server.serve_forever()
