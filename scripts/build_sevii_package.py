#!/usr/bin/env python3
"""Materialize the private Sevii runtime; never touch an installed mod or save.

The output is a new, standalone development package, not a completion claim.
ROM-derived maps are local inputs. No ROM or player data is packaged.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ROM_SHA1 = '18a3758ceeef2c77b315144be2c3910d6f1f69fe'
RUNTIME_DIRS = ('assets', 'integrated', 'lib', 'vendor')
STARTUP_FILES = (
    'integrated/ascendant_startup/StartupCard.lua',
    'integrated/ascendant_startup/NativePreload.lua',
    'integrated/ascendant_startup/VascPreload.lua',
    'integrated/ascendant_startup/PreloadQueue.lua',
    'integrated/ascendant_startup/IntroScene.lua',
    'integrated/ascendant_startup/VoxelBall.lua',
    'integrated/ascendant_startup/assets/ascendant-chime.wav',
    'integrated/ascendant_startup/assets/ascendant-start.png',
    'integrated/ascendant_startup/assets/eevee-atlas.png',
    'integrated/ascendant_startup/assets/mew-atlas.png',
    'integrated/ascendant_startup/assets/pikachu-atlas.png',
)
COMPANION = ROOT / 'companion' / 'vasc-kanto-sevii-fly-map-widescreen'
COMPANION_ID = 'vasc_kanto_sevii_fly_map_widescreen'
FORBIDDEN = {'.gba', '.gb', '.gbc', '.sav', '.srm'}


def digest(path):
    h = hashlib.sha256()
    with path.open('rb') as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def load(path):
    return json.loads(path.read_text())


def write(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n')


def safe_relative(name):
    path = PurePosixPath(name)
    if path.is_absolute() or not path.parts or any(p in ('..', '.') for p in path.parts) or '\\' in name:
        raise ValueError('Unsafe package path: ' + name)
    return path


def files_below(root):
    for parent, directories, files in os.walk(root, followlinks=True):
        directories[:] = sorted(d for d in directories if not d.startswith('.'))
        for name in sorted(files):
            if not name.startswith('.'):
                yield Path(parent) / name


def verify(output):
    output = output.resolve()
    receipt = load(output / 'package-manifest.json')
    assert receipt['schema'] == 'kasc.sevii-private-package/v1'
    expected = receipt['files']
    actual = set()
    for parent, directories, files in os.walk(output, followlinks=False):
        for name in directories + files:
            path = Path(parent) / name
            assert not path.is_symlink(), 'Package depends on external symlink: ' + str(path)
        for name in files:
            path = Path(parent) / name
            key = path.relative_to(output).as_posix()
            if key == 'package-manifest.json':
                continue
            assert path.suffix.lower() not in FORBIDDEN, 'ROM/save found: ' + key
            actual.add(key)
    assert actual == set(expected), 'Package file inventory changed'
    for key, record in expected.items():
        path = output / safe_relative(key)
        assert path.stat().st_size == record['bytes'] and digest(path) == record['sha256'], 'Package hash mismatch: ' + key
    mod = output / 'mods' / 'kanto_ascendant'
    assert load(mod / 'manifest.json')['id'] == 'kanto_ascendant'
    for relative in STARTUP_FILES:
        assert (mod / relative).is_file(), 'Missing startup file: ' + relative
    assert load(mod / 'assets/sevii_local/import-report.json')['romSha1'] == ROM_SHA1
    assert (mod / 'assets/sevii_local/habitats.json').is_file()
    companion = output / 'mods' / COMPANION_ID
    if companion.exists():
        assert load(companion / 'manifest.json')['id'] == COMPANION_ID
        master = (companion / 'assets/sevii_fly_map_master.png').read_bytes()
        assert master[:8] == b'\x89PNG\r\n\x1a\n'
        assert int.from_bytes(master[16:20], 'big') == 1672
        assert int.from_bytes(master[20:24], 'big') == 941
    return {'verified': True, 'files': len(expected), 'bytes': sum(r['bytes'] for r in expected.values()),
            'standaloneMod': True, 'companionMap': companion.exists(),
            'status': receipt['status'], 'releaseReady': receipt['releaseReady']}


def build(runtime, output, asset_evidence, candidate=False):
    runtime = runtime.resolve()
    output = output.absolute()
    # Creating a new parent is deliberate: no installation, overwrite or merge.
    if output.exists() or output.is_symlink():
        raise FileExistsError('Choose a new output directory: ' + str(output))
    mod_manifest = load(runtime / 'manifest.json')
    assert mod_manifest['id'] == 'kanto_ascendant'
    if candidate:
        assert '-rc.' in mod_manifest['version'] and mod_manifest.get('experimental') is True
    assert load(runtime / 'assets/sevii_local/import-report.json')['romSha1'] == ROM_SHA1
    for relative in STARTUP_FILES:
        assert (runtime / relative).is_file(), 'Missing startup file: ' + relative
    assert load(COMPANION / 'manifest.json')['id'] == COMPANION_ID
    # Every current top-level Lua module must exist in the assembled QA runtime.
    # This rejects stale overlays that forgot to link a newly authored owner.
    modules = sorted(ROOT.glob('*.lua'))
    for source in modules:
        candidate = runtime / source.name
        assert candidate.is_file() and digest(candidate) == digest(source), 'Stale/missing runtime module: ' + source.name
    # Check the independently recorded ordinary sprites and special-quest art.
    recorded = {k: v['sha256'] for k, v in load(asset_evidence).items() if isinstance(v, dict) and 'sha256' in v}
    for species in load(ROOT / 'SEVII_SPECIAL_ASSETS.json')['species']:
        for row in species['files']:
            previous = recorded.get(row['path'])
            assert previous is None or previous == row['sha256'], 'Conflicting asset evidence'
            recorded[row['path']] = row['sha256']
    for name, sha in recorded.items():
        assert digest(runtime / safe_relative(name)) == sha, 'Changed verified asset: ' + name
    sources = {}
    for path in sorted(runtime.iterdir()):
        # The public 6.7.32 receipt describes the old stable archive. This RC
        # has its own complete package-manifest and must not ship that stale
        # release identity as though it described the Sevii candidate.
        if candidate and path.name == 'local-rc-receipt.json':
            continue
        if path.is_file() and (path.suffix in ('.lua', '.json') or path.name == 'mod.card'):
            sources[path.name] = path
    for folder in RUNTIME_DIRS:
        for path in files_below(runtime / folder):
            sources[path.relative_to(runtime).as_posix()] = path
    for name, path in sources.items():
        safe_relative(name)
        assert path.is_file() and path.suffix.lower() not in FORBIDDEN, 'Unexpected input: ' + str(path)
    # All preflight checks finish before an output directory is made.
    output.mkdir(parents=True, exist_ok=False)
    mod = output / 'mods' / 'kanto_ascendant'
    records = {}
    for name, source in sorted(sources.items()):
        destination = mod / name
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, destination, follow_symlinks=True)
        records[destination.relative_to(output).as_posix()] = {'bytes': destination.stat().st_size, 'sha256': digest(destination)}
    for source in files_below(COMPANION):
        name = source.relative_to(COMPANION)
        destination = output / 'mods' / COMPANION_ID / name
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, destination, follow_symlinks=True)
        records[destination.relative_to(output).as_posix()] = {
            'bytes': destination.stat().st_size, 'sha256': digest(destination)}
    readme = output / 'SEVII_TESTPAKET_DE.md'
    heading = '# Lokales Sevii-RC-Testpaket' if candidate else '# Lokales Sevii-Testpaket – Entwicklungsstand'
    vasc = 'einen passenden Voxel-Ascendant-Sevii-Stand'
    readme.write_text(f'''{heading}

Dieses Paket ist noch keine abgeschlossene Veröffentlichung. Es enthält den
aktuellen KASC-Arbeitsstand samt lokal erzeugten Sevii-Karten und Grafiken.
Der zweite Mod-Ordner `mods/vasc_kanto_sevii_fly_map_widescreen` enthaelt
die hochaufgeloeste Kanto-/Sevii-Regionskarte. Beide Ordner zusammen
installieren; die bisherige einzelne Kanto-Widescreen-Karte deaktivieren.
Die Sevii-Uebersicht ist ab der ersten Ankunft verfuegbar, Insel-FLIEGEN
erst nach der Funkstation. Die Faehre bleibt jederzeit offen.
Die abschaltbare Fangserie funktioniert bereits ab Kantos ersten Wildkaempfen;
ihr Zaehler ist vor der Liga im Shiny-Dex sichtbar.
Engine, ROM und Spielstände sind nicht enthalten. Alle Dateien sind echte
Dateien; Verknüpfungen auf den Entwicklungsrechner werden nicht benötigt.

Zum isolierten Testen beide Ordner aus `mods/` in eine separate,
kompatible Engine-Kopie übernehmen, {vasc} aktivieren
und ein eigenes Testprofil verwenden. Der Sevii-Fährmann lässt ohne Voxel
Ascendant keine Überfahrt zu. Die gewählte Ansicht bleibt auf den Inseln
erhalten; auch 2D ist möglich. Nach der Rückfahrt gilt wieder die zuvor
in Kanto gewählte Ansicht.
Voxel Ascendant ist eine separate Installation und liegt diesem Paket nicht bei.
Nicht zusätzlich neben einer zweiten KASC-Kopie aktivieren. Dieses Paket
installiert nichts automatisch und verändert keine vorhandenen Profile.

`package-manifest.json` dokumentiert jede Datei mit Größe und SHA-256.
Eine bestandene Integritätsprüfung belegt den Paketinhalt, nicht die
Vollständigkeit der Erweiterung. Die finale Spielstands-/Inhaltsprüfung und
Freigabe erfolgen erst nach Abschluss der noch offenen Arbeiten. Dieser RC
behaelt deshalb `releaseReady=false` und wird nicht automatisch installiert.
''')
    records[readme.name] = {'bytes': readme.stat().st_size, 'sha256': digest(readme)}
    commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    write(output / 'package-manifest.json', {'schema': 'kasc.sevii-private-package/v1',
          'status': 'release-candidate' if candidate else 'development',
          'releaseReady': False, 'baseCommit': commit, 'sourceManifestVersion': load(runtime / 'manifest.json')['version'],
          'moduleCount': len(modules), 'verifiedAssetCount': len(recorded), 'romSha1': ROM_SHA1, 'files': records})
    return verify(output)


def archive(output):
    # The launcher imports one mod per ZIP and requires manifest.json at its root.
    # Keep the integrity receipt in the extracted package, then export each mod.
    result = verify(output)
    mods = [
        ('kanto_ascendant', output.name + '.zip'),
        (COMPANION_ID, 'Sevii-Fly-Map-1.1.0-rc.1.zip'),
    ]
    targets = [(output / 'mods' / mod_id, output.parent / filename) for mod_id, filename in mods]
    for source, target in targets:
        assert source.is_dir() and (source / 'manifest.json').is_file()
        if target.exists():
            raise FileExistsError(target)
    exported = {}
    for (mod_id, _), (source, target) in zip(mods, targets):
        with zipfile.ZipFile(target, 'x', compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive_file:
            for path in sorted(source.rglob('*')):
                if path.is_file():
                    archive_file.write(path, path.relative_to(source).as_posix())
        with zipfile.ZipFile(target) as archive_file:
            assert 'manifest.json' in archive_file.namelist()
            assert json.loads(archive_file.read('manifest.json'))['id'] == mod_id
            assert archive_file.testzip() is None
        exported[mod_id] = {'zip': str(target), 'zipSha256': digest(target)}
    return {**result, 'archives': exported,
            'zip': exported['kanto_ascendant']['zip'],
            'zipSha256': exported['kanto_ascendant']['zipSha256']}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--runtime', type=Path)
    parser.add_argument('--asset-evidence', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--verify-only', action='store_true')
    parser.add_argument('--zip', action='store_true')
    parser.add_argument('--rc', action='store_true', help='Label the private package as a local release candidate')
    args = parser.parse_args()
    if args.verify_only:
        result = verify(args.output)
    else:
        if not args.runtime or not args.asset_evidence:
            parser.error('--runtime and --asset-evidence are required for a build')
        result = build(args.runtime, args.output, args.asset_evidence, candidate=args.rc)
    if args.zip:
        result = archive(args.output)
    print(json.dumps(result, ensure_ascii=False))
