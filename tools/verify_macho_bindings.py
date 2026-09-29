#!/usr/bin/env python3
"""Reject arm64 dylibs with unresolved flat-namespace/runtime lookups.

System imports must bind to a linked dylib; WolFox classes must be defined in
the output. This catches the successful-but-unloadable location builds.
"""
from pathlib import Path
import struct
import sys


def dynamic_imports(data):
    if len(data) < 32:
        raise ValueError("truncated Mach-O header")
    magic, cpu, _, kind, count, command_bytes, _, _ = struct.unpack_from("<8I", data)
    if magic != 0xFEEDFACF or cpu != 0x0100000C or kind != 6:
        raise ValueError("expected an arm64 Mach-O dylib")
    command_end = 32 + command_bytes
    if command_end > len(data):
        raise ValueError("truncated load commands")
    offset, symbols = 32, None
    for _ in range(count):
        if offset + 8 > command_end:
            raise ValueError("invalid load command")
        cmd, size = struct.unpack_from("<II", data, offset)
        if size < 8 or offset + size > command_end:
            raise ValueError("invalid load command size")
        if cmd == 2:  # LC_SYMTAB
            if size < 24:
                raise ValueError("truncated symbol table command")
            symbols = struct.unpack_from("<4I", data, offset + 8)
        offset += size
    if symbols is None:
        raise ValueError("missing symbol table")
    symoff, nsyms, stroff, strsize = symbols
    if symoff + nsyms * 16 > len(data) or stroff + strsize > len(data):
        raise ValueError("truncated symbol/string table")
    strings = data[stroff:stroff + strsize]
    unresolved = []
    for i in range(nsyms):
        index, kind, _, desc, value = struct.unpack_from("<IBBHQ", data, symoff + i * 16)
        if kind & 0xE0 or kind & 0x0E or value:  # STAB, defined or common
            continue
        if desc >> 8 not in (0, 254, 255):  # defined library ordinal
            continue
        if index >= len(strings) or b"\0" not in strings[index:]:
            raise ValueError("invalid symbol name")
        unresolved.append(strings[index:].split(b"\0", 1)[0].decode("utf-8"))
    return unresolved


def main():
    if len(sys.argv) < 2:
        raise SystemExit("usage: verify_macho_bindings.py file.dylib [...]")
    failed = False
    for name in sys.argv[1:]:
        try:
            imports = dynamic_imports(Path(name).read_bytes())
            if imports:
                raise ValueError("unresolved runtime imports: " + ", ".join(imports))
            print(f"PASS {Path(name).name}: all imports bind to linked libraries")
        except (OSError, ValueError, struct.error) as error:
            print(f"FAIL {Path(name).name}: {error}", file=sys.stderr)
            failed = True
    return int(failed)


if __name__ == "__main__":
    sys.exit(main())
