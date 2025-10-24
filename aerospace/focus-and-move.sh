#!/usr/bin/env bash
# Focus an app and move it to the currently active workspace

app_name="$1"
AEROSPACE="/run/current-system/sw/bin/aerospace"

# Get the current workspace before opening the app
current_workspace=$($AEROSPACE list-workspaces --focused)

# Check if the app is already running
app_window=$($AEROSPACE list-windows --all --format '%{app-name} | %{workspace}' | grep "^$app_name" | head -1)

if [ -n "$app_window" ]; then
    # App exists, get its workspace (extract everything after the last " | ")
    app_workspace=$(echo "$app_window" | sed 's/.* | //')
    
    # If it's on a different workspace, move it here
    if [ "$app_workspace" != "$current_workspace" ]; then
        # Get the window ID before focusing
        window_id=$($AEROSPACE list-windows --all --format '%{window-id} | %{app-name}' | grep " | $app_name$" | head -1 | sed 's/ | .*//')
        
        # Move the window to current workspace without following it
        $AEROSPACE move-node-to-workspace --window-id "$window_id" "$current_workspace" 2>/dev/null
        sleep 0.1
        
        # Now focus it on this workspace
        open -a "$app_name"
    else
        # Already on the same workspace, just focus it
        open -a "$app_name"
    fi
else
    # App not running, just open it (will open on current workspace)
    open -a "$app_name"
fi

