# Skills for translating a semantics & pragmatics textbook into Basque (Quarto)

Seven skills, in the order the agent should meet them.

| # | Skill | Job |
|---|---|---|
| 1 | `eu-translation-orchestrator` | Master workflow. Phase 0 (set up the workflow, resource inventory, pilot chapter) comes before any translation. |
| 2 | `eu-terminology` | Resource tiers, decision ladder for terms, coinage rules, termbase schema, glossary generation. Includes `scripts/check_terms.py`. |
| 3 | `eu-academic-voice` | Academic-but-relaxed-and-funny voice, humour handling, anti-calque rules, one-time style decisions. |
| 4 | `eu-linguistic-examples` | Examples are data: classification A–E, what breaks in Basque, glossing, Basque-specific opportunities. |
| 5 | `eu-quarto-book` | What to translate in .qmd, what never to touch, language settings, interactive/OJS localisation, draft/release profiles. Includes `scripts/structure_check.py`. |
| 6 | `eu-review-loop` | Passes A–G, severity levels, exit criteria, back-translation, human package, regression sweeps. |
| 7 | `eu-ask-the-human` | When and how to ask for help; question-card format; provisional markers. |

## Install
Copy each folder into the agent's skills directory (keep the folder names; they match the `name:` in each SKILL.md).
The two scripts should be copied into the book repo's `scripts/` folder during Phase 0.

## Things to check before relying on these skills
- Resource names (EUSKALTERM, Hiztegi Batua, Elhuyar, OEH, EPG, UZEI, UEU, Termcat...) are starting points. The agent is told to verify access and names itself; correct the list in `eu-terminology` with what your team actually uses.
- Any Basque sentence inside the skills is illustrative and has not been reviewed by a human linguist.
- The Quarto details (Basque UI strings, CSL locale, babel hyphenation) depend on your Quarto version: the skills instruct the agent to test on a render and override where needed.

## Suggested first prompt to the agent
"Read `eu-translation-orchestrator`. Start Phase 0: send me your setup questions in one batch, then propose the project skeleton and the resource inventory plan. Don't translate anything yet."
