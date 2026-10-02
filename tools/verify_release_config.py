#!/usr/bin/env python3
import json, os, pathlib
root=pathlib.Path(__file__).resolve().parent.parent
c=json.loads((root/'release.json').read_text())
assert c['display_name']=='WolFox'
assert os.environ['GITHUB_REF_NAME']==c['branch'], 'Build only the configured branch'
for key,field in {'WOLFOX_VERSION':'version','WOLFOX_EDITION':'edition','WOLFOX_PROFILE':'profile','WOLFOX_INTERFACE_VARIANT':'interface_variant','WOLFOX_TARGET_BUNDLE_IDS':'bundle','WOLFOX_PROJECT_BUNDLE_ID':'bundle'}.items():
    assert os.environ[key]==str(c[field]), key
assert os.environ.get('WOLFOX_PROJECT_KEY'), 'Missing project key'
assert list((root/'.github/workflows').glob('*.yml'))==[root/'.github/workflows/build.yml'], 'One independent workflow per release branch'
print('Release branch, target, edition and version verified')
