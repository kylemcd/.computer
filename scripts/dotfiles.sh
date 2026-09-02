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

  local -a conflicts=()
  local line
  while IFS= read -r line; do
    if [[ "${line}" =~ existing\ target\ ([^[:space:]]+)\ since\ neither\ a\ link\ nor\ a\ directory ]]; then
      conflicts+=("${BASH_REMATCH[1]}")
    elif [[ "${line}" =~ existing\ target\ is\ not\ owned\ by\ stow:\ (.+)$ ]]; then
      # Old repo layouts leave dangling links that stow will not replace.
      # Back these up like unmanaged files; leave live foreign links alone.
      local conflict="${target}/${BASH_REMATCH[1]}"
      if [[ -L "${conflict}" && ! -e "${conflict}" ]]; then
        conflicts+=("${BASH_REMATCH[1]}")
      fi
    fi
  done <<< "${output}"

  if [[ "${#conflicts[@]}" -eq 0 ]]; then
    return 1
  fi

  local backup_root
  backup_root="${XDG_STATE_HOME:-${HOME}/.local/state}/computer/stow-conflicts/$(date +%Y%m%d-%H%M%S)"
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

dotfiles_configure_zsh() {
  # This bootstrap must live outside stow: an existing .zshenv can contain
  # secrets. Append only the redirect and preserve all existing content.
  local zshenv="${HOME}/.zshenv"
  local redirect='export ZDOTDIR="$HOME/.config/zsh"'
  if ! grep -qxF "${redirect}" "${zshenv}" 2>/dev/null; then
    printf '\n# Load the shell config managed by .computer.\n%s\n' "${redirect}" >> "${zshenv}"
    log "  Configured ~/.zshenv to load ~/.config/zsh"
  fi
}

dotfiles_link_skill_compat() {
  local skills_dir="${DOTFILES_REPO_ROOT}/home/.config/agents/skills"
  [[ -d "${skills_dir}" ]] || return 0

  # Claude Code reads skills from ~/.claude/skills as one symlinked directory.
  if [[ -d "${HOME}/.claude" ]]; then
    ln -sfn "${skills_dir}" "${HOME}/.claude/skills"
    log "  ~/.claude/skills -> home/.config/agents/skills"
  fi

  # A few skills in the kylemcd/skills submodule itself (worktree,
  # fix-pr-comments, auto-build) hardcode ~/.agents/skills/... as an
  # absolute path in their own scripts. That's a separate repo, so this
  # symlink is what keeps those paths working without patching it.
  ln -sfn ".config/agents" "${HOME}/.agents"
  log "  ~/.agents -> .config/agents"

  # Codex bundles its own skills under ~/.codex/skills/.system/ (untouched,
  # not ours) and expects user skills as direct siblings,
  # ~/.codex/skills/<name>/ — confirmed by reading its own skill-installer
  # script. There's no single directory to symlink the way ~/.claude/skills
  # works, so link one per skill instead, and keep it in sync: add a link
  # for every skill currently in the submodule, and remove any link we
  # previously made here for a skill that's since been renamed or removed
  # (only ever touches links that point back into skills_dir — .system/ and
  # anything else under ~/.codex/skills/ is never touched).
  if [[ -d "${HOME}/.codex" ]]; then
    mkdir -p "${HOME}/.codex/skills"

    local target name
    for target in "${skills_dir}"/*/; do
      [[ -d "${target}" ]] || continue
      name="$(basename "${target}")"
      ln -sfn "${target%/}" "${HOME}/.codex/skills/${name}"
    done

    local link
    for link in "${HOME}/.codex/skills"/*; do
      [[ -L "${link}" ]] || continue
      case "$(readlink "${link}")" in
        "${skills_dir}"/*)
          [[ -d "${link}" ]] || rm -f "${link}"
          ;;
      esac
    done
    log "  ~/.codex/skills/<name> (one symlink per skill)"
  fi
}

# Registers a per-user launchd agent that reruns dotfiles_link_skill_compat
# automatically whenever home/.config/agents/skills/ changes — so a skill
# added/removed/renamed shows up in ~/.codex/skills/ without waiting for the
# next `computer stow`/`install`/`pull`. (Claude/.agents need no watcher:
# those are whole-directory symlinks, already live the instant a file exists
# on disk.) macOS only; a no-op on Linux or if Codex isn't installed.
dotfiles_install_skill_watcher() {
  [[ "$(uname)" == "Darwin" ]] || return 0
  [[ -d "${HOME}/.codex" ]] || return 0
  command -v launchctl >/dev/null 2>&1 || return 0

  local label="dev.kylemcd.computer.skill-sync"
  local plist="${HOME}/Library/LaunchAgents/${label}.plist"
  local state_dir="${HOME}/.local/state/computer"
  mkdir -p "${HOME}/Library/LaunchAgents" "${state_dir}"

  cat > "${plist}" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${label}</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>-c</string>
    <string>source '${DOTFILES_REPO_ROOT}/scripts/dotfiles.sh' &amp;&amp; dotfiles_link_skill_compat</string>
  </array>
  <key>WatchPaths</key>
  <array>
    <string>${DOTFILES_REPO_ROOT}/home/.config/agents/skills</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>StandardOutPath</key>
  <string>${state_dir}/skill-sync.log</string>
  <key>StandardErrorPath</key>
  <string>${state_dir}/skill-sync.log</string>
</dict>
</plist>
PLIST

  launchctl unload "${plist}" >/dev/null 2>&1 || true
  if launchctl load -w "${plist}" >/dev/null 2>&1; then
    log "  ~/.codex/skills/<name> now auto-syncs on change (launchd: ${label})"
  else
    warn "Failed to load launchd watcher ${label} — ~/.codex/skills/<name> will still sync on the next computer stow/install/pull"
  fi
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
      elif [[ "${pkg}" == ".config" && -f "${HOME}/.config/zsh/.zshrc" ]]; then
        dotfiles_configure_zsh || return 1
      fi
    fi
  done

  log "Linking agent skills into other tools..."
  dotfiles_link_skill_compat
  dotfiles_install_skill_watcher

  return "${stow_failed}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  err "This script is meant to be sourced, not executed directly."
fi
