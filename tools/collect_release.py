#!/usr/bin/env python3
"""Verify both DEBs against the built arm64 dylib and collect exact-commit source."""
import hashlib, json, os, pathlib, re, shutil, struct, subprocess, tempfile
root = pathlib.Path(__file__).resolve().parent.parent
os.chdir(root)
cfg = json.loads((root/'release.json').read_text())
product, version, bundle = cfg['product'], cfg['version'], cfg['bundle']
out = root/'release'; out.mkdir(exist_ok=True)
dylib = root/f'{product}.dylib'
magic, cpu = struct.unpack('<II', dylib.read_bytes()[:8])
assert magic == 0xfeedfacf and cpu == 0x100000c, 'Expected arm64 Mach-O'
digest = hashlib.sha256(dylib.read_bytes()).hexdigest()
for mode in ('Rootful', 'Rootless'):
    deb = root/f'{product}_v{version}_iOS15.8-27.0_{mode}.deb'
    assert subprocess.check_output(['dpkg-deb','-f',str(deb),'Version'],text=True).strip() == version
    assert subprocess.check_output(['dpkg-deb','-f',str(deb),'Name'],text=True).strip() == 'WolFox'
    with tempfile.TemporaryDirectory() as tmp:
        dest = pathlib.Path(tmp)
        subprocess.run(['dpkg-deb','-x',str(deb),tmp],check=True)
        prefix = dest/('var/jb' if mode == 'Rootless' else '')/'Library/MobileSubstrate/DynamicLibraries'
        assert hashlib.sha256((prefix/f'{product}.dylib').read_bytes()).hexdigest() == digest
        plist = (prefix/f'{product}.plist').read_text()
        assert re.findall(r'"([^"]+)"', plist) == [bundle], 'Filter must target only this host'
    shutil.copy2(deb,out/deb.name)
shutil.copy2(dylib,out/dylib.name)
for name in ('release.json','WOLFOX_REVIEW_AR.md','BRANCHES_AR.md'):
    shutil.copy2(root/name,out/name)
commit = subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip()
info = {'commit':commit,'run':os.environ.get('GITHUB_RUN_ID'),'branch':cfg['branch'],'version':version,'target':bundle,'device_tested':False}
(out/'BUILD_INFO.json').write_text(json.dumps(info,ensure_ascii=False,indent=2)+'\n')
subprocess.run(['git','archive','--format=zip',f'--output={out}/WolFox-Source.zip',commit],check=True)
checks = [f'{hashlib.sha256(f.read_bytes()).hexdigest()}  {f.name}' for f in sorted(out.iterdir()) if f.is_file() and f.name!='SHA256SUMS.txt']
(out/'SHA256SUMS.txt').write_text('\n'.join(checks)+'\n')
print(f'Verified {product} {version}, arm64, both DEBs, single bundle and exact source {commit}')
