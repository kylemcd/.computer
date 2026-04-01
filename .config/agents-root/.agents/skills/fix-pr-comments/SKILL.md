---
name: fix-pr-comments
description: Address unresolved GitHub PR review threads — especially from Cursor BugBot and other automated bots — skeptically and methodically. Use this skill whenever the user wants to work through open comments or feedback on a pull request, deal with bugbot or coderabbitai comments, resolve review threads, or address reviewer feedback on a PR. Does not apply to code comments (TODOs, inline comments in files) or general code review requests not tied to an open pull request.
allowed-tools:
  - "Bash(gh *)"
  - "Bash(git *)"
  - "Bash(gt *)"
  - "Bash(jq *)"
---

# Fix PR Comments

Work through unresolved PR review comments skeptically: gather context, decide what's worth fixing, apply minimal correct changes, get the user's sign-off, then commit per-issue, push, and resolve the thread on GitHub.

## The core idea

Automated tools like Cursor BugBot have high false-positive rates. The most important thing is to verify each issue against the *actual current codebase* — not just the diff — before touching anything. Many comments are stale, wrong, or describing intentional behavior.

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
# Fetch only unresolved review threads — substitute real values for OWNER, REPO, PR_NUMBER
gh api graphql -f query='
{
  repository(owner: "OWNER", name: "REPO") {
    pullRequest(number: PR_NUMBER) {
      reviewThreads(first: 100, filterBy: { isResolved: false }) {
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
}'
```

The API returns only unresolved threads. The first comment in each thread is the root issue to address. If there are none, stop and tell the user.

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

## Step 7: Present all fixes to the user

For each fix applied, output the diff as a fenced markdown diff block in your response — do not just run `git diff` raw. This ensures proper syntax highlighting in OpenCode, Cursor, and other UIs. Get the diff with:

```bash
git diff HEAD <file>
```

Then render it in your response as a before/after pair with emoji markers and language-tagged code blocks for syntax highlighting:

**🔴 Before:**
```<language>
<old code>
```

**🟢 After:**
```<language>
<new code>
```

Then present context and ask:

```
Comment by @<author> on <file>:<line>
Issue: <brief summary>
Assessment: <why you judged this valid>
```

```
question: "Does this fix look correct?"
options:
  - "Yes, looks good"
  - "No, request changes"
  - "Skip this fix"
```

If they request changes, ask them to describe what they want, apply the changes, show the updated diff, and ask again before moving on.

For each skipped thread, show inline (no question needed):

```
Comment by @<author> on <file>:<line>
Issue: <brief summary>
Decision: SKIP — <reason>
```

Once all fixes have been individually approved, do a final summary confirmation using the `question` tool:

```
question: "All fixes reviewed. Ready to commit and push?"
options:
  - "Yes, proceed"
  - "No, I want to revisit something"
```

---

## Step 8: Commit and push

After the user signs off, check for a cached Graphite availability result first to avoid re-running `which gt` every session:

```bash
cat /tmp/fix-pr-comments-gt-available 2>/dev/null
```

If the cache file doesn't exist, run the check and cache the result:

```bash
if which gt > /dev/null 2>&1; then
  echo "true" > /tmp/fix-pr-comments-gt-available
else
  echo "false" > /tmp/fix-pr-comments-gt-available
fi
```

If `gt` is not available, skip straight to plain git — don't ask. If `gt` is available, use the `question` tool to ask:

```
question: "Ready to push? Which tool should I use?"
options:
  - "Plain git"
  - "Graphite (gt)"
```

Use the answer to choose the right flow below. Never use `git add .` — stage only the files that belong to each individual fix.

### Plain git

For each approved fix:

```bash
git add <specific files>
git commit -m "fix: <concise description>

Addresses comment by @<author>: <one-line summary of the issue>"
```

Then push:

```bash
git push
```

### Graphite (`gt`)

For each approved fix:

```bash
git add <specific files>
gt modify -m "fix: <concise description>

Addresses comment by @<author>: <one-line summary of the issue>"
```

Then submit the full stack by default:

```bash
gt submit --no-interactive --stack
```

Only submit the current branch alone if the user explicitly asks for that:

```bash
gt submit --no-interactive
```

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

For **false-positive and stale threads, use the `question` tool to ask the user before resolving:

```
question: "Comment by @<author> on <file>:<line> is being skipped — <one-line reason>. Leave a reply on the thread explaining why before resolving?"
options:
  - "Yes, leave a reply"
  - "No, just resolve it silently"
```

If yes, post the reply first, then resolve:

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

## Principles

- **Verify first**: always check the actual current file, not just the diff, before deciding anything
- **Smallest fix**: change exactly what was reported, nothing more
- **One commit per issue**: keeps history clean and bisectable
- **User approves everything**: never push or resolve without explicit sign-off
- **Explain your reasoning**: whether you fix or skip, tell the user why
