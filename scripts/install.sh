#!/usr/bin/env bash

set -euo pipefail

log() { printf "[install] %s\n" "$*"; }
warn() { printf "[install][warn] %s\n" "$*" >&2; }
err() { printf "[install][error] %s\n" "$*" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "${REPO_ROOT}/scripts/homebrew.sh"
computer_homebrew_env

source "${REPO_ROOT}/scripts/dotfiles.sh"

# Ensure Homebrew is available
if ! command -v brew >/dev/null 2>&1; then
  err "Homebrew not found. Run 'computer init' first."
fi

# Before anything reads from them: skills and tmux plugins live in submodules,
# and a fresh clone leaves those directories empty until this runs.
dotfiles_update_submodules

# Install packages
log "Installing packages with $(command -v brew)..."
# Bundle buffers child output by default, making a long batch look stuck
# on the last listed package. Stream downloads, builds, and prompts.
brew bundle --verbose --file="${REPO_ROOT}/packages"

# Ensure stow is available
if ! command -v stow >/dev/null 2>&1; then
  err "stow not found. It should have been installed by brew bundle."
fi

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

# Install curl packages
log "Installing curl packages..."
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" || "$line" == \#* ]] && continue

  # Lines are "<url> [args...]". `bash -s --` is the only way to hand flags to
  # an installer that arrives over a pipe; args stay unquoted on purpose so a
  # multi-flag line splits into separate arguments.
  read -r url args <<< "$line"
  log "  Running installer: ${url}${args:+ ${args}}"
  # shellcheck disable=SC2086
  curl -fsSL "$url" | bash -s -- ${args}
done < "${REPO_ROOT}/curl-packages"

# Make plannotator's skip-skills choice stick for installs this repo doesn't
# drive (a manual `curl | bash`, a reinstall) — see the function's comment.
dotfiles_configure_plannotator

# Git config
log "Configuring git..."
git config --global credential.helper osxkeychain
if ! grep -qF '~/.config/git/gitconfig-computer' "${HOME}/.gitconfig" 2>/dev/null; then
  log "Adding gitconfig-computer include..."
  git config --global include.path '~/.config/git/gitconfig-computer'
fi

# Apply macOS settings
if [[ "$(uname)" == "Darwin" ]]; then
  log "Applying macOS settings..."
  "${REPO_ROOT}/scripts/os.sh"
else
  log "Skipping OS settings (non-macOS)."
fi

log "Done!"
