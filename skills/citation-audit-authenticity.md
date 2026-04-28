# Audit — Pass B: Reference authenticity

Catch deep-research hallucinations — plausible-looking but fabricated case-law numbers, doctrine codes, or misattributed sources — by scanning the body for inline references and verifying each one against an authoritative source.

Independently invokable as `/citation-audit-authenticity`, or used as the second pass of `citation-audit`.

## Input

A markdown document. No `citations.json` required — this pass works on the body text itself.

## Procedure

### 1. Extract inline references

Scan the body (not the footnotes) for these patterns:

| Category | Pattern examples |
|---|---|
| Case law | `Cass. com., [date], n° XX-XX.XXX`, `CA [ville], [date], n° XX/XXXXX` |
| Doctrine | `BJS [année], n° BJSXXXXXX`, `D. [année], p. XXX`, `LEDEN, [mois année], n° DEDXXXXXX`, `JCP E [année], XXX` |
| Legislation | `loi n° XXXX-XXX du [date]`, `ordonnance n° XXXX-XXXX du [date]` |

### 2. Verify each reference

`curl` the appropriate authoritative source:

| Reference type | Lookup URL |
|---|---|
| Pourvoi | `https://www.legifrance.gouv.fr/search/juri?query={number}` |
| Loi/ordonnance | `https://www.legifrance.gouv.fr/search/all?query={number}` |
| BJS / BJE | `https://www.labase-lextenso.fr/bulletin-joly-societes/{code}` |
| LEDEN | `https://www.labase-lextenso.fr/lettre-d-actualite-des-procedures-collectives/{code}` |
| D. (Recueil Dalloz) | `https://www.dalloz-actualite.fr/search?query={author}+{year}` |

### 3. Apply the hallucination red-flag checklist

| Red flag | Example | Why suspect |
|---|---|---|
| Letters in numeric-only codes | `BJS201m7`, `DED202a7` | BJS / LEDEN codes are digits after the prefix |
| Pourvoi format violation | `2020538` instead of `20-20.538` | Must be `YY-YY.YYY` |
| Weekend / holiday court date | `Cass. com., dimanche 7 sept. 2022` | Courts don't sit on weekends |
| Ordonnance year mismatch | `ordonnance n° 2009-112 du 30 janvier 2008` | Year prefix ≠ stated date |
| Author / journal mismatch | Crocq publishing in LEDEN (proc. coll. newsletter) | Unusual venue for the author |
| Unparseable page reference | `D. 2023, p. 447` — page 447 of Recueil Dalloz | Valid format, but verify author + title exist |
| No trace anywhere | curl returns 0 results on Legifrance + Doctrine.fr | Strongest hallucination signal |

### 4. Score

| Score | Meaning |
|---|---|
| `✅ vérifié` | Found on authoritative source, content matches |
| `⚠️ non vérifié` | Plausible format, could not confirm (paywall, no network result) |
| `❌ suspect` | Hallucination indicators present |

## Output

### 1. Warning header — only if any `❌ suspect` items

Prepend to the document:

```markdown
## ⚠️ Références suspectes

> Les références suivantes n'ont pas pu être vérifiées et présentent
> des indicateurs d'hallucination. Vérification manuelle requise.

| Réf. | Texte dans le document | Problème | Paragraphe |
|------|------------------------|----------|------------|
| ! | Cass. com., 7 sept. 2022, n° 20-20.538 | Pourvoi introuvable sur Legifrance | §3.1 |
| ! | BJS, déc. 2022, n° BJS201m7 | Lettre inattendue dans code BJS | §3.1 |
```

### 2. Authenticity fragment

For each footnote whose paragraph contains an inline reference, fill its `Authenticité` cell:

```markdown
| # | Pertinence | Source | Page | HTTP | Authenticité |
|---|------------|--------|------|------|--------------|
| 1 | — | Lextenso | Fiducie-sûreté... | 403 | ✅ vérifié (BJS202t8) |
| 6 | — | Village Justice | Étude simplifiée... | 200 | ✅ vérifié (loi 2007-211) |
| 14 | — | Manufacture Notaires | Mise à disposition... | 200 | ✅ vérifié (CA Bordeaux 23/04451) |
```

- **Pertinence** = `—` here (filled by `audit-relevance`)
- **Authenticité** annotation in parentheses = the specific identifier verified

Footnotes whose paragraphs have no inline reference don't appear here.
