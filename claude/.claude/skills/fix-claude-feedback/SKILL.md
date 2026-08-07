---
name: fix-claude-feedback
description: >
  Iteratively resolve all feedback from this repo's Claude PR review bot
  (anthropics/claude-code-action via .github/workflows/claude-review.yml) until zero
  comments remain unresolved. Fixes mechanical feedback, replies to and resolves each
  thread it addressed, pushes, and waits for the bot's automatic re-review — repeating
  until clean or until feedback needs your design input. Use in any repo with a Claude
  review bot workflow when the user wants to fully address a PR against that bot's
  review.
compatibility: Requires git and gh (GitHub CLI) authenticated, and a
  .github/workflows/claude-review.yml (anthropics/claude-code-action) on the repo.
  GitHub only — the reply/resolve mechanics below are GitHub-specific.
---

# fix-claude-feedback

Take a PR from "just reviewed by the Claude bot" to "zero unresolved bot comments."

The bot re-reviews automatically on every push (`pull_request: synchronize`), so unlike
Greptile-style loops there is no manual re-trigger step — push, then wait for the run.

This runs only while the session is open. There is no background daemon — if the
session ends, the watch ends. Say so plainly if the user seems to expect otherwise.

## Set up

Identify the PR: `gh pr view --json number,headRefName,headRefOid`. Switch to the
branch if not already on it.

Identify the bot's comment author, since resolving/replying needs to filter to its
threads specifically. List recent comment authors —
`gh api repos/{owner}/{repo}/issues/<N>/comments --jq '.[].user.login'` — and confirm
which login is the bot (not the PR author, not a human reviewer, not dependabot). It's
most likely `github-actions[bot]`, since `claude-review.yml` authenticates `gh`/the
inline-comment MCP tool with the workflow's own `GITHUB_TOKEN`, not a distinct GitHub
App identity — but verify per-repo on first use rather than assuming.

## Loop (max 5 iterations)

### A. Fetch current feedback

Unresolved review threads, filtered to the bot's login:

```bash
gh api graphql -f query='
query($cursor: String) {
  repository(owner: "OWNER", name: "REPO") {
    pullRequest(number: PR_NUMBER) {
      reviewThreads(first: 100, after: $cursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          isResolved
          path
          line
          comments(first: 10) {
            nodes { databaseId body author { login } }
          }
        }
      }
    }
  }
}'
```

Filter to `isResolved: false` nodes whose first comment's `author.login` is the bot.
`databaseId` on each comment is the REST comment id, needed to reply in step D.

Also fetch the bot's latest top-level summary comment for context —
`gh pr view <N> --comments`, most recent entry from the bot's login (a re-review edits
this comment in place via `--edit-last`, so there's exactly one to find).

### B. Check exit conditions

Stop the loop if either is true:

- Zero unresolved threads from the bot
- Max iterations reached (report current state)

### C. Classify each unresolved thread

Read the file and comment in context (priority label — P1/P2/P3 — is a severity signal,
not a mechanical/design signal; classify by content, not label):

- **Mechanical** — bugs, missing null checks, missing test coverage, incorrect error
  handling, naming, "use the existing helper": fix it.
- **Design** — changes the approach, data model, or public interface; disagrees with a
  decision already made; widens scope: don't fix it.

If any thread is design feedback: still fix and push whatever mechanical threads exist
in this round (real progress, worth landing), but leave the design thread(s) unresolved
and open, then **stop the loop** — don't push into another automated review round until
the user has weighed in. Report which comment(s) stopped you and what you'd propose, per
CLAUDE.md's design/process split.

### D. Reply to and resolve threads you fixed

For each thread you fixed, reply on the specific comment (not a generic top-level
comment — the reviewer, human or bot, shouldn't have to re-read the whole diff) via the
REST reply endpoint, using the `databaseId` from step A:

```bash
gh api --method POST "repos/{owner}/{repo}/pulls/<PR_NUMBER>/comments/<DATABASE_ID>/replies" \
  -f body="Fixed: <what changed, and why if it wasn't purely mechanical>"
```

Then resolve the thread(s) by GraphQL `id`:

```bash
gh api graphql -f query='
mutation {
  t1: resolveReviewThread(input: {threadId: "ID1"}) { thread { isResolved } }
  t2: resolveReviewThread(input: {threadId: "ID2"}) { thread { isResolved } }
}'
```

Leave design threads unresolved and unreplied — resolving a thread you didn't actually
address misrepresents what happened.

### E. Commit and push

```bash
git add -A
git commit -m "Address Claude review feedback (iteration N)"
git push
```

New commit, never amended — same reasoning as any other review round: the bot's next
pass (and a human skimming history) needs to see what changed since last time, not a
rewritten past.

### F. Wait for the bot's re-review

Pushing fires `synchronize` automatically — no trigger comment needed. Poll for the run
against the new HEAD SHA:

```bash
HEAD_SHA=$(git rev-parse HEAD)

while true; do
  RUN=$(gh run list --workflow=claude-review.yml --json headSha,status,conclusion,databaseId \
    --limit 5 | jq -r --arg sha "$HEAD_SHA" '.[] | select(.headSha == $sha)')

  if [ -z "$RUN" ]; then
    echo "Waiting for the review run to appear..."
    sleep 5
    continue
  fi

  STATUS=$(echo "$RUN" | jq -r '.status')
  if [ "$STATUS" = "completed" ]; then
    echo "Review run completed: $(echo "$RUN" | jq -r '.conclusion')"
    break
  fi

  echo "Waiting for review... (status: $STATUS)"
  sleep 10
done
```

Then go back to step **A**.

## Stopping

Stop and report when any of these hit:

- **Zero unresolved comments** — done.
- **Design feedback** — as in step C. Say which comment stopped you and your proposal.
- **Max iterations (5)** — report remaining unresolved threads.
- **Same comment reappears after being marked fixed** — the bot re-flagged something
  you already replied-and-resolved as addressed. Stop; you're guessing at what it
  actually wants. Report both rounds' comments so the user can judge.

## Report

```
fix-claude-feedback complete.
  PR:            #42
  Iterations:    2
  Resolved:      6 comments
  Remaining:     0
```

If stopped early:

```
fix-claude-feedback stopped: design feedback needs your input.
  PR:            #42
  Iterations:    1
  Resolved:      3 comments (pushed)
  Remaining:     1 (blocked on your input)

  src/api/orders.ts:88 (P1) — "This changes the order-status enum; apps/mobile's
  OrderStatus type in packages/api-client isn't updated to match."
  Proposal: update the shared type in the same PR, or split it out — which do you want?
```
