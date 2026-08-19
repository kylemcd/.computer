#!/bin/bash
# When switching to a lettered workspace:
# - Move any windows of the assigned app from other workspaces here

WORKSPACE="$AEROSPACE_FOCUSED_WORKSPACE"

case "$WORKSPACE" in
  c) APP="Cursor" ;;
  s) APP="Slack" ;;
  g) APP="GitHub Desktop" ;;
  l) APP="Linear" ;;
  b) APP="Firefox" ;;
  p) APP="1Password" ;;
  n) APP="Notion" ;;
  z) APP="Zoom" ;;
  t) APP="Ghostty" ;;
  e) APP="Mail" ;;
  a) APP="ChatGPT" ;;
  m) APP="Messages" ;;
  f) APP="Finder" ;;
  w) APP="Calendar" ;;
  r) APP="Reminders" ;;
  j) APP="Manet" ;;
  o) APP="Obsidian" ;;
  *) exit 0 ;;  # numeric or unmapped workspace
esac

# Find windows for this app on other workspaces and pull them here
while IFS=' ' read -r WINDOW_ID WINDOW_WORKSPACE; do
  if [[ "$WINDOW_WORKSPACE" != "$WORKSPACE" ]]; then
    aerospace move-node-to-workspace --window-id "$WINDOW_ID" "$WORKSPACE"
  fi
done < <(aerospace list-windows --all --format '%{window-id} %{workspace} %{app-name}' 2>/dev/null \
  | grep -i " ${APP}$" \
  | awk '{print $1, $2}')


