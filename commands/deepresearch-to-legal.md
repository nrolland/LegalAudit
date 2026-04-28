Take a Claude.ai deep-research markdown export and produce a footnoted, link-verified, hallucination-audited legal document.

Read these two skills in order:
1. ~/.claude/skills/deepresearch-to-legal.md — mapping, footnoting, link resolution, assembly
2. ~/.claude/skills/citation-audit.md — relevance + authenticity + cross-check audit

Input:
- $ARGUMENTS: the markdown file (the deep-research export)
- citations.json in the same directory

Workflow:
0. deepresearch-to-legal step 0 — preflight (FAIL LOUD, NEVER SILENT):
   0a. If the input top contains `<!-- Citations hydrated on YYYY-MM-DD -->`, abort: file already processed.
   0b. If citations.json is missing, abort and print the full multi-line instructions for producing it (Options A and B from the skill). Do not try to proceed without it.
   0c. If citations.json is malformed, abort with a schema reminder.
1. deepresearch-to-legal steps 1–6 (map → footnote → resolve authoritative links → verify URLs)
2. citation-audit passes A–C (relevance → authenticity → cross-check)
3. Assemble <basename>-hydrated.md with hydration marker + warning header + body + footnotes + audit table

Report: total footnotes, authoritative links added, broken URLs, suspect references.
