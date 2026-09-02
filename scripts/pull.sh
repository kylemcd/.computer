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

# Submodules are updated by install.sh (dotfiles_update_submodules), which runs
# next — no need to do it here too.
log "Running install (submodules + packages + stow + OS settings)..."
"${REPO_ROOT}/scripts/install.sh"

