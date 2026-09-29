#!/usr/bin/env python3
import json, os, pathlib
root=pathlib.Path(__file__).resolve().parent.parent
c=json.loads((root/'release.json').read_text())
assert c['display_name']=='WolFox'
ref_name=os.environ.get('GITHUB_REF_NAME', c['branch'])
assert ref_name==c['branch'], 'Build only the configured branch'
defaults={
    'WOLFOX_VERSION':str(c['version']),
    'WOLFOX_EDITION':str(c['edition']),
    'WOLFOX_PROFILE':str(c['profile']),
    'WOLFOX_INTERFACE_VARIANT':str(c['interface_variant']),
    'WOLFOX_TARGET_BUNDLE_IDS':str(c['bundle']),
    'WOLFOX_PROJECT_BUNDLE_ID':str(c['bundle']),
}
for key,field in {'WOLFOX_VERSION':'version','WOLFOX_EDITION':'edition','WOLFOX_PROFILE':'profile','WOLFOX_INTERFACE_VARIANT':'interface_variant','WOLFOX_TARGET_BUNDLE_IDS':'bundle','WOLFOX_PROJECT_BUNDLE_ID':'bundle'}.items():
    value=os.environ.get(key, defaults[key])
    assert value==str(c[field]), key
if os.environ.get('GITHUB_ACTIONS')=='true':
    assert os.environ.get('WOLFOX_PROJECT_KEY'), 'Missing project key'
assert list((root/'.github/workflows').glob('*.yml'))==[root/'.github/workflows/build.yml'], 'One independent workflow per release branch'
print('Release branch, target, edition and version verified')
