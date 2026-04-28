Audit citations in a document for relevance and authenticity.

Read ~/.claude/skills/citation-audit.md for the full procedure.

Input:
- $ARGUMENTS: a markdown file containing footnoted references (either hydrated or manually authored)

This command runs the citation-audit skill standalone:
1. If the document has a ## Sources et références section with [Title](URL) footnotes → run Pass A (relevance) + URL verification
2. Scan body for inline legal references (case law, doctrine codes, legislation) → run Pass B (authenticity) + Pass C (cross-check)
3. Prepend ⚠️ Références suspectes section if any ❌ suspect items found
4. Append Vérification des liens table sorted by severity
5. Write <basename>-audited.md

Report: total references checked, verified, unverified, suspect.
