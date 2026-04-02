---
name: gh-stack
description: >
  Create, manage, and merge stacked pull requests using plain Git + GitHub CLI,
  as a full replacement for Graphite. Only use this skill when Graphite is
  fundamentally unavailable — not installed, not synced to the repo, or the
  user has explicitly decided not to use it at all. Also trigger when the user
  asks to do PR stack operations "manually" in a context that means bypassing
  Graphite entirely (not just fixing a Graphite error). Do NOT trigger when the
  user is working within Graphite and hits an error or conflict — use the
  graphite skill to fix those. Do NOT trigger for general stacking/merging
  requests with no signal that Graphite is absent. Concrete triggers: "graphite
  isn't installed on this repo", "we don't have graphite set up", "do it without
  graphite", "not using graphite on this project", "graphite doesn't have access
  to this repo", "manually merge these PRs" (where manually = without any tool,
  not = fix a tool error).
---

# gh-stack: stacked PRs without Graphite

This skill covers the full lifecycle of a PR stack when Graphite is not available
or not synced to the repo: creating the stack, pushing branches, opening PRs,
and merging them bottom-up with proper retargeting and conflict resolution.

---

## Mental model

A stack is a series of branches where each one is parented on the one below it:

```
main
 └── branch-A   (PR #1 → base: main)
      └── branch-B   (PR #2 → base: branch-A)
           └── branch-C   (PR #3 → base: branch-B)
```

When PR #1 is squash-merged into main, branch-B now has stale history. Before
merging PR #2, you must rebase branch-B onto the updated main (skipping any
commits that were already merged) and force-push, then update the PR base to
`main`. Repeat for each PR down the stack.

---

## Creating the stack

1. Start from main, pull latest:
   ```bash
   git checkout main && git pull
   ```

2. For each logical change, stage your files and create a branch:
   ```bash
   git add <files>
   git checkout -b <branch-name>
   git commit -m "<message>"
   ```
   Each subsequent branch is created while already on the previous one — this
   is what makes them stacked.

3. Push all branches in one shot:
   ```bash
   git push origin branch-A branch-B branch-C
   ```

4. Open PRs, setting the base to the **parent branch** (not main) for all but
   the first:
   ```bash
   gh pr create --head branch-A --base main       --title "..." --body-file /tmp/pr-A.md
   gh pr create --head branch-B --base branch-A   --title "..." --body-file /tmp/pr-B.md
   gh pr create --head branch-C --base branch-B   --title "..." --body-file /tmp/pr-C.md
   ```
   Setting the base to the parent means GitHub shows only the incremental diff
   for each PR — much easier to review.

---

## Merging the stack (bottom-up)

Work from the bottom of the stack upward. For each PR:

### Step 1 — Try squash merge
```bash
gh pr merge <number> --squash --subject "<commit message>"
```

If this fails with "not mergeable: the base branch policy prohibits the merge",
branch protection is blocking you (likely requires an approving review).
Try `--admin` to bypass non-review rules:
```bash
gh pr merge <number> --squash --admin --subject "<commit message>"
```
If *that* fails with "At least 1 approving review is required", you cannot
bypass it — wait for approval or ask the user how to proceed.

### Step 2 — Retarget the next PR to main
After the bottom PR merges, the next one's base is now a deleted/stale branch.
Retarget it:
```bash
gh pr edit <next-number> --base main
```

### Step 3 — Rebase the next branch onto updated main
```bash
git fetch origin main
git checkout <next-branch>
git rebase origin/main
```

During the rebase, commits that were already squash-merged will appear as
conflicts or be detected as already upstream. Handle them:

- **If git says "patch contents already upstream"** — it auto-drops them. Let
  the rebase finish normally.
- **If there's a conflict on a commit you know is already merged** — skip it:
  ```bash
  git rebase --skip
  ```
  Only skip commits you're certain are already in main. If the conflict is in
  a commit unique to this branch, resolve it manually, then:
  ```bash
  git add <resolved-files>
  git rebase --continue
  ```

After a clean rebase:
```bash
git push origin <next-branch> --force-with-lease
```

### Step 4 — Repeat
Go back to Step 1 for the next PR in the stack.

---

## Writing PR bodies

Always write PR bodies to a temp file and use `--body-file`, not `--body`.
Shell escaping will mangle markdown in `--body` strings.

```bash
# Write body to file first
cat > /tmp/pr-body.md << 'EOF'
## Summary
...
EOF

gh pr create ... --body-file /tmp/pr-body.md
```

For a stacked PR, the body should explain:
- What this PR changes (relative to its parent)
- How it fits into the stack (what the stack is trying to accomplish overall)

---

## Common failure modes

| Symptom | Cause | Fix |
|---------|-------|-----|
| `not mergeable: base branch policy prohibits` | CI still running or review required | Check `gh pr checks <n>`, wait or get approval |
| `At least 1 approving review is required` | Branch protection rule | Cannot bypass — must get approval |
| `not mergeable: merge commit cannot be cleanly created` | Stale branch after lower PR merged | Rebase onto main and force-push (Step 3 above) |
| Rebase conflict on a commit you recognize as already merged | Squash merge changes the commit hash | `git rebase --skip` |
| Rebase conflict on a commit unique to this branch | Actual conflict with changes landed since you branched | Resolve manually, `git add`, `git rebase --continue` |

---

## Checking PR status

Before merging, verify CI is green:
```bash
gh pr checks <number>
```

Check for bot review comments (BugBot, CodeRabbit, etc.):
```bash
gh api repos/<owner>/<repo>/pulls/<number>/reviews --jq '.[] | "\(.user.login): \(.state)"'
gh api repos/<owner>/<repo>/pulls/<number>/comments --jq '.[] | "\(.user.login): \(.body[:120])"'
gh api repos/<owner>/<repo>/issues/<number>/comments --jq '.[] | "\(.user.login): \(.body[:120])"'
```

---

## Updating Linear tickets

If the branches are named after Linear tickets (e.g., `kyle-kno-12385-...`),
update the ticket state as you go:
- When PRs are created: set to "In Progress"
- When PRs are merged: set to "Done"

---

## Quick reference — full merge sequence for a 4-PR stack

```bash
# Merge bottom PR
gh pr merge 981 --squash --subject "fix: ..."

# Retarget + rebase second PR
gh pr edit 982 --base main
git fetch origin main && git checkout branch-B && git rebase origin/main
# (skip any already-merged commits with: git rebase --skip)
git push origin branch-B --force-with-lease
gh pr merge 982 --squash --subject "fix: ..."

# Retarget + rebase third PR
gh pr edit 983 --base main
git fetch origin main && git checkout branch-C && git rebase origin/main
git push origin branch-C --force-with-lease
gh pr merge 983 --squash --subject "fix: ..."

# And so on...
```
