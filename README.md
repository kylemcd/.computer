# .computer

## Quick start

```
sudo ./bin/bootstrap.sh
```

## What this does

This repo is my one command setup for a fresh Mac. It installs Nix, applies a `nix-darwin` system configuration, wires in Home Manager for user level dotfiles, and brings in my apps and CLI tools. It also applies a few macOS defaults so the machine feels right from the start.

## How it works

The `bin/bootstrap.sh` script is the entry point. It runs with `set -euo pipefail` for safety and walks through these steps:

1. Verifies the OS is macOS.
2. Caches sudo so you are not prompted repeatedly.
3. Ensures Xcode Command Line Tools are present. If they are missing it kicks off the Apple installer and waits until it finishes.
4. On Apple Silicon it installs Rosetta if needed.
5. Installs Nix using the Determinate Systems installer in multi user mode.
6. Exposes Nix in the current shell and enables flakes and `nix-command` for the session.
7. Applies the system configuration with `nix-darwin` using the flake at `nix-darwin#kpm`.
8. Prints a completion message. Some changes require a new shell or log out and in.

## The tech behind it

- Nix flakes: reproducible inputs and outputs for the system configuration.
- nix-darwin: manages macOS system settings and system packages declaratively.
- Home Manager: manages user level programs and dotfiles.
- Determinate Systems installer: fast and reliable Nix install on macOS.

## What gets installed

From `nix-darwin` and `home-manager` the flake installs these packages by default:

- Apps: 1Password, ChatGPT, Cursor, Google Chrome, iTerm2, Obsidian, Postman, Raycast, Shottr, Slack.
- Terminal: Neovim, oh my posh, oh my zsh, zoxide.
- Dev utilities: asdf, GitHub CLI, git, Graphite CLI.

## Configuration that is applied

- User and shell

  - Sets the login shell for `kyle` to `zsh` from Nix packages.

- Zsh setup

  - Enables oh my zsh with the `agnoster` theme and plugins `git`, `npm`, `history`, and `node`.
  - Adds Nix paths to `PATH` so Nix binaries are available.
  - Sources `~/.computer/zsh/evals.zsh` and `~/.computer/zsh/aliases.zsh` if present.
  - Initializes `asdf` and shell completions.

- Git

  - Uses the full git build with helpers and configures the `osxkeychain` credential helper.

- Neovim

  - Home Manager links `~/.config/nvim` to `~/.computer/nvim` so my editor config is versioned in this repo.

- macOS defaults
  - Dock auto hide on, orientation left, no recents, no magnification, slightly faster auto hide animation.

## Re running and updating

You can re run the bootstrap safely. If Nix is already installed the script skips the install and only switches to the flake configuration. You can also switch directly with this command:

```
nix-rebuild
```

## Troubleshooting

- If the `nix` command is not found after the first run open a new terminal window and try again.
- The Xcode Command Line Tools step can open a system dialog. Let it finish before you expect the script to continue.
- On Apple Silicon Rosetta install is best effort. It is fine if it is already installed.
