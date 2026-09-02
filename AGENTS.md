# .computer — Agent Instructions

This is a dotfiles/configuration repository managed with [GNU Stow](https://www.gnu.org/software/stow/). There is exactly one stow package, `home/.config/`, stowed with `--target=~/.config` (**not** `$HOME`) — so its own contents map onto `~/.config/` one-to-one, with no per-tool wrapper folder and no name repeated twice in the path.

**Why `--target` is `~/.config`, not `$HOME`:** stow never uses the package name when computing target paths, only `--target` plus the package's own internal relative paths. So `home/.config/tmux/tmux.conf`, stowed with `--target=~/.config`, lands at `~/.config/tmux/tmux.conf` — correct, and "tmux" appears once. Stowing the same tree with `--target=$HOME` instead would need an extra `.config/tmux/` wrapper *inside* the package just to reach the same place (`home/.config/tmux/.config/tmux/tmux.conf` → `~/.config/tmux/tmux.conf`) — that redundant doubled nesting is exactly what this structure avoids. See `dotfiles_stow()` in `scripts/dotfiles.sh` for the working implementation.

**Default to `~/.config/<tool>/` over a home-root dotfile whenever the tool actually supports it** (git via `include.path`, zsh via `ZDOTDIR` — see below). A tool that hardcodes its own location and can't be redirected (e.g. Factory's `~/.factory/`) needs its own sibling package next to `home/.config/`, targeting that real directory the same way — `.config` isn't managing anything like that right now, but that's the pattern if one comes up.

## Repo Structure

```
.computer/
├── bin/computer          # CLI: init, install, stow, linux-stow, upgrade, pull, os, mutagen, help
├── scripts/
│   ├── init.sh           # Xcode CLI tools, Rosetta, Homebrew
│   ├── install.sh        # brew bundle + stow + package extras
│   ├── homebrew.sh       # select the platform's Homebrew before shell config is loaded
│   ├── stow.sh           # stow dotfiles only (no package install)
│   ├── linux-stow.sh     # Linux-focused stow (skips oh-my-zsh bootstrap)
│   └── mutagen-sync.sh   # set up / ensure workbench <-> ~/projects file sync
├── packages              # Brewfile
├── bun-packages          # bun global packages (one per line)
├── gh-extensions         # gh extensions (one per line)
├── curl-packages         # curl | bash installers (one URL per line)
└── home/
    └── .config/          # stowed with --target=~/.config — mirrors it directly
        ├── aerospace/    # → ~/.config/aerospace/
        ├── agents/       # → ~/.config/agents/  (skills/ is a git submodule)
        ├── ghostty/      # → ~/.config/ghostty/
        ├── git/          # → ~/.config/git/  (gitconfig-computer only — ~/.config/git/ is a real, pre-existing dir with other unrelated content)
        ├── nvim/         # → ~/.config/nvim/
        ├── tmux/         # → ~/.config/tmux/  (plugins/{tpm,tmux-floax} are gitlinks, not real submodules)
        └── zsh/          # → ~/.config/zsh/  (.zshrc lives here too, via ZDOTDIR — see below)
```

opencode, gh-dash, tuicr, and Factory (`~/.factory/settings.json`) used to be managed here
too — removed by request. The apps/CLIs themselves are untouched (still installed, still
work); only this repo's management of their config was dropped. `packages` (Brewfile) still
has `tuicr` and `opencode` taps, and `gh-extensions` still lists `dlvhdr/gh-dash` — those
were intentionally left alone since removing *config management* is a different question
from removing *installation*; ask before touching those if it comes up.

Two things need something *outside* this repo to actually take effect, because the tool has to be told to look in `~/.config/` in the first place:

- **git** — `~/.gitconfig` (the user's real, unmanaged main gitconfig — never lives in this repo) has `[include] path = ~/.config/git/gitconfig-computer`, set via `git config --global include.path '~/.config/git/gitconfig-computer'` in `scripts/install.sh`. Without that include line, `home/.config/git/gitconfig-computer` is inert — git doesn't look for it on its own the way it does `~/.gitconfig`.
- **zsh** — `~/.zshenv` (unmanaged, lives outside this repo — see below) sets `export ZDOTDIR="$HOME/.config/zsh"`. zsh always reads `~/.zshenv` from the fixed default location first, *then* looks for `.zshrc`/`.zshenv`-siblings under `$ZDOTDIR`; that's the only way to make zsh read `.zshrc` from `~/.config/zsh/` instead of `~/`.

**Agent skills also get linked into other tools that don't use stow at all** — handled automatically by `dotfiles_link_skill_compat()` in `scripts/dotfiles.sh`, called at the end of every `dotfiles_stow()` (so every `computer stow`/`install`/`pull`, on any machine, keeps these current — nothing here needs a manual fix):

- **`~/.agents -> .config/agents`** — a few skills in the `kylemcd/skills` submodule itself (`worktree`, `fix-pr-comments`, `auto-build`) hardcode `~/.agents/skills/...` as an absolute path in their own scripts. That's a separate repo, so fixing it here would mean editing and pushing to `kylemcd/skills` too, out of scope for this repo. The symlink is what keeps those hardcoded paths working.
- **`~/.claude/skills -> home/.config/agents/skills`** — one whole-directory symlink; that's what Claude Code (this session included) actually reads skills from.
- **`~/.codex/skills/<name>`** — one symlink *per skill*, not a single directory. Codex bundles its own skills under `~/.codex/skills/.system/` (skill-creator, review-agent, etc. — untouched, not ours) and expects user skills as direct siblings, `~/.codex/skills/<name>/SKILL.md` (confirmed by reading its own `skill-installer` script, which installs to exactly that layout — no directory-level symlink is possible here). The function keeps this in sync both ways: adds a link for every skill currently in the submodule, and removes any link it previously made for a skill since renamed or removed — it only ever touches links pointing back into `home/.config/agents/skills/`, never `.system/` or anything else under `~/.codex/skills/`.

**This one also has a live watcher, not just a per-stow sync** — unlike the two whole-directory symlinks above (instantly live the moment a file exists on disk), Codex's per-skill links only update when `dotfiles_link_skill_compat()` actually runs. `dotfiles_install_skill_watcher()` (also in `scripts/dotfiles.sh`, called right after it in `dotfiles_stow()`) registers a per-user launchd agent — `~/Library/LaunchAgents/dev.kylemcd.computer.skill-sync.plist`, `WatchPaths` on `home/.config/agents/skills` — that reruns the linking function the moment a skill is added, removed, or renamed there, with no `computer stow`/`pull` needed. Verified end-to-end: a new skill dir shows up under `~/.codex/skills/` in about a second, no command run. macOS only (no-op on Linux); logs to `~/.local/state/computer/skill-sync.log`. Re-registering (every `dotfiles_stow()` run) unloads and reloads it, so editing the plist logic here and re-running `computer stow` is enough to pick up changes — no manual `launchctl` needed. To inspect or remove it by hand: `launchctl list | grep skill-sync`, `launchctl unload ~/Library/LaunchAgents/dev.kylemcd.computer.skill-sync.plist`.

Also worth knowing: Codex separately has `/Users/kyle/Code/skills` registered as a project in `~/.codex/config.toml` — a fully independent manual clone of the same `kylemcd/skills.git` remote, unrelated to this repo's submodule and *not* touched by `dotfiles_link_skill_compat()` or the watcher. It needs its own occasional `git pull` and won't update just because the submodule here does.

### `~/.zshenv` is intentionally NOT in this repo

`~/.zshenv` holds live secrets (API keys) alongside the `ZDOTDIR` export, so it's a plain unmanaged file directly in `$HOME` — same reasoning as `~/.agent/memory/` below. **Never add it to this repo or symlink it in via stow.** If it needs a new line (like the `ZDOTDIR` export was), edit `~/.zshenv` directly, the same way `scripts/install.sh` edits `~/.gitconfig` directly with `git config --global`.

## workbench sync (mutagen)

`computer mutagen` runs `scripts/mutagen-sync.sh`, which keeps `~/projects` in
two-way sync with the workbench homelab box
(`kyle@workbench.tail43f50e.ts.net:/home/kyle/projects`) over Tailscale, via
[mutagen](https://mutagen.io). Key points:

- **Idempotent + opt-in per machine.** It is NOT run by `computer install`,
  because it needs Tailscale up and this machine's SSH key authorized on
  workbench (two one-time, per-machine prerequisites the script can't automate).
- **mutagen is installed on demand** by the script, so it's deliberately kept
  out of the `packages` Brewfile (only machines that sync should have it).
- **No `~/.ssh/config` alias needed** — the endpoint is a full Tailscale
  MagicDNS name + user, so it resolves and authenticates from any network.
- The project file (`~/projects/mutagen.yml`) and its lock are generated by the
  script and are self-ignored, so they never sync to workbench.
- Full rationale + manual walkthrough: `~/projects/homelab/docs/mutagen-mac-setup.md`.

## Skills submodule

`home/.config/agents/skills/` is a git submodule pointing at the
private [kylemcd/skills](https://github.com/kylemcd/skills) repo. That keeps
all skill content in one place, shared across every repo/machine that wants
it, instead of living only inside this dotfiles repo.

- **Cloning fresh?** Run `git submodule update --init` (or clone with
  `--recurse-submodules`) to populate it.
- **Tracks `main`.** The submodule is configured with `branch = main` in
  `.gitmodules`, and `computer pull` runs `git submodule update --remote`
  (see `scripts/pull.sh`) — so it always checks out the latest commit on
  `kylemcd/skills` main, not the exact SHA pinned in this repo's tree.
- **Editing a skill?** Just commit and push from inside
  `home/.config/agents/skills/` itself (it's its own repo). No need
  to also bump the gitlink here — the next `computer pull` (on any machine)
  picks it up automatically. This means `git status` here may show the
  submodule as "modified" after a pull that picked up new commits; that's
  expected and safe to leave uncommitted. If you do want to lock in a
  specific skills version in this repo's history (e.g. for reproducibility),
  `git add home/.config/agents/skills && git commit` records the
  currently-checked-out commit as the pointer.
- **skillset symlinks** (`skillset install <name>`, used for shared Knock
  work skills) land inside this submodule directory too. They're excluded via
  the submodule's own `.git/info/exclude` — see
  `scripts/ignore-skillset-skills.sh` — so internal skill names never land in
  either repo's history. Re-run that script after `skillset install`/`uninstall`.

## Key Rules

- **Always check this repo first** before looking elsewhere for config files. If the user asks about a tool's config (AeroSpace, Ghostty, Neovim, Zsh, etc.), look in `home/.config/<tool>/` here first.
- Config files are stowed, so `home/.config/aerospace/aerospace.toml` here maps to `~/.config/aerospace/aerospace.toml` — everything under `home/.config/` mirrors `~/.config/` directly, with no wrapper folder.
- Do not create new top-level config directories without also updating `scripts/install.sh` to stow them (or, for anything under `~/.config/`, just add it under `home/.config/` — the `.config` package already covers it, no script change needed).
- If stow hits unmanaged-file conflicts during install/pull, `scripts/dotfiles.sh` now auto-backs up the conflicting targets to `~/.local/state/computer/stow-conflicts/<timestamp>/` before retrying.
- Dangling symlinks left by the old repo layout are also backed up before stow retries. Live foreign symlinks remain conflicts.
- After successfully stowing Zsh, `dotfiles_configure_zsh()` appends the `ZDOTDIR` export to the unmanaged `~/.zshenv` if missing, preserving existing content and secrets. It never puts `.zshenv` in version control.
- `install.sh`, `init.sh`, and `stow.sh` select the platform's Homebrew through `scripts/homebrew.sh` before checking tools. Installation uses `brew bundle --verbose` to show child output as it runs; the final listed package can otherwise hide an entire batch of downloads or builds.
- **Keep this file up to date.** When new tools, configs, skills, or conventions are added to this repo, update AGENTS.md to reflect them.


## CRITICAL: Only Edit Files In This Repo

**NEVER write to `~/.config/`, `~/`, or any path outside this repo directly.**

All config changes MUST be made to the files inside this repo (under `home/`). Stow symlinks them to the correct locations automatically. Writing directly to `~/.config/` bypasses version control and will be overwritten or will conflict with stow.

Examples:
- To add an agent skill → edit files under `home/.config/agents/skills/`, NOT `~/.config/agents/skills/`
- To change Ghostty config → edit `home/.config/ghostty/config`, NOT `~/.config/ghostty/config`

If a tool's install script (like `ocx`, `brew`, etc.) writes files directly to `~/.config/`, copy the relevant output back into this repo and do not leave changes outside the repo.

## Skills

Agent skills live in `home/.config/agents/skills/` and are stowed to `~/.config/agents/skills/`.

**IMPORTANT:** Always use the `skill-creator` skill when creating or modifying any skill. Never write a skill manually without going through `skill-creator` unless explicitly told to skip it.

### Available skills

- **defuddle** — extract clean markdown from web pages (prefer over WebFetch for articles/docs)
- **emil-design-eng** — UI polish and component design philosophy
- **feedback-loop** — self-validate work with deterministic feedback loops
- **fix-pr-comments** — address unresolved GitHub PR review threads
- **gh-stack** — stacked PRs with GitHub's native `gh stack` CLI extension
- **graphite** — stacked PRs with Graphite (gt)
- **json-canvas** — create/edit Obsidian Canvas files
- **obsidian-bases** — create/edit Obsidian Bases (.base files)
- **obsidian-cli** — interact with Obsidian vault via CLI
- **obsidian-markdown** — Obsidian Flavored Markdown syntax
- **skill-creator** — create/modify/eval agent skills
- **agent-browser** — browser automation via `agent-browser` CLI with dev server management, auth state, and UI verification
- **write-pr-description** — compose PR description content based on repo template and diff
- **worktree** — create/manage git worktrees with per-project copy/symlink/hook config from `~/.agent/memory/worktree-projects.json`
- **auto-build** — end-to-end autonomous implementation: Linear ticket → worktree → code → self-review → PR → babysit CI/comments

## Agent Memory

`~/.agent/memory/` is a persistent cross-session key-value store for agents. It lives outside this repo (never version controlled) to avoid committing secrets.

Each file is a named JSON blob written by tools/extensions and read by agent skills:

| File | Written by | Read by | Contents |
|---|---|---|---|
| `agent-browser-projects.json` | Manually edited | agent-browser skill | Per-project config: dev server (command, cwd, port, readyPattern), auth (stateFile, refreshInstructions, sourceOrigin) |
| `agent-browser-playbooks/index.json` | agent-browser skill | agent-browser skill | Index of browser playbooks. Each entry: `description`, `repos` (array of `org/repo`), `when_to_use` (plain-English guidance on which tasks benefit), `playbook` (path to `.md`), `last_updated` |
| `agent-browser-playbooks/<key>.md` | agent-browser skill | agent-browser skill | Per-project browser playbook: routes, complex flows, shortcuts/tricks, auth notes. Loaded on demand when index entry matches current repo and task. |
| `worktree-projects.json` | Manually edited / worktree skill | worktree skill | Per-project worktree config: files to copy, dirs to symlink, postCreate/preDelete hooks. `_worktrees` key stores per-worktree metadata (stacking tool) keyed by absolute path. |

### Adding new memory files

Skills that need cross-session persistence should read/write named JSON files in `~/.agent/memory/`. Document the file in the table above when adding one.
