Run only Pass B (inline-reference authenticity + hallucination detection) of the citation audit.

Read ~/.claude/skills/citation-audit-authenticity.md for the full procedure.

Input:
- $ARGUMENTS: a markdown file. No `## Sources et références` section required — this pass works on the body text.

This command does not score footnote relevance and does not cross-check decision/commentary pairs. It scans the body for inline French legal references (case law, doctrine codes, legislation), curls each one against the appropriate authoritative source (Legifrance, Lextenso, Dalloz), and applies the hallucination red-flag checklist.

Output:
1. A `## ⚠️ Références suspectes` warning header (only if any ❌ suspect items found).
2. A partial Vérification des liens table fragment with the Authenticité column filled.

Useful even on hand-authored documents that never went through deep research — catches typos in pourvoi numbers, BJS codes, ordonnance years.

Report: total references checked, verified, unverified, suspect.
