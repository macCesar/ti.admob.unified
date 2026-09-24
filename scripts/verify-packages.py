#!/usr/bin/env python3
"""Inspect all twelve release archives; fail on unwanted or altered dependencies."""
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
NETWORKS = {
    'applovin': ('applovin', '13.6.4.2'),
    'meta': ('facebook', '6.22.0.1'),
    'inmobi': ('inmobi', '11.4.1.2'),
    'unity': ('unity', '4.20.1.0'),
    'liftoff': ('vungle', '7.7.8.1'),
}


def verify():
    owned = set()
    for network in [None, *NETWORKS]:
        base = ROOT / 'mediation' / network if network else ROOT
        module_id = 'ti.admob.unified' + ('.mediation.' + network if network else '')
        inventory = dict(line.split()[::-1] for line in (base / 'ios/framework-checksums.sha256').read_text().splitlines())
        assert not owned.intersection(inventory), 'Framework shared by multiple modules'
        owned.update(inventory)
        for platform, target in [('android', 'android'), ('ios', 'iphone')]:
            archive = base / platform / 'dist' / f'{module_id}-{target}-1.0.0.zip'
            with zipfile.ZipFile(archive) as z:
                prefix = f'modules/{target}/{module_id}/1.0.0/'
                assert all(n.startswith(prefix) for n in z.namelist()), f'Unexpected module path in {archive}'
                manifest = z.read(prefix + 'manifest').decode()
                assert re.search(r'^version: 1\.0\.0$', manifest, re.M)
                assert re.search(r'^minsdk: 13\.2\.0\.GA$', manifest, re.M)
                assert re.search(r'^moduleid: ' + re.escape(module_id) + '$', manifest, re.M)
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
                    expected = {('com.google.ads.mediation', *NETWORKS[network])} if network else {('com.google.android.gms', 'play-services-ads', '25.5.0'), ('com.google.android.ump', 'user-messaging-platform', '4.0.0'), ('com.google.guava', 'guava', '33.7.1-android')}
                    if network in ('inmobi', 'liftoff'):
                        expected.add(('com.squareup.okhttp3', 'okhttp', '4.12.0'))
                    expected |= {('org.appcelerator', 'titanium', '13.2.0.GA'), ('org.jetbrains.kotlin', 'kotlin-stdlib-jdk8', '2.3.0')}
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
                    for name in z.namelist():
                        if '/documentation/' not in name or not name.endswith('.html'):
                            continue
                        for href in re.findall(r'href="([^"]+)"', z.read(name).decode()):
                            target = href.split('#')[0]
                            if not target or ':' in target:
                                continue
                            resolved = posixpath.normpath(posixpath.join(posixpath.dirname(name), target))
                            assert resolved in z.namelist(), f'Broken packaged link: {archive}: {name} -> {href}'
            print(f'OK {archive.relative_to(ROOT)}')
    print('Verified 12 ZIPs, 6 POMs, disjoint frameworks, link flags, versions, architectures, permissions and tree checksums.')


if __name__ == '__main__':
    verify()
