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

# Install gh extensions
if command -v gh >/dev/null 2>&1; then
  log "Installing gh extensions..."
  while IFS= read -r ext || [[ -n "$ext" ]]; do
    [[ -z "$ext" || "$ext" == \#* ]] && continue
    if gh extension list | grep -qF "${ext##*/}"; then
      log "  ${ext} already installed"
    else
      gh extension install "$ext"
    fi
  done < "${REPO_ROOT}/gh-extensions"
else
  warn "gh not found, skipping gh extensions."
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
