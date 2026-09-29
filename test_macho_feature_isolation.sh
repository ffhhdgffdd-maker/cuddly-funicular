#!/usr/bin/env bash
set -euo pipefail

profile="${1:?usage: $0 <location|location-id|location-id-bluetooth> <dylib>}"
dylib="${2:?usage: $0 <profile> <dylib>}"
[[ -f "$dylib" ]] || { echo "❌ dylib غير موجود: $dylib"; exit 1; }

file_output="$(file -b "$dylib")"
case "$file_output" in
  *Mach-O*) ;;
  *) echo "❌ الناتج ليس Mach-O: $file_output"; exit 1 ;;
esac

# Parse Mach-O load commands directly so the gate works on the Ubuntu cross-
# compile runner as well as macOS, without depending on otool.
mapfile -t linked < <(python3 - "$dylib" <<'PY'
import struct, sys

path = sys.argv[1]
data = open(path, 'rb').read()

def dylibs(blob, base=0):
    magic = struct.unpack_from('<I', blob, base)[0]
    if magic == 0xfeedfacf:  # MH_MAGIC_64
        ncmds = struct.unpack_from('<I', blob, base + 16)[0]
        cursor = base + 32
        for _ in range(ncmds):
            cmd, size = struct.unpack_from('<II', blob, cursor)
            if size < 8 or cursor + size > len(blob):
                raise SystemExit('invalid Mach-O load command')
            # LC_LOAD_DYLIB and its weak/reexport/upward/lazy variants.
            if cmd in {0xc, 0x18, 0x1f, 0x20, 0x23}:
                if size < 24:
                    raise SystemExit('invalid dylib load command')
                name_offset = struct.unpack_from('<I', blob, cursor + 8)[0]
                end = blob.find(b'\0', cursor + name_offset, cursor + size)
                if end < 0:
                    raise SystemExit('invalid dylib name')
                print(blob[cursor + name_offset:end].decode('utf-8', 'replace'))
            cursor += size
        return
    if magic == 0xcafebabe:  # FAT_MAGIC, big-endian table
        count = struct.unpack_from('>I', blob, base + 4)[0]
        for i in range(count):
            _, _, offset, _, _ = struct.unpack_from('>IIIII', blob, base + 8 + i * 20)
            dylibs(blob, offset)
        return
    if magic == 0xcffaedfe:  # FAT_CIGAM_64, uncommon
        raise SystemExit('unsupported 64-bit fat byte order')
    raise SystemExit(f'unsupported Mach-O magic: 0x{magic:08x}')

dylibs(data)
PY
)

forbidden_common=(CoreBluetooth AdSupport CoreMedia CoreVideo)
case "$profile" in
  location) forbidden=("${forbidden_common[@]}") ;;
  location-id) forbidden=(CoreBluetooth CoreMedia CoreVideo) ;;
  location-id-bluetooth) forbidden=(CoreMedia CoreVideo) ;;
  *) echo "❌ Profile غير معروف: $profile"; exit 1 ;;
esac
for framework in "${forbidden[@]}"; do
  for linked_name in "${linked[@]}"; do
    if [[ "$linked_name" == *"${framework}.framework"* ]]; then
      echo "❌ $profile يربط إطارًا غير مسموح: $framework"
      exit 1
    fi
  done
done

echo "✅ Mach-O isolation passed: profile=$profile file=$dylib"
