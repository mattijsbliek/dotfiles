---
name: pr-follow-through
description: Watch an open PR/MR until the pipeline is green and review feedback is clear, fixing CI failures and mechanical review comments — from a human or an automated review bot (e.g. a Claude review action) — along the way. Use after opening a PR/MR, or when asked to follow up on, babysit, or iterate on one.
---

Take a PR/MR from "opened" to "green and clear" without further prompting.

This runs only while the session is open. There is no background daemon — if the session ends,
the watch ends. Say so plainly if the user seems to expect otherwise.

## Set up

Identify the PR/MR. If not given one, use the current branch:
`gh pr view --json number,url,headRefName` (GitHub) or `glab mr view` (GitLab).

Pick the CLI from `git remote get-url origin` — `github.com` → `gh`, GitLab → `glab`. The `gh`
invocations below are exact; for `glab`, check `glab mr --help` / `glab ci --help` for the
current flag names rather than guessing.

If the repo has an automated review bot (e.g. `.github/workflows/claude-review.yml` running
`anthropics/claude-code-action`), it re-reviews automatically on every push — no manual
retrigger needed, and its job shows up as just another entry in `gh pr checks`. Identify its
comment login so you can tell its feedback apart from a human's:
`gh api repos/{owner}/{repo}/issues/$PR/comments --jq '.[].user.login'` and pick the one that
isn't the PR author, a human reviewer, or dependabot — most likely `github-actions[bot]`, since
these workflows typically authenticate with the workflow's own `GITHUB_TOKEN` rather than a
distinct GitHub App identity. Verify per-repo rather than assuming.

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
  `APPROVED`, `CHANGES_REQUESTED`, or `REVIEW_REQUIRED`. Top-level comments come from
  `gh api repos/{owner}/{repo}/issues/$PR/comments`. The REST inline-comments endpoint
  (`.../pulls/$PR/comments`) doesn't carry resolved state — use the GraphQL query below to know
  which threads are still open.

## What to fix yourself, and what to bring back

This is the design/process split from CLAUDE.md, applied to review feedback. If a bot review
labels comments by severity (e.g. P1/P2/P3), that's a severity signal, not a mechanical/design
one — a P1 can still be a design question, a P3 can still be a one-line fix. Classify by
content, not label.

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

Reference what you addressed: `<ticket-id> Address review: use existing retry helper`.

For GitHub, reply to and resolve each thread you fixed — don't just push and let the diff speak
for itself. Fetch unresolved threads (this also gives you the resolved/open state the REST
comments endpoint lacks):

```bash
gh api graphql -f query='
query {
  repository(owner: "OWNER", name: "REPO") {
    pullRequest(number: PR_NUMBER) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          comments(first: 10) { nodes { databaseId body author { login } } }
        }
      }
    }
  }
}'
```

Reply on the specific comment via its `databaseId`, then resolve the thread by its GraphQL `id`:

```bash
gh api --method POST "repos/{owner}/{repo}/pulls/$PR/comments/<DATABASE_ID>/replies" \
  -f body="Fixed: <what changed, and why if it wasn't purely mechanical>"

gh api graphql -f query='
mutation { resolveReviewThread(input: {threadId: "<THREAD_ID>"}) { thread { isResolved } } }'
```

Leave threads you didn't actually address unresolved and unreplied — resolving one you didn't
fix misrepresents what happened. For GitLab, use `glab api .../discussions` and
`PUT .../discussions/<id>` with `resolved=true` instead.

Never merge the PR/MR. Never dismiss a review.

## Stopping

Stop and report when any of these hit:

- **Green and clear** — CI green and every review thread (human or bot) resolved. If a human
  reviewer has actually submitted a review, `reviewDecision` must be `APPROVED` —
  `CHANGES_REQUESTED` blocks regardless of resolved threads. If no human reviewer ever engages
  (solo-maintained repos, bot-only review), don't wait forever for an approval that isn't
  coming — green plus all threads resolved is the finish line. Say so, link the PR, and use
  PushNotification if the user has likely walked away.
- **Design feedback** — as above.
- **Same failure twice** — if a check fails again with the same error after your fix, stop.
  You're guessing; say what you tried and what the log says.
- **Five fix attempts on one PR** — stop regardless of state and summarize.
- **Failure unrelated to the change** — infrastructure, expired credentials, an unrelated flaky
  suite. Report it; don't thrash trying to fix someone else's pipeline.

Never report green without having actually seen a passing status. If you stopped early, lead
with what is still red or unaddressed.
