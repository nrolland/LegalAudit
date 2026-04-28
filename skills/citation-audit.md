# Citation Audit

Verify the relevance and authenticity of citations in a document. Designed to catch deep-research hallucinations — plausible-looking but fabricated case-law numbers, doctrine codes, or misattributed sources.

Can be invoked standalone (via `/audit-citations`) or as a sub-step of `deepresearch-to-legal`. This skill is a **thin orchestrator** — the substance lives in three sub-skills, each individually invokable:

| Pass | Sub-skill | Slash command | What it does |
|---|---|---|---|
| A | `~/.claude/skills/citation-audit-relevance.md` | `/citation-audit-relevance` | Source ↔ paragraph match |
| B | `~/.claude/skills/citation-audit-authenticity.md` | `/citation-audit-authenticity` | Inline-reference verification + hallucination red flags |
| C | `~/.claude/skills/citation-audit-crosscheck.md` | `/citation-audit-crosscheck` | Decision/commentary internal consistency |

## Input

A markdown document containing:
- Body text with legal claims, case-law references, doctrine citations
- A `## Sources et références` section with numbered `[Title](URL)` footnotes
- Footnote markers `[1, 2, 3]` in body paragraphs

## Procedure

1. Read `~/.claude/skills/citation-audit-relevance.md` and run **Pass A** on every footnote. Produces a relevance fragment (one row per footnote, `Pertinence` filled).
2. Read `~/.claude/skills/citation-audit-authenticity.md` and run **Pass B** on the body. Produces:
   - A `⚠️ Références suspectes` warning header if any `❌ suspect` items are found.
   - An authenticity fragment (one row per footnote whose paragraph contains an inline reference, `Authenticité` filled).
3. Read `~/.claude/skills/citation-audit-crosscheck.md` and run **Pass C** on paragraphs that pair a decision with a commentary. Appends rows to the warning header if any inconsistencies are found.
4. **Merge fragments** into a single `## Vérification des liens` table — each row keyed by footnote `#`, with both `Pertinence` and `Authenticité` populated where each pass had something to say.
5. **Sort** the merged table: `❌` → `⚠️` → `✅`, then by footnote number within each tier.

## Output

Two sections to be inserted into the document.

### 1. Warning header (top of document)

Only produced if Pass B or Pass C surfaced suspect items. Format defined in `citation-audit-authenticity.md` and `citation-audit-crosscheck.md`.

### 2. Verification table (end of document)

```markdown
## Vérification des liens

| # | Pertinence | Source | Page | HTTP | Authenticité |
|---|------------|--------|------|------|--------------|
| 3 | ❌ hors-sujet | Studocu | Analyse L622-13... | 200 | — |
| 7 | ⚠️ tangentiel | Professioncgp | La fiducie outil... | 200 | ⚠️ non vérifié |
| 1 | ✅ | Lextenso | Fiducie-sûreté... | 403 | ✅ vérifié |
```

**Columns**:
- **#**: footnote number
- **Pertinence**: from Pass A
- **Source**: short publisher / domain name
- **Page**: page title truncated (≤40 chars, `...` suffix)
- **HTTP**: status code from URL check (filled by `deepresearch-to-legal` step 6 if available, otherwise `—`)
- **Authenticité**: from Pass B for footnotes whose paragraph contains an inline legal reference

## Standalone usage

The umbrella runs all three passes. To run only one:

```
/citation-audit-relevance      file.md   # Pass A only
/citation-audit-authenticity   file.md   # Pass B only — useful even on hand-written docs
/citation-audit-crosscheck     file.md   # Pass C only — best after Pass B
/audit-citations               file.md   # all three (this skill)
```

Each individual pass produces a partial table fragment (the column it owns is filled, others are `—`).
