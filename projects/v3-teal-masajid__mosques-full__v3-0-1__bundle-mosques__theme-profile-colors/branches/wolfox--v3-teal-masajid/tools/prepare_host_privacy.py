#!/usr/bin/env python3
"""Prepare a separate host Info.plist copy; never modifies a signed host in place."""
import argparse, pathlib, plistlib
TARGETS = {'sa.gov.moia.mosques-2', 'com.tahakom.mytahakom'}
REQUIRED = {
    'NSBluetoothAlwaysUsageDescription': 'البحث عن أجهزة Bluetooth القريبة عند طلب المستخدم.',
    'NSLocationWhenInUseUsageDescription': 'عرض موقع الجهاز على الخريطة عند استخدام ميزة الموقع.',
    'NSCameraUsageDescription': 'فتح واجهة الكاميرا والتقاط الصور عند طلب المستخدم.',
}
def prepare(info):
    if info.get('CFBundleIdentifier') not in TARGETS:
        raise ValueError('Unexpected host bundle identifier')
    result = dict(info)
    for key, description in REQUIRED.items():
        if not isinstance(result.get(key), str) or not result[key].strip(): result[key] = description
    return result
if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('input', type=pathlib.Path)
    parser.add_argument('output', type=pathlib.Path)
    args = parser.parse_args()
    if args.input.resolve() == args.output.resolve(): parser.error('Use a separate output path, then re-sign the authorized app package.')
    args.output.write_bytes(plistlib.dumps(prepare(plistlib.loads(args.input.read_bytes()))))
