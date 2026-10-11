"""Integrity failures must refuse a private Sevii package, never repair it."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('sevii_package', ROOT / 'scripts/build_sevii_package.py')
package = importlib.util.module_from_spec(spec)
spec.loader.exec_module(package)


class PackageIntegrity(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.output = Path(self.temp.name) / 'package'
        self.mod = self.output / 'mods/kanto_ascendant'
        (self.mod / 'assets/sevii_local').mkdir(parents=True)
        inputs = {'manifest.json': {'id': 'kanto_ascendant'},
                  'assets/sevii_local/import-report.json': {'romSha1': package.ROM_SHA1},
                  'assets/sevii_local/habitats.json': {'fixture': True}}
        for name, data in inputs.items():
            (self.mod / name).write_text(json.dumps(data))
        for name in package.STARTUP_FILES:
            path = self.mod / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('return {}\n')
        self.records = {p.relative_to(self.output).as_posix(): {'bytes': p.stat().st_size, 'sha256': package.digest(p)}
                        for p in self.output.rglob('*') if p.is_file()}
        package.write(self.output / 'package-manifest.json',
                      {'schema': 'kasc.sevii-private-package/v1', 'status': 'development',
                       'releaseReady': False, 'files': self.records})

    def test_complete_fixture_verifies_without_claiming_release(self):
        result = package.verify(self.output)
        self.assertTrue(result['verified'])
        self.assertFalse(result['releaseReady'])

    def test_changed_file_is_rejected_without_repair(self):
        target = self.mod / 'manifest.json'
        target.write_text('{"id":"tampered_mod"}')
        before = target.read_bytes()
        with self.assertRaises(AssertionError):
            package.verify(self.output)
        self.assertEqual(before, target.read_bytes())

    def test_missing_startup_file_is_rejected_before_export(self):
        target = self.mod / package.STARTUP_FILES[0]
        target.unlink()
        with self.assertRaisesRegex(AssertionError, 'inventory'):
            package.verify(self.output)
        # Even a tampered receipt cannot make a package without startup load.
        receipt = package.load(self.output / 'package-manifest.json')
        del receipt['files'][target.relative_to(self.output).as_posix()]
        package.write(self.output / 'package-manifest.json', receipt)
        with self.assertRaisesRegex(AssertionError, 'Missing startup file'):
            package.verify(self.output)

    def test_missing_or_extra_file_is_rejected(self):
        target = self.mod / 'extra.lua'
        target.write_text('return true')
        with self.assertRaisesRegex(AssertionError, 'inventory'):
            package.verify(self.output)
        target.unlink()
        (self.mod / 'assets/sevii_local/habitats.json').unlink()
        with self.assertRaisesRegex(AssertionError, 'inventory'):
            package.verify(self.output)

    def test_external_link_is_rejected_even_with_identical_bytes(self):
        target = self.mod / 'manifest.json'
        outside = Path(self.temp.name) / 'external.json'
        outside.write_bytes(target.read_bytes())
        target.unlink()
        target.symlink_to(outside)
        with self.assertRaisesRegex(AssertionError, 'symlink'):
            package.verify(self.output)

    def test_rom_and_save_never_belong_in_output(self):
        for name in ('game.gba', 'player.sav'):
            target = self.output / name
            target.write_bytes(b'private fixture')
            with self.assertRaisesRegex(AssertionError, 'ROM/save'):
                package.verify(self.output)
            target.unlink()

    def test_unsafe_receipt_paths_refused(self):
        for name in ('../escape', '/absolute', 'dir/../../escape', 'dir\\escape', ''):
            with self.assertRaises(ValueError):
                package.safe_relative(name)

    def test_launcher_archives_have_a_manifest_at_their_root(self):
        companion = self.output / 'mods' / package.COMPANION_ID
        (companion / 'assets').mkdir(parents=True)
        (companion / 'manifest.json').write_text(json.dumps({'id': package.COMPANION_ID}))
        (companion / 'assets/sevii_fly_map_master.png').write_bytes(
            b'\x89PNG\r\n\x1a\n' + b'\0' * 8 + (1672).to_bytes(4, 'big') + (941).to_bytes(4, 'big'))
        receipt = package.load(self.output / 'package-manifest.json')
        for path in companion.rglob('*'):
            if path.is_file():
                receipt['files'][path.relative_to(self.output).as_posix()] = {
                    'bytes': path.stat().st_size, 'sha256': package.digest(path)}
        package.write(self.output / 'package-manifest.json', receipt)
        result = package.archive(self.output)
        for mod_id in ('kanto_ascendant', package.COMPANION_ID):
            with zipfile.ZipFile(result['archives'][mod_id]['zip']) as archive:
                self.assertIn('manifest.json', archive.namelist())
                self.assertEqual(json.loads(archive.read('manifest.json'))['id'], mod_id)
                self.assertFalse(any(name.startswith('mods/') for name in archive.namelist()))
                if mod_id == 'kanto_ascendant':
                    self.assertIn(package.STARTUP_FILES[0], archive.namelist())


if __name__ == '__main__':
    unittest.main()
