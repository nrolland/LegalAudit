# Deep Research → Legal Document

Take a Claude.ai deep-research markdown export and turn it into a publication-ready, footnoted, link-verified, hallucination-audited legal document.

The pipeline: rehydrate citations as numbered footnotes, resolve authoritative French-legal references (Legifrance, Lextenso, Dalloz) inline, verify every URL, audit relevance and authenticity, and assemble a structured markdown ready for export (PDF, HTML, brief).

Deep research stores sources as UI badges (colored pills like "Lextenso +2") that are **not embedded** in the exported markdown. This skill maps them back in and applies the legal-domain quality checks needed before the document can be relied on.

## Input

- A markdown file (the deep research artifact export)
- `citations.json` alongside it:

```json
[
  {
    "url": "https://...",
    "source": "La Base Lextenso",
    "page_title": "Full article title...",
    "start": 160,
    "end": 383
  }
]
```

## Procedure

### 0. Preflight

Run **all** of these checks before doing any mutating work. If any check fails, abort cleanly with the exact message shown — never partially-process the file.

#### 0a. Already processed?

Read the first ~10 non-blank lines of the input file. If any of them contains the marker

```
<!-- Citations hydrated on YYYY-MM-DD -->
```

(any ISO date) abort with:

> The file appears to already have been processed on `<date>`. Run `/deepresearch-to-legal` on the original deep-research export, not on a `*-hydrated.md`. To force a re-run, delete the marker line at the top of the file.

This guard exists because steps 3 and 5 mutate the body (appending footnote markers and rewriting first-occurrence references into inline links) — running them twice would produce `[1, 2, 3][1, 2, 3]` duplicates and corrupt the link resolution. The marker is written by step 8 of the previous successful run.

#### 0b. citations.json present?

Look for `citations.json` in the **same directory as the input file**. If absent, abort with the following message verbatim — the user needs every line:

```
citations.json not found at <input-dir>/citations.json

This pipeline needs a citations.json file mapping each cited URL back to its
character span in the deep-research markdown. The file is NOT in the artifact
export — you have to extract it from the deep-research conversation transcript,
which contains an "md_citations": [...] array.

Two ways to produce citations.json:

  Option A — from a saved transcript file (recommended)
  ──────────────────────────────────────────────────────
    1. On Claude.ai, open the deep-research conversation.
    2. Save the conversation as JSON or copy the raw transcript to a file
       (e.g. transcript.txt) — anything that includes the "md_citations": [...]
       block from the artifact's metadata.
    3. Run:
         python3 scripts/extract-citations.py path/to/transcript.txt
       This writes citations.json in the current directory.

  Option B — paste the transcript into this Claude Code session
  ─────────────────────────────────────────────────────────────
    1. Paste the deep-research transcript directly into the chat.
    2. Ask: "Extract the md_citations array from this transcript into a
       citations.json file with fields url, source, page_title, start, end."
    3. Claude will write citations.json next to the input file.

Then re-run:  /deepresearch-to-legal <input-file>
```

#### 0c. citations.json well-formed?

Read `citations.json`. It must be a JSON array. Each element should have at least `url`; the `start`/`end` span fields are needed for paragraph mapping (step 1). If parsing fails or the top level is not an array, abort with:

> citations.json at `<path>` is malformed — expected a JSON array of `{url, source, page_title, start, end}` objects. See `skills/deepresearch-to-legal.md` for the schema.

If the array is empty (`[]`), proceed but skip steps 1–4 and warn the user that the document will be processed without footnotes (only inline link resolution and audit will run).

### 1. Map citations → paragraphs

Each citation has `start`/`end` character indices into the original text. Use the midpoint to assign it to the overlapping paragraph.

### 2. Deduplicate per paragraph

Keep unique URLs only.

### 3. Insert footnote markers

Append `[1, 2, 3]` at end of each cited paragraph.

### 4. Build footnotes section

```markdown
## Sources et références

1. [Page Title](URL)
2. [Page Title](URL)
```

### 5. Resolve authoritative links

Scan body for domain-specific plain-text references. Resolve **first occurrence** of each to an inline markdown link:

| Domain | Target | Method |
|--------|--------|--------|
| French legislation | Legifrance | `curl -sL` search or LEGIARTI IDs |
| French case law | Legifrance / Doctrine.fr | Search by pourvoi number |
| Doctrine (BJS, BJE, LEDEN, D., JCP) | Lextenso / Dalloz | Search by reference code |

Leave subsequent occurrences as plain text.

### 6. Verify all URLs

```bash
curl -sI -o /dev/null -w "%{http_code}" -L "$URL"
```

- 200, 301→200: ✅
- 403 on paywall domains: ✅ (behind paywall)
- 404, 500, timeout: ❌

Paywall domains: `labase-lextenso.fr`, `lexbase.fr`, `dalloz.fr`, `dalloz-actualite.fr`, `doctrine.fr`

### 7. Run citation audit

**Invoke the `citation-audit` skill** (see `~/.claude/skills/citation-audit.md`) on the hydrated document. This produces:
- The `⚠️ Références suspectes` warning header
- The `Vérification des liens` table with relevance + authenticity columns

### 8. Assemble output

Write `<basename>-hydrated.md`:

```
<!-- Citations hydrated on YYYY-MM-DD -->

[⚠️ Références suspectes section — from citation-audit]

---

[body with footnote markers and inline authoritative links]

---

## Sources et références
[numbered links]

## Vérification des liens
[audit table — from citation-audit]
```

## Generating citations.json from a transcript

See `scripts/extract-citations.py` in the source repo, or run the equivalent inline:

```python
import json, sys

with open(sys.argv[1] if len(sys.argv) > 1 else 'transcript.txt') as f:
    content = f.read()

start = content.find('"md_citations": [')
if start < 0:
    print("No md_citations found"); sys.exit(1)

depth, i = 0, start + len('"md_citations": ')
while i < len(content):
    if content[i] == '[': depth += 1
    elif content[i] == ']':
        depth -= 1
        if depth == 0: break
    i += 1

citations = json.loads(content[start + len('"md_citations": '):i+1])

out = []
for c in citations:
    sources = c.get('sources', [])
    out.append({
        'url': c.get('url', ''),
        'source': c.get('title', ''),
        'page_title': sources[0].get('title', '') if sources else c.get('title', ''),
        'start': c.get('start_index', 0),
        'end': c.get('end_index', 0)
    })

with open('citations.json', 'w') as f:
    json.dump(out, f, indent=2, ensure_ascii=False)
print(f"{len(out)} citations ({len(set(c['url'] for c in out))} unique URLs)")
```

## Legifrance URL patterns

- Article: `https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI{id}`
- Section: `https://www.legifrance.gouv.fr/codes/id/LEGISCTA{id}`
- JORF: `https://www.legifrance.gouv.fr/jorf/id/JORFTEXT{id}`
- Jurisprudence: `https://www.legifrance.gouv.fr/juri/id/JURITEXT{id}`
- Search: `https://www.legifrance.gouv.fr/search/juri?query=XX-XX.XXX`
