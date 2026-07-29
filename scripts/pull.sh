#!/usr/bin/env bash

set -euo pipefail

log() { printf "[pull] %s\n" "$*"; }
warn() { printf "[pull][warn] %s\n" "$*" >&2; }
err() { printf "[pull][error] %s\n" "$*" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Ensure Homebrew is available
if ! command -v brew >/dev/null 2>&1; then
  err "Homebrew not found. Run 'computer init' first."
fi

log "Pulling latest from git..."
cd "${REPO_ROOT}" && git pull

# `git pull` only moves the gitlink pointer; it never populates a submodule's
# working directory (on a fresh clone) or fast-forwards it (after a pull that
# bumps the pointer). Do that explicitly, scoped to paths declared in
# .gitmodules only — this repo also has a couple of stray gitlinks
# (.config/tmux/tmux/plugins/{tpm,tmux-floax}) left over from nested .git
# dirs that were never registered as real submodules, and `git submodule
# update --init --recursive` with no path errors out on those.
if [[ -f "${REPO_ROOT}/.gitmodules" ]]; then
  # Avoid `mapfile` (bash 4+) — macOS ships bash 3.2 as /bin/bash, and
  # `env bash` isn't guaranteed to resolve to a newer Homebrew bash yet
  # this early in setup.
  submodule_paths=()
  while IFS= read -r path; do
    [[ -n "$path" ]] && submodule_paths+=("$path")
  done < <(git config --file "${REPO_ROOT}/.gitmodules" --get-regexp '\.path$' | awk '{print $2}')
  if [[ ${#submodule_paths[@]} -gt 0 ]]; then
    log "Updating submodules: ${submodule_paths[*]}"
    git -C "${REPO_ROOT}" submodule update --init --recursive -- "${submodule_paths[@]}"
  fi
fi

log "Running install (packages + stow + OS settings)..."
"${REPO_ROOT}/scripts/install.sh"

