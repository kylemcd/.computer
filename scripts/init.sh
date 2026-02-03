#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { printf "[init] %s\n" "$*"; }
err() { printf "[init][error] %s\n" "$*" >&2; exit 1; }

# macOS only
if [[ "$(uname)" != "Darwin" ]]; then
  err "This script is intended for macOS only."
fi

ARCH=$(uname -m)

# Xcode Command Line Tools
log "Checking Xcode Command Line Tools..."
if ! xcode-select -p >/dev/null 2>&1; then
  log "Installing Command Line Tools..."
  xcode-select --install
  until xcode-select -p >/dev/null 2>&1; do
    sleep 10
  done
  log "Command Line Tools installed."
else
  log "Command Line Tools already installed."
fi

# Rosetta on Apple Silicon
if [[ "${ARCH}" == "arm64" ]]; then
  log "Installing Rosetta..."
  softwareupdate --install-rosetta --agree-to-license 2>/dev/null || true
fi

# Homebrew
log "Checking Homebrew..."
if ! command -v brew >/dev/null 2>&1; then
  log "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
  # Add to PATH for this session
  if [[ "${ARCH}" == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  log "Homebrew installed."
else
  log "Homebrew already installed."
fi

# Run install
log "Running install..."
"${SCRIPT_DIR}/install.sh"

# Apply macOS settings
log "Applying macOS settings..."
"${SCRIPT_DIR}/os.sh"
