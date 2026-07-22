# CLAUDE.md

## Identity
- Name: Mattijs
- Role: Software Engineer (Backend Java, Backend PHP, Backend JS/TS/Node, Frontend)

## Branching
Format: `mattijs/<ticket-id>-short-description`

## Commits
Format: `<ticket-id> Imperative description`
- Subject max 72 chars, says WHAT changed
- Body (optional) says WHY
- One logical change per commit

## Git Hosting
Check the remote URL (`git remote get-url origin`) to determine the hosting platform, then use the appropriate CLI:

- **GitLab** (`gitlab.com` or self-hosted): use `glab`
- **GitHub** (`github.com`): use `gh`

## Model Selection
Default to Sonnet if you're unsure

- **Sonnet** — everyday tasks, code generation, quick fixes
- **Opus** — complex architecture, multi-file refactors, planning
- **Haiku** — fast/cheap tasks, simple formatting

## Behavioral guidelines
Reduces common LLM coding mistakes. Biases toward caution over speed — use judgment on trivial tasks.

1. **Think before coding** — state assumptions explicitly; ask if uncertain. Present multiple interpretations rather than picking silently. Flag simpler approaches; push back when warranted. Stop and ask if something's unclear.
2. **Simplicity first** — minimum code that solves the problem. No speculative features, abstractions for single-use code, unrequested flexibility, or error handling for impossible scenarios. If 200 lines could be 50, rewrite it.
3. **Surgical changes** — touch only what you must. Don't improve adjacent code/comments/formatting or refactor working code; match existing style. Mention unrelated dead code but don't delete it. Remove only imports/vars/functions your change made unused, not pre-existing dead code. Every changed line should trace to the user's request.
4. **Goal-driven execution** — turn tasks into verifiable goals (e.g. "fix the bug" → reproduce with a test, then make it pass). For multi-step tasks, state a plan with a verify step per item. Strong success criteria let you loop independently; weak criteria ("make it work") force constant clarification.

Working well if: diffs have fewer unnecessary changes, fewer rewrites from overcomplication, and clarifying questions come before implementation rather than after mistakes.

## Documentation
Always update relevant existing documentation (README.md, docs/) when making code changes that affect setup, configuration, commands, or architecture. Create new documentation files when adding a significant new feature or subsystem that isn't yet covered.

## PR/MR Descriptions
Never add "Generated with Claude Code" or any similar AI attribution statements to PR/MR descriptions, commit messages, or any other user-facing content.