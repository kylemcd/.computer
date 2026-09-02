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

# Populates every submodule declared in .gitmodules and moves it to the tip of
# the branch it tracks.
#
# `git pull` only moves the gitlink pointer; it never populates a submodule's
# working directory on a fresh clone, nor fast-forwards it after a pull that
# bumps that pointer. `--remote` checks out the tip of each submodule's tracked
# branch (`branch =` in .gitmodules) instead of the exact SHA pinned in this
# repo's tree, so skills and tmux plugins stay current without needing a
# pointer-bump commit here.
#
# Called from install.sh, which means `computer install` and `computer pull`
# (which ends by running install.sh) both leave submodules up to date.
dotfiles_update_submodules() {
  [[ -f "${DOTFILES_REPO_ROOT}/.gitmodules" ]] || return 0
  command -v git >/dev/null 2>&1 || return 0

  log "Updating submodules..."

  # Two passes on purpose. `--remote` is what we want for *our* submodules
  # (move to the tip of the branch in .gitmodules), but it must not be combined
  # with `--recursive`: that applies --remote to nested submodules too, dragging
  # them off the SHA their own parent pins. tpm pins lib/tmux-test, so the
  # combined form left tpm permanently reporting "modified content" after every
  # install. Top-level tracks the branch; nested stays pinned.
  if git -C "${DOTFILES_REPO_ROOT}" submodule update --init --remote &&
    git -C "${DOTFILES_REPO_ROOT}" submodule foreach --quiet \
      'git submodule update --init --recursive'; then
    return 0
  fi

  # Non-fatal: offline or a temporarily unreachable remote shouldn't abort an
  # install that can still stow everything already on disk.
  warn "Submodule update failed; continuing with what is currently checked out."
}

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

# Mirrors every skill in the submodule into one agent's skills directory as
# <dest>/<name> -> <skills_dir>/<name>, and keeps it in sync: adds a link for
# every skill currently present, and removes any link we previously made for a
# skill since renamed or removed. It only ever touches symlinks that point back
# into skills_dir, so an agent's own bundled skills (real directories, e.g.
# Codex's .system/) and skills installed by other tools are never touched.
# Plannotator's installer writes its own copies of the plannotator-* skills
# into every agent scope it knows about, and can shell out to `npx skills add`
# for the extras. Those skills are maintained in the skills submodule instead,
# and one of the scopes it writes (~/.agents/skills) symlinks back into this
# repo — so an unsuppressed install drops files straight into the working tree.
#
# curl-packages passes --skip-skills for the install this repo drives. This
# makes the same choice stick for any run it doesn't (a manual `curl | bash`,
# a reinstall) by setting plannotator's own persistent options. Both files hold
# live app state and can't be stowed over, so they're edited in place — the
# same reasoning as dotfiles_configure_zsh() and ~/.zshenv.
#
# Idempotent, and a no-op until plannotator has been installed once.
dotfiles_configure_plannotator() {
  local dir="${HOME}/.plannotator"
  [[ -d "${dir}" ]] || return 0

  # extras=no stops the `npx skills add ...` step.
  local prefs="${dir}/install-prefs"
  if [[ -f "${prefs}" ]] && grep -q '^extras=yes$' "${prefs}" 2>/dev/null; then
    # BSD sed wants an explicit empty suffix for -i; GNU sed rejects it.
    sed -i '' 's/^extras=yes$/extras=no/' "${prefs}" 2>/dev/null ||
      sed -i 's/^extras=yes$/extras=no/' "${prefs}"
    log "  plannotator: extras=no (no npx skills add)"
  fi

  # skipInstall.skills stops it writing plannotator-* into any skill scope.
  local config="${dir}/config.json"
  if ! command -v jq >/dev/null 2>&1; then
    warn "jq not found; leaving ${config} alone (plannotator may reinstall its skills)"
    return 0
  fi

  [[ -f "${config}" ]] || printf '{}\n' >"${config}"
  [[ "$(jq -r '.skipInstall.skills // false' "${config}" 2>/dev/null)" == "true" ]] && return 0

  local tmp="${config}.tmp"
  if jq '.skipInstall.skills = true' "${config}" >"${tmp}" 2>/dev/null; then
    mv "${tmp}" "${config}"
    log "  plannotator: skipInstall.skills=true (skills come from the submodule)"
  else
    rm -f "${tmp}"
    warn "Could not update ${config} (invalid JSON?); plannotator may reinstall its skills."
  fi
}

dotfiles_link_skills_into() {
  local skills_dir="$1"
  local dest="$2"

  mkdir -p "${dest}"

  local target name dest_path
  for target in "${skills_dir}"/*/; do
    [[ -d "${target}" ]] || continue
    name="$(basename "${target}")"
    dest_path="${dest}/${name}"

    # A real directory under this name belongs to some other installer — the
    # plannotator installer in curl-packages writes plannotator*/ straight
    # into ~/.claude/skills, for instance. Pointing `ln -sfn` at one links
    # *inside* it (<dest>/<name>/<name>), the same silent nesting that broke
    # the old whole-directory link. Never clobber it: skip, say so, and clear
    # any nested link an earlier run left behind.
    if [[ -d "${dest_path}" && ! -L "${dest_path}" ]]; then
      [[ -L "${dest_path}/${name}" ]] && rm -f "${dest_path}/${name}"
      warn "  ${dest_path} exists and isn't ours — skipping (installed by another tool)"
      continue
    fi

    ln -sfn "${target%/}" "${dest_path}"
  done

  local link link_target
  for link in "${dest}"/*; do
    [[ -L "${link}" ]] || continue
    link_target="$(readlink "${link}")"

    # A link pointing at skills_dir *itself* rather than a skill inside it is
    # the old whole-directory link. When dest already existed as a real
    # directory, `ln -sfn` silently created it one level down as
    # <dest>/skills -> <skills_dir>, leaving every skill at
    # <dest>/skills/<name>/SKILL.md — one level too deep for the agent to
    # find, and no error anywhere. Never valid; always remove it.
    if [[ "${link_target}" == "${skills_dir}" ]]; then
      rm -f "${link}"
      continue
    fi

    case "${link_target}" in
      "${skills_dir}"/*)
        # Dangling => the skill it pointed at is gone or was renamed.
        [[ -d "${link}" ]] || rm -f "${link}"
        ;;
    esac
  done
}

dotfiles_link_skill_compat() {
  local skills_dir="${DOTFILES_REPO_ROOT}/home/.config/agents/skills"
  [[ -d "${skills_dir}" ]] || return 0

  # A few skills in the kylemcd/skills submodule itself (worktree,
  # fix-pr-comments, auto-build) hardcode ~/.agents/skills/... as an
  # absolute path in their own scripts. That's a separate repo, so this
  # symlink is what keeps those paths working without patching it.
  ln -sfn ".config/agents" "${HOME}/.agents"
  log "  ~/.agents -> .config/agents"

  # Claude Code and Codex both read user skills as direct children of their own
  # skills directory — ~/.claude/skills/<name>/SKILL.md and
  # ~/.codex/skills/<name>/SKILL.md — and both already hold real directories
  # that aren't ours: Codex bundles its own under .system/ (confirmed by
  # reading its skill-installer script), and ~/.claude/skills collects skills
  # installed by other tools (plannotator, the Cloudflare set, ...).
  #
  # So neither can be a single whole-directory symlink. That's what
  # ~/.claude/skills used to be, and it silently failed: `ln -sfn` against an
  # existing real directory links *inside* it instead of replacing it, so
  # every skill in the submodule sat one level too deep and Claude Code loaded
  # none of them. Link one per skill for both instead.
  if [[ -d "${HOME}/.claude" ]]; then
    dotfiles_link_skills_into "${skills_dir}" "${HOME}/.claude/skills"
    log "  ~/.claude/skills/<name> (one symlink per skill)"
  fi

  if [[ -d "${HOME}/.codex" ]]; then
    dotfiles_link_skills_into "${skills_dir}" "${HOME}/.codex/skills"
    log "  ~/.codex/skills/<name> (one symlink per skill)"
  fi
}

# Registers a per-user launchd agent that reruns dotfiles_link_skill_compat
# automatically whenever home/.config/agents/skills/ changes — so a skill
# added/removed/renamed shows up in ~/.claude/skills/ and ~/.codex/skills/
# without waiting for the next `computer stow`/`install`/`pull`. Both are
# per-skill links, so both need this; only ~/.agents is a whole-directory
# symlink that's live the instant a file exists on disk. macOS only; a no-op
# on Linux or if neither Claude nor Codex is installed.
dotfiles_install_skill_watcher() {
  [[ "$(uname)" == "Darwin" ]] || return 0
  [[ -d "${HOME}/.claude" || -d "${HOME}/.codex" ]] || return 0
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
    log "  per-skill links now auto-sync on change (launchd: ${label})"
  else
    warn "Failed to load launchd watcher ${label} — per-skill links will still sync on the next computer stow/install/pull"
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
