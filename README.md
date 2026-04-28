# LegalAudit

Claude Code skills that turn a Claude.ai **deep research export** into a **footnoted, link-verified, hallucination-audited legal document** — staying in markdown the whole way so the result is easy to edit, diff, and export to HTML or PDF.

The headline command is **`/deepresearch-to-legal`** — one slash command that wraps the full pipeline (preflight → footnoting → authoritative-link resolution → URL verification → relevance/authenticity/cross-check audit → assembly). Sub-skills are individually invokable when you only need one piece.

The skills were originally distributed as a single bundled installer (`install-citation-skills.sh`, heredoc-style). This repo decomposes that bundle into editable source files so the skills can evolve like normal code.

---

## Why this exists

When you run a deep research on Claude.ai and export the artifact as markdown, **the source links are missing from the markdown body**. They only exist as colored UI badges ("Lextenso +2", etc.) on the website, plus as a `md_citations` array buried in the conversation transcript.

Worse, deep research occasionally **fabricates** plausible-looking French legal references — case-law pourvoi numbers (`Cass. com., 7 sept. 2022, n° 20-20.538`), Bulletin Joly codes (`BJS201m7`), ordonnance numbers with mismatched years — that look real to a non-specialist but don't exist on Legifrance.

This pipeline solves both problems:

1. **Hydration** — pulls the missing URLs back into the markdown as numbered footnotes and resolves the most authoritative references (Legifrance, Lextenso, Dalloz) inline.
2. **Audit** — verifies each footnote's relevance, checks every URL with `curl`, and scans the body for hallucination red flags. Suspect references get a warning header at the top of the document.

---

## End-to-end workflow

```
┌──────────────────────┐    ┌────────────────────┐    ┌──────────────────────────┐
│  1. Deep research    │    │  2. Extract        │    │  3. /deepresearch-to-    │
│     on Claude.ai     │───▶│     citations      │───▶│         legal            │
│  → research.md       │    │  → citations.json  │    │     hydrate + audit      │
│    (no links)        │    │     (URLs + spans) │    │  → *-hydrated.md         │
└──────────────────────┘    └────────────────────┘    └────────────┬─────────────┘
                                                                   │
                                                      ┌────────────▼─────────────┐
                                                      │  4. Render as HTML/PDF   │
                                                      │     (viewer template)    │
                                                      └──────────────────────────┘
```

### Step 1 — run the deep research

On Claude.ai, run a deep research on a legal topic. When it finishes, **export the markdown artifact** (the rendered document) and **save the conversation transcript** (the full JSON log) — the transcript is what holds the source URLs.

You'll end up with two inputs:

- `research.md` — the deep-research output, no links inside
- `transcript.txt` (or the raw JSON dump) — contains the `md_citations` array

### Step 2 — extract `citations.json`

You need a JSON file that maps each cited URL back to a character span in the markdown:

```json
[
  {
    "url": "https://www.labase-lextenso.fr/bulletin-joly-societes/BJS202t8",
    "source": "La Base Lextenso",
    "page_title": "Fiducie-sûreté, accélération de la dette...",
    "start": 160,
    "end": 383
  }
]
```

Two ways to produce it:

**a. Run the extractor script** if you have the transcript file:

```bash
python3 scripts/extract-citations.py path/to/transcript.txt
# writes citations.json in the current directory
```

**b. Ask Claude to do it.** Open Claude Code in the directory, drop the transcript in the conversation, and ask:

> "Extract the `md_citations` array from this transcript into a `citations.json` file with fields `url`, `source`, `page_title`, `start`, `end`. Use `scripts/extract-citations.py` as reference for the shape."

Claude will produce the file directly. This is convenient when the transcript is pasted inline rather than saved to disk, or when the structure varies slightly between Claude.ai versions.

### Step 3 — turn the research into a legal document

With `research.md` and `citations.json` in the same directory:

```bash
claude /deepresearch-to-legal research.md
```

This runs the full pipeline:

0. **Preflight (fail-loud).** Aborts with a clear message if (a) the file already has a `<!-- Citations hydrated on ... -->` marker, (b) `citations.json` is missing — and prints both ways to produce it, or (c) `citations.json` is malformed.
1. Maps each citation span to a paragraph (midpoint of `[start, end]`).
2. Deduplicates URLs per paragraph and appends footnote markers `[1, 2, 3]`.
3. Builds the `## Sources et références` section.
4. Resolves the **first** plain-text occurrence of authoritative references (Legifrance articles, JORF, jurisprudence, Lextenso codes) into inline markdown links.
5. Verifies every URL with `curl` (200/301 ✅, paywall 403 on `lextenso/dalloz/doctrine` ✅, anything else ❌).
6. Calls the `citation-audit` skill, which runs three passes:
   - **Pass A** — relevance: does each footnote actually support its paragraph? (`pertinent / tangentiel / hors-sujet`)
   - **Pass B** — authenticity: scans the body for inline references and flags hallucination red flags (letters in numeric codes, pourvoi format violations, weekend court dates, year mismatches).
   - **Pass C** — cross-check: does a cited commentary plausibly postdate the decision it comments on?
7. Writes `research-hydrated.md` with:
   - `<!-- Citations hydrated on YYYY-MM-DD -->` re-run marker
   - `⚠️ Références suspectes` warning header (only if any `❌ suspect` items)
   - The hydrated body
   - `## Sources et références` numbered links
   - `## Vérification des liens` audit table, sorted by severity

To audit an already-written document **without** hydration (no `citations.json` needed):

```bash
claude /audit-citations              document.md   # all 3 passes
claude /citation-audit-relevance     document.md   # Pass A only — quick footnote ↔ paragraph check
claude /citation-audit-authenticity  document.md   # Pass B only — find hallucinated refs in body
claude /citation-audit-crosscheck    document.md   # Pass C only — decision/commentary pairing
```

The three passes are independent skills that produce table fragments. The umbrella `/audit-citations` runs all three and merges them; the standalone commands are useful when you only need one signal — e.g. `/citation-audit-authenticity` on a hand-authored brief that never went through deep research, to catch typos in pourvoi numbers and BJS codes.

### Step 4 — render as HTML (optional)

`viewer/md-to-legal-html.html` is a self-contained single-file template (uses `marked.js` over CDN). Open it in a browser, then drag-drop the hydrated `.md` onto the textarea (or paste it in) and click *Aperçu*. The template:

- renders headings, footnote anchors, tables, and quotes in a Lextenso/Dalloz-like brick-and-gold theme;
- preserves inline `[Title](URL)` links so verified references stay clickable;
- exports a self-contained HTML file (markdown is embedded as a `<script type="text/markdown">` for round-trips).

---

## Repo layout

```
.
├── README.md                       # this file
├── install.sh                      # copies skills + commands into ~/.claude/
├── skills/
│   ├── deepresearch-to-legal.md          # main pipeline: preflight → footnote → resolve → verify → audit → assemble
│   ├── citation-audit.md                 # audit umbrella (delegates to A/B/C)
│   ├── citation-audit-relevance.md       # Pass A — source ↔ paragraph match
│   ├── citation-audit-authenticity.md    # Pass B — inline-ref verification + red flags
│   └── citation-audit-crosscheck.md      # Pass C — decision/commentary consistency
├── commands/
│   ├── deepresearch-to-legal.md          # /deepresearch-to-legal
│   ├── audit-citations.md                # /audit-citations  (all 3 passes)
│   ├── citation-audit-relevance.md       # /citation-audit-relevance
│   ├── citation-audit-authenticity.md    # /citation-audit-authenticity
│   └── citation-audit-crosscheck.md      # /citation-audit-crosscheck
├── scripts/
│   └── extract-citations.py        # transcript → citations.json
├── viewer/
│   └── md-to-legal-html.html       # single-file markdown → styled HTML viewer
└── examples/
    ├── fiducie-surete-guide-final.md             # raw deep-research export
    ├── citations.json                            # extracted md_citations
    ├── fiducie-surete-guide-final-audited.md     # after /deepresearch-to-legal
    └── fiducie-surete-guide-final-audited.pdf    # PDF render of the audited md
```

## Install

```bash
bash install.sh
```

This copies:

- `skills/*.md` → `~/.claude/skills/` (loaded automatically by Claude Code)
- `commands/*.md` → `~/.claude/commands/` (registers `/deepresearch-to-legal`, `/audit-citations`, and the three single-pass audit commands as slash commands)

A version stamp lives at `~/.claude/.citation-skills-version`. Re-running the installer prompts before overwriting; set `FORCE=1` to skip the prompt.

The original bundled installer (`install-citation-skills.sh`, with skills embedded as heredocs) is superseded by this repo. Edit the source `.md` files in `skills/` and `commands/` and re-run `install.sh`.

---

## Evolving the skills

Because the skills are plain markdown files, editing is straightforward:

- **Tune the audit rules** — add a new hallucination red flag in `skills/citation-audit.md` under *Pass B*. Examples of useful additions: implausibly recent doctrine (e.g. citing 2026 articles when the research ran in 2024), DOI-shaped strings that don't resolve, OCR-style typos in court abbreviations.
- **Add new authoritative domains** — extend the table in `skills/deepresearch-to-legal.md` step 5 (e.g. EUR-Lex for EU law, the Conseil d'État portal). Add the matching paywall entry in step 6 if appropriate.
- **Add a new slash command** — drop a new `commands/<name>.md` and update `install.sh` to copy it. The command file is just a prompt that points the model at the relevant skill(s).
- **Change the output format** — the `## Sources et références` header, the audit table columns, and the warning header text are all defined in `skills/citation-audit.md` *Output* section. Change them once there; both `/deepresearch-to-legal` and `/audit-citations` follow.

After editing, re-run `bash install.sh` to push changes to `~/.claude/`.

### Versioning

Bump `VERSION="2"` in `install.sh` whenever you make a non-backwards-compatible change to the skill format. The installer detects the previous version and removes the old files before copying the new ones, so users don't end up with stale skill files.

---

## Worked example

A complete real-world run lives in `examples/` — a deep research on French *fiducie-sûreté* that produced ~70 footnotes and surfaced several hallucinated references.

| File | Purpose |
|------|---------|
| `examples/fiducie-surete-guide-final.md` | Raw deep-research export (no links) |
| `examples/citations.json` | Extracted `md_citations` array |
| `examples/fiducie-surete-guide-final-audited.md` | Result after `/deepresearch-to-legal` |
| `examples/fiducie-surete-guide-final-audited.pdf` | PDF rendered from the audited markdown |
| `viewer/md-to-legal-html.html` | The HTML viewer template |

The audited markdown is a useful reference for what the skills should produce: numbered `[Title](URL)` footnotes, inline Legifrance links on first occurrence, and a `## Vérification des liens` table sorted `❌ → ⚠️ → ✅`. To reproduce locally:

```bash
cp examples/fiducie-surete-guide-final.md examples/citations.json /tmp/
claude /deepresearch-to-legal /tmp/fiducie-surete-guide-final.md
diff /tmp/fiducie-surete-guide-final-hydrated.md examples/fiducie-surete-guide-final-audited.md
```

---

## Limits and known gotchas

- **Network dependence.** URL verification needs outbound `curl`; the skills won't tell broken links from offline runs apart. If running in a sandbox, comment out step 6 in `deepresearch-to-legal.md` or pre-cache the verifications.
- **Paywall false negatives.** Lextenso/Dalloz/Doctrine.fr return 403 on HEAD requests — these are whitelisted as ✅, but a genuinely dead URL on those domains will be missed. Cross-check by searching the title.
- **French-law-centric.** The hallucination red flags (BJS codes, pourvoi format, ordonnance year matching) are tuned for French legal references. Apply to other jurisdictions only after extending the rules.
- **Not idempotent — but guarded.** Step 8 of `deepresearch-to-legal` writes a `<!-- Citations hydrated on YYYY-MM-DD -->` marker at the top of the output. Step 0a (preflight) reads that marker on the next run and aborts with a message rather than double-hydrating. To force a re-run on an already-hydrated file, delete the marker line first. Always run on the original `research.md` for normal use.
- **Foolproof on missing inputs.** Step 0b refuses to run when `citations.json` is absent and prints the full multi-line instructions for producing it (run `scripts/extract-citations.py` on the transcript file, or paste the transcript into the chat and ask Claude). Step 0c rejects a malformed `citations.json`. The skill never partially-processes a file.
