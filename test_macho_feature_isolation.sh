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

# otool is provided by the macOS runner. Keep the check explicit so a build
# cannot silently pass with a framework that the selected edition must not load.
command -v otool >/dev/null 2>&1 || { echo "❌ otool مطلوب لفحص Mach-O"; exit 1; }
linked="$(otool -L "$dylib")"
forbidden_common=(CoreBluetooth AdSupport CoreMedia CoreVideo)
case "$profile" in
  location)
    forbidden=("${forbidden_common[@]}")
    ;;
  location-id)
    forbidden=(CoreBluetooth CoreMedia CoreVideo)
    ;;
  location-id-bluetooth)
    forbidden=(AdSupport CoreMedia CoreVideo)
    ;;
  *) echo "❌ Profile غير معروف: $profile"; exit 1 ;;
esac
for framework in "${forbidden[@]}"; do
  if grep -q "${framework}.framework" <<<"$linked"; then
    echo "❌ $profile يربط إطارًا غير مسموح: $framework"
    exit 1
  fi
done

# The feature source is compiled with dead stripping, but these framework
# checks are the release gate: they verify the actual Mach-O load commands.
echo "✅ Mach-O isolation passed: profile=$profile file=$dylib"
