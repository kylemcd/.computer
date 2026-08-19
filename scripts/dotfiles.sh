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
  # ~/.config must be a real directory *before* stowing, or stow will
  # tree-fold the whole thing into a single symlink into this repo the first
  # time it doesn't exist yet (fresh machine) — instead of descending in and
  # symlinking just the individual tools we manage.
  mkdir -p "${HOME}/.config"

  local stow_failed=0

  # Each package is named exactly for where it lands under $HOME, and is
  # stowed with --target set to THAT directory itself (${HOME}/${pkg}), not
  # just $HOME. Stow never uses the package name when computing target
  # paths, only --target plus the package's own internal relative paths — so
  # targeting plain $HOME here would (and did, before this was fixed)
  # scatter aerospace/tmux/etc. as loose entries directly into $HOME instead
  # of into $HOME/.config. Targeting $HOME/${pkg} directly is what lets each
  # package's contents skip any redundant per-tool wrapper folder:
  #   home/.config/tmux/tmux.conf → ~/.config/tmux/tmux.conf   (not
  #   home/.config/tmux/tmux/tmux.conf, which is what a package targeting
  #   plain $HOME would have needed instead).
  #   home/.config/  → ~/.config/  (aerospace, agents, ghostty, git, nvim,
  #                                 tmux, zsh all live inside it — stow
  #                                 descends into the real ~/.config and
  #                                 symlinks each tool individually, no
  #                                 per-tool package needed)
  # A tool whose config can't live under ~/.config/ (hardcoded by the app
  # itself, e.g. ~/.factory/) would need its own sibling package here,
  # named for its own real target dir the same way.
  # Space-delimited override, e.g.:
  #   DOTFILES_PACKAGES=".config"
  local -a packages
  if [[ -n "${DOTFILES_PACKAGES:-}" ]]; then
    # shellcheck disable=SC2206
    packages=(${DOTFILES_PACKAGES})
  else
    packages=(.config)
  fi

  local pkg
  for pkg in "${packages[@]}"; do
    if [[ -d "${DOTFILES_REPO_ROOT}/home/${pkg}" ]]; then
      log "  ${pkg}"
      if ! dotfiles_stow_package "${DOTFILES_REPO_ROOT}/home" "${HOME}/${pkg}" "${pkg}"; then
        warn "Failed to stow ${pkg}"
        stow_failed=1
      fi
    fi
  done

  return "${stow_failed}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  err "This script is meant to be sourced, not executed directly."
fi
