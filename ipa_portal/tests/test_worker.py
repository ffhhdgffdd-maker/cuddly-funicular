import hashlib
import importlib.util
from pathlib import Path
import socket
import stat
import struct
import tempfile
import unittest
from unittest.mock import patch
import zipfile
from fixtures import ipa, macho

spec = importlib.util.spec_from_file_location('worker', Path(__file__).parents[1] / 'bin/ipa_worker.py')
worker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(worker)


class WorkerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def test_unchanged_preserves_every_byte_even_if_encrypted(self):
        src = ipa(self.root/'a.ipa', macho(encrypted=True))
        out = self.root/'b.ipa'
        result = worker.process(src, [], out)
        self.assertEqual(src.read_bytes(), out.read_bytes())
        self.assertEqual(result['mode'], 'unchanged')
        self.assertEqual(result['sha256'], hashlib.sha256(out.read_bytes()).hexdigest())

    def test_injection_changes_commands_preserves_code_and_adds_library(self):
        src = ipa(self.root/'a.ipa'); out = self.root/'b.ipa'
        lib = self.root/'Tool.dylib'; lib.write_bytes(macho(kind=6))
        result = worker.process(src, [lib], out)
        self.assertEqual(result['mode'], 'injected_unsigned')
        with zipfile.ZipFile(out) as z:
            binary = z.read('Payload/Demo.app/Demo')
            details = worker.inspect_binary(binary, 2)[0]
            self.assertIn('@executable_path/Frameworks/WolFoxInject/Tool.dylib', details[3])
            self.assertNotIn(0x1D, [cmd for cmd, _ in details[1]])
            self.assertEqual(binary[4096:], macho()[4096:])
            self.assertEqual(z.read('Payload/Demo.app/Frameworks/WolFoxInject/Tool.dylib'), lib.read_bytes())
            self.assertFalse(any('_CodeSignature' in n for n in z.namelist()))
            self.assertIsNone(z.testzip())

    def test_rejects_encryption_and_no_padding(self):
        for data in [macho(encrypted=True), macho(padding=224)]:
            with self.subTest():
                with self.assertRaises(worker.Invalid): worker.inject_binary(data, ['Tool.dylib'])

    def test_rejects_nonzero_padding_and_malformed_commands(self):
        binary = bytearray(macho()); binary[230] = 17
        with self.assertRaises(worker.Invalid): worker.inject_binary(binary, ['Tool.dylib'])
        binary = bytearray(macho()); struct.pack_into('<I', binary, 36, 0)
        with self.assertRaises(worker.Invalid): worker.inject_binary(binary, ['Tool.dylib'])

    def test_universal_updates_each_slice_without_moving_content(self):
        binary = bytearray(32768)
        struct.pack_into('>II', binary, 0, 0xCAFEBABE, 2)
        struct.pack_into('>5I', binary, 8, worker.ARM64, 0, 4096, 8192, 12)
        struct.pack_into('>5I', binary, 28, worker.ARM64, 2, 16384, 8192, 12)
        binary[4096:12288] = macho()
        binary[16384:24576] = macho(subtype=2)
        result = worker.inject_binary(binary, ['Tool.dylib'])
        self.assertEqual(len(result), len(binary))
        for info in worker.inspect_binary(result, 2): self.assertEqual(len(info[3]), 1)

    def test_archive_rejects_traversal_duplicate_and_symlinks(self):
        link = zipfile.ZipInfo('Payload/Demo.app/link')
        link.external_attr = (stat.S_IFLNK | 0o777) << 16
        for extra in [[('../escape', 'x')], [('Payload/Demo.app/demo', 'x')], [(link, '/etc/passwd')]]:
            src = ipa(self.root/'a.ipa', extra=extra)
            with self.assertRaises(worker.Invalid): worker.process(src, [], self.root/'b.ipa')

    def test_rejects_non_library_and_duplicate_library_names(self):
        src = ipa(self.root/'a.ipa'); lib = self.root/'Tool.dylib'
        lib.write_bytes(macho(kind=2))
        with self.assertRaises(worker.Invalid): worker.process(src, [lib], self.root/'b.ipa')
        lib.write_bytes(macho(kind=6))
        with self.assertRaises(worker.Invalid): worker.process(src, [lib, lib], self.root/'b.ipa')

    def test_private_dns_addresses_are_blocked(self):
        for ip in ['127.0.0.1', '10.0.0.1', '169.254.169.254', '::1', 'fc00::1', '::ffff:127.0.0.1', '224.0.0.1']:
            with self.subTest(ip=ip), patch.object(socket, 'getaddrinfo', return_value=[(0, 0, 0, '', (ip, 443))]):
                with self.assertRaises(worker.Invalid): worker.public_addresses('example.com')

    def test_rejects_library_already_embedded_even_after_rename(self):
        src = ipa(self.root/'a.ipa', extra=[('Payload/Demo.app/K7GPS.dylib', macho(kind=6))])
        renamed = self.root/'Renamed.dylib'; renamed.write_bytes(macho(kind=6))
        with self.assertRaisesRegex(worker.Invalid, 'موجودة أصلًا'):
            worker.process(src, [renamed], self.root/'b.ipa')
        same_name = self.root/'K7GPS.dylib'; same_name.write_bytes(macho(kind=6, subtype=2))
        with self.assertRaisesRegex(worker.Invalid, 'موجودة أصلًا'):
            worker.process(src, [same_name], self.root/'b.ipa')

    def test_rejects_different_bytes_with_same_install_identity(self):
        def identified(raw):
            data = bytearray(raw)
            path = b'/Library/MobileSubstrate/DynamicLibraries/Test.dylib\0'
            size = (24 + len(path) + 7) & ~7
            command = struct.pack('<6I', 0xD, size, 24, 0, 0x10000, 0x10000) + path
            count, old = struct.unpack_from('<II', data, 16)
            data[32+old:32+old+size] = command.ljust(size, b'\0')
            struct.pack_into('<II', data, 16, count+1, old+size)
            return bytes(data)
        src = ipa(self.root/'a.ipa', extra=[('Payload/Demo.app/Old.dylib', identified(macho(kind=6)))])
        lib = self.root/'New.dylib'; lib.write_bytes(identified(macho(kind=6, subtype=2)))
        with self.assertRaisesRegex(worker.Invalid, 'موجودة أصلًا'):
            worker.process(src, [lib], self.root/'b.ipa')

    def test_pinned_public_dns_and_redirect_to_private_blocked(self):
        with patch.object(socket, 'getaddrinfo', return_value=[(0, 0, 0, '', ('8.8.8.8', 443))]):
            self.assertEqual(worker.public_addresses('example.com'), ['8.8.8.8'])
        class Redirect:
            def __init__(self, *args): pass
            def request(self, *args, **kwargs): pass
            def getresponse(self): return self
            status = 302
            def getheader(self, name): return 'https://internal.test/x.ipa'
            def close(self): pass
        with patch.object(worker, 'PinnedHTTPS', Redirect), patch.object(socket, 'getaddrinfo', side_effect=[[(0,0,0,'',('8.8.8.8',443))], [(0,0,0,'',('127.0.0.1',443))]]):
            with self.assertRaises(worker.Invalid): worker.download('https://example.com/a.ipa', self.root/'b.ipa')


if __name__ == '__main__': unittest.main()
