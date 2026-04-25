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

dotfiles_stow_package() {
  local stow_dir="$1"
  local target="$2"
  local pkg="$3"
  local output

  if output="$(stow --dir="${stow_dir}" --target="${target}" --restow "${pkg}" 2>&1)"; then
    return 0
  fi

  warn "Initial stow failed for ${pkg}:"
  while IFS= read -r line; do
    warn "  ${line}"
  done <<< "${output}"

  local -a conflicts
  local line
  while IFS= read -r line; do
    if [[ "${line}" =~ existing\ target\ ([^[:space:]]+)\ since\ neither\ a\ link\ nor\ a\ directory ]]; then
      conflicts+=("${BASH_REMATCH[1]}")
    fi
  done <<< "${output}"

  if [[ "${#conflicts[@]}" -eq 0 ]]; then
    return 1
  fi

  local backup_root
  backup_root="${HOME}/.local/state/computer/stow-conflicts/$(date +%Y%m%d-%H%M%S)"
  mkdir -p "${backup_root}"

  local moved=0
  local rel_target
  local abs_target
  local backup_target
  for rel_target in "${conflicts[@]}"; do
    rel_target="${rel_target#./}"
    abs_target="${target}/${rel_target}"
    if [[ ! -e "${abs_target}" && ! -L "${abs_target}" ]]; then
      continue
    fi

    backup_target="${backup_root}/${rel_target}"
    mkdir -p "$(dirname "${backup_target}")"
    mv "${abs_target}" "${backup_target}"
    log "  Backed up unmanaged ${abs_target} -> ${backup_target}"
    moved=1
  done

  if [[ "${moved}" -eq 0 ]]; then
    return 1
  fi

  warn "Retrying stow for ${pkg} after backing up conflicts."
  stow --dir="${stow_dir}" --target="${target}" --restow "${pkg}"
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
    config_packages=(aerospace ghostty gh-dash nvim opencode tmux tuicr zsh)
  fi

  local pkg
  for pkg in "${config_packages[@]}"; do
    if [[ -d "${DOTFILES_REPO_ROOT}/.config/${pkg}" ]]; then
      log "  ~/.config/${pkg}"
      if ! dotfiles_stow_package "${DOTFILES_REPO_ROOT}/.config" "${HOME}/.config" "${pkg}"; then
        warn "Failed to stow ${pkg}"
        stow_failed=1
      fi
    fi
  done

  # Stow .gitconfig into $HOME
  if [[ -d "${DOTFILES_REPO_ROOT}/.config/git-root" ]]; then
    log "  ~/.gitconfig-computer"
    if ! dotfiles_stow_package "${DOTFILES_REPO_ROOT}/.config" "${HOME}" "git-root"; then
      warn "Failed to stow git-root"
      stow_failed=1
    fi
  fi

  # Stow .zshrc into $HOME
  if [[ -d "${DOTFILES_REPO_ROOT}/.config/zsh-root" ]]; then
    log "  ~/.zshrc"
    if ! dotfiles_stow_package "${DOTFILES_REPO_ROOT}/.config" "${HOME}" "zsh-root"; then
      warn "Failed to stow zsh-root"
      stow_failed=1
    fi
  fi

  # Stow ~/.agents into $HOME
  if [[ -d "${DOTFILES_REPO_ROOT}/.config/agents-root" ]]; then
    log "  ~/.agents"
    if ! dotfiles_stow_package "${DOTFILES_REPO_ROOT}/.config" "${HOME}" "agents-root"; then
      warn "Failed to stow agents-root"
      stow_failed=1
    fi
  fi

  # Stow ~/.factory/settings.json into $HOME
  if [[ -d "${DOTFILES_REPO_ROOT}/.config/factory-root" ]]; then
    log "  ~/.factory/settings.json"
    if ! dotfiles_stow_package "${DOTFILES_REPO_ROOT}/.config" "${HOME}" "factory-root"; then
      warn "Failed to stow factory-root"
      stow_failed=1
    fi
  fi

  return "${stow_failed}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  err "This script is meant to be sourced, not executed directly."
fi
