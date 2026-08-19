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
│   └── computer         # CLI command
├── scripts/
│   ├── init.sh          # installs Xcode CLI tools, Rosetta, Homebrew
│   ├── install.sh       # runs brew bundle + stow
│   ├── stow.sh          # stows dotfiles only
│   └── linux-stow.sh    # stows dotfiles only (Linux)
├── packages             # Brewfile
└── home/
    └── .config/         # → ~/.config/ (stowed with --target=~/.config, so this mirrors it directly)
        ├── aerospace/   # → ~/.config/aerospace/
        ├── agents/      # → ~/.config/agents/  (skills/ is a git submodule)
        ├── ghostty/     # → ~/.config/ghostty/
        ├── git/         # → ~/.config/git/  (gitconfig-computer only — ~/.config/git/ is a real, pre-existing dir)
        ├── nvim/        # → ~/.config/nvim/
        ├── tmux/        # → ~/.config/tmux/
        └── zsh/         # → ~/.config/zsh/  (.zshrc lives here too, via ZDOTDIR — see below)
```

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

**CLI tools:** asdf, bun, gh, git, graphite, neovim, oh-my-posh, ripgrep, stow, zoxide, zsh-autosuggestions, zsh-syntax-highlighting

**Apps:** 1Password, AeroSpace, ChatGPT, Cursor, Firefox, Ghostty, GitHub Desktop, Ice, Obsidian, Postman, Raycast, Rectangle, Reminders Menubar, Shottr, Slack, Tailscale

## Manual commands

Restow everything under `~/.config/` (there's no per-tool package anymore — `.config` is stowed as one unit, so this re-links all of aerospace/agents/ghostty/git/nvim/tmux/zsh together):

```bash
stow --dir=~/.computer/home --target=~/.config --restow .config
```

Update packages only:

```bash
brew bundle --file=~/.computer/packages
```
