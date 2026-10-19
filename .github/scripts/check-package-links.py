#!/usr/bin/env python3
"""Audit links against the files in an R source tarball, never the checkout."""

import argparse
import hashlib
import json
import posixpath
import re
import subprocess
import tarfile
from collections import defaultdict
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit


class HTMLLinks(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.links = []
        self.anchors = set()

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        self.anchors.update(filter(None, [attrs.get('id'), attrs.get('name')]))
        for name in ('href', 'src', 'poster', 'action'):
            if attrs.get(name):
                self.links.append(attrs[name])

    handle_startendtag = handle_starttag


def document_links(name, text):
    """Use Pandoc for Markdown references/autolinks and HTMLParser for HTML."""
    html = HTMLLinks()
    if name.lower().endswith(('.md', '.rmd', '.qmd')):
        html.feed(subprocess.check_output(
            ['pandoc', '--from=markdown', '--to=html'], input=text, text=True
        ))
    elif name.lower().endswith(('.html', '.htm')):
        html.feed(text)
        html.links.extend(re.findall(r'url\(\s*[\"\']?([^\"\')\s]+)', text))
    elif name.endswith(('.R', '.Rd')) or Path(name).name == 'DESCRIPTION':
        html.links.extend(re.findall(r'https?://[^\s<>\"\'{}]+', text))
    return html


def audit(archive, offline=False, browser_verified=()):
    with tarfile.open(archive) as package:
        members = {
            member.name: package.extractfile(member).read()
            for member in package.getmembers() if member.isfile()
        }
    roots = {name.split('/')[0] for name in members}
    if len(roots) != 1:
        raise ValueError('Expected one package directory in the source archive')
    root = next(iter(roots))
    docs = {}
    for name, contents in members.items():
        if name.lower().endswith(('.md', '.rmd', '.qmd', '.html', '.htm', '.r', '.rd')) or Path(name).name == 'DESCRIPTION':
            docs[name] = document_links(name, contents.decode('utf-8'))
        elif name.lower().endswith('.pdf'):
            raise ValueError('PDF added: extend the audit to inspect its annotations')
    references = []
    remote = defaultdict(set)
    errors = []
    for name, doc in docs.items():
        for raw in sorted(set(doc.links)):
            if raw.startswith(('data:', 'javascript:')):
                continue
            url = urlsplit(raw)
            if url.scheme in ('http', 'https') or raw.startswith('//'):
                remote['https:' + raw if raw.startswith('//') else raw].add(name)
                continue
            if url.scheme in ('mailto', 'tel'):
                references.append({'from': name, 'url': raw, 'status': 'non-file URI'})
                continue
            if url.scheme:
                errors.append({'from': name, 'url': raw, 'error': 'Unsupported URI scheme'})
                continue
            target = posixpath.normpath(posixpath.join(posixpath.dirname(name), unquote(url.path))) if url.path else name
            record = {'from': name, 'url': raw, 'target': target}
            if not target.startswith(root + '/') or target not in members:
                record['error'] = 'Target is absent from the source archive'
                errors.append(record)
            elif url.fragment and target in docs and unquote(url.fragment) not in docs[target].anchors:
                record['error'] = 'Fragment is absent from the target document'
                errors.append(record)
            else:
                record['status'] = 'OK'
            references.append(record)
    external = []
    for url, sources in sorted(remote.items()):
        record = {'url': url, 'from': sorted(sources)}
        if offline:
            record['status'] = 'not requested (offline)'
        else:
            # Match CRAN's HEAD check, then try GET when a server rejects HEAD.
            for method in ('HEAD', 'GET'):
                command = ['curl', '--location', '--silent', '--show-error',
                           '--max-time', '60', '--output', '/dev/null',
                           '--write-out', '%{http_code}\n%{url_effective}']
                if method == 'HEAD':
                    command.append('--head')
                result = subprocess.run(command + [url], capture_output=True, text=True)
                response = result.stdout.splitlines()
                code = int(response[0]) if response and response[0].isdigit() else 0
                record.update(method=method, http_status=code,
                              final_url=response[1] if len(response) > 1 else url)
                if result.returncode == 0 and 200 <= code < 300:
                    record['status'] = 'OK'
                    break
            else:
                if result.returncode == 0 and code == 403 and url in browser_verified:
                    record['status'] = 'HTTP 403; separately verified in a browser'
                else:
                    record['error'] = result.stderr.strip() or f'HTTP {code}'
                    errors.append(record)
        external.append(record)
    return {
        'archive': str(archive),
        'sha256': hashlib.sha256(Path(archive).read_bytes()).hexdigest(),
        'scanned_documents': sorted(docs),
        'local_references': references,
        'external_urls': external,
        'errors': errors,
    }


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('archive', type=Path)
    parser.add_argument('--report', type=Path, required=True)
    parser.add_argument('--offline', action='store_true')
    parser.add_argument('--browser-verified-url', action='append', default=[])
    args = parser.parse_args()
    report = audit(args.archive, args.offline, args.browser_verified_url)
    args.report.write_text(json.dumps(report, indent=2) + '\n')
    print(f"Scanned {len(report['scanned_documents'])} source/help/Markdown/HTML documents")
    print(f"Checked {len(report['local_references'])} local references and {len(report['external_urls'])} distinct external URLs")
    for url in report['external_urls']:
        print(url['url'], url.get('status', url.get('error')))
    for error in report['errors']:
        print('ERROR:', error)
    raise SystemExit(bool(report['errors']))
