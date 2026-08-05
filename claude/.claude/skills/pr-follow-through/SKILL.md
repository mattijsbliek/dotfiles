---
name: pr-follow-through
description: Watch an open PR/MR until the pipeline is green and the reviewer has approved, fixing CI failures and mechanical review comments along the way. Use after opening a PR/MR, or when asked to follow up on, babysit, or iterate on one.
---

Take a PR/MR from "opened" to "green and approved" without further prompting.

This runs only while the session is open. There is no background daemon — if the session ends,
the watch ends. Say so plainly if the user seems to expect otherwise.

## Set up

Identify the PR/MR. If not given one, use the current branch:
`gh pr view --json number,url,headRefName` (GitHub) or `glab mr view` (GitLab).

Pick the CLI from `git remote get-url origin` — `github.com` → `gh`, GitLab → `glab`. The `gh`
invocations below are exact; for `glab`, check `glab mr --help` / `glab ci --help` for the
current flag names rather than guessing.

## Loop

Watch CI with the Monitor tool so you react as each check lands instead of polling blindly:

```bash
prev=""
while true; do
  s=$(gh pr checks "$PR" --json name,bucket 2>/dev/null) || { sleep 30; continue; }
  cur=$(jq -r '.[] | select(.bucket!="pending") | "\(.name): \(.bucket)"' <<<"$s" | sort)
  comm -13 <(echo "$prev") <(echo "$cur")
  prev=$cur
  jq -e 'all(.bucket!="pending")' <<<"$s" >/dev/null && break
  sleep 30
done
```

Each time you wake, check both sides:

- **Pipeline** — `gh pr checks "$PR"`. For a failure, read the actual log before touching
  anything: `gh run view <run-id> --log-failed`.
- **Review** — `gh pr view "$PR" --json reviewDecision,reviews`. `reviewDecision` is
  `APPROVED`, `CHANGES_REQUESTED`, or `REVIEW_REQUIRED`. Inline comments come from
  `gh api repos/{owner}/{repo}/pulls/$PR/comments`; top-level ones from
  `gh api repos/{owner}/{repo}/issues/$PR/comments`.

## What to fix yourself, and what to bring back

This is the design/process split from CLAUDE.md, applied to review feedback.

**Fix and push** — process:
- Failing lint, formatter, type check, or build
- Tests your change broke
- Review comments that are mechanical: naming, extract this, add a test case, missing null
  check, use the existing helper

**Stop and ask** — design:
- Review feedback that changes the approach, the data model, or the public interface
- Anything that widens scope beyond the original task
- A reviewer disagreeing with a decision the user made
- A failure whose fix you can't justify from the log alone

When you stop, say which comment stopped you and what you'd propose.

## Pushing fixes

Push **new commits**, never amended ones — the reviewer needs to see what changed since they
looked. Never force-push and never rewrite pushed history.

Reference what you addressed: `<ticket-id> Address review: use existing retry helper`. Reply to
the comment you fixed so the reviewer isn't re-reading the whole diff.

Never merge the PR/MR. Never dismiss a review.

## Stopping

Stop and report when any of these hit:

- **Green and approved** — done. Say so, link the PR, and use PushNotification if the user has
  likely walked away.
- **Design feedback** — as above.
- **Same failure twice** — if a check fails again with the same error after your fix, stop.
  You're guessing; say what you tried and what the log says.
- **Five fix attempts on one PR** — stop regardless of state and summarize.
- **Failure unrelated to the change** — infrastructure, expired credentials, an unrelated flaky
  suite. Report it; don't thrash trying to fix someone else's pipeline.

Never report green without having actually seen a passing status. If you stopped early, lead
with what is still red or unaddressed.
