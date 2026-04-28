# Audit — Pass A: Contextual relevance

Check whether each footnote actually supports the paragraph it's cited in.

Independently invokable as `/citation-audit-relevance`, or used as the first pass of `citation-audit`.

## Input

A markdown document with:
- Footnote markers `[1, 2, 3]` in body paragraphs
- A `## Sources et références` section containing numbered `[Title](URL)` entries

## Procedure

For each `[n]` footnote in the body:

1. Read the **cited paragraph** — identify the specific claim it makes (a legal rule, a case, a date, a numerical figure, a doctrinal position).
2. Read the **footnote target** — page title + source domain.
3. Decide which bucket fits:

| Score | Meaning |
|-------|---------|
| `✅ pertinent` | The page directly addresses the paragraph's specific claim |
| `⚠️ tangentiel` | Same legal domain or topic, but doesn't speak to the specific claim |
| `❌ hors-sujet` | No meaningful connection to the paragraph's content |

If the same footnote number appears in multiple paragraphs, score it against each occurrence — the worst score wins.

## Output

A relevance fragment, one row per footnote:

```markdown
| # | Pertinence | Source | Page | HTTP | Authenticité |
|---|------------|--------|------|------|--------------|
| 3 | ❌ hors-sujet | Studocu | Analyse L622-13... | 200 | — |
| 7 | ⚠️ tangentiel | Professioncgp | La fiducie outil... | 200 | — |
| 1 | ✅ | Lextenso | Fiducie-sûreté... | 403 | — |
```

- **Source** = short publisher/domain name (≤20 chars)
- **Page** = page title truncated to 40 chars + `...`
- **HTTP** = status from URL verification (filled by hydration step 6 if available, otherwise `—`)
- **Authenticité** = always `—` here (filled by `audit-authenticity`)

Sort: `❌` → `⚠️` → `✅`, then by footnote number within each tier.
