#!/bin/zsh
# ============================================================================
# resize-panes.sh — Resize all panes based on the stored @pane_fractions mapping
#
# Usage: Called by split-pane.sh and close-pane.sh after creating/removing panes.
#
# How it works:
#   - Reads @pane_fractions from the current tmux window (e.g. "%5:4,%6:3")
#   - Each entry means "pane %5 should be 1/4 of the window, pane %6 should be 1/3"
#   - Calculates exact column widths: window_width / N for each mapped pane
#   - The LEFTMOST pane is never in the mapping — it gets whatever space remains
#     after all mapped panes and pane separators (1 column each) are accounted for
#   - Cleans up entries for panes that no longer exist (after close)
#
# Example with a 316-column window and @pane_fractions="%5:4,%6:4":
#   - Pane %5 gets 316/4 = 79 columns
#   - Pane %6 gets 316/4 = 79 columns
#   - 2 separators = 2 columns
#   - Leftmost pane gets 316 - 79 - 79 - 2 = 156 columns
# ============================================================================

# --- Gather current state ---------------------------------------------------

win_width=$(tmux display -p '#{window_width}')                       # total window width in columns
fractions=$(tmux show-window-option -v @pane_fractions 2>/dev/null)  # stored fraction mapping
existing_panes=( $(tmux list-panes -F '#{pane_id}') )                # all pane IDs in this window

# Nothing to resize if only one pane remains
(( ${#existing_panes} <= 1 )) && return 0

# --- Parse mapping and clean up stale entries --------------------------------

typeset -A pane_sizes   # associative array: pane_id -> target column width
new_fractions=()        # cleaned-up fraction entries (only panes that still exist)

if [[ -n "$fractions" ]]; then
  # Split the comma-separated mapping and process each entry
  for entry in ${(s:,:)fractions}; do
    pid=${entry%%:*}    # pane ID, e.g. "%5"
    n=${entry##*:}      # fraction denominator, e.g. "4" (meaning 1/4)

    # Only keep entries for panes that still exist
    # ${existing_panes[(Ie)$pid]} returns the index if found, 0 if not
    if (( ${existing_panes[(Ie)$pid]} )); then
      pane_sizes[$pid]=$(( win_width / n ))  # convert fraction to columns
      new_fractions+=("$entry")              # keep this entry
    fi
    # Stale entries (closed panes) are silently dropped
  done
fi

# Write the cleaned-up mapping back to the window variable
tmux set-window-option @pane_fractions "${(j:,:)new_fractions}" 2>/dev/null

# --- Calculate the leftmost pane's width ------------------------------------

# Sum up all the column widths claimed by mapped panes
mapped_total=0
for pid size in "${(@kv)pane_sizes}"; do
  mapped_total=$(( mapped_total + size ))
done

# Leftmost pane = total width - all mapped panes - pane border separators
# Each separator between panes is 1 column wide
num_panes=${#existing_panes}
separators=$(( num_panes - 1 ))
left_size=$(( win_width - mapped_total - separators ))
first_pane=${existing_panes[1]}  # leftmost pane is always first in the list

# Safety: never let a pane shrink below 10 columns (prevents invisible panes)
(( left_size < 10 )) && left_size=10

# --- Apply all resizes ------------------------------------------------------

# Resize the leftmost pane first — it absorbs/releases space for the others
tmux resize-pane -t "$first_pane" -x "$left_size" 2>/dev/null

# Then resize each mapped pane to its exact target width
for pid size in "${(@kv)pane_sizes}"; do
  (( size < 10 )) && size=10  # safety minimum
  tmux resize-pane -t "$pid" -x "$size" 2>/dev/null
done
