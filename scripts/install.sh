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

source "${REPO_ROOT}/scripts/dotfiles.sh"

dotfiles_install_oh_my_zsh

if ! dotfiles_stow; then
  err "Stow failed. Fix the errors above and re-run."
fi

# Git config
log "Configuring git..."
git config --global credential.helper osxkeychain

# Apply macOS settings
if [[ "$(uname)" == "Darwin" ]]; then
  log "Applying macOS settings..."
  "${REPO_ROOT}/scripts/os.sh"
else
  log "Skipping OS settings (non-macOS)."
fi

log "Done!"
