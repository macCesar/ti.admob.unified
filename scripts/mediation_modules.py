#!/usr/bin/env python3
"""Shared discovery for build, artifact and package tooling (standard library only)."""
import argparse
from dataclasses import dataclass
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
BUILD_DEPENDENCIES = ('org.appcelerator:titanium:13.2.0.GA', 'org.jetbrains.kotlin:kotlin-stdlib-jdk8:2.3.0')



def read_manifest(path):
    values = {}
    for line in path.read_text().splitlines():
        if not line.strip() or line.lstrip().startswith('#'):
            continue
        key, separator, value = line.partition(':')
        if not separator or key.strip() in values:
            raise ValueError(f'Invalid or duplicate manifest field: {path}: {line}')
        values[key.strip()] = value.strip()
    for key in ('moduleid', 'version', 'minsdk'):
        if not values.get(key):
            raise ValueError(f'Missing {key}: {path}')
    if not re.fullmatch(r'[a-z][a-z0-9.]*', values['moduleid']) or not re.fullmatch(r'\d+\.\d+\.\d+(?:[-.][A-Za-z0-9]+)*', values['version']):
        raise ValueError(f'Invalid module identity/version: {path}')
    return values


@dataclass(frozen=True)
class Module:
    base: Path
    module_id: str
    version: str
    android_dependencies: tuple

    def archive(self, platform):
        target = 'iphone' if platform == 'ios' else 'android'
        return self.base / platform / 'dist' / f'{self.module_id}-{target}-{self.version}.zip'


def module_from_manifests(base, dependencies):
    android, ios = [read_manifest(base / platform / 'manifest') for platform in ('android', 'ios')]
    for key in ('moduleid', 'version', 'minsdk'):
        if android[key] != ios[key]:
            raise ValueError(f'Platform manifest {key} mismatch: {base}')
    return Module(base, android['moduleid'], android['version'], tuple(dependencies))


def android_dependencies(base):
    # Keep dependency declarations literal and reviewable; never execute Gradle here.
    source = (base / 'android/build.gradle').read_text()
    source = re.sub(r'/\*.*?\*/', '', source, flags=re.S)
    source = re.sub(r'//[^\n]*', '', source)
    dependencies = []
    for line in source.splitlines():
        line = line.strip()
        if not line or line in ('dependencies {', '}'):
            continue
        match = re.fullmatch(r"implementation\s*(?:\(\s*)?(['\"])([A-Za-z0-9_.-]+:[A-Za-z0-9_.-]+:[A-Za-z0-9_.-]+)\1\s*\)?\s*;?", line)
        if not match or match[2].endswith('-SNAPSHOT') or ':' not in match[2]:
            raise ValueError(f'Use exact literal implementation coordinates in {base}/android/build.gradle: {line}')
        dependencies.append(match[2])
    if not dependencies or len(dependencies) != len(set(dependencies)):
        raise ValueError(f'Missing or duplicate Android dependencies: {base}')
    return tuple(dependencies) + BUILD_DEPENDENCIES


def discover_modules(root=ROOT):
    root = Path(root).resolve()
    modules = [module_from_manifests(root, android_dependencies(root))]
    mediation = root / 'mediation'
    for base in sorted(mediation.iterdir()) if mediation.exists() else []:
        if base.name.startswith('.') or not base.is_dir():
            continue
        if base.is_symlink() or not re.fullmatch(r'[a-z][a-z0-9]*', base.name):
            raise ValueError(f'Invalid provider directory: {base}')
        module = module_from_manifests(base, android_dependencies(base))
        if module.module_id != 'ti.admob.unified.mediation.' + base.name:
            raise ValueError(f'Provider directory and module ID mismatch: {base}')
        modules.append(module)
    return modules


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=ROOT)
    args = parser.parse_args()
    try:
        for module in discover_modules(args.root):
            print(module.base.relative_to(args.root.resolve()).as_posix())
    except (ValueError, OSError) as error:
        parser.exit(1, f'{error}\n')
