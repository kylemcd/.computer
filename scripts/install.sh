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

# Install bun global packages
if command -v bun >/dev/null 2>&1; then
  log "Installing bun global packages..."
  while IFS= read -r pkg || [[ -n "$pkg" ]]; do
    [[ -z "$pkg" || "$pkg" == \#* ]] && continue
    bun install -g "$pkg"
  done < "${REPO_ROOT}/bun-packages"
else
  warn "bun not found, skipping global bun packages."
fi

# Git config
log "Configuring git..."
git config --global credential.helper osxkeychain
if ! grep -qF 'gitconfig-computer' "${HOME}/.gitconfig" 2>/dev/null; then
  log "Adding gitconfig-computer include..."
  git config --global include.path '~/.gitconfig-computer'
fi

# Apply macOS settings
if [[ "$(uname)" == "Darwin" ]]; then
  log "Applying macOS settings..."
  "${REPO_ROOT}/scripts/os.sh"
else
  log "Skipping OS settings (non-macOS)."
fi

log "Done!"
