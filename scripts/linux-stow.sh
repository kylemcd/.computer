#!/usr/bin/env bash

set -euo pipefail

log() { printf "[linux-stow] %s\n" "$*"; }
err() { printf "[linux-stow][error] %s\n" "$*" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v stow >/dev/null 2>&1; then
  err "stow not found. Install stow first, then re-run."
fi

source "${REPO_ROOT}/scripts/dotfiles.sh"

if ! dotfiles_stow; then
  err "Stow failed. Fix the errors above and re-run."
fi

log "Done!"
