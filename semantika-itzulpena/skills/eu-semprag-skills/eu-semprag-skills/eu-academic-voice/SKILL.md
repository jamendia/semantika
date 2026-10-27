---
name: eu-academic-voice
description: Tone, register and style rules for the Basque version of the semantics & pragmatics textbook: academic but relaxed and humorous, natural standard Basque (euskara batua), no calques. Use whenever drafting, rewriting, polishing or reviewing Basque prose for the book, adapting a joke, pun, aside or pop-culture reference, choosing how to address the reader, or deciding typographic and orthographic conventions. Use it even for short passages like callout text, exercise prompts and captions.
---

# Voice: academic, relaxed, funny, and actually Basque

## The target voice in one paragraph

A good lecturer who knows the material cold and doesn't need to prove it. She explains precisely, allows herself a raised eyebrow, and trusts the reader. The register is **standard Basque (euskara batua), formal enough to cite, loose enough to read in bed**. Humour is dry, usually understated, and always serves understanding. The Basque must read as if it had been *written* in Basque, not translated from English; a reader should not be able to guess the source language from the syntax.

## What stays strict and what may relax

| Zone | Rule |
|---|---|
| Definitions, theorems, principles, formal notation, truth conditions, maxims, step-by-step derivations | **Precise, neutral, no jokes.** Meaning identical to source. |
| Explanations, motivation, transitions, chapter openings/closings, summaries | Relaxed voice, rhetorical questions, direct address, understatement. |
| Examples, scenarios, exercises, asides, callouts | Where humour lives. Keep or adapt the source's jokes; localise scenarios. |

Humour never changes a claim. If a joke would make a technical sentence ambiguous, move the joke to the neighbouring sentence.

## Translating humour: function first

For every joke, pun or aside in the source, decide what it *does*:

1. **Decorative** (a smile; no teaching function) → translate the effect, not the words. Free to recast, shorten, or swap for a natural Basque equivalent of the same size and flavour.
2. **Illustrative** (the joke *is* the example: a pun showing ambiguity, an ironic remark showing implicature) → this is linguistic data. Follow `eu-linguistic-examples`: you may need a different Basque example demonstrating the same phenomenon. Always flag to the human.
3. **Cultural** (refers to US/UK culture, celebrities, brands, TV) → options: (a) keep with a half-sentence of context if the reference is part of the point; (b) substitute a reference a Basque university student would get (Basque, Iberian or global culture) with the same function; (c) drop and log. Prefer (b) when it's cheap and tasteful; ask when the substitution is a "creative leap".
4. **Self-referential** (the author joking about the book or about linguists) → keep; this is the voice.

Rules:
- **Log every adapted joke** in `_review/humor-log.md`: source line, function type, what you did, and alternatives you rejected.
- **Humour density should match the source**, not exceed it. Don't "improve" the book by adding jokes. If you spot a spot where a Basque-only joke would be a gift (e.g. a language-specific pragmatics example), put it in a margin proposal for the human instead of the text.
- Basque humour tends to land through understatement, irony, deadpan, and sudden concreteness. Avoid exclamation-mark-driven comedy and mechanical word-for-word translations of English quips.
- Don't joke at the expense of dialects, regions, minority groups, or languages (this is a book about a minority language's first semantics textbook; it should be a friendly place).
- A joke that needs explaining is a joke that has failed. If you can only make it work with a footnote, it's an `ask-the-human` case.

## Addressing the reader

- Address the reader as **zu** (singular, formal-neutral) by default and **zuek** where the source addresses a plural audience. Never **hi** (unless inside an object-language example that demonstrates it).
- Authorial "we" → inclusive first person plural (*ikus dezagun…*, *demagun…*) used moderately.
- Imperatives for exercises and "try this" prompts: short and friendly.
- **Decision to take once** (see below): consistent use of *zu* in interactive feedback ("Zuzen!", "Ia-ia") so that the UI voice matches the prose voice.

Illustrative examples of the register (a human must check them; do not treat as a style authority):

> Demagun Mikelek «Hotz dago hemen» esaten duela. Leihoa ixtea eskatzen ari da, ala eguraldiaren berri ematen besterik ez?

That is the tone: a concrete everyday scene, a question the reader can answer, no ceremony.

## Writing natural academic Basque (anti-calque rules)

Check your draft against these; consult Euskaltzaindia's grammar when in doubt, and ask when a rule below collides with the source's meaning.

1. **Don't mirror English syntax.** Re-plan the sentence in Basque order: topic first, new/focal information immediately before the verb, verb at the end of its clause by default. If the English sentence is a long chain of postmodifiers, split it.
2. **Prefer short and medium sentences**; academic does not mean long. One idea per sentence, and let connectors do the work.
3. **Beware stacked genitives and *-ko* chains** (X-ren Y-ren Z-ko…). Break them with verbs or relative clauses. Beware piles of nominalisations in *-tze* and *-pen*.
4. **Avoid the English/Spanish periphrastic passive.** Prefer active voice, impersonal constructions, or restructured subjects that sound natural in Basque.
5. **Check relative clauses and long subordination** for agreement and for the right case on the *last* element of the noun phrase (Basque case is marked at the phrase edge).
6. **Check ergative/absolutive/dative agreement** in the auxiliary whenever the clause is long or the sentence has three arguments. This is where fluent-looking Basque breaks first.
7. **Don't import Spanish connectors and idioms** (*por lo tanto*-type calques, *sin embargo*-type calques, etc.). Look for native connectors and idiomatic alternatives, and use evidence from corpora when unsure.
8. **Vary connectors**; don't let every sentence open with the same *beraz/hortaz/orduan*.
9. **Loanwords**: adapt per Euskaltzaindia's rules, and decline them correctly (final-letter/phonetic issues). Check each new loan.
10. **Dialect**: standard Basque only in narration. Dialectal forms are allowed only as deliberate object-language examples, labelled.
11. **Hedging**: preserve the author's degrees of certainty (*may, might, arguably, seems to*): do not strengthen or weaken them.
12. **Generic statements and definiteness**: Basque marks definiteness with a suffix, so English generic/definite/indefinite choices (*a/the/zero*) do not map one-to-one. Check each generic claim for a natural Basque form without changing its scope; this matters a lot in semantics, where the source's article choice may be the *topic*.
13. **Pronouns**: Basque has no gender distinction in third-person pronouns. English "he/she/his/her" disambiguation does not carry over (see `eu-linguistic-examples`).

## Decisions to take once (record in `_style/stylesheet-eu.md`; ask the human if the norms leave room)

- Quotation marks for prose quotes, for linguistic expressions (object-language), for meanings, and for scare quotes; and how italics/bold/small caps are used for terms, glosses and meanings (in semantics the convention matters: don't break it).
- Decimal separator and number formatting; date and time formats.
- Hyphenation of compounds and of technical prefixes (apply Euskaltzaindia's rules; record exceptions).
- Treatment of foreign names and of acronyms in declension.
- How to cite English-language works in the text (original title only, translated title in brackets, etc.).
- UI voice for interactive feedback, buttons, and quiz messages (*zu*; tone; punctuation).
- Whether the preface explains the term-handling convention ("English original in brackets at first mention").

## Procedure for each section

1. Read the section and the next one. Decide its **zone map**: strict zones vs relaxed zones.
2. Draft in Basque from meaning, not from English wording (paraphrase the English to yourself first).
3. Re-read the Basque *without* the English open. Does it flow? Does it sound like a lecturer or like a translation?
4. Compare with the English for meaning, hedges, scope, examples.
5. Humour check: every joke accounted for in `humor-log.md`.
6. Run the anti-calque checklist above.
7. Compare against `_style/voice-samples.md`; add the section as a new sample **only** after a human approves it.

## Consistency over cleverness
Voice drifts over a long book. At the start of each session reread two approved voice samples. Every ten chapters, compare openings and closings across the book (see `eu-review-loop`, whole-book passes).
