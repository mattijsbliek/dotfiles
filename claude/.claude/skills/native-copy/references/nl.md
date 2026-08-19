# Dutch language profile

## Register

**"je/jij", never "u"** for modern software. "u" reads as a bank, a government letter, or a summons. The exceptions are genuinely formal products — legal, medical, insurance, government — and Belgian audiences, who use "u" more readily than Dutch ones. When in doubt for a B2B SaaS product: "je".

Note that "je" is not a licence to be cute. Dutch product copy that tries to be playful lands badly far more often than English does; the ceiling on charm is lower. Plain and direct is the register, with "je" as the pronoun — not chatty.

**Benchmarks worth naming.** For prose rhythm and word choice: *NRC*, *de Volkskrant*. For SaaS and product voice: *moneybird.nl*, *thebookie.nl*. What these share is short sentences, concrete nouns, verbs doing the work, and no throat-clearing.

## Grammatical traps that produce stiff Dutch

**Nominalisation.** The single biggest one. English "Verification failed" → "Verificatie mislukt" is grammatical and reads like officialese. "Die controle lukte niet" says the same thing as a person. Watch for `-ing`/`-ion` nouns arriving as `-ing`/`-atie` nouns: *overschrijving*, *goedkeuring*, *verificatie*, *bevestiging*. Ask whether the sentence can be built on the verb instead.

**"Hun/deze" imported from English possessives.** "collect their feedback" → "verzamel hun feedback" is a calque; Dutch usually drops the possessive: "verzamel feedback".

**Clause pile-ups on "waardoor" / "zodat" / "waarbij".** English hangs long subordinate clauses off a relative pronoun and stays readable. Dutch, with the verb at the end of the subordinate clause, does not. Split into two sentences.

**Compounds are written closed.** *huisstijlgids*, *klantportaal*, *reactiepaneel* — not spaced as in English. Spacing them ("huis stijl gids") is the most visible non-native error in Dutch and very common in software.

**Diminutives are a register tool, used sparingly.** "een mailtje", "een documentje" adds warmth and slight dismissiveness; exactly right in "ergens in een mailtje", wrong in a status label. Never in chrome.

## Typography and punctuation

**Quote marks: ‘…' (single curly).** This is NL newspaper house style (NRC, Volkskrant). Do *not* use „…" — the low-9 opening quote is German typography that Dutch dropped decades ago and is a strong foreign-hand signal. Double curly "…" is acceptable in book-like contexts.

**No Oxford comma in standard Dutch** — "a, b en c", not "a, b, en c". **But check the project's guide**: a house style may deliberately require it (Clientroom does, recorded in `docs/agents/translation.md`). Where a project has made that call, keep it and do not "correct" it away.

**Decimals use a comma, thousands a period**: 4,1 MB; 1.200 bestanden. Dates: "12 mei" (no ordinal, lowercase month). Times with a colon: 11:04.

**Sentence case for headings and labels**, not Title Case. English UI capitalises "New Folder"; Dutch is "Nieuwe map".

## Idioms that do not survive from English

| English | Why the literal fails | Reach for |
| --- | --- | --- |
| losing the thread | "de draad kwijtraken" exists but only in the mental sense — the mail-thread pun dies | "het eeuwige heen en weer", "al dat heen en weer" |
| know what they approved | "weten wat ze hebben goedgekeurd" is flat | "zwart op wit hebben wat er is goedgekeurd" |
| gradually / bit by bit | "geleidelijk aan" is limp and slightly bureaucratic | "mondjesmaat", "stap voor stap" |
| hold a piece of the job | "dekken een stukje van de taak" is a calque | "doen elk een stukje van het werk" |
| which version is current | "welke versie actueel is" is officialese | "welke versie de laatste is" |
| who signed off | — (this one works) | "wie akkoord gaf" |

**File-naming gags**: English `_final_v2_really` → Dutch `_definitief_v2_echt`.

## Loanwords to leave untranslated

Common in Dutch business and creative software, and translating them reads worse than keeping them: **team**, **review**, **branding** (as an app UI label), **tone of voice**, **upload/uploaden**, **downloaden**, **feedback**, **template**, **dashboard**.

Note the split on *branding*: it stays as-is as a settings label, but in marketing prose **huisstijl** is the word a Dutch studio actually uses. Check the project glossary — this exact distinction is recorded in Clientroom's.

## Native words a translator would never produce

Worth reaching for when the English is flat: **mondjesmaat** (sparingly, grudgingly), **zwart op wit** (documented, undeniable), **het heen en weer** (back-and-forth), **houterig** (stilted), **gedoe** (hassle — Moneybird's whole positioning), **mits/tenzij** (precise conditionals English needs a clause for), **overzicht** (the thing users actually want and English has no single word for).

## Verb forms worth getting right

**Imperatives**: "Houd" and "Hou" are both correct; "Hou" is more spoken, "Houd" safer in written copy. Same for "Word/Wordt" confusion — imperative and first person are "word".

**"Klik hieronder"** is medium-neutral and works for both a rendered button and a bare URL in a plain-text email. "Klik op de knop" only works where a button exists.

**Situational "dit"/"dat"** refers to the situation, not to a grammatical antecedent — "Dit was al geregeld" is ordinary Dutch and needs no het-word nearby. Reviewers sometimes flag this as a gender-agreement error; it isn't. (Naming the subject explicitly is often still clearer: "Je plek was al bevestigd".)
