# Audit — Pass C: Internal consistency cross-check

For paragraphs that pair a court decision with a doctrinal commentary, verify that the two references make sense together. Catches the case where a decision is real but the commentary is invented (or vice versa).

Independently invokable as `/citation-audit-crosscheck`, or used as the third pass of `citation-audit`.

## Input

A markdown document, ideally already processed by `citation-citation-audit-authenticity` so each inline reference has a `✅ vérifié` / `⚠️ non vérifié` / `❌ suspect` annotation. Works without it (will simply do its own verification on demand) but is much faster with it.

## Procedure

For each paragraph that contains both a decision reference (Cass., CA, CE, etc.) and a commentary reference (BJS, D., LEDEN, JCP, etc.):

### 1. Temporal plausibility

Does the commentary's stated date plausibly **postdate** the decision?

- A 2024 commentary on a 2023 decision: plausible.
- A 2018 commentary on a 2022 decision: impossible — flag.
- A commentary published the same day as the decision: implausible for a substantive note (but possible for a flash news bulletin).

### 2. Author–venue plausibility

Does the cited author actually publish in this area of law / in this venue?

- Pierre Crocq → sûretés, civil law (LGDJ, BJS, D.). Publishing in LEDEN (proc. coll. newsletter) is unusual.
- Dominique Legeais → bancaire / sûretés (RTD com., JCP E). Publishing in BJS is plausible.
- An unknown author cited by initials only → flag for manual verification.

### 3. Cross-status consistency

If `citation-audit-authenticity` ran first, look at each pair's pair of statuses:

| Decision | Commentary | Action |
|---|---|---|
| `✅` | `✅` | OK |
| `✅` | `⚠️` | Flag the commentary — could be invented around a real decision |
| `✅` | `❌` | Strong flag — hallucinated commentary attached to real decision |
| `⚠️` | `✅` | Flag the decision — verify it exists |
| `❌` | any | Already covered by Pass B's warning header |

## Output

A list of cross-check flags appended to the warning header (or, if `citation-audit-authenticity` produced no warning header, a new section with the same `## ⚠️ Références suspectes` heading):

```markdown
| Réf. | Texte dans le document | Problème | Paragraphe |
|------|------------------------|----------|------------|
| ! | BJS, oct. 2025, p. 12, note Crocq | Crocq publie peu en BJS ; commentaire à vérifier | §4.2 |
| ! | D. 2024, p. 781, obs. Legeais sur Cass. com. 12 sept. 2024 | Décision vérifiée, commentaire introuvable Dalloz | §5.1 |
```

If no inconsistencies are found, output a single line:

```
No internal consistency issues found.
```

Cross-check findings are advisory — they do not by themselves promote a reference to `❌ suspect` if `citation-audit-authenticity` has already verified it. They flag the **pairing**, not the individual reference.
