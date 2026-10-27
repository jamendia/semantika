---
name: eu-review-loop
description: Quality and correctness loop for the Basque semantics & pragmatics translation: layered review passes (completeness, terminology, semantic accuracy, Basque language quality, voice and humour, back-translation spot checks, Quarto build), severity levels, exit criteria, human-review packaging, and regression sweeps. Use after drafting any section or chapter, whenever asked to check, review, proofread, QA or "make sure it's right", and when integrating reviewer feedback. Never declare a chapter finished without running it.
---

# Review loop

**Core stance:** you are a translator with a known weakness (a low-resource language) and a strength (systematic checking). The loop exists so that your errors are caught by structure and by humans, not by luck. Your output is "agent-reviewed, ready for human review", never "correct".

## Severity scale (used in every report)

| Level | Meaning | Example |
|---|---|---|
| **S1** | Meaning error or misleading content | Entailment reversed; scope changed; definition altered; a hedge turned into a claim |
| **S2** | Terminology inconsistency or unsourced term | Same concept, two terms; rejected variant used; invented term presented as standard |
| **S3** | Language quality | Agreement/case error, calque, awkward syntax, spelling per Hiztegi Batua, punctuation |
| **S4** | Preference | Rhythm, word choice between equally good options |

## The passes (run in order; each produces a short section in `_review/qa-reports/NN-chapter.md`)

### Pass A: Completeness and structure (mechanical)
- `structure_check.py` clean.
- Every source paragraph, example, footnote, caption, exercise and solution has a counterpart; numbers, units, dates, names, and citations match.
- Anything intentionally changed is in `_review/changelog.md`.

### Pass B: Terminology audit
- `check_terms.py` clean (no rejected variants, expected terms used).
- Read the chapter for **concepts used without a termbase entry** (new technical words you introduced while drafting). Add them or fix them.
- Verify each first-mention gloss: Basque term (English original).
- Compare against definitions in the termbase; if the chapter defines a term differently from `definition_eu`, resolve it.
- Check that no term is simultaneously a technical term and an unmarked ordinary word in the same paragraph (collision).

### Pass C: Semantic accuracy (the one that matters most in this book)
Go through the chapter claim by claim, concentrating on:
- **Definitions** and **principles/maxims**: is the Basque definition logically equivalent to the English one? Same quantifier force, same conditionals, same scope of negation, same *necessary vs sufficient*?
- **Truth-conditional and inferential relations**: entailment, presupposition, implicature, contradiction, and contrariety are in the right direction and category.
- **Examples**: do they still demonstrate what the text says they demonstrate (see `eu-linguistic-examples`)? Re-test every ambiguity, scope, presupposition and implicature claim *in Basque*.
- **Hedging and modality**: *might / must / typically / arguably* preserved.
- **Cross-references and "as we saw in Chapter X"** claims still true.
- **Formal notation**: untouched and still matched by the prose that explains it.
- Mark each checked claim in the report; list those you could not verify.

### Pass D: Basque language quality
Read the Basque *without* the English. Check:
- Spelling and morphology against Euskaltzaindia norms (spell-checker if available; don't rely on it alone).
- **Agreement** (ergative/absolutive/dative in the auxiliary), **case on the last element of long noun phrases**, correct use of the **partitive** and of **definiteness** in negation, interrogatives and generic statements.
- Declension of loanwords and foreign names; hyphenation of compounds.
- Calque hunting: structures that mirror English or Spanish; connectors that are Spanish in disguise; periphrastic passives; "-ko" and genitive chains; excessive nominalisations.
- Sentence length and readability: split anything that makes a first-year student reread.
- Punctuation and typography per the stylesheet.
- **Search for evidence** when in doubt: a phrase that returns nothing in the corpora and dictionaries you can access is a candidate error, not a candidate innovation.

### Pass E: Voice and humour
- Strict zones strictly neutral; relaxed zones relaxed; no joke inside a definition.
- Every joke accounted for in `humor-log.md`; none added; none explained to death.
- Reader address consistent (*zu/zuek*).
- Read the first and last paragraph of every section aloud (mentally): do they sound like the same lecturer as in `voice-samples.md`?

### Pass F: Blind back-translation spot-check
This is how you detect meaning drift that looks fine in Basque.
- Select: **all definitions, all principle/maxim statements, all examples that carry an argument, all jokes, and about 10–15% of other paragraphs** (randomly chosen, plus the five densest paragraphs).
- In a **separate pass without the English visible**, translate the selected Basque back into English, literally.
- Compare to the original. Any difference in claim, scope, modality, polarity or reference → S1 or S2; investigate.
- If you cannot isolate context (single conversation), at least do the back-translation *before* rereading the English, and write it into the report so a human can inspect it.

### Pass G: Build and interactive test
- `quarto render` in `draft` profile: no warnings about references or missing resources.
- Click through every interactive widget in Basque (see `eu-quarto-book`), check UI strings and truncated labels.
- Check rendered auto-generated text (TOC, "Figure", "References", search) is in Basque.

## Exit criteria for "agent-reviewed"
- No open S1 or S2 (except those explicitly queued for a human, marked `[queued]` in the report and in `queue-for-humans.md`).
- S3 count below the agreed threshold (start with: ≤ 3 per 1,000 words after your own fixes, and tell the human the actual figure).
- All passes A–G performed and reported, even if "no findings".
- Report includes: word count, number of terms used/new, number of provisional items, examples by type (A–E), jokes adapted, back-translation sample size and results, open questions.
- Then hand over to humans. The status is `agent-reviewed`.

## The report (template)

```{}
# Chapter NN QA report: YYYY-MM-DD
Words: ... | New terms: ... | Provisional: ... | Examples A/B/C/D/E: ... | Jokes adapted: ...
## Findings fixed (by pass, with severity)
## Findings open [queued] (with queue IDs)
## Claims I could not verify (and why)
## Back-translation sample (n=..., differences found: ...)
## Suggested focus for the human reviewer (top 5 places)
```

## Human review package
Give reviewers: the rendered HTML (or PDF) plus the `.qmd` diff, the QA report, and the **top-5 focus list** (where you're least sure), plus ≤10 questions in the format of `eu-ask-the-human`. Ask them to mark comments with severity if they can. Make it easy: reviewers' time is the scarcest resource in the project.

## Integrating feedback and regression sweeps
1. Log every reviewer comment in `changelog.md` with the action taken.
2. If feedback changes a **term**: update `termbase.csv`, set `decided_by`, status `approved`, then search *all* translated chapters (script + manual) and fix every occurrence, including glossary, captions, alt text, quiz feedback, and the interactive strings.
3. If feedback reveals a **style or grammar pattern**: add a rule to `stylesheet-eu.md` and grep for the pattern across the book.
4. If feedback reveals a **semantic misreading**: look for the same kind of passage elsewhere (same construction, same concept).
5. Re-run passes A, B, G after the sweep; commit; update `STATE.md`.

## Whole-book passes (Phase 3)
- Term usage matrix by chapter; hunt for concepts that drift.
- Read all chapter openings in sequence (voice drift) and all chapter summaries (consistency of definitions).
- Verify glossary/index regenerate cleanly and match the text.
- Re-run Pass C on the five most technical chapters with a fresh pass and, if possible, a different human.

## Failure modes (specific to this project)
- **Fluent wrongness**: the Basque reads smoothly but says something slightly different (typically scope, polarity, or the strength of a claim). Pass C and F target this.
- **Invented authority**: claiming a term is "standard" without a source.
- **Silent smoothing**: fixing an obscure or ambiguous source sentence by guessing. Ask instead.
- **Over-polishing humour**: jokes that are explained, or added where none existed.
- **Review fatigue**: shorter and shorter reports as the book progresses. Keep the template; report "no findings" explicitly.
- **Self-congratulation**: writing "all verified" about things you did not check. If unchecked, say so.