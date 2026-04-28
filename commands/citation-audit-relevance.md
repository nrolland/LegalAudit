Run only Pass A (contextual relevance) of the citation audit.

Read ~/.claude/skills/citation-audit-relevance.md for the full procedure.

Input:
- $ARGUMENTS: a markdown file containing footnoted references in a `## Sources et références` section

This command does not verify URLs, does not scan the body for inline legal references, and does not cross-check decision/commentary pairs. It only scores each footnote ✅ pertinent / ⚠️ tangentiel / ❌ hors-sujet against the paragraph it's cited in.

Output: a partial Vérification des liens table fragment with the Pertinence column filled, sorted by severity. Authenticité, HTTP, and warning-header rows are left to /citation-audit-authenticity and /citation-audit-crosscheck.

Report: total footnotes, pertinent, tangentiels, hors-sujet.
