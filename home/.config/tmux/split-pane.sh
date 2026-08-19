#!/bin/zsh
# ============================================================================
# split-pane.sh — Create a new tmux pane at 1/N of the total window width
#
# Usage: split-pane.sh <N>
#   e.g. split-pane.sh 4  → new pane takes up 1/4 of the window
#
# How it works:
#   1. Creates a new pane to the right using -hf (horizontal, full-window split)
#   2. Registers the pane's target fraction in a tmux window variable (@pane_fractions)
#   3. Calls resize-panes.sh to enforce all pane sizes from the mapping
#
# The @pane_fractions variable is a comma-separated list of pane_id:fraction pairs
# stored per-window. Example: "%5:4,%6:3" means pane %5 wants 1/4, pane %6 wants 1/3.
# The leftmost pane is never in this mapping — it absorbs whatever space remains.
# ============================================================================

n=$1                                                    # fraction denominator (e.g. 4 for 1/4)
win_width=$(tmux display -p '#{window_width}')          # total window width in columns
new_size=$(( win_width / n ))                           # target column width for the new pane
cwd=$(tmux display -p '#{pane_current_path}')           # inherit the current pane's working directory
SCRIPT_DIR="${0:A:h}"                                   # directory this script lives in (for sibling scripts)

# Create the new pane to the right.
# -h  = horizontal split (side by side)
# -f  = split relative to the FULL window, not just the current pane
# -l  = initial size in columns (set close to target to minimize visual flash)
# -c  = start in the same working directory
tmux split-window -hf -l "$new_size" -c "$cwd"

# Get the newly created pane's unique ID (tmux auto-focuses it after split)
new_pane=$(tmux display -p '#{pane_id}')

# Register this pane's target fraction in the window-level @pane_fractions variable.
# Append to existing mapping if one exists, otherwise start a new one.
fractions=$(tmux show-window-option -v @pane_fractions 2>/dev/null)
if [[ -n "$fractions" ]]; then
  fractions="${fractions},${new_pane}:${n}"
else
  fractions="${new_pane}:${n}"
fi
tmux set-window-option @pane_fractions "$fractions"

# Resize ALL panes in the window to their correct sizes based on the full mapping.
# This corrects any drift caused by the split stealing space from existing panes.
"$SCRIPT_DIR/resize-panes.sh"
