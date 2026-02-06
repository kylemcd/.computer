#!/usr/bin/env bash

# Shared dotfiles helpers.
#
# Intended usage:
#   source "${REPO_ROOT}/scripts/dotfiles.sh"
#   dotfiles_install_oh_my_zsh
#   dotfiles_stow
#
# Callers can provide their own log/warn/err functions before sourcing.

if ! declare -F log >/dev/null 2>&1; then
  log() { printf "[dotfiles] %s\n" "$*"; }
fi

if ! declare -F warn >/dev/null 2>&1; then
  warn() { printf "[dotfiles][warn] %s\n" "$*" >&2; }
fi

if ! declare -F err >/dev/null 2>&1; then
  err() { printf "[dotfiles][error] %s\n" "$*" >&2; exit 1; }
fi

DOTFILES_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

dotfiles_install_oh_my_zsh() {
  if [[ ! -d "${HOME}/.oh-my-zsh" ]]; then
    log "Installing oh-my-zsh..."
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    log "oh-my-zsh already installed."
  fi
}

dotfiles_stow() {
  if ! command -v stow >/dev/null 2>&1; then
    err "stow not found."
  fi

  log "Stowing configs..."
  mkdir -p "${HOME}/.config"

  local stow_failed=0

  # Space-delimited override, e.g.:
  #   DOTFILES_CONFIG_PACKAGES="nvim zsh"
  local -a config_packages
  if [[ -n "${DOTFILES_CONFIG_PACKAGES:-}" ]]; then
    # shellcheck disable=SC2206
    config_packages=(${DOTFILES_CONFIG_PACKAGES})
  else
    config_packages=(aerospace ghostty nvim zsh)
  fi

  local pkg
  for pkg in "${config_packages[@]}"; do
    if [[ -d "${DOTFILES_REPO_ROOT}/.config/${pkg}" ]]; then
      log "  ~/.config/${pkg}"
      if ! stow --dir="${DOTFILES_REPO_ROOT}/.config" --target="${HOME}/.config" --restow "${pkg}"; then
        warn "Failed to stow ${pkg}"
        stow_failed=1
      fi
    fi
  done

  # Stow .zshrc into $HOME
  if [[ -d "${DOTFILES_REPO_ROOT}/.config/zsh-root" ]]; then
    log "  ~/.zshrc"
    if ! stow --dir="${DOTFILES_REPO_ROOT}/.config" --target="${HOME}" --restow zsh-root; then
      warn "Failed to stow zsh-root"
      stow_failed=1
    fi
  fi

  return "${stow_failed}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  err "This script is meant to be sourced, not executed directly."
fi

