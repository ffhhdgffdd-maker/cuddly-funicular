import http.cookiejar
import json
import os
from pathlib import Path
import re
import shutil
import socket
import subprocess
import tempfile
import time
from types import SimpleNamespace
import unittest
import urllib.error
import urllib.parse
import urllib.request
from fixtures import ipa, macho


def multipart(fields, files=()):
    boundary = 'WolFoxTestBoundary968642'
    chunks = []
    for name, value in fields.items():
        chunks.append(f'--{boundary}\r\nContent-Disposition: form-data; name="{name}"\r\n\r\n{value}\r\n'.encode())
    for field, name, raw in files:
        chunks.append(f'--{boundary}\r\nContent-Disposition: form-data; name="{field}"; filename="{name}"\r\nContent-Type: application/octet-stream\r\n\r\n'.encode() + raw + b'\r\n')
    chunks.append(f'--{boundary}--\r\n'.encode())
    return b''.join(chunks), 'multipart/form-data; boundary=' + boundary


class HTTPTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        php = os.environ.get('PHP_BIN', shutil.which('php') or '')
        if not php: raise RuntimeError('PHP is required to verify the private portal.')
        cls.temp = tempfile.TemporaryDirectory()
        cls.root = Path(cls.temp.name)/'portal'
        shutil.copytree(Path(__file__).parents[1], cls.root, ignore=shutil.ignore_patterns('config.local.php', '__pycache__', 'storage'))
        (cls.root/'storage').mkdir()
        setup = "<?php return ['https_only'=>false,'username'=>'tester','password_hash'=>password_hash('test-password-983', PASSWORD_DEFAULT),'python'=>" + repr(shutil.which('python3')) + "];"
        (cls.root/'config.local.php').write_text(setup)
        with socket.socket() as sock:
            sock.bind(('127.0.0.1', 0)); port = sock.getsockname()[1]
        cls.base = f'http://127.0.0.1:{port}/index.php'
        cls.log = open(cls.root/'server.log', 'w')
        cls.server = subprocess.Popen([php, '-n', '-d', 'upload_max_filesize=512M', '-d', 'post_max_size=800M', '-S', f'127.0.0.1:{port}', '-t', str(cls.root/'public')], stdout=cls.log, stderr=cls.log)
        for _ in range(50):
            try:
                urllib.request.urlopen(cls.base, timeout=1).read(); break
            except OSError: time.sleep(.1)
        else: raise RuntimeError('PHP test server failed to start')

    @classmethod
    def tearDownClass(cls):
        cls.server.terminate(); cls.server.wait(timeout=5); cls.log.close(); cls.temp.cleanup()

    def client(self): return urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))

    def request(self, client, query='', fields=None, files=()):
        data, headers = None, {}
        if fields is not None:
            data, content_type = multipart(fields, files); headers['Content-Type'] = content_type
        request = urllib.request.Request(self.base+query, data=data, headers=headers)
        try: response = client.open(request, timeout=30)
        except urllib.error.HTTPError as exc: response = exc
        with response:
            raw = response.read()
            return SimpleNamespace(status=response.status, headers=response.headers, read=lambda: raw)

    def token(self, client):
        return re.search(r'name="csrf" value="([a-f0-9]+)"', self.request(client).read().decode()).group(1)

    def test_private_upload_injection_download_delete_and_limits(self):
        client = self.client(); stranger = self.client()
        first = self.request(client)
        self.assertIn('HttpOnly', first.headers.get('Set-Cookie', ''))
        self.assertIn('SameSite=Strict', first.headers.get('Set-Cookie', ''))
        self.assertIn("frame-ancestors 'none'", first.headers['Content-Security-Policy'])
        csrf = self.token(client)
        response = self.request(client, '?action=upload', {'csrf':csrf})
        self.assertEqual(response.status, 401)
        response = self.request(client, '?action=login', {'csrf':'bad','username':'tester','password':'test-password-983'})
        self.assertEqual(response.status, 403)
        page = self.request(client, '?action=login', {'csrf':csrf,'username':'tester','password':'test-password-983'}).read().decode()
        self.assertIn('id="upload-form"', page)
        csrf2 = self.token(client); self.assertNotEqual(csrf, csrf2)
        src = ipa(self.root/'sample.ipa').read_bytes()
        response = self.request(client, '?action=upload', {'csrf':csrf2}, [('ipa','sample.ipa',src)])
        self.assertEqual(response.status, 200, response.read().decode() if response.status != 200 else '')
        result = json.load(response); self.assertEqual(result['mode'], 'unchanged')
        download = '?action=download&id=' + result['id']
        self.assertEqual(self.request(client, download).read(), src)
        self.assertIn('أهلًا بك', self.request(stranger, download).read().decode())
        for path in ['/config.local.php','/storage/job-'+result['id']+'/result.ipa', '/src/bootstrap.php']:
            try: urllib.request.urlopen(self.base.replace('/index.php', path))
            except urllib.error.HTTPError as exc: self.assertEqual(exc.code, 404)
            else: self.fail('Private file was exposed')
        response = self.request(client, '?action=upload', {'csrf':csrf2}, [('ipa','sample.ipa',src), ('libraries[]','Test.dylib',macho(6))])
        injected = json.load(response); self.assertTrue(injected['ok'], injected)
        self.assertEqual(injected['mode'], 'injected_unsigned')
        self.assertNotEqual(self.request(client, '?action=download&id='+injected['id']).read(), src)
        bad = self.request(client, '?action=upload', {'csrf':csrf2, 'url':'https://127.0.0.1/private.ipa'})
        self.assertEqual(bad.status, 400); self.assertFalse(json.load(bad)['ok'])
        bad = self.request(client, '?action=upload', {'csrf':csrf2}, [('ipa','broken.ipa',b'not an archive')])
        self.assertEqual(bad.status, 400)
        delete = self.request(client, '?action=delete', {'csrf':csrf2, 'id':result['id']})
        self.assertEqual(delete.status, 200)
        self.assertEqual(self.request(client, download).status, 404)
        job = self.root/'storage'/('job-'+injected['id']); os.utime(job, (time.time()-90000, time.time()-90000))
        self.assertEqual(self.request(client, '?action=download&id='+injected['id']).status, 404)
        self.request(client, '?action=logout', {'csrf':csrf2})
        self.assertNotIn('id="upload-form"', self.request(client).read().decode())
        csrf3 = self.token(client)
        for _ in range(8): self.request(client, '?action=login', {'csrf':csrf3,'username':'tester','password':'wrong'})
        blocked = self.request(client, '?action=login', {'csrf':csrf3,'username':'tester','password':'test-password-983'}).read().decode()
        self.assertIn('محاولات كثيرة', blocked)


if __name__ == '__main__': unittest.main()
