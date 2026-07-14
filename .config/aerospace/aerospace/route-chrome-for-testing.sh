#!/bin/bash
# Route a just-launched "Google Chrome for Testing" window (vitest browser mode)
# to workspace 8 without leaving you stranded there.
#
# When the test browser launches, macOS makes it the frontmost window and
# AeroSpace follows focus to its workspace, so a plain `move-node-to-workspace 8`
# strands you on 8. Here we move the window to 8 and then reclaim focus on your
# origin workspace. This leaves a brief (~100ms) flash to 8 as the move happens,
# which is intentionally preferred over pre-emptively re-focusing your current
# window (that shuffle was more noticeable than the small flash).
set -u
AS=/opt/homebrew/bin/aerospace
TARGET_WS=8

origin=$("$AS" list-workspaces --focused 2>/dev/null)
[ "$origin" = "$TARGET_WS" ] && exit 0   # launched while already on 8; leave it

# Identify the just-detected window (AeroSpace sets $AEROSPACE_WINDOW_ID for
# on-window-detected callbacks; fall back to querying by app name).
win="${AEROSPACE_WINDOW_ID:-}"
if [ -z "$win" ]; then
  win=$("$AS" list-windows --all --format '%{window-id} %{app-name}' 2>/dev/null \
    | grep -i 'Google Chrome for Testing' | head -1 | awk '{print $1}')
fi

# Move the window to workspace 8.
if [ -n "$win" ]; then
  "$AS" move-node-to-workspace --window-id "$win" "$TARGET_WS" >/dev/null 2>&1
fi

# Reclaim focus on the origin workspace, but only if we actually got dragged to
# 8, for ~2s to beat the macOS activation race.
for _ in $(seq 1 20); do
  cur=$("$AS" list-workspaces --focused 2>/dev/null)
  if [ "$cur" = "$TARGET_WS" ]; then
    "$AS" workspace "$origin" >/dev/null 2>&1
  fi
  sleep 0.1
done
