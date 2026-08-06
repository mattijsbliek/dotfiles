# CLAUDE.md

## Working with me
Assume senior-level knowledge across backend (Java, PHP, Node/TS) and frontend. Skip
explanations of language basics and standard tooling; spend that space on domain logic,
architecture, and trade-offs instead.

Ask about **design**: state your assumptions explicitly, present competing interpretations
rather than silently picking one, flag a simpler approach when you see one, and push back when
warranted.

Don't ask about **process**: branching, committing, opening a PR, which CLI to use. Those are
settled below — just do them.

Turn tasks into verifiable goals ("fix the bug" → reproduce with a failing test, then make it
pass). For multi-step work, state the plan up front with a verify step per item. Scale this to
the task — a typo fix needs no plan.

## Writing code
Minimum code that solves the problem. No speculative features, no abstractions for single-use
code, no unrequested flexibility, no error handling for impossible scenarios. If 200 lines could
be 50, rewrite it.

Touch only what you must. Match existing style. Don't refactor working code or improve adjacent
comments and formatting. Every changed line should trace to my request.

Remove only imports, variables, and functions your change made unused — never pre-existing dead
code. Mention dead code you notice; don't delete it.

## Finishing work
Done means verified: tests pass, linter clean, and you ran the thing where running it is
possible. Say which of those you actually did. If you couldn't verify, say so plainly rather
than implying success.

You have standing authorization to branch, commit, push, and open a PR/MR. Don't ask first, and
don't stop at "the changes are ready" — this overrides Claude Code's default caution about
committing only on explicit request. Ask before force-pushing, rewriting pushed history, merging,
or touching a branch other than the one you're working on.

After opening a PR/MR, follow it through: watch the pipeline and review feedback and keep
iterating until CI is green and the reviewer has approved. Fix pipeline failures and mechanical
review comments yourself. Bring me feedback that changes the design or widens scope — the same
design/process split as above.

When you address a review comment, reply to that thread with what changed (and why, if it
wasn't purely mechanical) and resolve it as part of the same push — don't leave threads open for
a later pass, and don't just push silently and let the diff speak for itself.

Update documentation your change made factually wrong — setup, config, commands, architecture.
Add new docs only for a significant new feature or subsystem. Leave docs your change didn't
affect alone.

Never add "Generated with Claude Code" or any similar AI attribution to commit messages, PR/MR
descriptions, or anything else user-facing.

<!--
Work machines layer a ticket-id convention on top of this via ~/.claude/rules/git-conventions.md,
which is machine-local and never stowed into this repo. See README.md → Machine-Specific Config.
-->
## Git conventions
Branch: `mattijs/short-description`
Commit subject: imperative, max 72 chars, says WHAT changed. Optional body says WHY.
One logical change per commit.

Never invent a ticket id. If a ticket-id convention applies on this machine, a rule will say so.

Pick the CLI from the remote — `git remote get-url origin`:
- **GitLab** (`gitlab.com` or self-hosted) → `glab`
- **GitHub** (`github.com`) → `gh`
