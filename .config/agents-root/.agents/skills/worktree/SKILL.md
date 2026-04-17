---
name: worktree
description: Manage git worktrees for isolated development — creating, switching, listing, and removing worktrees. Use this skill whenever the user mentions worktrees, wants to work on multiple branches simultaneously, asks to spin up an isolated environment for a branch or PR, or uses the wt/wtr/wtrm/wtl/wtcd/wtprune commands. Also use when the graphite skill needs a clean branch environment — worktrees integrate with stacked PRs to keep each stack layer isolated.
allowed-tools:
  - "Bash(git worktree *)"
  - "Bash(git fetch *)"
  - "Bash(git branch *)"
  - "Bash(git checkout *)"
  - "Bash(git stash *)"
  - "Bash(gt *)"
  - "Bash(ls *)"
  - "Bash(bash ~/.agents/skills/worktree/scripts/*)"
---

# Worktree Skill

Manage git worktrees for isolated development. A worktree is a separate checkout of the same repo in a different directory — no stashing, no context switching, no dirty state bleed between tasks.

## Shell Aliases Available

The user has these functions in their shell (from `~/.config/zsh/zsh/aliases.zsh`):

| Command | What it does |
|---------|-------------|
| `wt <branch> [base]` | New worktree + branch off `base` (default: `main`) |
| `wtr <remote-branch> [dir]` | Fetch and check out an existing remote branch (detached) |
| `wtrm <branch> [-k]` | Remove worktree; also deletes the local branch unless `-k` is passed |
| `wtl` | List all worktrees |
| `wtcd <name>` | `cd` into a worktree by name |
| `wtprune` | Prune stale worktree refs |

`WT_DIR` defaults to `..` (sibling of the current repo directory). So for a repo at `~/projects/myapp`, worktrees land at `~/projects/<branch-name>`.

**OpenCode-created worktrees** land at `~/.local/share/opencode/worktree/<repo-hash>/<branch-name>/`. This path is pre-permitted in `opencode.json` so no approval prompts appear.

---

## Per-Project Config

Project-specific worktree config lives in `~/.agent/memory/worktree-projects.json`. Read it at the start of any worktree creation to know what to copy, symlink, and run.

### Finding the right project entry

Match the current repo to a project key by checking if the repo's path contains the key as a substring. For example, CWD `.../Code/knock/control` matches key `knock/control`.

### Config shape

```json
"_worktrees": {
  "/abs/path/to/new-worktree": {
    "gitTool": "graphite"
  }
}
```

| Field | Description |
|-------|-------------|
| `copyFiles` | Paths relative to repo root to copy from main worktree into new one |
| `symlinkDirs` | Paths relative to repo root to symlink instead of copy (saves disk space) |
| `hooks.postCreate` | Shell commands to run inside the new worktree after creation |
| `hooks.preDelete` | Shell commands to run inside the worktree before removal |
| `_worktrees` | Per-worktree metadata, keyed by absolute path |
| `_worktrees.<path>.gitTool` | `"graphite"`, `"gh-stack"`, or `"git"` |

If no matching project entry exists, proceed without config and mention to the user that they can add one.

---

## Creating a Worktree

### Full creation sequence

1. **Create the worktree** (via shell alias or raw git):
   ```bash
   # Using shell alias (sibling dir layout)
   wt my-feature           # new branch from main
   wt my-feature some-base # new branch from some-base

   # Raw git (e.g. for a specific path)
   git worktree add -b my-feature <path> main
   ```
2. **Run the setup script** — it reads `~/.agent/memory/worktree-projects.json`, matches the project, copies files, creates symlinks, and runs postCreate hooks:
   ```bash
   bash ~/.agents/skills/worktree/scripts/setup-worktree.sh <source_repo_path> <new_worktree_path>
   ```
   Both paths must be absolute. The script is a no-op if no config entry matches.
3. **Record the git tool — this step is mandatory and blocks completion.** A worktree is not fully created until `gitTool` is written to memory. Do not report success to the user until this is done.

   Use the `question` tool to ask — do not default, do not skip, do not infer from context:
   ```
   question: "Which git tool do you want to use in this worktree?"
   options:
     - "Graphite (gt)"
     - "GitHub stacking (gh stack)"
     - "Plain git"
   ```
   Then immediately write the answer:
   ```bash
   bash ~/.agents/skills/worktree/scripts/memory.sh set-tool /abs/path/to/new-worktree <graphite|gh-stack|git>
   ```
   Verify it was written:
   ```bash
   bash ~/.agents/skills/worktree/scripts/memory.sh get-tool /abs/path/to/new-worktree
   # must return non-empty output — if empty, something went wrong, try again
   ```
4. **Tell the user** the worktree path so they can open it.

### Check out an existing remote branch

```bash
# Fetches origin/feat/login, creates a dir with slashes converted to dashes
wtr feat/login

# With a custom directory name
wtr feat/login login-review
```

---

## Removing a Worktree

1. **Run the teardown script** — runs preDelete hooks inside the worktree before removal:
   ```bash
   bash ~/.agents/skills/worktree/scripts/teardown-worktree.sh <source_repo_path> <worktree_path>
   ```
2. **Remove the worktree entry from memory**:
   ```bash
   bash ~/.agents/skills/worktree/scripts/memory.sh remove /abs/path/to/worktree
   ```
3. **Remove**:
   ```bash
   wtrm my-feature     # removes worktree + deletes local branch
   wtrm my-feature -k  # removes worktree, keeps branch
   ```
4. Prune stale refs if needed: `wtprune`

---

## Housekeeping

```bash
wtl        # list all worktrees and their HEADs
wtprune    # clean up refs to deleted worktrees
```

---

## Worktrees + Stacked PRs

Worktrees keep each stack isolated — useful for reviewing or editing lower layers without disturbing the top.

### Starting a stack in a fresh worktree

After creating the worktree (including the git tool question from the creation sequence), proceed with the chosen tool:

**With Graphite:** the new worktree branch will be untracked — fix before stacking:

```bash
gt track -p main
# then proceed with gt create per the graphite skill
```

**With gh stack:** see the gh-stack skill.

**With plain git:** use regular branches and `gh pr create` per PR.

### Reviewing a PR stack in a worktree

```bash
# Check out the top-of-stack branch (detached, read-only)
wtr feat/auth-top auth-review
wtcd auth-review
gt ls    # inspect the stack from here
```

### Cleanup after a merged stack

```bash
wtrm auth-bugfix   # remove worktree + branch
wtprune            # prune any leftover refs
```

---

## Resuming Work in a Worktree

When you open a session from the main repo, conversation history from a prior worktree session is fully accessible. But OpenCode launches with CWD set to wherever you started — the main repo, not the worktree. Any tool call (Bash, Read, Edit) will execute there unless corrected.

### On session resume, orient immediately

Run this to see all worktrees for the current repo:

```bash
git worktree list --porcelain
```

Scan the conversation history for file paths or `workdir` values that don't match the current CWD. If prior tool calls reference a path under `~/.local/share/opencode/worktree/` or a sibling directory (e.g. `../my-feature`), that's the worktree this session was operating in.

Once identified, **set `workdir` to the worktree path on every Bash, Read, Edit, and Write tool call** for the rest of the session. Do not `cd` — use the `workdir` parameter directly. State this explicitly to the user:

> "This session was working in `<path>`. I'll continue running all commands there."

### If it's ambiguous

Ask rather than guess:

```
question: "Which worktree should I resume work in?"
options: [list each path from `git worktree list`]
```

### Stack resume

After orienting to the worktree path, read the stacking tool from memory:

```bash
bash ~/.agents/skills/worktree/scripts/memory.sh get-tool /abs/path/to/worktree
```

Use whichever tool is recorded — do not ask again. Then surface the full stack state:

```bash
# Graphite
gt ls

# gh stack
gh stack view
```

Report to the user:
- Which branches are in the stack and their order
- Which branch is currently checked out
- Which PRs have been submitted vs. still local
- Any with unresolved comments or failing CI

This gives the user a full picture before deciding what to do next (continue the stack, fix a comment, submit, etc.).

If `gitTool` is missing from memory for this worktree path, ask the user which tool they were using and write it back before continuing.

### Worktree no longer exists

If the path from history no longer appears in `git worktree list`, the worktree was removed. Options:

- Recreate it: run the full creation sequence (including setup script) on the same branch
- Continue in the main repo if the branch was already merged or the work was completed

---

## Updating Project Config

If the user wants to add or change worktree config for a project, edit `~/.agent/memory/worktree-projects.json`. This file is **not** version controlled (lives outside any repo) — it's persistent agent memory. Always read it fresh at the start of each worktree operation, never cache it.

Also document any new entry in the `~/.computer/AGENTS.md` memory table if it introduces a new file.

---

## Tips

- Worktrees share the same `.git` dir — commits, fetches, and branch updates are visible in all worktrees immediately.
- You can't check out the same branch in two worktrees at once. If you get "already checked out", use `wtr` (detached) or create a new branch.
- Long-running builds work well in worktrees — start a build in one while editing in another.
- When in doubt about which worktree you're in: `wtl`.
