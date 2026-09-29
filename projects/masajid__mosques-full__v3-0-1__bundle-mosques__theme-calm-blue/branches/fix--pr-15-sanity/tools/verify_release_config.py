#!/usr/bin/env python3
import json
import os
import pathlib
import sys

root = pathlib.Path(__file__).resolve().parent.parent
release_file = root / 'release.json'

if not release_file.exists():
    raise SystemExit('Missing release.json for this build bundle')

with release_file.open('r', encoding='utf-8') as fh:
    cfg = json.load(fh)

if cfg.get('display_name') != 'WolFox':
    raise SystemExit('Release metadata is not a WolFox build')

if os.environ.get('GITHUB_REF_NAME') and cfg.get('branch') and os.environ['GITHUB_REF_NAME'] != cfg['branch']:
    raise SystemExit(f'Build is targeting {os.environ.get("GITHUB_REF_NAME")} but release.json expects {cfg["branch"]}')

required = {
    'WOLFOX_VERSION': 'version',
    'WOLFOX_EDITION': 'edition',
    'WOLFOX_PROFILE': 'profile',
    'WOLFOX_INTERFACE_VARIANT': 'interface_variant',
    'WOLFOX_TARGET_BUNDLE_IDS': 'bundle',
    'WOLFOX_PROJECT_BUNDLE_ID': 'bundle',
}

for key, field in required.items():
    env_value = os.environ.get(key)
    if env_value is None:
        raise SystemExit(f'Missing required environment variable: {key}')
    if str(cfg.get(field)) != str(env_value):
        raise SystemExit(f'{key} mismatch: env={env_value} release.json={cfg.get(field)}')

if not os.environ.get('WOLFOX_PROJECT_KEY'):
    raise SystemExit('Missing project key')

workflow_dir = root / '.github' / 'workflows'
workflows = sorted(workflow_dir.glob('*.yml'))
if workflows and workflows[0] != workflow_dir / 'build.yml':
    raise SystemExit('This release branch expects a single workflow: build.yml')

print('Release branch, target, edition and version verified')
