from pathlib import Path
import plistlib
import struct
import zipfile


def macho(kind=2, encrypted=False, padding=4096, subtype=0):
    segment = struct.pack('<II16sQQQQiiII', 0x19, 152, b'__TEXT', 0, 8192, 0, 8192, 7, 5, 1, 0)
    section = struct.pack('<16s16sQQIIIIIIII', b'__text', b'__TEXT', padding, 8192-padding, padding, 2, 0, 0, 0, 0, 0, 0)
    encryption = struct.pack('<6I', 0x2C, 24, 4096, 4096, int(encrypted), 0)
    signature = struct.pack('<4I', 0x1D, 16, 8100, 92)
    commands = segment + section + encryption + signature
    header = struct.pack('<8I', 0xFEEDFACF, 0x0100000C, subtype, kind, 3, len(commands), 0, 0)
    data = bytearray(8192)
    data[:len(header + commands)] = header + commands
    data[padding:] = b'X' * (8192-padding)
    return bytes(data)


def ipa(path, binary=None, extra=None):
    with zipfile.ZipFile(path, 'w', zipfile.ZIP_DEFLATED) as z:
        z.writestr('Payload/Demo.app/Info.plist', plistlib.dumps({'CFBundleIdentifier':'com.example.demo', 'CFBundleExecutable':'Demo', 'CFBundleName':'تطبيق تجريبي', 'CFBundleShortVersionString':'1.0'}))
        z.writestr('Payload/Demo.app/Demo', binary if binary is not None else macho())
        z.writestr('Payload/Demo.app/_CodeSignature/CodeResources', b'old signature')
        if extra:
            for name, value in extra:
                z.writestr(name, value)
    return Path(path)
