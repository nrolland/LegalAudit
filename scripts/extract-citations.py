#!/usr/bin/env python3
"""
Extract md_citations from a Claude.ai deep research transcript into citations.json.

Usage:
    python3 extract-citations.py path/to/transcript.txt
    # writes citations.json in the current directory

The transcript is the raw conversation log (or a saved JSON blob containing it).
Look for a section that contains `"md_citations": [ ... ]`. This script finds
that array and extracts each entry's url, source title, page title, and the
character span (start_index/end_index) into the deep research markdown.
"""
import json
import sys


def extract(transcript_path: str, out_path: str = "citations.json") -> int:
    with open(transcript_path) as f:
        content = f.read()

    start = content.find('"md_citations": [')
    if start < 0:
        print("No md_citations found", file=sys.stderr)
        return 1

    # Walk the JSON array, balancing brackets, to find its end.
    depth, i = 0, start + len('"md_citations": ')
    while i < len(content):
        if content[i] == '[':
            depth += 1
        elif content[i] == ']':
            depth -= 1
            if depth == 0:
                break
        i += 1

    citations = json.loads(content[start + len('"md_citations": '):i + 1])

    out = []
    for c in citations:
        sources = c.get('sources', [])
        out.append({
            'url': c.get('url', ''),
            'source': c.get('title', ''),
            'page_title': sources[0].get('title', '') if sources else c.get('title', ''),
            'start': c.get('start_index', 0),
            'end': c.get('end_index', 0),
        })

    with open(out_path, 'w') as f:
        json.dump(out, f, indent=2, ensure_ascii=False)

    unique = len(set(c['url'] for c in out))
    print(f"{len(out)} citations ({unique} unique URLs) → {out_path}")
    return 0


if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else "transcript.txt"
    sys.exit(extract(path))
