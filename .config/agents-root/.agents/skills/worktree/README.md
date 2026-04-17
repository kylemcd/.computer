# Worktree Skill

An agent skill for managing git worktrees — creating isolated branches, running per-project setup, tracking which git tool you use, and resuming work mid-stack.

## First-time setup

```bash
bash ~/.agents/skills/worktree/scripts/install.sh
```

Checks dependencies, creates `~/.agent/memory/worktree-projects.json`, and creates `~/.local/worktree/`. Safe to re-run.

**Dependencies:** `git`, `jq`, `fzf` (all installable via `brew install <name>`)

---

## Shell commands

These are available in your terminal after stowing the dotfiles:

| Command | What it does |
|---------|-------------|
| `wt <branch> [base]` | Create a new worktree + branch from `base` (default: `main`) |
| `wtr <remote-branch> [dir]` | Check out an existing remote branch into a worktree |
| `wtrm <branch> [-k]` | Remove a worktree; deletes the local branch unless `-k` is passed |
| `wtl` | List all worktrees for the current repo |
| `wtcd <name>` | `cd` into a worktree by name |
| `wts` | Fuzzy-pick a worktree with fzf and `cd` into it |
| `wtprune` | Prune stale worktree refs |

> Note: these are shell functions — they're for you in the terminal, not for the agent. The agent always uses raw `git worktree` commands.

---

## Per-project config

Add project entries to `~/.agent/memory/worktree-projects.json` to automate setup when a worktree is created:

```json
{
  "my-org/my-repo": {
    "copyFiles": [".env", "backend/dev.env"],
    "symlinkDirs": ["node_modules"],
    "hooks": {
      "postCreate": ["yarn install"],
      "preDelete": ["docker compose down"]
    }
  },
  "_worktrees": {}
}
```

The project key is matched as a substring of the repo path — `my-org/my-repo` matches any path containing that string.

| Field | Description |
|-------|-------------|
| `copyFiles` | Files to copy from the main worktree (relative to repo root) |
| `symlinkDirs` | Directories to symlink instead of copy (saves disk space) |
| `hooks.postCreate` | Shell commands to run inside the new worktree after creation |
| `hooks.preDelete` | Shell commands to run before the worktree is removed |

The `_worktrees` key is managed automatically by the agent — it stores per-worktree metadata (which git tool you chose) keyed by absolute path.

---

## How the agent uses this skill

When you ask the agent to create, remove, or resume a worktree, it:

1. **Creates** the worktree at `~/.local/worktree/<repo-name>/<branch-name>/`
2. **Runs** `scripts/setup-worktree.sh` to copy files, create symlinks, and run hooks
3. **Asks** which git tool you want to use (Graphite, gh stack, or plain git) — this is mandatory and cannot be skipped
4. **Writes** your answer to `_worktrees` in memory via `scripts/memory.sh`

On **resume**, the agent reads the git tool from memory (no need to answer again) and orients all subsequent commands to the worktree path using `workdir`, not `cd`.

On **removal**, the agent runs `scripts/teardown-worktree.sh` for preDelete hooks, cleans up the memory entry, then removes the worktree and branch.

---

## Scripts

| Script | What it does |
|--------|-------------|
| `scripts/install.sh` | One-time setup — run on a new machine |
| `scripts/setup-worktree.sh <source> <dest>` | Post-create: copy files, symlink dirs, run hooks |
| `scripts/teardown-worktree.sh <source> <worktree>` | Pre-delete: run preDelete hooks |
| `scripts/memory.sh set-tool <path> <tool>` | Write gitTool for a worktree |
| `scripts/memory.sh get-tool <path>` | Read gitTool for a worktree |
| `scripts/memory.sh remove <path>` | Remove all metadata for a worktree |

---

## Worktrees + stacked PRs

After creating a worktree, the agent asks which git tool to use. Depending on your answer:

- **Graphite** — the new branch is untracked; the agent runs `gt track -p main` before starting the stack
- **gh stack** — see the `gh-stack` skill
- **Plain git** — use regular branches and `gh pr create` per PR

On resume mid-stack, the agent reads the tool from memory, runs `gt ls` or `gh stack view`, and reports the full stack state (which branches exist, which are submitted, where HEAD is) before doing anything.
