---
name: eu-quarto-book
description: Technical rules for translating and building the Basque textbook as a Quarto book: what to translate and what never to touch in .qmd files, language settings, cross-references, citations, glossary/index generation, draft vs release profiles, and how to localise interactive material (Observable JS widgets, quizzes, code cells, callouts, figures). Use whenever editing or creating .qmd/YAML files, localising interactive content or UI strings, running or fixing a Quarto build, or checking that the Basque version has the same structure as the English source.
---

# Quarto mechanics for the Basque edition

Translation inside Quarto is a structural editing job as much as a linguistic one. A beautiful Basque paragraph that breaks `@fig-` references is a broken book.

## Golden rule: same skeleton, new words

`chapters/xx.qmd` must have **the same structure as `src-en/xx.qmd`**: same headings and levels, same labels/IDs, same code cells, same callouts, same figures and tables, same citations, same shortcodes. Run `scripts/structure_check.py` after every section and before every commit.

## What to translate vs. what to leave alone

| Element | Action |
|---|---|
| Prose, headings text, captions (`fig-cap`, `tbl-cap`, `lst-cap`), callout titles, alt text, footnote text | Translate |
| YAML values for `title`, `subtitle`, `abstract`, `description`, navbar/sidebar text, `lang`-dependent labels | Translate (`lang: eu`) |
| YAML keys, class names, option names, file names, URLs | **Never** translate |
| Labels and IDs: `{#sec-...}`, `{#fig-...}`, `{#tbl-...}`, `{#eq-...}`, `{#exm-...}` | **Keep identical to source** (stable cross-references and deep links) |
| Cross-references `@sec-...`, citations `@key`, `[@key, p. 12]` | Keep keys; translate locator words if the citation style doesn't do it for you |
| Shortcodes `{{< ... >}}` | Keep; translate only the *human-visible* argument text (e.g. a caption) |
| Code (R, Python, Julia, OJS, JS) | Don't change logic or identifiers. Translate **comments, labels, user-visible strings and plot text** |
| Math and logical formulae | Untouched (unless the termbase says to rename a predicate) |
| Image files | Keep file names; if an image contains English text, flag it (needs a redrawn Basque version) |
| Bibliography `.bib` | Keep entries as they are |

## Language and build settings

- In `_quarto.yml` set `lang: eu`. Quarto UI strings (table of contents, "Copy code", search UI, callout defaults, "Abstract", "References", cross-reference prefixes such as "Figure") may not have built-in Basque; **check on a test render** and, where missing or wrong, override them via the `language:` key in YAML. Keep all overrides in one file (`_language-eu.yml`) and include it from the project config. Record which strings you chose in `_style/stylesheet-eu.md`.
- PDF/LaTeX output: ensure Basque hyphenation (babel's Basque support) and fonts that cover all characters you use. Test with a long chapter; bad hyphenation shows up in long agglutinated words.
- Bibliography: check whether a Basque CSL locale is available; if not, use an English locale with translated labels via the `language:` overrides.
- Make **two profiles**: `draft` (shows `.term-pending` and `.exm-pending` highlighting, comments, a "pending questions" count banner) and `release` (hides nothing, but the build **fails** if pending markers remain; `check_terms.py --release` runs as a pre-render script).
- Files whose names start with `_` are skipped by Quarto during rendering: keep working files there (`_terminology/`, `_review/`, `_style/`).

## Cross-references and numbering
- Keep numbering conventions identical to the source. Translate the *prefix text* (e.g. what "Figure" or "Example" turns into) via the `language:` override or `crossref:` options. Choose one form and write it in the stylesheet.
- If Basque grammar needs a case suffix after a cross-reference (@fig-x-ren…), use a form that works with whatever prefix text is generated; test the rendered output, not the source. If it can't be made natural, rephrase the sentence rather than hacking the reference.

## Glossary, index, and tooltips
- Generate `glossary/glossary-eu.qmd` from `_terminology/termbase.csv` with a small script (Python or R), run as a `pre-render` step. Never maintain the glossary by hand.
- First-mention convention: *Basque term* (*English original*). If the book uses hover tooltips, generate them from the termbase (data attributes or Quarto extension), so text and glossary can't diverge.
- Keep index entries (`index` mechanism of your choice) in the termbase too.

## Interactive materials: localise, don't rewrite

Typical formats in a book like this: Observable JS (OJS) cells and inputs, small JavaScript widgets, R/Python (WebR/Pyodide) cells, quizzes, show/hide solutions, drag-and-drop classification of utterances, truth-table or scope explorers, "fill the context" dialogue builders, polls.

**Principles**
1. **Separate strings from logic.** At the top of each interactive chunk, put a single `strings` object (or a YAML/JSON file loaded once) with every user-visible message. Translate only that. This makes the Basque version diff-able and lets future languages reuse the code.
2. **Never change behaviour while translating.** If an interaction depends on English input (it parses English sentences, matches English keywords, expects English answers), you cannot just translate the strings: flag it to the human; the logic may need to be redesigned for Basque input. Do not "fix" it yourself.
3. **Feedback messages are part of the voice.** Quiz feedback ("Correct!", "Not quite") should sound like the book's narrator, in *zu* register, short, friendly, and never condescending. Keep the tone consistent with `eu-academic-voice`.
4. **Answers keys and distractors are content.** Translate with the same care as definitions: a distractor that is accidentally correct (or accidentally ambiguous) in Basque is a bug. Test each quiz item in Basque as if you were a student.
5. **Basque input handling**: for free-text answers, don't rely on exact string match. Basque inflection means the same answer can have several forms. Prefer multiple-choice, ordering, or tolerant matching (normalise case/diacritics, accept listed variants, or match on stems).
6. **Accessibility**: provide Basque alt text for every figure and widget; keyboard operability; contrast; no flashing. Label inputs in Basque and set the element language where English is quoted (`lang="en"` on English object-language examples so screen readers pronounce them correctly).
7. **Offline-friendly and shareable**: avoid dependencies that need accounts, trackers or paid APIs. Prefer client-side computation so the book works as a static site. Record every external dependency in the interactive inventory.
8. **Test in the browser.** After translating an interactive chunk: render, click through every path, check that strings are not truncated by longer Basque words (Basque words are often longer than English ones; check buttons, table headers, plots' labels and mobile layout).

**Ideas for new interactives** are the author's call. Propose in `_review/proposals.md`; don't add on your own.

## Per-chapter technical procedure
1. Branch `chapter-NN`. Copy `src-en/NN.qmd` to `chapters/NN.qmd` (this guarantees an identical skeleton), then replace text in place, section by section.
2. After each section: `python scripts/structure_check.py src-en chapters` (non-zero exit means a mismatch to fix).
3. After the chapter: `quarto render chapters/NN.qmd` in the `draft` profile. Fix warnings: unresolved references, missing citations, overflow, broken widgets.
4. Commit with message `NN: pass X (draft|terms|style|qa)`; attach the QA report path.
5. Before release: render the full book in the `release` profile, run link check, run spell check using a Basque dictionary if available, and verify the glossary and index are regenerated.

## Common mistakes
- Translating a label (`{#sec-semantica}` instead of `{#sec-semantics}`) and breaking every reference to it.
- Translating an option name or class in a code chunk header.
- Leaving English strings in OJS inputs, plot axis labels, tooltips, or error messages.
- Letting auto-generated text (e.g. "Figure 1", "Table of contents", "Search") remain English because nobody looked at the rendered page.
- Typographic quotes in code or YAML: curly quotes break parsing. Use straight quotes in code/YAML and typographic ones only in prose, per the stylesheet.
- Silent line-wrapping edits that make diffs unreadable for human reviewers: keep paragraph/line structure aligned with the source (one sentence per line is a good practice if the source does it).

## Scripts
- `scripts/structure_check.py <src-dir> <eu-dir>`: compares headings, labels, cross-refs, citations, code cells, callouts/divs, shortcodes and images between the English source and the Basque version.
