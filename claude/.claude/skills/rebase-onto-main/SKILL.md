---
name: rebase-onto-main
description: Fetch the latest default branch (main/master), rebase the target branch onto it, resolve mechanical conflicts, and force-push the result with --force-with-lease. Use when asked to rebase onto main, sync/update a branch with main, or resolve rebase conflicts and push.
metadata:
  user-invocable: true
  argument-hint: "[branch]"
---

# Rebase onto main

Bring a branch up to date with the default branch via rebase (not merge), and push the
result. Optional argument: the branch to rebase (`$ARGUMENTS`), default the current branch.

## Set up

1. Confirm this is a git repo and the target branch isn't the default branch itself — if it
   is, there's nothing to rebase, stop and say so.
2. Resolve the default branch name without guessing: `git symbolic-ref refs/remotes/origin/HEAD`
   (strip the `refs/remotes/origin/` prefix). If that's unset, fall back to
   `git remote show origin` and read the `HEAD branch:` line. Don't hardcode `main`.
3. `git status --porcelain` — if the working tree is dirty, `git stash push -u -m
   rebase-onto-main` before switching branches or rebasing, and pop it back at the end (after
   the push, or after aborting — see Stopping).
4. If `$ARGUMENTS` names a branch other than the current one, `git checkout <branch>`.

## Rebase

```bash
git fetch origin <default-branch>
git rebase origin/<default-branch>
```

Rebasing onto `origin/<default-branch>` (not a local `main`) avoids needing to touch a branch
you're not on — this only fetches, it never updates local `main`/`master`.

If it completes without conflicts, skip to Push.

## Resolving conflicts

`git rebase` pauses on each conflicting commit in turn. For every conflicted file
(`git status --porcelain` shows `UU`/`AA`/etc. — or `git diff --name-only --diff-filter=U`):

Read the conflict markers and classify:

- **Mechanical — resolve and continue**: the two sides touch different things that git only
  flagged for proximity (adjacent unrelated hunks), import/require ordering, formatting/
  whitespace-only differences. For machine-generated lockfiles (`package-lock.json`,
  `composer.lock`, `yarn.lock`, `Gemfile.lock`, ...), don't hand-merge — take the incoming
  version and regenerate with the project's install command if one is available, otherwise
  take `--theirs` (the rebased-onto side) and note that lockfile conflicts were auto-resolved.
  After editing, `git add <file>`.
- **Semantic — stop**: both sides changed the same logic with different intent, or it's
  ambiguous which side should win. Leave the rebase paused right there — don't
  `--continue` and don't `--abort`. Report the file, both sides of the conflict, and what
  you'd propose; wait for a decision before resuming.

Once every conflict in the current step is resolved: `GIT_EDITOR=true git rebase --continue`
(`GIT_EDITOR=true` avoids an interactive commit-message prompt in a non-interactive shell). Repeat
for the next paused commit, if any, until `git rebase` reports it's done.

## Push

Once the rebase is fully complete (clean `git status`, no `rebase-merge`/`rebase-apply` dir):

```bash
git push --force-with-lease origin <branch>
```

If the branch has no upstream yet (never pushed before), `--force-with-lease` doesn't apply —
use `git push -u origin <branch>` instead.

Push without asking first — `--force-with-lease` already refuses if the remote moved since your
last fetch, which is the actual danger case, and invoking this skill is itself the request to
rebase-and-push. If the push is rejected because the lease is stale, stop and report it rather
than retrying with a plain `--force`.

If the stash from Set up step 3 exists, `git stash pop` now.

## Stopping

Stop and report, without pushing, when:

- A conflict is semantic (see above) — the rebase stays paused for you to resume manually with
  `git rebase --continue`/`--abort`.
- The rebase makes no changes (branch was already up to date) — say so, nothing to push.
- `--force-with-lease` is rejected — someone else pushed to the branch since your last fetch;
  don't override it silently.
