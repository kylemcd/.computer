# .computer — Agent Instructions

This is a dotfiles/configuration repository managed with [GNU Stow](https://www.gnu.org/software/stow/). Configs live under `.config/` and are symlinked to `~/.config/` via stow.

## Repo Structure

```
.computer/
├── bin/computer          # CLI: init, install, upgrade, pull, os, help
├── scripts/
│   ├── init.sh           # Xcode CLI tools, Rosetta, Homebrew
│   └── install.sh        # brew bundle + stow
├── packages              # Brewfile
├── bun-packages          # bun global packages (one per line)
├── gh-extensions         # gh extensions (one per line)
├── curl-packages         # curl | bash installers (one URL per line)
└── .config/
    ├── aerospace/        # → ~/.config/aerospace/
    ├── agents-root/      # → ~/  (contains .agents/skills/ and agent-team-draft/)
    ├── gh-dash/          # → ~/.config/gh-dash/
    ├── ghostty/          # → ~/.config/ghostty/
    ├── git-root/         # → ~/  (contains .gitconfig etc.)
    ├── nvim/             # → ~/.config/nvim/
    ├── opencode/         # → ~/.config/opencode/
    ├── tmux/             # → ~/.config/tmux/
    ├── tuicr/            # → ~/.config/tuicr/
    ├── zsh/              # → ~/.config/zsh/
    ├── zsh-root/         # → ~/  (contains .zshrc)
    └── factory-root/     # → ~/  (contains .factory/settings.json)
```

## Key Rules

- **Always check this repo first** before looking elsewhere for config files. If the user asks about a tool's config (AeroSpace, Ghostty, Neovim, Zsh, OpenCode, etc.), look in `.config/<tool>/` here first.
- Config files are stowed, so `.config/aerospace/aerospace/aerospace.toml` here maps to `~/.config/aerospace/aerospace.toml`.
- Do not create new top-level config directories without also updating `scripts/install.sh` to stow them.
- **Keep this file up to date.** When new tools, configs, skills, or conventions are added to this repo, update AGENTS.md to reflect them.


## CRITICAL: Only Edit Files In This Repo

**NEVER write to `~/.config/`, `~/`, or any path outside this repo directly.**

All config changes MUST be made to the files inside this repo (under `.config/`). Stow symlinks them to the correct locations automatically. Writing directly to `~/.config/` bypasses version control and will be overwritten or will conflict with stow.

Examples:
- To change the OpenCode config → edit `.config/opencode/opencode/opencode.json` in this repo, NOT `~/.config/opencode/opencode.json`
- To add an agent skill → edit files under `.config/agents-root/.agents/skills/`, NOT `~/.agents/skills/`
- To change Ghostty config → edit `.config/ghostty/ghostty/config`, NOT `~/.config/ghostty/config`

If a tool's install script (like `ocx`, `brew`, etc.) writes files directly to `~/.config/`, copy the relevant output back into this repo and do not leave changes outside the repo.

## Skills

Agent skills live in `.config/agents-root/.agents/skills/` and are stowed to `~/.agents/skills/`.

**IMPORTANT:** Always use the `skill-creator` skill when creating or modifying any skill. Never write a skill manually without going through `skill-creator` unless explicitly told to skip it.

### Draft skills (in repo, not live)

Skills in `.config/agents-root/` but **outside** `.agents/skills/` are not stowed and therefore not visible to agents. They are works-in-progress kept in the repo for development.

- **agent-team-draft** → `.config/agents-root/agent-team-draft/` — orchestrates a team of specialized agents for large tasks

To promote a draft skill to live: move it into `.config/agents-root/.agents/skills/` and re-stow.

### Available skills

- **defuddle** — extract clean markdown from web pages (prefer over WebFetch for articles/docs)
- **emil-design-eng** — UI polish and component design philosophy
- **feedback-loop** — self-validate work with deterministic feedback loops
- **fix-pr-comments** — address unresolved GitHub PR review threads
- **gh-stack** — stacked PRs without Graphite
- **graphite** — stacked PRs with Graphite (gt)
- **json-canvas** — create/edit Obsidian Canvas files
- **obsidian-bases** — create/edit Obsidian Bases (.base files)
- **obsidian-cli** — interact with Obsidian vault via CLI
- **obsidian-markdown** — Obsidian Flavored Markdown syntax
- **skill-creator** — create/modify/eval agent skills
- **agent-browser** — browser automation via `agent-browser` CLI with dev server management, auth state, and UI verification
- **write-pr-description** — compose PR description content based on repo template and diff

## Agent Memory

`~/.agent/memory/` is a persistent cross-session key-value store for agents. It lives outside this repo (never version controlled) to avoid committing secrets.

Each file is a named JSON blob written by tools/extensions and read by agent skills:

| File | Written by | Read by | Contents |
|---|---|---|---|
| `agent-browser-projects.json` | Manually edited | agent-browser skill | Per-project config: dev server (command, cwd, port, readyPattern), auth (stateFile, refreshInstructions, sourceOrigin) |

### Adding new memory files

Skills that need cross-session persistence should read/write named JSON files in `~/.agent/memory/`. Document the file in the table above when adding one.

