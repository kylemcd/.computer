#!/usr/bin/env bash

set -euo pipefail

log() { printf "[macos] %s\n" "$*"; }

# ------------------------------------------------------------------------------
# Dock settings
# ------------------------------------------------------------------------------
log "Configuring Dock..."
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock orientation -string "left"
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock magnification -bool false
defaults write com.apple.dock autohide-time-modifier -float 0.5

# ------------------------------------------------------------------------------
# Spaces
# ------------------------------------------------------------------------------
log "Configuring Spaces..."
defaults write com.apple.spaces spans-displays -bool false

# ------------------------------------------------------------------------------
# Restart Dock to apply changes
# ------------------------------------------------------------------------------
log "Restarting Dock..."
killall Dock

# ------------------------------------------------------------------------------
# Login Items
# ------------------------------------------------------------------------------
log "Configuring Login Items..."

# `make login item` appends unconditionally — it does not check for an existing
# entry. Since install.sh runs this script on every `computer install` and
# `computer pull`, adding without checking stacked up duplicates. Look first.
login_item_exists() {
  local name="$1"
  osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null \
    | tr ',' '\n' \
    | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
    | grep -qxF "$name"
}

add_login_item() {
  local app_path="$1"
  local name
  name="$(basename "$app_path" .app)"

  if [[ ! -e "$app_path" ]]; then
    log "  Skipped (not found): $app_path"
    return
  fi

  if login_item_exists "$name"; then
    log "  Already present: $name"
    return
  fi

  osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"$app_path\", hidden:false}" 2>/dev/null || true
  log "  Added: $name"
}

# Apps to start on login
add_login_item "/Applications/1Password.app"
add_login_item "/Applications/AeroSpace.app"
add_login_item "/Applications/Ice.app"
add_login_item "/Applications/macshot.app"
add_login_item "/Applications/Raycast.app"
add_login_item "/Applications/Reminders MenuBar.app"
add_login_item "/Applications/Shottr.app"
add_login_item "/Applications/Tailscale.app"

log "Done! Some changes may require logout/login to take effect."
