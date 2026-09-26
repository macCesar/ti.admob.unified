"""Discovery behavior without a central provider list or duplicate metadata."""
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from mediation_modules import discover_modules

class DiscoveryTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for platform in ('android', 'ios'):
            (self.root / platform).mkdir()
            shutil.copy(ROOT / platform / 'manifest', self.root / platform / 'manifest')

        shutil.copy(ROOT / 'android/build.gradle', self.root / 'android/build.gradle')

    def test_core_dependencies_follow_gradle(self):
        gradle = self.root / 'android/build.gradle'
        gradle.write_text("dependencies {\nimplementation 'org.example:core:9.8.7'\n}\n")
        self.assertEqual(discover_modules(self.root)[0].android_dependencies[0], 'org.example:core:9.8.7')

    def add_network(self, name):
        base = self.root / 'mediation' / name
        for relative in ('android/manifest', 'ios/manifest', 'android/build.gradle'):
            path = base / relative; path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text((ROOT / 'mediation/applovin' / relative).read_text().replace('applovin', name))
        return base

    def test_sixth_provider_and_manifest_versions(self):
        for name in ('one', 'two', 'three', 'four', 'five', 'sixth'): self.add_network(name)
        modules = discover_modules(self.root)
        self.assertEqual(len(modules), 7)
        sixth = next(m for m in modules if m.module_id.endswith('.sixth'))
        self.assertIn('com.google.ads.mediation:sixth:13.6.4.2', sixth.android_dependencies)
        self.assertEqual(len([m.archive(p) for m in modules for p in ('ios', 'android')]), 14)
        for platform in ('ios', 'android'):
            manifest = sixth.base / platform / 'manifest'
            manifest.write_text(manifest.read_text().replace('version: 1.0.0', 'version: 1.2.3'))
        sixth = next(m for m in discover_modules(self.root) if m.module_id.endswith('.sixth'))
        self.assertEqual(sixth.archive('ios').name, sixth.module_id + '-iphone-1.2.3.zip')

    def test_mismatched_manifests_fail(self):
        base = self.add_network('example')
        manifest = base / 'ios/manifest'
        manifest.write_text(manifest.read_text().replace('version: 1.0.0', 'version: 1.0.1'))
        with self.assertRaises(ValueError): discover_modules(self.root)

    def test_incomplete_directory_fails(self):
        (self.root / 'mediation/unfinished').mkdir(parents=True)
        with self.assertRaises((ValueError, OSError)): discover_modules(self.root)

    def test_reads_gradle_literals_and_rejects_unverifiable_dependencies(self):
        base = self.add_network('example'); gradle = base / 'android/build.gradle'
        gradle.write_text('''dependencies {
  // implementation 'ignored:comment:1.0'
  /* implementation 'ignored:block:1.0' */
  implementation("org.example:adapter:1.2.3")
  implementation 'org.example:utility:4.5.6' // pinned
}
''')
        module = discover_modules(self.root)[1]
        self.assertIn('org.example:adapter:1.2.3', module.android_dependencies)
        self.assertIn('org.example:utility:4.5.6', module.android_dependencies)
        self.assertEqual(len(module.android_dependencies), 4)
        for declaration in ["implementation libs.adapter", "implementation 'group:artifact:1.+'", "api 'group:artifact:1.0'", "implementation 'group:artifact:$version'"]:
            gradle.write_text('dependencies {\n' + declaration + '\n}\n')
            with self.assertRaises(ValueError): discover_modules(self.root)

if __name__ == '__main__': unittest.main()
