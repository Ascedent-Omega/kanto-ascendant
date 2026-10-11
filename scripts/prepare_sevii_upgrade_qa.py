#!/usr/bin/env python3
"""Build an isolated, unmodified KASC-base runtime for save-upgrade QA."""
import argparse
import hashlib
import io
import json
from pathlib import Path
import subprocess
import tarfile

p = argparse.ArgumentParser()
p.add_argument('--engine', type=Path, required=True)
p.add_argument('--output', type=Path, required=True)
p.add_argument('--base', default='b30cfad48')
a = p.parse_args()
root = Path(__file__).resolve().parents[1]
commit = subprocess.check_output(['git', 'rev-parse', a.base], cwd=root, text=True).strip()
dest = a.output.resolve()
dest.mkdir(parents=True, exist_ok=False)
for entry in a.engine.resolve().iterdir():
    if entry.name not in {'mods', '.git'}:
        (dest / entry.name).symlink_to(entry, target_is_directory=entry.is_dir())
mod = dest / 'mods' / 'kanto_ascendant'
mod.mkdir(parents=True)
archive = subprocess.check_output(['git', 'archive', '--format=tar', commit], cwd=root)
with tarfile.open(fileobj=io.BytesIO(archive)) as tar:
    # Extraction is confined to this newly created QA directory.
    for member in tar.getmembers():
        path = Path(member.name)
        assert not path.is_absolute() and '..' not in path.parts
        assert member.isfile() or member.isdir(), 'Unexpected Git archive link or special file: ' + member.name
    tar.extractall(mod)
added = 0
for directory in ('assets', 'optional_pokemon', 'lib'):
    source = a.engine.resolve() / 'mods' / 'kanto_ascendant' / directory
    for entry in source.rglob('*'):
        if not entry.is_file() or 'sevii_local' in entry.parts:
            continue
        target = mod / directory / entry.relative_to(source)
        if not target.exists():
            target.parent.mkdir(parents=True, exist_ok=True)
            target.symlink_to(entry.resolve())
            added += 1
hashes = {}
for name in ('main.lua', 'event_archive.lua', 'gift_codes.lua', 'generation_evidence.lua'):
    wanted = subprocess.check_output(['git', 'show', commit + ':' + name], cwd=root)
    assert (mod / name).read_bytes() == wanted
    hashes[name] = hashlib.sha256(wanted).hexdigest()
assert not (mod / 'sevii_expedition.lua').exists()
(dest.parent / 'upgrade-base-runtime.json').write_text(json.dumps({
    'commit': commit, 'engine': str(dest), 'baseCodeHashes': hashes,
    'additionalAssetFiles': added,
    'scope': 'Tracked mod files from the unmodified base commit; shared engine and missing optional assets from isolated QA. No player installation or save accessed.'
}, indent=2) + '\n')
print('SEVII_UPGRADE_BASE_READY', commit, dest, added, 'additional asset files')
