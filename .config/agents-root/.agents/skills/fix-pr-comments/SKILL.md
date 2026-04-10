---
name: fix-pr-comments
description: Address unresolved GitHub PR review threads — especially from Cursor BugBot and other automated bots — skeptically and methodically. Use this skill whenever the user wants to work through open comments or feedback on a pull request, deal with bugbot or coderabbitai comments, resolve review threads, or address reviewer feedback on a PR. Also use this skill when the user asks to "watch", "babysit", "monitor", or "keep an eye on" a PR — in watch mode, polls for both new BugBot comments AND CI check failures on every tick. Does not apply to code comments (TODOs, inline comments in files) or general code review requests not tied to an open pull request.
allowed-tools:
  - "Bash(gh *)"
  - "Bash(git *)"
  - "Bash(gt *)"
  - "Bash(jq *)"
  - "Bash(sleep *)"
---

# Fix PR Comments

Two modes:

- **Fix mode** (default): work through existing unresolved review comments right now — triage, fix, get sign-off, push, resolve.
- **Watch mode**: poll the PR (or PR stack) every 60 seconds for new BugBot comments AND CI failures, then fire the fix workflow automatically when they appear.

If the user says "watch", "babysit", "monitor", or "keep an eye on" a PR, use **Watch mode**. Otherwise use **Fix mode**.

## The core idea

Automated tools like Cursor BugBot have high false-positive rates. The most important thing is to verify each issue against the *actual current codebase* — not just the diff — before touching anything. Many comments are stale, wrong, or describing intentional behavior.

---

## Watch Mode

Use this when the user wants the agent to monitor a PR (or stack of PRs) and automatically kick off fixes when BugBot comments appear.

### Detect stack vs single PR

```bash
GT_AVAILABLE=$(which gt > /dev/null 2>&1 && echo "true" || echo "false")
```

If `GT_AVAILABLE` is true, check whether there's a stack:

```bash
gt log --short 2>/dev/null
```

If there are multiple PRs in the stack, collect all their numbers. Otherwise treat it as a single PR.

### Ask how often to poll

Before starting, ask the user using the `question` tool:

```
question: "How often should I check for new BugBot comments and CI status?"
options:
  - "Every 60 seconds (default)"
  - "Every 30 seconds"
  - "Every 2 minutes"
  - "Every 5 minutes"
```

The `custom` option (always available) lets them type any interval they want. Use whatever they say as the sleep duration. Default to 60 seconds if they don't specify.

### Poll loop

Run the entire watch loop as a **single long-running bash script** rather than repeated tool calls. This is critical for token efficiency — each tool call reloads context, so a tight shell loop that sleeps internally costs a fraction of the tokens compared to calling `sleep` as a separate tool call every tick.

Write and execute a script like this:

```bash
PR=<pr_number>
INTERVAL=<seconds>
OWNER=<owner>
REPO=<repo>
TICK=0

while true; do
  TICK=$((TICK + 1))

  # Check CI status
  CI_JSON=$(gh pr checks $PR --json name,status,conclusion 2>/dev/null)
  FAILING=$(echo "$CI_JSON" | jq '[.[] | select(.conclusion == "failure" or .conclusion == "timed_out" or .conclusion == "cancelled" or .conclusion == "action_required" or .conclusion == "startup_failure")] | length')
  RUNNING=$(echo "$CI_JSON" | jq '[.[] | select(.status == "in_progress" or .status == "queued")] | length')
  TOTAL=$(echo "$CI_JSON" | jq 'length')

  # Check unresolved BugBot threads
  UNRESOLVED=$(gh api graphql -f query='
  {
    repository(owner: "'$OWNER'", name: "'$REPO'") {
      pullRequest(number: '$PR') {
        reviewThreads(first: 100) {
          nodes {
            id
            isResolved
            comments(first: 1) {
              nodes { author { login } body }
            }
          }
        }
      }
    }
  }' | jq '[.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false) | select(.comments.nodes[0].author.login | test("cursor|bugbot|coderabbitai|sourcery|github-actions"; "i"))]')

  UNRESOLVED_COUNT=$(echo "$UNRESOLVED" | jq 'length')

  echo "[tick $TICK] CI: $TOTAL total, $RUNNING running, $FAILING failing | BugBot threads: $UNRESOLVED_COUNT unresolved"

  # Exit the loop if action is needed — the agent handles it from here
  if [ "$FAILING" -gt 0 ]; then
    echo "ACTION:CI_FAILURE"
    echo "$CI_JSON" | jq '[.[] | select(.conclusion == "failure" or .conclusion == "timed_out" or .conclusion == "cancelled" or .conclusion == "action_required" or .conclusion == "startup_failure")]'
    break
  fi

  if [ "$UNRESOLVED_COUNT" -gt 0 ]; then
    echo "ACTION:BUGBOT_COMMENTS"
    echo "$UNRESOLVED"
    break
  fi

  # All clear — CI ran, nothing is failing or still running, no unresolved threads
  # neutral/skipped/success all count as acceptable; we only block on the failure states above
  if [ "$TOTAL" -gt 0 ] && [ "$RUNNING" -eq 0 ] && [ "$FAILING" -eq 0 ] && [ "$UNRESOLVED_COUNT" -eq 0 ]; then
    echo "ACTION:ALL_CLEAR"
    break
  fi

  sleep $INTERVAL
done
```

When the script exits with `ACTION:ALL_CLEAR`, report to the user that CI is passing and there are no unresolved BugBot threads, and stop.

When the script exits with `ACTION:CI_FAILURE`, read the failing check names from the output and ask the user what to do:

```
question: "CI check '<name>' is failing on PR #<number>. What should I do?"
options:
  - "Investigate and fix it"
  - "Ignore it and keep watching"
  - "Stop watching"
```

If they choose to investigate, fetch the failure logs with `gh run view <run-id> --log-failed` and attempt a fix using the same subagent pattern as Fix Mode.

When the script exits with `ACTION:BUGBOT_COMMENTS`, take the unresolved thread JSON and jump straight into Fix Mode (Step 2 onwards).

**PR stack:** for multiple PRs, add each PR number to the loop and aggregate the checks. Only proceed to fixing BugBot comments when every PR in the stack has been seen by BugBot — meaning each PR has at least one BugBot review (resolved or unresolved). This avoids fixing PR #1 while BugBot hasn't reviewed PR #3 yet.

### After fixing

When the fix workflow completes, ask the user:

```
question: "Fixes applied and pushed. What should I do now?"
options:
  - "Keep watching for new BugBot comments and CI"
  - "Stop watching"
```

If they choose to keep watching, restart the poll loop with the same interval. If they stop, exit.

### Interruption

Tell the user how to stop the watch before starting: "I'll check every <interval>. Send a message at any time to stop."

---

## Fix Mode

Work through unresolved PR review comments skeptically: gather context, decide what's worth fixing, apply minimal correct changes, get the user's sign-off, then commit per-issue, push, and resolve the thread on GitHub.

---

## Step 1: Find the PR

```bash
gh pr view --json number,title,url,headRefName
```

If there's no PR for the current branch, stop and tell the user. If there is one but it has zero unresolved review threads (after Step 2), tell the user "No unresolved review threads found on this PR." and stop.

---

## Step 2: Fetch unresolved review threads

The REST API doesn't expose resolved status, so use GraphQL. First get the owner, repo, and PR number, then interpolate them into the query:

```bash
# Get owner, repo, and PR number
gh repo view --json owner,name
gh pr view --json number
```

```bash
# Fetch all review threads then filter to unresolved — substitute real values for OWNER, REPO, PR_NUMBER
# NOTE: GitHub's GraphQL API does NOT support filterBy on reviewThreads. Fetch all and filter with jq.
gh api graphql -f query='
{
  repository(owner: "OWNER", name: "REPO") {
    pullRequest(number: PR_NUMBER) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          comments(first: 10) {
            nodes {
              databaseId
              body
              path
              line
              diffHunk
              author { login }
            }
          }
        }
      }
    }
  }
}' | jq '.data.repository.pullRequest.reviewThreads.nodes | map(select(.isResolved == false))'
```

Filter unresolved threads client-side with `jq` since the API returns all threads. The first comment in each thread is the root issue to address. If there are none, stop and tell the user.

Also grab top-level (issue-level) comments if relevant:

```bash
gh api repos/{owner}/{repo}/issues/{pr_number}/comments --paginate
```

---

## Step 3: Triage each comment skeptically

Before writing a single line of code, run through this for every unresolved thread:

**Is this a bot?** Check `author.login`. Common bot accounts: `cursor-bugbot`, `github-actions[bot]`, `coderabbitai[bot]`, `sourcery-ai[bot]`. Bot comments deserve extra skepticism — they're often wrong.

**Is the issue actually present?** Read the referenced file at its current state, not just the diff hunk. The code may already be fixed in a later commit.

**Is this stale?** Comments are written against a snapshot of the code. Check if the lines in question have changed since the comment was posted with `git log -p -- <file>`.

**Is this a real bug or just a style preference?** Search the codebase for similar patterns. If the same pattern appears in 10 other places without issue, it's probably intentional.

**Is the suggested fix correct for *this* project?** Check `AGENTS.md`, `CLAUDE.md`, or `CONTRIBUTING.md` for guidance. Bot suggestions often don't account for project-specific conventions.

### What to do with each thread

For comments that are clearly valid or clearly false positives, decide inline. For anything ambiguous or risky, invoke the `question` tool to ask the user before proceeding. The `question` tool is a real tool call that presents selectable options in the UI — use it anywhere the skill calls for user input rather than asking in plain text:

```
question: "Comment by @<author> on <file>:<line> — <one-line summary>. This looks ambiguous: <reason>. How should I handle it?"
options:
  - "Fix it"
  - "Skip it"
  - "Skip and resolve the thread"
```

| Situation | Action |
|---|---|
| Clear valid bug, not yet fixed | Fix it |
| Valid bug but already fixed in a later commit | Skip — ask user if they want a reply comment, then resolve |
| False positive / valid intentional code | Skip — ask user if they want a reply comment, then resolve |
| Ambiguous or risky fix | Use the `question` tool to ask the user |

---

## Step 4: Spawn a subagent per fix (in parallel)

For each comment triaged as a genuine fix (not a skip), spawn a subagent to apply it. Launch all fix subagents in the same turn so they run in parallel — do not gather context yourself first, let each subagent do its own context gathering for its specific fix.

Each subagent should be given:
- The comment body, file path, and line number
- The diff hunk for context
- The triage reasoning (why this was judged a real issue)
- Instructions to:
  - Read the full file at the referenced path (not just the diff hunk)
  - Search for similar patterns in the codebase to understand intent
  - Check git log for the affected lines to understand history
  - Make the **smallest correct change** that addresses the issue — nothing more
  - Output a summary of exactly what it changed

Skipped comments (false positives, stale, ambiguous) do not get a subagent — handle those inline.

Wait for all subagents to complete before proceeding.

---

## Step 6: Run checks once

After all fix subagents have completed, run the project's lint, format, and build checks **once** — not per-fix. Check for the project's rules in this order:

1. `AGENTS.md`, `CLAUDE.md`, or `CONTRIBUTING.md` for the canonical check commands
2. `package.json` scripts (look for `lint`, `typecheck`, `build`, `test`)
3. `Makefile`, `justfile`, or `Taskfile`

Run whatever combination of checks is appropriate. If anything fails, assess whether the failure is related to one of the fixes — if so, spawn a subagent to fix it, then re-run checks. If the failure appears unrelated to the fixes, flag it to the user and ask whether to proceed anyway or stop.

---

## Step 7: Present all fixes and get sign-off

Show all diffs together first, then ask one question to approve and push. Do not ask per-fix — gather the full picture first.

For each fix applied, output the diff as a fenced markdown diff block in your response — do not just run `git diff` raw. This ensures proper syntax highlighting in OpenCode, Cursor, and other UIs. Get the diff with:

```bash
git diff HEAD <file>
```

Then render it in your response as a before/after pair with emoji markers and language-tagged code blocks for syntax highlighting:

**Comment by @\<author\> on \<file\>:\<line\>**
Issue: \<brief summary\>
Assessment: \<why you judged this valid\>

**🔴 Before:**
```<language>
<old code>
```

**🟢 After:**
```<language>
<new code>
```

For each skipped thread, show inline below the fixes (no question needed):

```
SKIP — Comment by @<author> on <file>:<line>: <one-line reason>
```

After showing everything, check Graphite availability and the last-used tool preference:

```bash
GT_AVAILABLE=$(which gt > /dev/null 2>&1 && echo "true" || echo "false")
GT_PREFERENCE=$(git config --local fix-pr-comments.pushtool 2>/dev/null)
```

Then ask a single question that combines approval and push method. If `GT_AVAILABLE` is `false`, omit the Graphite option entirely:

```
question: "Do these fixes look correct?"
options:
  - "Commit and push with Graphite" (recommended if GT_AVAILABLE and GT_PREFERENCE is "gt" or unset)
  - "Commit and push with plain git" (recommended if GT_PREFERENCE is "git", or GT_AVAILABLE is false)
  - "Request changes"
```

If they request changes, ask them to describe what they want, apply the changes, re-show the updated diffs, and ask again.

After the user picks a push method, save their choice so it's recommended first next time:

```bash
git config --local fix-pr-comments.pushtool <git|gt>
```

Use the answer to choose the right flow below. Never use `git add .` — stage only the files that belong to each individual fix.

---

## Step 8: Commit and push

### Stack awareness

When fixes span multiple PRs in a stack, each fix must be committed on the branch that owns that PR — not wherever the repo happens to be checked out. Before committing any fix, look up the branch for that PR:

```bash
gh pr view <pr_number> --json headRefName --jq '.headRefName'
```

Then checkout that branch before staging and committing:

```bash
git checkout <branch>
```

After all commits are done, return to the original branch:

```bash
git checkout <original_branch>
```

Group fixes by PR so you only checkout each branch once — don't thrash between branches per-fix.

### Plain git

For each approved fix, on the correct branch:

```bash
git add <specific files>
git commit -m "fix: <concise description>

Addresses comment by @<author>: <one-line summary of the issue>"
```

After all commits across all branches, push each affected branch:

```bash
git push origin <branch>
```

### Graphite (`gt`)

For each approved fix, on the correct branch:

```bash
git add <specific files>
gt modify -m "fix: <concise description>

Addresses comment by @<author>: <one-line summary of the issue>"
```

After **all** fixes across all branches are committed, submit the entire stack in one shot:

```bash
gt ss
```

Do not run `gt submit` or `gt ss` per-fix or per-branch — commit everything first, then submit once at the end.

---

## Step 9: Resolve threads on GitHub

After pushing, resolve all threads. Use the thread `id` node ID from Step 2 for all GraphQL calls.

For **fixed threads**, resolve immediately:

```bash
gh api graphql -f query='
mutation {
  resolveReviewThread(input: {threadId: "THREAD_NODE_ID"}) {
    thread { isResolved }
  }
}'
```

For **false-positive and stale threads**, if there are any skipped threads, ask once (not per thread) using the `question` tool:

```
question: "Leave a reply on skipped threads explaining why before resolving?"
options:
  - "Yes, reply then resolve"
  - "No, just resolve silently"
```

If yes, post a reply on each skipped thread, then resolve:

```bash
# Post reply
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments/{comment_id}/replies \
  -f body="Not a real issue — <explanation of why this is a false positive or already handled>"

# Then resolve the thread
gh api graphql -f query='
mutation {
  resolveReviewThread(input: {threadId: "THREAD_NODE_ID"}) {
    thread { isResolved }
  }
}'
```

If no, resolve silently:

```bash
gh api graphql -f query='
mutation {
  resolveReviewThread(input: {threadId: "THREAD_NODE_ID"}) {
    thread { isResolved }
  }
}'
```

For top-level issue comments (which can't be "resolved"), reply with the relevant commit sha instead.

---

## Writing style for PR replies

When posting reply comments on GitHub threads, follow these rules:

- **Never use em dashes** (—). Use commas, periods, or parentheses instead to break up sentences.
- Keep replies concise and direct.
- Use inline code formatting for identifiers, file names, and code snippets.

## Principles

- **Verify first**: always check the actual current file, not just the diff, before deciding anything
- **Smallest fix**: change exactly what was reported, nothing more
- **One commit per issue**: keeps history clean and bisectable
- **User approves everything**: never push or resolve without explicit sign-off
- **Explain your reasoning**: whether you fix or skip, tell the user why
