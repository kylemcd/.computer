---
name: fix-pr-comments
description: Address unresolved GitHub PR review threads — especially from Cursor BugBot and other automated bots — skeptically and methodically. Use this skill whenever the user wants to work through open comments or feedback on a pull request, deal with bugbot or coderabbitai comments, resolve review threads, or address reviewer feedback on a PR. Does not apply to code comments (TODOs, inline comments in files) or general code review requests not tied to an open pull request.
allowed-tools:
  - "Bash(gh *)"
  - "Bash(git *)"
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

If there's no PR for the current branch, stop and tell the user.

---

## Step 2: Fetch unresolved review threads

The REST API doesn't expose resolved status, so use GraphQL:

```bash
# Get owner/repo first
gh repo view --json owner,name

# Then fetch all review threads
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
}'
```

Filter to threads where `isResolved: false`. The first comment in each thread is the root issue to address.

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

For comments that are clearly valid or clearly false positives, decide inline. For anything ambiguous or risky, use the `question` tool to ask the user before proceeding:

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
| Valid bug but already fixed in a later commit | Skip — note this for the user, resolve the thread |
| False positive / valid intentional code | Skip — explain why, resolve the thread |
| Ambiguous or risky fix | Use the `question` tool to ask the user |

---

## Step 4: For each fix, gather context first

Before changing anything:

- Read the full file at the referenced path (not just the diff hunk)
- Search for similar patterns in the codebase to understand whether it's intentional
- Check git blame/log for the affected lines to understand the history
- For type or nullability issues, trace back to the type definitions

The goal is to understand *why* the code is the way it is before deciding to change it.

---

## Step 5: Spawn a subagent per fix (in parallel)

For each comment triaged as a genuine fix (not a skip), spawn a subagent to apply it. Launch all fix subagents in the same turn so they run in parallel.

Each subagent should be given:
- The comment body, file path, and line number
- The diff hunk for context
- The triage reasoning (why this was judged a real issue)
- The instruction to make the **smallest correct change** that addresses the issue — nothing more
- The instruction to output a summary of exactly what it changed

Skipped comments (false positives, stale, ambiguous) do not get a subagent — handle those inline.

Wait for all subagents to complete before proceeding.

---

## Step 6: Run checks once

After all fix subagents have completed, run the project's lint, format, and build checks **once** — not per-fix. Check for the project's rules in this order:

1. `AGENTS.md`, `CLAUDE.md`, or `CONTRIBUTING.md` for the canonical check commands
2. `package.json` scripts (look for `lint`, `typecheck`, `build`, `test`)
3. `Makefile`, `justfile`, or `Taskfile`

Run whatever combination of checks is appropriate. If anything fails, fix it before presenting to the user.

---

## Step 7: Present all fixes to the user

Show a summary of everything — fixes applied and threads skipped — so the user can review at once:

For each fix applied:

```
Comment by @<author> on <file>:<line>
Issue: <brief summary>
Assessment: <why you judged this valid>
Fix: <what was changed>

<show the relevant diff>
```

For each skipped thread:

```
Comment by @<author> on <file>:<line>
Issue: <brief summary>
Decision: SKIP — <reason>
```

Use the `question` tool to get sign-off:

```
question: "Do all of these look right?"
options:
  - "Yes, looks good"
  - "No, I want to revisit something"
```

If they want to revisit, ask which comment and handle it before proceeding.

---

## Step 8: Commit and push

After the user signs off, first check whether Graphite is available:

```bash
which gt
```

If `gt` is not found, skip straight to plain git — don't ask. If `gt` is available, use the `question` tool to ask:

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

Then submit the stack:

```bash
gt submit --no-interactive
```

---

## Step 9: Resolve threads on GitHub

After pushing, resolve each addressed thread using GraphQL (use the thread `id` node ID from Step 2):

```bash
gh api graphql -f query='
mutation {
  resolveReviewThread(input: {threadId: "THREAD_NODE_ID"}) {
    thread { isResolved }
  }
}'
```

For false-positive threads, use the `question` tool to ask the user before resolving:

```
question: "Comment by @<author> on <file>:<line> is a false positive — <one-line reason>. Would you like to leave a comment explaining this before resolving the thread?"
options:
  - "Yes, leave a comment explaining why"
  - "No, just resolve it silently"
```

If yes, post a reply with the explanation before resolving:

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments/{comment_id}/replies \
  -f body="Not a real issue — <explanation of why this is a false positive or already handled>"
```

For top-level issue comments (which can't be "resolved"), reply with the relevant commit sha instead.

---

## Principles

- **Verify first**: always check the actual current file, not just the diff, before deciding anything
- **Smallest fix**: change exactly what was reported, nothing more
- **One commit per issue**: keeps history clean and bisectable
- **User approves everything**: never push or resolve without explicit sign-off
- **Explain your reasoning**: whether you fix or skip, tell the user why
