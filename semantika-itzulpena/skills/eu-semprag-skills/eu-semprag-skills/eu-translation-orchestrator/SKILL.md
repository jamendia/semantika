---
name: eu-translation-orchestrator
description: Master workflow for translating an English semantics & pragmatics textbook into Basque (euskara batua) as a Quarto book. Use at the start of every session and whenever the task is to set up, plan, resume, or advance the translation project, BEFORE translating any text. Make sure to use this skill whenever the user mentions the Basque textbook, "the book", a chapter, project setup, workflow, progress, or just says "continue" or "do the next chapter". It decides what happens in what order and tells you which of the other eu-* skills to load at each step.
---

# Orchestrator: semantics & pragmatics textbook, English → Basque

You are translating what may be the first university textbook of semantics and pragmatics written in Basque. Two things follow from that:

1. **There is no safety net.** There are no earlier Basque textbooks to copy terminology from, so every terminological choice becomes a precedent. Slow, documented decisions beat fast, silent ones.
2. **Basque is a low-resource language for you.** You will sometimes produce fluent-looking Basque that is wrong (invented terms, Spanish calques, broken case/agreement in long sentences). Your job is not to be infallible; it is to be *traceable* (every term has a source), *checkable* (scripts and review passes catch you), and *honest* (you ask a human when evidence runs out).

## Non-negotiable rules

- **Workflow before words.** Do not translate a single paragraph until Phase 0 is done and the human has signed off on it.
- **Never present an invented term as an attested one.** A term is "standard" or "attested" only if you found it in a named source during this project. Otherwise it is `proposed`.
- **Never edit the English source.** `src-en/` is read-only.
- **Never silently drop, merge, or add content.** Every omission or addition goes in the changelog and, if it matters, to a human.
- **Decisions are written down.** If it isn't in `_terminology/` or `_style/`, it doesn't exist in the next session. You have no memory between sessions except the files.
- **Asking for help is part of the method, not a failure.** See `eu-ask-the-human`.

## Session-start ritual (every session, no exceptions)

1. Read `STATE.md` (where we are, what's blocked, what was decided last).
2. Read `_style/stylesheet-eu.md` and skim `_terminology/termbase.csv` (at least the terms for the current chapter).
3. Read `_review/queue-for-humans.md` and fold in any answers the humans left; update termbase/stylesheet accordingly and note what changed in `STATE.md`.
4. Only then pick up work.

At the end of every session, update `STATE.md` (done / in progress / blocked / next).

## Phase 0: Set up the workflow (first task, always)

Goal: a reproducible project where terminology, style, review and builds are all under control. Work through this checklist and report to the human at the end.

### 0.1 Ask the human the setup questions (one batch, use `eu-ask-the-human` format)
- Which terminological/lexicographic resources can you actually reach (open web, paywalled, downloadable files, local copies)? Which ones does the team consider authoritative for this domain?
- Who are the human reviewers (linguists? Basque philologists? the author?), how much time do they have, and in what format do they prefer to review (git diffs, rendered HTML, comments in a doc)?
- Do we have permission and a contact for the original author(s) (for jokes, examples, and ambiguous source passages)?
- Target outputs: HTML book only, or also PDF/ePub? Hosting?
- Orthographic/typographic decisions that need a human ruling (see `eu-academic-voice`, section "Decisions to take once").

### 0.2 Create the project skeleton
```
book/
├── _quarto.yml
├── STATE.md                      # living status file
├── src-en/                       # READ-ONLY copy of the English source (.qmd)
├── chapters/                     # Basque .qmd, same filenames and structure as src-en/
├── _terminology/
│   ├── termbase.csv              # THE source of truth for terms (schema in eu-terminology)
│   ├── candidates.csv            # extracted-but-undecided terms
│   ├── decisions.md              # prose rationale for non-obvious choices
│   └── resources.md              # inventory of resources: what, where, tier, access date
├── _style/
│   ├── stylesheet-eu.md          # orthography, typography, address forms, recurring phrasings
│   └── voice-samples.md          # approved "golden" paragraphs for tone
├── _review/
│   ├── queue-for-humans.md       # questions waiting for answers
│   ├── humor-log.md              # every joke/pun adaptation
│   ├── qa-reports/               # one per chapter per pass
│   └── changelog.md              # additions/omissions/deviations from source
├── glossary/                     # generated from termbase.csv
└── scripts/                      # structure_check.py, check_terms.py, ...
```
Copy the scripts from `eu-quarto-book/scripts/` and `eu-terminology/scripts/` into `scripts/`. Use git; one branch per chapter; commit after every pass.

### 0.3 Build the resource inventory
Follow `eu-terminology`, section "Phase 0: resource inventory". Test each resource with 5 known linguistics terms (e.g. *semantics*, *deixis*, *speech act*, *entailment*, *scope*) and record whether it answers, how, and how reliably. This is both a smoke test and a calibration of which resources are useful for this domain.

### 0.4 Read the whole English book once, before translating
Produce, in `_review/qa-reports/00-source-analysis.md`:
- A chapter map (titles, dependencies, which chapters introduce which core notions).
- A first-pass **term extraction** into `candidates.csv` (every defined term, bold term, glossary entry, index entry; plus recurring technical verbs and adjectives).
- An **example inventory**: count and classify the object-language examples (see `eu-linguistic-examples`).
- An **interactive inventory**: every code cell, widget, quiz, figure, callout type, shortcode, and external dependency (see `eu-quarto-book`).
- A **humor inventory**: where the source is funny, and *how* (puns, irony, absurd scenarios, asides, pop-culture references).
- A **risk list**: passages likely to be hard (language-specific examples, wordplay, anything relying on English grammar).

### 0.5 Pilot chapter
Choose the shortest chapter that still has a definition, an example set, a joke and an interactive element. Run it through the full chapter loop below, with extra human attention. Outcome: stylesheet v1, voice samples, and a first batch of approved terms. **Freeze these as v1 before moving on**, and tell the human what you froze.

Phase 0 is done only when the human says so.

## Phase 1: Foundational terminology first

Before translating chapters in order, take the terms that appear in the first two chapters and across many chapters (the "load-bearing vocabulary": meaning, sense, reference, truth conditions, entailment, presupposition, implicature, speech act, context, etc.) and settle them with `eu-terminology` and `eu-ask-the-human`. Early term decisions are the most expensive ones to reverse. Batch these questions.

## Phase 2: Chapter loop (repeat for each chapter)

1. **Prepare**: re-read the chapter; list its terms from `candidates.csv`; resolve any undecided ones (or mark provisional and queue questions).
2. **Translate in sections** (about 300–800 words at a time, always with the previous and next section visible for context). Load `eu-academic-voice`, `eu-linguistic-examples`, `eu-quarto-book` as relevant.
3. **Structure check**: run `scripts/structure_check.py` (headings, labels, cross-refs, code cells, callouts, citations must match the source).
4. **Run the review loop** from `eu-review-loop` (passes A–G). Fix; re-run until the exit criteria are met.
5. **Package for humans**: chapter report + top questions from `queue-for-humans.md`. Mark the chapter `agent-reviewed` in `STATE.md`. Do not call it `done`.
6. **Absorb human feedback**: update termbase/stylesheet, then run a **regression sweep** over already-translated chapters for anything the feedback affects (see `eu-review-loop`).
7. Mark `human-reviewed`; freeze.

Chapter statuses: `not-started → drafted → agent-reviewed → human-reviewed → frozen`.

## Phase 3: Whole-book passes
- Terminology consistency across all chapters; regenerate glossary and index.
- Cross-reference and link check; render all formats; accessibility check.
- Voice consistency read of chapter openings and closings across the book (tone drift is common in long projects).
- Final human read of the front matter, preface, glossary and the funniest chapter.

## Phase 4: Release
`check_terms.py --release` must pass (no pending/provisional terms), all questions in the queue closed or consciously deferred, changelog complete, build green.

## When things go wrong
- *You're unsure about meaning in the source*: ask the human/author; don't guess and smooth over.
- *A resource contradicts another*: record both in `decisions.md` and ask.
- *You catch your own earlier error*: fix it, log it in `changelog.md`, search for the same error elsewhere (regression sweep), and add a rule to `stylesheet-eu.md` if it could recur.
- *You are running long and quality drops*: stop, update `STATE.md`, resume next session. Fatigue shows up as calques and flat tone.
