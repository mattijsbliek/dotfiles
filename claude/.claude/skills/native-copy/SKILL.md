---
name: native-copy
description: Write copy that reads as if it was written in the target language, not translated into it. Use when writing or reviewing non-English copy (nl.ts/de.ts message catalogs, marketing pages, transactional emails), when asked to translate UI or product text, or when existing copy reads stiff, formal, or foreign.
---

# Native Copy

A translation and native copy are different artifacts. A translation is judged against the source: did it carry the meaning across. Native copy is judged against the reader: does this sound like a person writing in their own language. A string can be a flawless translation and still announce that it was translated.

That announcement is what this skill is for. It is usually not a vocabulary problem — the words are right. It is grammar, rhythm, idiom, and punctuation imported from the source language along with the meaning.

## Before you write

**1. Find the project's own guide.** Look for a translation or tone-of-voice doc, a glossary, ADRs about locale handling: `fd -i 'translat|tone|copy|i18n' docs/`, and check `CLAUDE.md` for a pointer. If one exists it outranks this skill on register, terminology, and house style — including where it contradicts standard usage. Read it before writing a word.

Do not copy its rules into the skill or restate them back to the user as if you decided them. Two sources of truth for the same term will drift, and the drift surfaces as a reviewer telling you the copy is inconsistent.

**2. Load the language profile.** Read `references/<lang>.md` for the target language — register defaults, the idioms that don't survive, typography, punctuation, and the loanwords to leave alone. If there is no profile for the language, say so and write one as you go (see the last section).

**3. Decide which mode you are in.** This governs how much liberty you have, and it is the difference between good copy and a bug.

## The two modes

**Prose — the source is a brief.** Marketing pages, onboarding, empty states, help text, transactional email bodies. Rewrite freely. Change the metaphor, reorder the sentence, drop a clause the target language doesn't need, replace a joke with one that lands locally. Serve the reader, not the source string.

**Chrome — the source is a spec.** Buttons, labels, statuses, menu items, error messages, confirmation dialogs. The words may change; the semantics may not. A button must still name exactly what the code does, a status must match the state machine, and the project glossary beats your taste every time. "Delete" that becomes a livelier verb on one screen and a different livelier verb on another is a defect, not a style.

**Most files hold both.** A marketing content file's headings and body are prose while its UI-mockup labels are chrome — and the mockup labels should match what the real app says, because a reader who signs up will see the app. When a string is in a shared component, check whether it also renders somewhere with different constraints before you touch it.

## The four tells

These are what "reads translated" decomposes into. Work through them explicitly on any copy you are fixing.

**1. Nominalisations carried across.** English turns verbs into nouns freely and reads fine; most other languages get stiff and bureaucratic doing the same. "Verification failed" → a noun-first rendering sounds like a parking fine; put the verb back. Symptom: a sentence whose main action is a noun. Fix: find the verb it was made from and build the sentence on that instead.

**2. Calqued idioms.** The test is not "does this phrase exist in the target language" — it is **does the reason the source chose it survive**. English "losing the thread" does double duty: the mail thread and the narrative thread. Dutch has "de draad kwijtraken" but only with the mental sense, so a word-for-word rendering keeps a cliché and throws away the pun. When the double meaning dies, don't translate the idiom — find what the source was actually pointing at and pick a live local idiom for that.

**3. Source-language sentence architecture.** Long subordinate clauses hung off a single connective, serial constructions the target language builds differently, the source's comma conventions. Symptom: every sentence is the same length and shape as its English counterpart. Fix: split, re-order, and let the target language's natural clause order take over — sentence boundaries are not part of the meaning.

**4. Source-language typography.** Quote marks, decimal and thousands separators, date and time formats, spacing around punctuation, capitalisation in headings and labels. Small, mechanical, and the fastest signal to a native reader that a foreigner set this text. The language profile lists the conventions.

## Localise more than words

The parts of copy that carry the most personality are the parts a translator skips.

**Jokes and examples land locally or not at all.** A gag about a file named `_final_v2_really` is funny in any language and about *someone else's* desktop in all but one. Rewrite it with the local convention (`_definitief_v2_echt`) and it becomes a joke about the reader.

**Sample data too**: placeholder names, company names, addresses, currency, phone formats. And check that a translated sample filename or folder name doesn't collide with a domain term — a mockup that says "gedrukte versie" inside a product whose data model has a Version is a small trap.

## Verify

Copy work feels safe because it compiles. It compiles because message catalogs are usually typed — a `Content` interface or a `Record<keyof typeof en, string>` enforces that every key exists and is a string. **That enforces shape, never meaning.** Every real defect in copy lives in the gap the type system does not cover, so verification has to be manual and deliberate.

**Render it and look at it.** Not measure — look. Take a screenshot and read it with your own eyes. Measurements of block elements lie about line counts: `getBoundingClientRect()` returns one rectangle no matter how many lines wrap inside, so a heading that reports "one box, 187px tall" is three lines with an orphaned word. If you must measure, lay a `Range` over the contents and group `getClientRects()` by `top`. But look first; the image does not lie.

Target language strings are routinely longer than English. Check the tight spots specifically: buttons, chips, badges, table headers, and any heading with a manual line break. **A manual `<br>` guarantees a break, not a line count** — the line after it can still wrap.

**Read the whole surface for contradictions.** Term decisions are made string by string and contradict each other page by page. A `<title>` that uses the native word while the FAQ four sections down uses the English loanword is invisible in a diff and obvious to a reader. Grep the whole surface for each term you decided on.

**Check strings shared across renderings.** One string often feeds an HTML body and a plain-text fallback, or a tooltip and an aria-label. Medium-specific words then break one of them: "click the button below" is false above a bare URL in a text email. Before making a string more specific, find every place it renders.

**Grep before you delete.** When you remove or replace a user-facing string, `grep -rn` a distinctive word from it across `docs/` and the repo — you are looking not for other copies but for *references*: glossary rows citing it as an example, ADRs, code comments, test names. Do it at the moment of deletion; the citation is in another file, so nothing in the diff will remind you.

**Record term decisions where the project keeps them.** If you introduce or redefine a recurring term, add it to the project's glossary in the same change, with the reasoning. If you deliberately break a standard convention of the language because the project prefers it, write that down too and say it is deliberate — otherwise the next person "corrects" it back, with a good argument.

## Reviewing rather than writing

When asked whether existing copy reads natively, work the four tells as a checklist and quote the offending string with its replacement side by side. Give the reasoning per change, not a rewritten file — the person reading is deciding whether to trust your ear, and a diff of 40 strings with no argument is unreviewable.

Separate what is **wrong** (a calque, a broken idiom, an inconsistent term) from what is **your taste** (a punchier heading, a different metaphor). Present taste calls as options with a recommendation, and say which is which. Voice is the owner's decision; correctness is yours.

## Adding a language profile

Write `references/<lang>.md` covering: the register default and who it addresses (formal/informal pronoun, and what the product's audience expects); named benchmarks for the voice — actual publications and products whose copy is the target; idioms that do *not* survive from English, with what to use instead; typography and punctuation conventions; the specific grammatical traps that produce stiff prose in that language; loanwords that should stay untranslated in software; and native words worth reaching for that a translator would never produce.

Keep it short and specific. A profile that reads like a grammar textbook won't be used; one that names ten real traps will be.
