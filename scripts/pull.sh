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

cd "${REPO_ROOT}" && git pull

computer install

