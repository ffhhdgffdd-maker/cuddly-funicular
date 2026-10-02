#!/usr/bin/env python3
import json, os, pathlib
root=pathlib.Path(__file__).resolve().parent.parent
c=json.loads((root/'release.json').read_text())
assert c['display_name']=='WolFox'
ref=os.environ.get('GITHUB_REF_NAME','')
event=os.environ.get('GITHUB_EVENT_NAME','')
assert ref==c['branch'] or (ref.startswith('v') and c['branch']=='main') or event=='pull_request', 'Build only main, a version tag, or a pull request'
for key,field in {'WOLFOX_VERSION':'version','WOLFOX_EDITION':'edition','WOLFOX_PROFILE':'profile','WOLFOX_INTERFACE_VARIANT':'interface_variant','WOLFOX_PROJECT_BUNDLE_ID':'bundle'}.items():
    assert os.environ[key]==str(c[field]), key
target_expected = str(c.get('target_bundles', c['bundle']))
assert os.environ['WOLFOX_TARGET_BUNDLE_IDS'] == target_expected, 'WOLFOX_TARGET_BUNDLE_IDS'
assert os.environ.get('WOLFOX_PROJECT_KEY'), 'Missing project key'
assert list((root/'.github/workflows').glob('*.yml'))==[root/'.github/workflows/build.yml'], 'One independent workflow per release branch'
print(f"Release config verified: {c['edition']} {c['version']} on {ref}")
