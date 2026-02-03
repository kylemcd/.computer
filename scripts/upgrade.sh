#!/usr/bin/env bash

set -euo pipefail

log() { printf "[upgrade] %s\n" "$*"; }

log "Updating Homebrew..."
brew update

log "Upgrading formulae..."
brew upgrade

log "Upgrading casks..."
brew upgrade --cask

log "Cleaning up..."
brew cleanup

log "Done!"
