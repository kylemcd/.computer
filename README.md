# .computer

## Quick start

```bash
# First time (runs init + install)
./scripts/init.sh

# After install, use globally
computer init      # full setup (init + install)
computer install   # just packages + stow
computer stow      # stow configs only (auto-select by OS)
computer linux-stow # stow configs only (Linux)
```

## Structure

```
.computer/
├── bin/
│   └── computer                  # CLI command
├── scripts/
│   ├── init.sh                   # installs Xcode CLI tools, Rosetta, Homebrew
│   ├── install.sh                # submodules + brew bundle + stow + OS settings
│   ├── pull.sh                   # git pull, then install.sh
│   ├── stow.sh                   # stows dotfiles only (macOS)
│   ├── linux-stow.sh             # stows dotfiles only (Linux)
│   ├── dotfiles.sh               # shared helpers: stow, submodules, skill linking
│   ├── homebrew.sh               # selects the platform's Homebrew
│   ├── os.sh                     # macOS defaults + login items
│   ├── upgrade.sh                # brew update/upgrade/cleanup
│   ├── mutagen-sync.sh           # workbench <-> ~/projects file sync
│   └── ignore-skillset-skills.sh # keeps skillset symlinks out of git
├── packages                      # Brewfile
├── bun-packages                  # bun global packages (one per line)
├── gh-extensions                 # gh extensions (one per line)
├── curl-packages                 # curl | bash installers, "<url> [args...]" per line
└── home/
    └── .config/                  # → ~/.config/ (stowed with --target=~/.config, so this mirrors it directly)
        ├── .stow-local-ignore    # the ignore list stow actually reads (see note below)
        ├── aerospace/            # → ~/.config/aerospace/
        ├── agents/               # → ~/.config/agents/  (skills/ is a git submodule)
        ├── ghostty/              # → ~/.config/ghostty/
        ├── git/                  # → ~/.config/git/  (gitconfig-computer only — ~/.config/git/ is a real, pre-existing dir)
        ├── nvim/                 # → ~/.config/nvim/
        ├── tmux/                 # → ~/.config/tmux/  (plugins/{tpm,tmux-floax} are git submodules)
        └── zsh/                  # → ~/.config/zsh/  (.zshrc lives here too, via ZDOTDIR — see below)
```

Stow reads its ignore list from `<stow-dir>/<package>/.stow-local-ignore` — here that's
`home/.config/.stow-local-ignore`. A copy at the repo root is never read.

No per-tool wrapper folder and no name repeated twice — `home/.config/` is stowed with
`--target=~/.config` (not `~`), so its own contents map onto `~/.config/` one-to-one.
`~/.zshrc` doesn't exist anymore; zsh is pointed at `~/.config/zsh/.zshrc` via
`ZDOTDIR="$HOME/.config/zsh"`, set in `~/.zshenv` (unmanaged, lives outside this repo — see AGENTS.md).

(opencode, gh-dash, tuicr, and Factory configs used to be managed here too — removed. Their
apps/CLIs are untouched; only this repo's management of their config was dropped.)

## Commands

```bash
computer init      # install Homebrew, then run install
computer install   # install packages, stow configs, apply macOS settings
computer stow      # stow configs only (macOS uses stow.sh, Linux uses linux-stow.sh)
computer linux-stow # stow configs only (Linux; skips oh-my-zsh install)
computer upgrade   # upgrade all Homebrew packages
computer pull      # git pull, then run install
computer os        # apply macOS settings & login items
computer mutagen   # set up / ensure the workbench <-> ~/projects file sync
computer help      # show help
```

## What gets installed

See `packages` for the authoritative list — this is a summary.

**CLI tools:** asdf, bun, fzf, gh, git, graphite, neovim, oh-my-posh, opencode, ripgrep,
sesh, stow, television, tmux, tree-sitter, tree-sitter-cli, tuicr, worktrunk, zoxide, zsh,
zsh-autosuggestions, zsh-syntax-highlighting

**Apps:** 1Password, AeroSpace, ChatGPT, Cursor, Cursor CLI, Firefox, Ghostty, GitHub Desktop,
HRM, Ice, macshot, Obsidian, Postman, Raycast, Reminders MenuBar, Shottr, Slack, Tailscale, Zen

**Fonts:** Maple Mono

## Manual commands

Restow everything under `~/.config/` (there's no per-tool package anymore — `.config` is stowed as one unit, so this re-links all of aerospace/agents/ghostty/git/nvim/tmux/zsh together):

```bash
stow --dir=~/.computer/home --target=~/.config --restow .config
```

Update packages only:

```bash
brew bundle --file=~/.computer/packages
```
