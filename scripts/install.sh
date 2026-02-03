#!/usr/bin/env bash

set -euo pipefail

log() { printf "[install] %s\n" "$*"; }
warn() { printf "[install][warn] %s\n" "$*" >&2; }
err() { printf "[install][error] %s\n" "$*" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Ensure Homebrew is available
if ! command -v brew >/dev/null 2>&1; then
  err "Homebrew not found. Run 'computer init' first."
fi

# Install packages
log "Installing packages..."
brew bundle --file="${REPO_ROOT}/packages"

# Ensure stow is available
if ! command -v stow >/dev/null 2>&1; then
  err "stow not found. It should have been installed by brew bundle."
fi

# Install oh-my-zsh
if [[ ! -d "${HOME}/.oh-my-zsh" ]]; then
  log "Installing oh-my-zsh..."
  RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  log "oh-my-zsh already installed."
fi

# Stow .config packages into ~/.config
log "Stowing configs..."
mkdir -p "${HOME}/.config"

CONFIG_PACKAGES=(aerospace ghostty nvim zsh)
for pkg in "${CONFIG_PACKAGES[@]}"; do
  if [[ -d "${REPO_ROOT}/.config/${pkg}" ]]; then
    log "  ~/.config/${pkg}"
    stow --dir="${REPO_ROOT}/.config" --target="${HOME}/.config" --restow "${pkg}" || warn "Failed to stow ${pkg}"
  fi
done

# Stow .zshrc into $HOME
if [[ -d "${REPO_ROOT}/.config/zsh-root" ]]; then
  log "  ~/.zshrc"
  stow --dir="${REPO_ROOT}/.config" --target="${HOME}" --restow zsh-root || warn "Failed to stow zsh-root"
fi

# Git config
log "Configuring git..."
git config --global credential.helper osxkeychain

log "Done!"
