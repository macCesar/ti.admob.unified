#!/usr/bin/env python3
"""Inspect all discovered release archives; fail on unwanted or altered dependencies."""
from pathlib import Path
import hashlib
from io import BytesIO
import plistlib
import posixpath
import re
import stat
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parent.parent
from mediation_modules import discover_modules


def verify():
    owned = set()
    modules = discover_modules(ROOT)
    for module in modules:
        base, module_id, version = module.base, module.module_id, module.version
        inventory = dict(line.split()[::-1] for line in (base / 'ios/framework-checksums.sha256').read_text().splitlines())
        assert not owned.intersection(inventory), 'Framework shared by multiple modules'
        owned.update(inventory)
        for platform, target in [('android', 'android'), ('ios', 'iphone')]:
            archive = module.archive(platform)
            with zipfile.ZipFile(archive) as z:
                prefix = f'modules/{target}/{module_id}/{version}/'
                assert all(n.startswith(prefix) for n in z.namelist()), f'Unexpected module path in {archive}'
                manifest = z.read(prefix + 'manifest').decode()
                assert re.search(r'^version: ' + re.escape(version) + '$', manifest, re.M)
                assert re.search(r'^minsdk: 13\.4\.1\.GA$', manifest, re.M)
                assert re.search(r'^moduleid: ' + re.escape(module_id) + '$', manifest, re.M)
                for source in (base / 'documentation').glob('*.md'):
                    name = prefix + source.relative_to(base).as_posix()
                    assert z.read(name) == source.read_bytes(), f'Stale packaged document: {archive}: {name}'
                    assert name[:-3] + '.html' in z.namelist(), f'Missing rendered document: {archive}: {name}'
                for name in z.namelist():
                    if not name.startswith(prefix + 'documentation/') or not name.endswith(('.md', '.html')):
                        continue
                    source = base / name[len(prefix):]
                    assert source.exists() or (source.suffix == '.html' and source.with_suffix('.md').exists()), f'Retired document: {archive}: {name}'
                    if name.endswith('.html'):
                        for href in re.findall(r'href="([^"]+)"', z.read(name).decode()):
                            target = href.split('#')[0]
                            if target and ':' not in target:
                                resolved = posixpath.normpath(posixpath.join(posixpath.dirname(name), target))
                                assert resolved in z.namelist(), f'Broken packaged link: {archive}: {name} -> {href}'
                for source in (base / '.github/screenshots').glob('*.png'):
                    name = prefix + source.relative_to(base).as_posix()
                    assert z.read(name) == source.read_bytes(), f'Stale packaged screenshot: {archive}: {name}'
                for source in (base / 'example').rglob('*'):
                    if source.is_file() and not any(part.startswith('.') for part in source.relative_to(base).parts):
                        name = prefix + source.relative_to(base).as_posix()
                        assert z.read(name) == source.read_bytes(), f'Stale packaged example: {archive}: {name}'
                if platform == 'android':
                    aars = [n for n in z.namelist() if n.endswith('.aar')]
                    assert len(aars) == 1, aars
                    with zipfile.ZipFile(BytesIO(z.read(aars[0]))) as aar:
                        abis = {n.split('/')[1] for n in aar.namelist() if n.startswith('jni/') and n.endswith('.so')}
                        assert abis == {'arm64-v8a', 'armeabi-v7a', 'x86', 'x86_64'}, (archive, abis)
                    poms = [n for n in z.namelist() if n.endswith('.pom')]
                    assert len(poms) == 1, poms
                    pom = ET.fromstring(z.read(poms[0]))
                    ns = {'m': 'http://maven.apache.org/POM/4.0.0'}
                    dependencies = {(d.findtext('m:groupId', namespaces=ns), d.findtext('m:artifactId', namespaces=ns), d.findtext('m:version', namespaces=ns)) for d in pom.findall('m:dependencies/m:dependency', ns)}
                    expected = {tuple(coordinate.split(':')) for coordinate in module.android_dependencies}
                    assert dependencies == expected, (archive, dependencies, expected)
                else:
                    module_plist = plistlib.loads(z.read(prefix + module_id + '.xcframework/Info.plist'))
                    slices = {(s['SupportedPlatform'], s.get('SupportedPlatformVariant', ''), tuple(sorted(s['SupportedArchitectures']))) for s in module_plist['AvailableLibraries']}
                    assert slices == {('ios', '', ('arm64',)), ('ios', 'simulator', ('arm64', 'x86_64'))}, (archive, slices)
                    platform_prefix = prefix + 'platform/'
                    actual = {n[len(platform_prefix):].split('/')[0] for n in z.namelist() if n.startswith(platform_prefix)}
                    assert actual == set(inventory), (archive, actual)
                    packaged_flags = re.findall(r'^OTHER_LDFLAGS=.*$', z.read(prefix + 'module.xcconfig').decode(), re.M)
                    source_flags = re.findall(r'^OTHER_LDFLAGS=.*$', (base / 'ios/module.xcconfig').read_text(), re.M)
                    assert packaged_flags == source_flags, (archive, packaged_flags)
                    for framework, expected in inventory.items():
                        fp = platform_prefix + framework + '/'
                        entries = [i for i in z.infolist() if i.filename.startswith(fp) and not i.is_dir()]
                        lines = []
                        for entry in sorted(entries, key=lambda i: i.filename):
                            assert (entry.external_attr >> 16) & stat.S_IWUSR, f'Read-only ZIP entry: {entry.filename}'
                            relative = './' + entry.filename[len(fp):]
                            lines.append(hashlib.sha256(z.read(entry)).hexdigest() + '  ' + relative + '\n')
                        digest = hashlib.sha256(''.join(lines).encode()).hexdigest()
                        assert digest == expected, (archive, framework, digest)
                    assert any(n.endswith('.a') and module_id in n for n in z.namelist()), f'Missing native library: {archive}'
            print(f'OK {archive.relative_to(ROOT)}')
    print(f'Verified {2 * len(modules)} ZIPs, {len(modules)} POMs, disjoint frameworks, link flags, versions, architectures, permissions and tree checksums.')


if __name__ == '__main__':
    verify()
