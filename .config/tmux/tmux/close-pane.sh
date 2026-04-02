#!/bin/zsh
# ============================================================================
# close-pane.sh — Close the active tmux pane and resize remaining panes
#
# Usage: Called by Ctrl+W keybinding or the `tc` shell alias.
#
# How it works:
#   1. Kills the currently active pane
#   2. Calls resize-panes.sh which:
#      - Removes the dead pane's entry from @pane_fractions (stale ID cleanup)
#      - Resizes all remaining panes to their registered fractions
#      - The leftmost pane absorbs the freed space
# ============================================================================

SCRIPT_DIR="${0:A:h}"  # directory this script lives in (for sibling scripts)

# Kill the active pane. tmux will give the freed space to a neighbor arbitrarily.
tmux kill-pane

# Immediately re-layout all remaining panes to their correct sizes.
# resize-panes.sh auto-cleans stale pane IDs from the @pane_fractions mapping,
# so we don't need to manually remove the killed pane's entry here.
"$SCRIPT_DIR/resize-panes.sh"
