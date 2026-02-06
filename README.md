# .computer

## Quick start

```bash
# First time (runs init + install)
./scripts/init.sh

# After install, use globally
computer init      # full setup (init + install)
computer install   # just packages + stow
```

## Structure

```
.computer/
├── bin/
│   └── computer         # CLI command
├── scripts/
│   ├── init.sh          # installs Xcode CLI tools, Rosetta, Homebrew
│   └── install.sh       # runs brew bundle + stow
├── packages             # Brewfile
└── .config/
    ├── aerospace/       # → ~/.config/aerospace/
    ├── ghostty/         # → ~/.config/ghostty/
    ├── nvim/            # → ~/.config/nvim/
    ├── zsh/             # → ~/.config/zsh/
    └── zsh-root/
        └── .zshrc       # → ~/.zshrc
```

## Commands

```bash
computer init      # install Homebrew, then run install
computer install   # install packages, stow configs, apply macOS settings
computer upgrade   # upgrade all Homebrew packages
computer pull      # git pull, then run install
computer os        # apply macOS settings & login items
computer help      # show help
```

## What gets installed

**CLI tools:** asdf, bun, gh, git, graphite, neovim, oh-my-posh, ripgrep, stow, zoxide, zsh-autosuggestions, zsh-syntax-highlighting

**Apps:** 1Password, AeroSpace, ChatGPT, Cursor, Firefox, Ghostty, GitHub Desktop, Ice, Obsidian, Postman, Raycast, Rectangle, Reminders Menubar, Shottr, Slack, Tailscale

## Manual commands

Restow a config:

```bash
stow --dir=~/.computer/.config --target=~/.config --restow nvim
```

Update packages only:

```bash
brew bundle --file=~/.computer/packages
```
