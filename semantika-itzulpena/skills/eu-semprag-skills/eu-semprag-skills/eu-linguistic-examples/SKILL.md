---
name: eu-linguistic-examples
description: How to handle object-language examples, glosses, puns, logical notation and language-specific phenomena when translating a semantics & pragmatics textbook into Basque. Use whenever a passage contains an example sentence, an interlinear gloss, an ambiguity or implicature demonstration, a pun, a pronoun/article/tense-dependent example, a named classic example (Russell, Grice, Austin...), or an exercise built on English grammar. In a semantics book the examples are the data: use this skill before translating any of them.
---

# Examples are data, not decoration

In a semantics and pragmatics textbook, an example sentence is usually *evidence* for a claim about English (or another language). Translating it as if it were narrative can destroy the argument. Before translating any example, classify it.

## Classification (do this in Phase 0.4, record in the example inventory)

| Type | What it is | Treatment |
|---|---|---|
| **A. Language-neutral** | The phenomenon does not depend on English form (a scenario, a conversational exchange, a world-knowledge inference) | Translate into natural Basque; localise names and settings. |
| **B. English as object language** | The claim is about English itself (English articles, English tense, English word order, English ambiguity of a specific word) | **Keep the English example** in the text, give a Basque translation and a gloss if needed, and say that the phenomenon is English-specific. |
| **C. Replaceable by a Basque example** | The phenomenon exists in Basque too, with a different surface form | Propose a Basque example that demonstrates the *same* phenomenon. **Flag for the human**; keep the English original in `_review/` or a comment. |
| **D. Untranslatable** | A pun, a rhyme or a scope ambiguity that exists only in English | Options: keep English + explanatory Basque paraphrase; find a Basque equivalent pun/ambiguity (type C); or reduce to a plain description. **Always ask.** |
| **E. Classic example** | A named canonical example in the literature (Russell's king of France, Grice's reference letter, Moore's paradox, and so on) | Translate it faithfully, give the English original at first mention, and keep it recognisable so students can match it with the international literature. |

Every B, C, D and E decision goes to `_review/changelog.md`, and every C and D to the human queue.

## Checks that catch silent breakage

Before translating an example, ask what in the English sentence the argument depends on:

- **Pronoun gender**: English *he/she/his/her* can disambiguate reference. Basque third-person pronouns don't mark gender, so the example may become genuinely ambiguous (or be fine). Decide whether the point survives. If not, use type B/C or restructure with names.
- **Articles**: *a / the / zero* carries the definiteness and genericity point in many examples. Basque expresses definiteness differently (suffix on the noun phrase), so a one-to-one rendering can change the claim. Check that the Basque example makes the same semantic point.
- **Tense and aspect**: the English tense/aspect system maps imperfectly onto Basque verb forms. Examples about the present perfect, progressive, or sequence of tenses are almost always B or C.
- **Scope and quantifier ambiguities**: check that the Basque sentence has the *same set of readings* as the English one; Basque word order and focus can force or block readings. If the example's point is that a sentence is ambiguous, verify that the Basque version really is. When you can't verify it, ask a native-speaker reviewer.
- **Negation, polarity items, modal verbs**: English *any/some/ever*, *must/may/can* lack one-to-one counterparts.
- **Word-order and focus** (topic/focus): relevant for information-structure examples; the Basque default is different and the translation can change which element is focused.
- **Politeness and address forms**: Basque has the *zu/hi* distinction and an allocutive system in some dialects, so politeness examples can't be mapped from English *you* mechanically.
- **Lexical ambiguity or polysemy** that the example exploits (e.g. an English word with two senses): the Basque translation will likely be unambiguous. Type D.
- **Names**: localise names in type-A scenarios (Basque or widely used names, varied for gender balance). Don't touch names that are part of a classic example or that refer to real people.

## Glossing and display

- Use a consistent interlinear format (follow the Leipzig Glossing Rules unless the source book uses a different convention; then use the source book's convention and say so). Keep gloss abbreviations in a single table; translate the *explanations* of abbreviations, not the abbreviations themselves, unless the termbase says otherwise.
- Display for each non-Basque example: original line, gloss, then Basque translation. Basque examples in the text: Basque line, gloss, English or Basque free translation (decide once; record in stylesheet).
- Number examples exactly as the source does; keep labels (`{#exm-...}`) identical so cross-references survive.
- Mark acceptability judgments (`*`, `?`, `#`) exactly as in the source. A `#` (pragmatic infelicity) is not an `*` (ungrammaticality); never normalise them.
- Keep logical notation, formulae, and set-theoretic symbols untouched. Translate only the surrounding prose and the *names* of predicates if the source uses English words as predicate names *and* the book treats them as translatable; otherwise keep them (ask).

## Basque as an opportunity (never on your own initiative in the main text)

Basque grammaticalises several pragmatic and semantic phenomena that make excellent examples: evidential and reportative marking by particles, interrogative uncertainty particles, allocutive agreement (a verb form encoding the addressee), the interplay of focus and word order, and politeness distinctions in address. These are *opportunities*, not obligations.

- You may **propose** boxed extras ("Euskaraz zer?"-style callouts) or exercise ideas in `_review/proposals.md`, each with the phenomenon, a candidate example, a source for the Basque facts, and where in the book it fits.
- **Never insert them into the main text without author/human approval.** The translation's job is fidelity; additions are the author's call.
- Always verify the Basque facts against a reference grammar or a native-speaker linguist before proposing; do not rely on your own intuition for subtle judgments.

## Procedure for each example set
1. Classify (A–E).
2. For B/C/D/E decide treatment and log it.
3. Translate or build the Basque example; test whether the *claim* still holds (the readings, the implicature, the presupposition).
4. For C/D: write a two-line note for the human: "English example / why it breaks in Basque / my proposal / alternatives".
5. Mark the example `{.exm-pending}` in draft if not yet approved.
6. After human feedback, record the pattern in the stylesheet ("how we treat gender-disambiguating examples", etc.) so later chapters follow it.
