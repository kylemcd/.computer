---
name: gh-stack
description: >
  Work with GitHub's native `gh stack` CLI extension for stacked pull requests.
  Use this skill whenever the user wants to create a stack, add branches to a
  stack, push or submit a stack, rebase/sync a stack, navigate between stack
  layers, rename or reorder branches in a stack, restructure a stack, or merge
  a stack bottom-up. Also use when the user mentions "gh stack", "GitHub stacked
  PRs", stacking branches with the gh CLI, or asks to set up the gh-stack
  extension. Prefer this skill over the graphite skill when the user is working
  with GitHub's native stacking feature rather than Graphite.
allowed-tools:
  - "Bash(gh stack *)"
  - "Bash(gh pr *)"
  - "Bash(git add *)"
  - "Bash(git commit *)"
  - "Bash(git checkout *)"
  - "Bash(git branch *)"
  - "Bash(git rebase *)"
  - "Bash(git fetch *)"
  - "Bash(git push *)"
  - "Bash(git status *)"
  - "Bash(git stash *)"
  - "Bash(git diff *)"
  - "Bash(git reset *)"
  - "Bash(git config *)"
---

# gh-stack Skill

Work with GitHub's native `gh stack` CLI extension for stacked pull requests.

## Setup

```sh
# Install the extension (one time)
gh extension install github/gh-stack

# Pre-configure to avoid interactive prompts on first use
git config rerere.enabled true       # remember conflict resolutions
git config remote.pushDefault origin # avoid remote picker if multiple remotes
```

Requires `gh` v2.0+ and Git 2.20+.

---

## Agent rules — read these first

**All `gh stack` commands must be run non-interactively.** Several commands launch interactive TUIs or prompt for input if called without the right arguments. Any of these will hang indefinitely for an agent.

| Never do this | Do this instead | Why |
|---|---|---|
| `gh stack view` | `gh stack view --json` | Without `--json`, launches an interactive TUI |
| `gh stack submit` | `gh stack submit --auto` | Without `--auto`, prompts for a PR title per branch |
| `gh stack init` (no args) | `gh stack init -p feat auth api` | No args triggers interactive branch-name prompt |
| `gh stack add` (no args) | `gh stack add api-routes` | No args triggers interactive branch-name prompt |
| `gh stack checkout` (no args) | `gh stack checkout 42` or `gh stack checkout feat/auth` | No args triggers interactive selection menu |
| `gh stack add api` with prefix `feat` set | `gh stack add api` (suffix only) | Passing full name `feat/api` creates `feat/feat/api` |

**When a prefix is set (`-p`), always pass only the suffix to `gh stack add`.** The prefix is applied automatically.

---

## Quick Reference

| I want to... | Command |
|---|---|
| Start a new stack with a prefix | `gh stack init -p feat auth api-routes frontend` |
| Adopt existing branches | `gh stack init --adopt branch-a branch-b branch-c` |
| Add a branch to top of stack | `gh stack add api-routes` (suffix only if prefix set) |
| Stage, commit, and add branch in one step | `gh stack add -Am "message" api-routes` |
| View the stack | `gh stack view --json` |
| Push all branches | `gh stack push` |
| Push branches and create/update PRs | `gh stack submit --auto` |
| Push branches as drafts | `gh stack submit --auto --draft` |
| Sync everything (fetch + rebase + push + PR state) | `gh stack sync` |
| Rebase the full stack | `gh stack rebase` |
| Rebase only branches above current | `gh stack rebase --upstack` |
| Move up one layer (away from trunk) | `gh stack up` |
| Move down one layer (toward trunk) | `gh stack down` |
| Jump to top of stack | `gh stack top` |
| Jump to bottom of stack | `gh stack bottom` |
| Check out a stack from a PR number | `gh stack checkout <pr-number>` |
| Rename a branch | `gh stack unstack` → `git branch -m old new` → `gh stack init --adopt` → `gh stack submit --auto` |
| Reorder branches | `gh stack unstack` → reorder → `gh stack init --adopt` → `gh stack submit --auto` |
| Delete the stack (keep branches/PRs) | `gh stack unstack` |

---

## What Makes a Good Stack?

A stack is a series of branches where each one builds on the layer below:

```
main
 └── feat/data-models    (PR #1 → base: main)         ← bottom
      └── feat/api-routes   (PR #2 → base: feat/data-models)
           └── feat/frontend  (PR #3 → base: feat/api-routes)  ← top
```

Each PR shows **only its own diff** — the incremental change between its branch and the one below. Reviewers see focused, reviewable slices instead of one giant change.

**Good layers are:**
- A discrete, logical unit of work (one concern per branch)
- Safe to review independently of layers above it
- Foundational changes go **lower**, dependent changes go **higher**

Plan your stack layers by dependency order **before writing code**. If code in one layer depends on another, the dependency must be in the same branch or a lower one.

---

## Branch Naming

Use the `-p` prefix flag — it groups branches under a namespace and means you only type the suffix on subsequent `add` calls:

```sh
gh stack init -p feat auth api-routes frontend
# creates: feat/auth, feat/api-routes, feat/frontend

gh stack add tests   # with prefix feat set → creates feat/tests
```

---

## Creating a Stack

### Standard flow

```sh
# 1. Start the stack — name branches upfront (best for agents, fully non-interactive)
gh stack init -p feat auth api-routes frontend
# Or with a custom trunk: gh stack init -p feat --base develop auth api-routes frontend

# 2. Write code, stage deliberately, commit on the first layer
git add internal/models/user.go
git commit -m "Add user model"

# 3. Advance to the next layer (branch already created by init — just navigate)
gh stack up

# 4. Write code and commit on the second layer
git add internal/api/routes.go
git commit -m "Add API routes"

# 5. Advance to the final layer and commit
gh stack up
git add frontend/dashboard.go
git commit -m "Add frontend dashboard"

# 6. Push branches and create PRs (--auto required to avoid title prompts)
gh stack submit --auto
```

### Abbreviated flow (stage + commit + create next branch in one step)

`gh stack add -Am "message" <branch>` stages all files, commits to the current branch, then creates and checks out the next branch. Use it for every layer **except the last** — on the last layer commit normally to avoid creating an unwanted extra branch.

```sh
gh stack init -p feat auth   # creates feat/auth, checks it out

# ... write code for layer 1 ...
gh stack add -Am "Add data models" api-routes   # commits feat/auth, creates + checks out feat/api-routes

# ... write code for layer 2 ...
gh stack add -Am "Add API routes" frontend      # commits feat/api-routes, creates + checks out feat/frontend

# ... write code for layer 3 (final layer) ...
git add -A && git commit -m "Add frontend"      # plain commit — do NOT use gh stack add here

gh stack submit --auto
```

`-A` stages all files including untracked. `-u` stages only tracked files. `-m` is required with either. The branch name is always the last positional argument.

### Adopting existing branches

```sh
gh stack init --adopt feat/data-models feat/api-routes feat/frontend
gh stack submit --auto
```

Order matters — list them bottom to top (closest to trunk first).

---

## Navigating a Stack

Navigation clamps at the bounds — going `up` from the top or `down` from the bottom is a no-op. Merged branches are skipped.

```sh
gh stack up          # move up one layer (away from trunk)
gh stack up 3        # move up three layers
gh stack down        # move down one layer (toward trunk)
gh stack down 2      # move down two layers
gh stack top         # jump to topmost branch
gh stack bottom      # jump to bottommost branch

# Check out by PR number (fetches from GitHub if not local)
gh stack checkout 42

# Check out by branch name (local stacks only)
gh stack checkout feat/api-routes
```

> **Agent warning:** `gh stack checkout <pr-number>` triggers an interactive conflict prompt if the local stack has different branches than the remote. To avoid this: run `gh stack unstack` first, then retry.

---

## Making Changes Mid-Stack

If you realize something lower in the stack needs fixing while you're working higher up:

```sh
# Navigate to the layer that needs the fix
gh stack checkout feat/api-routes   # or: gh stack down

# Make the fix and commit
git add internal/api/users.go
git commit -m "Add get-user endpoint"

# Rebase everything above to pick up the change
gh stack rebase --upstack

# Push the updated branches
gh stack push
```

This keeps each layer focused and avoids muddying reviewer diffs with changes that belong elsewhere.

### Responding to review feedback on a mid-stack PR

```sh
# Navigate to the branch that needs changes
gh stack checkout feat/api-routes

# Make the fixes and commit
git add internal/api/routes.go
git commit -m "Address review feedback"

# Cascade changes through the rest of the stack
gh stack rebase

# Push updated branches
gh stack push
```

---

## Viewing Stack State

Always use `--json` — without it, `gh stack view` launches an interactive TUI:

```sh
gh stack view --json
```

Useful jq patterns:

```sh
OUTPUT=$(gh stack view --json)

# Check if any branch needs rebase
echo "$OUTPUT" | jq '[.branches[] | select(.needsRebase == true)] | length'

# Get all open PR URLs
echo "$OUTPUT" | jq -r '.branches[] | select(.pr.state == "OPEN") | .pr.url'

# Find merged branches
echo "$OUTPUT" | jq -r '.branches[] | select(.isMerged == true) | .name'

# Get current branch
echo "$OUTPUT" | jq -r '.currentBranch'
```

---

## Rebasing

`gh stack rebase` fetches from origin, then cascades a rebase upward from trunk through every branch in the stack. Handles squash-merged PRs automatically.

```sh
gh stack rebase               # full stack
gh stack rebase --downstack   # trunk up to current branch only
gh stack rebase --upstack     # current branch up to top only
```

If a conflict occurs, the operation pauses. All branches are restored to their pre-rebase state if you abort:

```sh
# 1. Resolve conflict markers in the file
# 2. Stage the resolved file
git add <resolved-file>

# 3. Continue
gh stack rebase --continue

# Or abort entirely (restores all branches to pre-rebase state)
gh stack rebase --abort
```

---

## Syncing After Merges

When PRs at the bottom of the stack are merged on GitHub:

```sh
gh stack sync
```

This does everything in one command: fetch → fast-forward trunk → cascade rebase → push → sync PR state from GitHub.

If `sync` detects a conflict it restores all branches and tells you to run `gh stack rebase` to resolve interactively.

---

## Renaming Branches

`gh stack` does not have a rename command:

```sh
# 1. Tear down the stack (branches and PRs are preserved)
gh stack unstack

# 2. Rename the branch locally
git branch -m old-branch-name new-branch-name

# 3. Re-create the stack in order (bottom to top)
gh stack init --adopt new-branch-name other-branch-1 other-branch-2

# 4. Re-submit (re-associates existing open PRs with the new stack)
gh stack submit --auto
```

---

## Reordering Branches

```sh
# 1. Tear down the stack
gh stack unstack

# 2. Fix git history order (rebase to match desired order)
git checkout branch-you-want-second
git rebase branch-you-want-first

# 3. Re-create in the desired order (bottom to top)
gh stack init --adopt branch-first branch-second branch-third

# 4. Push and re-link PRs
gh stack submit --auto
```

---

## Merging a Stack

Stacks merge **bottom-up**. You cannot merge a PR until all PRs below it are merged.

> **CLI merge is not supported.** Open the PR URL in a browser to merge — `gh stack` does not have a merge command.

1. Open the bottom PR URL in a browser and merge it
2. Run `gh stack sync` locally to fast-forward and rebase the remaining branches
3. Repeat until the stack is empty

---

## Writing PR Descriptions

PR titles and bodies are auto-generated by `gh stack submit --auto` (single commit → commit subject; multiple commits → humanized branch name). To customize, use `gh pr edit` after creation — always use `--body-file` to avoid shell escaping issues with markdown:

```sh
cat > /tmp/pr-body.md << 'EOF'
## Stack Context

This stack adds user authentication to the app.

## What?

Adds the data layer — User model and migrations.

## Why?

The API routes (PR #2) and frontend (PR #3) depend on these models existing first.
EOF

gh pr edit <number> --title "feat/auth: add user model" --body-file /tmp/pr-body.md
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| Command hangs / TUI appears | Missing required arg or flag | See Agent rules table at top |
| `not in a stack` (exit 2) | Not on a tracked branch | Run `gh stack view --json` to check; use `gh stack checkout` to switch |
| Disambiguation (exit 6) | Branch belongs to 2+ stacks | Check out a non-shared branch first |
| Conflict during rebase (exit 3) | Diverged history | Resolve conflicts → `git add` → `gh stack rebase --continue` |
| `gh stack sync` conflict | Auto-rebase failed | Run `gh stack rebase` manually to resolve interactively |
| `checkout <pr>` triggers prompt | Local and remote stacks differ | `gh stack unstack` first, then retry `checkout` |
| Need to restructure | No direct rename/reorder command | `gh stack unstack` → adjust → `gh stack init --adopt` → `gh stack submit --auto` |
| Multiple remotes | Push/sync prompt for remote | Pass `--remote origin` or set `git config remote.pushDefault origin` |

---

## Exit Codes

| Code | Meaning |
|---|---|
| 2 | Not in a stack / stack not found |
| 3 | Rebase conflict — resolve and `--continue` |
| 4 | GitHub API failure — check `gh auth status` |
| 5 | Invalid arguments |
| 6 | Branch belongs to multiple stacks — disambiguate |
| 7 | Rebase already in progress |
| 8 | Stack locked by another process |
