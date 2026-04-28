Run only Pass C (decision/commentary internal consistency) of the citation audit.

Read ~/.claude/skills/citation-audit-crosscheck.md for the full procedure.

Input:
- $ARGUMENTS: a markdown file. Best run after /citation-audit-authenticity has annotated each inline reference, but works standalone.

This command does not score footnote relevance and does not run general inline-reference verification. It looks at paragraphs that pair a court decision (Cass., CA, CE) with a doctrinal commentary (BJS, D., LEDEN, JCP) and checks:
- Temporal plausibility — does the commentary postdate the decision?
- Author/venue plausibility — does the cited author publish in this venue?
- Cross-status consistency — if Pass B ran, do the decision/commentary statuses pair sensibly?

Output: rows appended to the `## ⚠️ Références suspectes` warning header. If no inconsistencies are found, prints "No internal consistency issues found."

Report: total decision/commentary pairs checked, plausible, flagged.
