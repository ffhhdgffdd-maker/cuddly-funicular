#!/usr/bin/env python3
"""Validate the consolidated project catalog and archived branch snapshots."""
from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECTS = ROOT / 'projects'
INDEX = PROJECTS / 'index.json'
CONFIG_FIELDS = (
    'slug', 'profile', 'version', 'edition', 'interface_variant',
    'bundle', 'product', 'theme', 'color',
)


def slug(value: object) -> str:
    return re.sub(r'[^a-z0-9]+', '-', str(value or '').lower()).strip('-') or 'project'


def expected_folder(config: dict | None, branch: str) -> str:
    if not config:
        branch_part = re.sub(r'[^a-zA-Z0-9]+', '--', branch).strip('-')
        return 'branch__' + slug(branch_part)
    parts = [slug(config.get('slug'))]
    if config.get('profile'):
        parts.append(slug(config['profile']))
    elif config.get('edition'):
        parts.append(slug(config['edition']))
    if config.get('version'):
        parts.append('v' + slug(config['version']))
    variant = config.get('interface_variant')
    if variant not in (None, '', 0, '0'):
        parts.append('interface-v' + slug(variant))
    bundle = str(config.get('bundle') or '')
    if bundle:
        bundle_slug = 'mosques' if 'mosques' in bundle else 'control' if 'tahakom' in bundle else slug(bundle)
        parts.append('bundle-' + bundle_slug)
    theme = str(config.get('theme') or '')
    if theme:
        parts.append('theme-' + slug(theme.split('.')[0]))
    return '__'.join(parts)


def tree_digest(path: Path) -> tuple[int, str]:
    entries = [x for x in path.rglob('*') if x.is_file()]
    entries.sort(key=lambda x: x.relative_to(path).as_posix())
    digest = hashlib.sha256()
    for item in entries:
        relative = item.relative_to(path).as_posix()
        digest.update(relative.encode('utf-8') + b'\0')
        digest.update(hashlib.sha256(item.read_bytes()).digest())
        digest.update(b'\n')
    return len(entries), digest.hexdigest()


def config_signature(config: dict | None) -> str | None:
    if config is None:
        return None
    return json.dumps({key: config.get(key, '') for key in CONFIG_FIELDS},
                      sort_keys=True, ensure_ascii=False, separators=(',', ':'))


def main() -> int:
    if not INDEX.is_file():
        raise SystemExit(f'Missing project index: {INDEX}')
    index = json.loads(INDEX.read_text(encoding='utf-8'))
    projects = index.get('projects', [])
    if index.get('project_count') != len(projects):
        raise SystemExit('project_count does not match projects[]')
    if len({p['project_folder'] for p in projects}) != len(projects):
        raise SystemExit('Duplicate project_folder in index')

    seen_branches: set[str] = set()
    seen_project_configs: dict[str, str] = {}
    files_checked = 0
    for entry in projects:
        folder = entry['project_folder']
        if '/' in folder or '\\' in folder or folder in ('', '.', '..'):
            raise SystemExit(f'Unsafe project folder name: {folder!r}')
        project_dir = PROJECTS / folder
        if not project_dir.is_dir():
            raise SystemExit(f'Missing project directory: {folder}')
        project_json_path = project_dir / 'PROJECT.json'
        if not project_json_path.is_file():
            raise SystemExit(f'Missing PROJECT.json: {folder}')
        project_json = json.loads(project_json_path.read_text(encoding='utf-8'))
        if project_json != entry:
            raise SystemExit(f'PROJECT.json does not match index entry: {folder}')
        source_branches = entry.get('source_branches', [])
        if not source_branches:
            raise SystemExit(f'Project has no source branches: {folder}')

        config = entry.get('release_config')
        signature = config_signature(config)
        if config:
            prior = seen_project_configs.setdefault(signature, folder)
            if prior != folder:
                raise SystemExit(f'Duplicate configuration split across folders: {prior}, {folder}')
        for branch in source_branches:
            name = branch['branch']
            if name in seen_branches:
                raise SystemExit(f'Duplicate source branch in project catalog: {name}')
            seen_branches.add(name)
            if expected_folder(config, name) != folder:
                raise SystemExit(f'Project folder is not derived from configuration: {folder} ({name})')
            branch_dir = project_dir / 'branches' / branch['folder']
            if not branch_dir.is_dir():
                raise SystemExit(f'Missing source branch snapshot: {name} -> {branch_dir}')
            count, digest = tree_digest(branch_dir)
            if count != branch['source_file_count']:
                raise SystemExit(f'Source file count mismatch for {name}: {count} != {branch["source_file_count"]}')
            if digest != branch['source_tree_sha256']:
                raise SystemExit(f'Source tree SHA-256 mismatch for {name}')
            files_checked += count
            archived_config_path = branch_dir / 'release.json'
            if config is not None:
                if not archived_config_path.is_file():
                    raise SystemExit(f'Configured source is missing release.json: {name}')
                archived_config = json.loads(archived_config_path.read_text(encoding='utf-8'))
                if config_signature(archived_config) != signature:
                    raise SystemExit(f'Grouped release config mismatch for source branch {name}')

    if len(seen_branches) != 44:
        raise SystemExit(f'Expected 44 archived source branches, found {len(seen_branches)}')
    if len(projects) != 32:
        raise SystemExit(f'Expected 32 project folders, found {len(projects)}')
    print(f'OK: {len(projects)} project folders, {len(seen_branches)} source branches, {files_checked} files; all source-tree hashes match.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
