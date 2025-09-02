#!/usr/bin/env bash

set -euo pipefail

log() { printf "[bootstrap] %s\n" "$*"; }
warn() { printf "[bootstrap][warn] %s\n" "$*" >&2; }
err() { printf "[bootstrap][error] %s\n" "$*" >&2; exit 1; }

if [ "${OSTYPE:-}" != "darwin" ] && ! uname | grep -qi darwin; then
  err "This bootstrap script is intended for macOS (Darwin)."
fi

# Cache sudo credentials and keep them alive while we run
if command -v sudo >/dev/null 2>&1; then
  log "Requesting sudo privileges (to avoid repeated prompts)..."
  sudo -v || true
  # Keep-alive: update existing sudo time stamp until the script finishes
  while true; do sudo -n true 2>/dev/null || true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done &
fi

ARCH=$(uname -m)
REPO_ROOT="/Users/kyle/.computer"
FLAKE_PATH="${REPO_ROOT}/nix-darwin"
FLAKE_REF="${FLAKE_PATH}#kpm"

if [ ! -d "${FLAKE_PATH}" ]; then
  err "Expected flake directory not found at ${FLAKE_PATH}"
fi

log "Ensuring Xcode Command Line Tools are installed..."
if ! xcode-select -p >/dev/null 2>&1; then
  log "Installing Command Line Tools... this may open a GUI prompt and take several minutes"
  xcode-select --install || true
  until xcode-select -p >/dev/null 2>&1; do
    sleep 20
  done
  log "Command Line Tools installed."
else
  log "Command Line Tools already installed."
fi

if [ "${ARCH}" = "arm64" ]; then
  log "Detected Apple Silicon (arm64). Attempting to install Rosetta (ok if already installed)..."
  softwareupdate --install-rosetta --agree-to-license >/dev/null 2>&1 || true
fi

ensure_nix_in_path() {
  if command -v nix >/dev/null 2>&1; then
    return 0
  fi
  # Source nix-daemon profile if available
  if [ -r "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
    # shellcheck disable=SC1091
    . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
  fi
}

log "Checking Nix installation..."
if ! command -v nix >/dev/null 2>&1; then
  log "Nix not found. Installing Nix (multi-user) via Determinate Systems installer..."
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install || err "Nix installation failed"
  ensure_nix_in_path
else
  log "Nix is already installed."
fi

ensure_nix_in_path
if ! command -v nix >/dev/null 2>&1; then
  err "Nix command not found in PATH even after install. Please open a new shell and re-run."
fi

log "Nix version: $(nix --version | tr -d '\n')"

export NIX_CONFIG="experimental-features = nix-command flakes"

log "Switching to nix-darwin configuration: ${FLAKE_REF}"
nix run github:LnL7/nix-darwin -- switch --flake "${FLAKE_REF}" || err "nix-darwin switch failed"

log "Bootstrap complete. You may need to restart your terminal or log out/in for some changes to take effect."


