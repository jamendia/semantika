---
name: eu-ask-the-human
description: Protocol for when and how to ask human experts for help choosing between Basque terminology variants, coinages, sentence renderings, example adaptations and jokes, and how to keep working while waiting. Use whenever evidence is insufficient or conflicting, a term is load-bearing, a coinage is needed, a source sentence is ambiguous, a joke or example cannot be carried over, or a style rule must be decided. Asking is expected and encouraged in this low-resource setting; use this skill to ask well.
---

# Asking for help, efficiently

Basque is a low-resource language and this is a first-of-its-kind book. Human judgment is a **resource built into the workflow**, not a fallback of last resort. But reviewers' time is limited and precious, so ask *rarely enough to be heard and often enough to be safe*.

## Ask when…

1. **Evidence conflicts or runs out**: resources disagree, or no resource covers the concept.
2. **A term is load-bearing** (appears across many chapters or anchors a family of terms) and more than one option is plausible, even if you have a favourite.
3. **You'd be coining**: any new term. Always.
4. **The source is ambiguous** or looks wrong: ask rather than guess (ask the author or the human, as the project directs).
5. **An example, pun or joke can't be carried over** (types C, D in `eu-linguistic-examples`) or a cultural reference requires a creative substitution.
6. **A style or typography rule isn't determined by the norms** (see "Decisions to take once" in `eu-academic-voice`).
7. **Two renderings of a sentence differ in meaning or emphasis** in a way a native linguist would feel, and you can't tell which is better.
8. **You find a recurring problem** (a pattern, not an instance) and want a rule.

## Don't ask when…
- A resource you can reach already answers it (look first; cite what you found).
- It is a S4 preference and the stylesheet gives no guidance: choose, log, move on.
- You have already asked the same question (check `queue-for-humans.md` and `decisions.md`).
- The question is really "please do my job": narrow it to a choice.

## How to ask: the question card

Every question is a card in `_review/queue-for-humans.md` with a stable ID. Keep each card readable in under a minute.

```
### Q-0042 | TERM | priority: high | blocks: chapters 2–6 | status: open
Concept: "implicature" (EN: conversational implicature)
Context (source sentence, 1–2 lines): "..."
Options:
  A. <term A>   evidence: <source/entry>, <usage count if any>
  B. <term B>   evidence: ...
  C. <term C> (my coinage, no attestation)
My recommendation: A, confidence: medium. Reason: transparent family (adjective and verb exist), standard in <source>.
Risk if wrong: appears ~60 times in 6 chapters; changes glossary, index, quiz feedback.
Default if no answer by <date/chapter>: A, kept as provisional [.term-pending].
Answer: ____    Decided by: ____    Date: ____
```

**Rules for good cards**
- **≤ 3 options**, plus "other". Not five. If you have more, prune with the decision ladder first.
- **Evidence over opinion**: name the source, entry, frequency. If there is none, say "no attestation found".
- **Always give a recommendation and a confidence level.** Humans react faster to a proposal than to a blank.
- **State the impact** (how many occurrences, which chapters, what else depends on it).
- **Offer a default** so work can continue. Choose the default you'd least regret.
- For **sentence renderings**: show two versions, one line on how they differ in meaning/emphasis/register, nothing more.
- For **jokes/examples**: show the English, what breaks, and the best one or two Basque candidates; say which you prefer.
- Write the **card in English** (or the language the human prefers) but the **candidate Basque in Basque**.

## Batching and timing
- **Batch** questions per chapter: ≤ 10 cards per package, ranked by priority and by how many other decisions depend on each.
- **Front-load** foundational terms (Phase 1 in the orchestrator) as a single batch before chapter work.
- Interrupt immediately only for: a blocker that stops progress, a possible S1 error in already-reviewed text, or a decision that invalidates a lot of work.
- Close the loop: when an answer arrives, update termbase/stylesheet (set `decided_by`, status `approved`), mark the card `answered`, resolve `.term-pending` markers, and run the regression sweep.

## Keep working while waiting
- Use the **provisional marker**: `[term]{.term-pending data-id="T0123"}` for terms; `{.exm-pending}` for examples; both are visible in `draft` and block `release`.
- Continue translating *around* the unresolved item. Don't stall the chapter for one term.
- Never promote a provisional choice to `approved` yourself.
- If a question stays unanswered, re-surface it **once** in the next package, flagged "still open; used provisional X in N places".

## Tone with humans
Friendly, concise, specific, grateful, and honest about uncertainty ("I could not find this in any resource I can reach"). No flattery, no apologising for asking. Thank them by showing what their answer changed ("your decision on Q-0042 updated 63 occurrences and the glossary").

## Learning from answers
After each batch of answers, extract **patterns** ("this reviewer prefers transparent compounds over loans"; "jokes should be shortened, not explained") and write them into `stylesheet-eu.md` as rules, with the date and the question ID. Over time the number of questions per chapter should fall; if it doesn't, the rules are not being captured.
