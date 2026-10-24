#!/usr/bin/env python3
"""Include offline documentation and examples in each release archive."""
from pathlib import Path
from functools import lru_cache
import json
import os
import posixpath
import re
import stat
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parent.parent
from mediation_modules import discover_modules


@lru_cache(maxsize=1)
def markdown_renderer():
    # Reuse the same renderer as Titanium's module builder.
    minimum = re.search(r'^minsdk:\s*(\S+)', (ROOT / 'android/manifest').read_text(), re.M)[1]
    installed = json.loads(subprocess.check_output(['ti', 'sdk', 'list', '--output', 'json'], text=True))['installed']
    return str(Path(installed[minimum]) / 'node_modules/markdown')


def render_documents(sources):
    if not sources:
        return {}
    rendered = subprocess.check_output(
        ['node', '-e', "const fs = require('fs'); const { markdown } = require(process.argv[1]); "
         "const docs = JSON.parse(fs.readFileSync(0, 'utf8')); "
         "process.stdout.write(JSON.stringify(docs.map(text => markdown.toHTML(text))));", markdown_renderer()],
        input=json.dumps([source.read_text() for source in sources]), text=True)
    return dict(zip(sources, json.loads(rendered)))


def prepare(base, archive):
    with zipfile.ZipFile(archive) as original:
        manifests = [name for name in original.namelist() if name.endswith('/manifest')]
        if len(manifests) != 1:
            raise ValueError(f'Expected one module manifest: {archive}')
        prefix = manifests[0].removesuffix('manifest')
        additions = {}
        # The offline README uses these images for its light/dark example.
        for source in (base / '.github/screenshots').glob('*.png'):
            additions[prefix + source.relative_to(base).as_posix()] = source.read_bytes()
        # Android's module builder does not include the shared example directory.
        for source in (base / 'example').rglob('*'):
            if source.is_file() and not any(part.startswith('.') for part in source.relative_to(base).parts):
                additions[prefix + source.relative_to(base).as_posix()] = source.read_bytes()
        # Keep linked root documents and Markdown originals usable offline.
        for source in [base / name for name in ('README.md', 'CHANGELOG.md', 'CONTRIBUTING.md', 'DEPENDENCIES.md', 'MEDIATION_COMPARISON.md', 'ROADMAP.md') if (base / name).exists()] + list((base / 'documentation').glob('*.md')):
            additions[prefix + source.relative_to(base).as_posix()] = source.read_bytes()
        for source, html in render_documents(sorted((base / 'documentation').glob('*.md'))).items():
            additions[prefix + source.relative_to(base).with_suffix('.html').as_posix()] = html.encode()
        # Removed source pages must not survive in a previously built archive.
        removed = set()
        for name in original.namelist():
            if not name.startswith(prefix + 'documentation/') or not name.endswith(('.md', '.html')):
                continue
            source = base / name[len(prefix):]
            if not source.exists() and not (source.suffix == '.html' and source.with_suffix('.md').exists()):
                removed.add(name)
        names = (set(original.namelist()) - removed) | set(additions)
        for name, data in additions.items():
            if '/documentation/' not in name or not name.endswith('.html'):
                continue
            def rewrite(match):
                href = match[1]
                target, separator, fragment = href.partition('#')
                if target.endswith('.md') and ':' not in target:
                    html = target[:-3] + '.html'
                    absolute = posixpath.normpath(posixpath.join(posixpath.dirname(name), html))
                    if absolute in names:
                        href = html + (separator + fragment if separator else '')
                return 'href="' + href + '"'
            additions[name] = re.sub(r'href="([^"]+)"', rewrite, data.decode()).encode()
        archive_mode = stat.S_IMODE(archive.stat().st_mode)
        handle, temporary = tempfile.mkstemp(dir=archive.parent, suffix='.zip')
        os.close(handle)
        try:
            with zipfile.ZipFile(temporary, 'w', compression=zipfile.ZIP_DEFLATED) as output:
                for entry in original.infolist():
                    if entry.filename in removed:
                        continue
                    data = additions.pop(entry.filename, None)
                    if data is None:
                        data = original.read(entry)
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
