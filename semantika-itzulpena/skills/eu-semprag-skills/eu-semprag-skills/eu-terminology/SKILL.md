---
name: eu-terminology
description: Build and maintain the Basque terminology for the semantics & pragmatics textbook: inventory terminological banks, dictionaries and thesauri, extract terms, choose or coin Basque equivalents, record them in a termbase, and generate the glossary. Use whenever a technical term, a term variant, a coinage, a glossary/index entry, or a proper-name declension question comes up, and during Phase 0 resource setup. Use it even for "small" word choices in a definition, because in this project every term choice is a precedent.
---

# Terminology for the Basque semantics & pragmatics textbook

## Principles

1. **Attested beats elegant. Standard beats attested. Human-approved beats everything.**
2. **Every term has a provenance.** Source name, entry or URL, date consulted. No source → status is `proposed`, and you say so.
3. **One concept, one term, throughout the book** (and one term, one concept: avoid homonymy inside the book).
4. **Consider the term family, not the isolated word.** If you choose a noun, check that a usable adjective, verb, agent noun and negation exist for it (think: *presuppose / presupposition / presuppositional / presupposed*). A pretty noun with no derivatives is a bad choice.
5. **Students will read this first.** Prefer transparent, morphologically productive formations over opaque loans, unless the loan is already the community's usage.
6. **Don't trust your own sense of what "sounds Basque".** For a low-resource language your intuition is the weakest evidence you have. Evidence ladder below.

## Phase 0: resource inventory

The Basque terminological ecosystem is good, but you must verify what is reachable *now*. Build `_terminology/resources.md` with one row per resource: name, type, tier, access method, licence/permission to cache, date checked, what you tested, verdict. **Do not assume a resource exists or is reachable because it appears in this list; confirm names and URLs by searching, and ask the human for the ones you cannot reach.**

Starting list (names to look for; confirm each and add the ones the team already uses):

| Tier | Purpose | Candidates to look for |
|---|---|---|
| 1. Normative | Spelling, morphology, grammar, loanword adaptation | Euskaltzaindia's *Hiztegi Batua* (the standard dictionary), Euskaltzaindia's published rules (*Arauak*), and its grammar (*Euskararen Gramatika*/EGLU) |
| 2. Terminology banks | Domain terms, official equivalents | EUSKALTERM (public Basque terminology bank; check the linguistics/Hizkuntzalaritza domain and related fields such as logic, philosophy, psychology, computing); terminology published by UZEI, Elhuyar, and by the UPV/EHU and UEU (Udako Euskal Unibertsitatea) |
| 3. General dictionaries and thesauri | Senses, collocations, synonyms, register | Elhuyar hiztegia (multilingual), *Orotariko Euskal Hiztegia* (OEH, historical attestations), synonym dictionaries and thesauri available to the team |
| 4. Corpora and usage evidence | Frequency, real usage, collocations | Standard-Basque corpora such as *Ereduzko Prosa Gaur* (EPG) and any corpus the team can query; news and academic Basque as secondary evidence |
| 5. Existing Basque scholarship | How Basque linguists already write about this | Basque-language linguistics articles, theses and course materials (journals and series such as ASJU, FLV, Uztaro, UEU publications); Basque Wikipedia as a *signal of circulating usage only* (low authority) |
| 6. Peer languages | Neologism strategies, not translations | Catalan (e.g. Termcat), Galician, Spanish and Irish/Welsh equivalents. Use to see *how others solved the problem*, never to copy: Spanish especially is a calque trap. |

Smoke test: query each reachable resource for *semantics, pragmatics, deixis, speech act, entailment, scope, anaphora, implicature*. Record which ones return what. This tells you early which of the load-bearing terms already have standard Basque equivalents and which are open problems.

Also check what exists as *Basque books on linguistics*: even if no semantics textbook exists, general linguistics, logic and philosophy-of-language texts in Basque already use some of this vocabulary. Reuse it; do not reinvent.

## Term extraction (Phase 0.4 and per chapter)

Extract into `candidates.csv`: bolded/defined terms, glossary and index entries, names of theories/principles/maxims/operators, recurring technical verbs ("entail", "presuppose", "scope over"), technical adjectives, notation names, and named people. Include multiword terms and keep the source sentence for context. Group into families.

## Decision procedure for each term

Work down the ladder; stop at the first rung that gives a clear answer, and log the rung.

1. **Standard entry exists** (Tier 1–2, same concept, same domain) → adopt. Status `standard`. Record the entry.
2. **No standard entry, but attested** in Basque scholarship or dictionaries (Tier 3–5) → adopt the best-supported variant. Status `attested`. Record all variants seen and where.
3. **Several competing variants** → compare on:
   - normative status and register;
   - semantic transparency for a first-year student;
   - derivational productivity (does the family work?);
   - frequency/real use (give counts when you have them, and say how you got them);
   - collision risk with another concept in this book;
   - coherence with neighbouring terms already decided (a *speech act* family should look like a family).
   If one variant clearly wins on most criteria, adopt it (`attested`) and log why. If it's close or it's a load-bearing term → **ask** (see `eu-ask-the-human`), with a recommendation.
4. **No equivalent anywhere** → coin, in this order of preference:
   a. an established loan, adapted to Basque spelling following Euskaltzaindia's rules for loanwords;
   b. a compound or derivation using productive Basque morphology, modelled on existing terms of the same type;
   c. a calque only if the source language is not Spanish/English-pattern-driven and the result is natural;
   d. a short descriptive paraphrase for first mention, with a compact label to use afterwards.
   Propose **2–3** candidates with a recommendation; status `proposed`; use the provisional marker below; queue a question. Never decide a coinage alone.
5. **Keep in English** (rare): e.g. a label that is itself the object of study (a maxim's name quoted as a name, a formal-notation symbol, a software command). Mark it as object-language, italic or code as per `eu-quarto-book`.

Illustrative dilemmas you will meet (candidates only, **unverified**; do not copy them into the termbase without sources): *entailment* vs. *presupposition* vs. *implicature* each need clearly distinct Basque terms that don't collapse into "inference"; *scope* needs one term that works for quantifiers, negation and operators; *speech act* needs a family covering locutionary/illocutionary/perlocutionary; *felicity conditions*, *common ground*, *deixis*, *face*, *relevance* each have more than one plausible rendering.

## Termbase schema (`_terminology/termbase.csv`)

One row per concept (not per word). Columns:

`id, en, en_variants, eu_preferred, eu_variants_allowed, eu_rejected, pos, family_id, domain, definition_en, definition_eu, status, sources, rationale, first_chapter, collisions, decided_by, date`

- `status` ∈ `standard | attested | proposed | provisional | approved` (`approved` = human signed off; every term should end here before release).
- `eu_rejected`: **stems/substrings** (not full inflected forms) that must never appear, so scripts can catch them.
- `definition_eu`: write it in your own words from the book's definition; reviewed by a human.
- `sources`: `NAME|entry-or-URL|YYYY-MM-DD` separated by `;`.
- `collisions`: other terms it could be confused with.
- Add derivatives as their own rows (or in `family_id`) so the whole family is searchable.

## Using terms in the text

- **First mention**: Basque term, with the English original in parentheses and italic: *inplikatura* (*implicature*) [illustrative formatting]. Subsequent mentions: Basque only. Chapter 1 or a preface explains this convention once.
- Define a term where the book defines it, using the `definition_eu` as the base.
- **Provisional marker** while a term is unresolved: `[term]{.term-pending data-id="T0123"}`. It renders highlighted in the `draft` profile and **fails the release build** (see `eu-quarto-book`). Never leave a proposed term unmarked.

## Proper names, abbreviations and citations
- Authors (Grice, Austin, Searle, Kripke, Montague, Levinson, etc.): keep original spelling. Inflection of foreign names (final silent letters, hyphen or apostrophe policy, and how to write suffixes after them) follows Euskaltzaindia's rules; **record the chosen pattern in the stylesheet once and ask a human if the rules leave room**.
- Abbreviations (QUD, CG, DRT, etc.): keep the standard international form when it is the community's usage; the first mention gives the Basque expansion if one is approved.
- Bibliography: keep titles in their original language; add a Basque translation only if the book does so for other languages.

## Glossary and index
- Generate `glossary/glossary-eu.qmd` from `termbase.csv`: Basque term → definition → English equivalent; plus an EN→EU lookup table (this is what students and other translators will use).
- Generate an index from the same file so index entries and text can't drift.
- Publish `termbase.csv` with the book (licence permitting): it is a contribution in its own right and invites correction from the community.

## Scripts
- `scripts/check_terms.py`: rejected variants in the text, pending markers, release gate. Run on every chapter (see `eu-review-loop`).

## Failure modes to guard against
- Treating a Spanish or English-shaped formation as "standard Basque" because it sounds plausible.
- Choosing a term for the noun and discovering later that the adjective is unusable.
- Different chapters (or different sessions) using different terms for one concept. Always check the termbase at session start.
- Forgetting that a chosen term collides with a general-language word used in the same chapter (e.g. an everyday word that is now also technical).
