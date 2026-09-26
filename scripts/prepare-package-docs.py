#!/usr/bin/env python3
"""Include offline documentation and examples in each release archive."""
from pathlib import Path
import os
import posixpath
import re
import stat
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parent.parent
from mediation_modules import discover_modules


def prepare(base, archive):
    with zipfile.ZipFile(archive) as original:
        manifests = [name for name in original.namelist() if name.endswith('/manifest')]
        if len(manifests) != 1:
            raise ValueError(f'Expected one module manifest: {archive}')
        prefix = manifests[0].removesuffix('manifest')
        additions = {}
        # Android's module builder does not include the shared example directory.
        for source in (base / 'example').rglob('*'):
            if source.is_file() and not any(part.startswith('.') for part in source.relative_to(base).parts):
                additions[prefix + source.relative_to(base).as_posix()] = source.read_bytes()
        # Keep linked root documents and Markdown originals usable offline.
        for source in [base / name for name in ('README.md', 'CHANGELOG.md', 'CONTRIBUTING.md', 'DEPENDENCIES.md', 'MEDIATION_COMPARISON.md', 'ROADMAP.md') if (base / name).exists()] + list((base / 'documentation').glob('*.md')):
            additions[prefix + source.relative_to(base).as_posix()] = source.read_bytes()
        names = set(original.namelist()) | set(additions)
        archive_mode = stat.S_IMODE(archive.stat().st_mode)
        handle, temporary = tempfile.mkstemp(dir=archive.parent, suffix='.zip')
        os.close(handle)
        try:
            with zipfile.ZipFile(temporary, 'w', compression=zipfile.ZIP_DEFLATED) as output:
                for entry in original.infolist():
                    data = additions.pop(entry.filename, None)
                    if data is None:
                        data = original.read(entry)
                    if '/documentation/' in entry.filename and entry.filename.endswith('.html'):
                        def rewrite(match):
                            href = match[1]
                            target, separator, fragment = href.partition('#')
                            if target.endswith('.md') and ':' not in target:
                                html = target[:-3] + '.html'
                                absolute = posixpath.normpath(posixpath.join(posixpath.dirname(entry.filename), html))
                                if absolute in names:
                                    href = html + (separator + fragment if separator else '')
                            return 'href="' + href + '"'
                        data = re.sub(r'href="([^"]+)"', rewrite, data.decode()).encode()
                    output.writestr(entry, data)
                for name, data in additions.items():
                    entry = zipfile.ZipInfo(name)
                    entry.compress_type = zipfile.ZIP_DEFLATED
                    entry.external_attr = (stat.S_IFREG | 0o644) << 16
                    output.writestr(entry, data)
            os.chmod(temporary, archive_mode)
            os.replace(temporary, archive)
        finally:
            if os.path.exists(temporary):
                os.unlink(temporary)
    print(f'Prepared documentation: {archive.relative_to(ROOT)}')


if __name__ == '__main__':
    for module in discover_modules(ROOT):
        for platform in ('android', 'ios'):
            prepare(module.base, module.archive(platform))
