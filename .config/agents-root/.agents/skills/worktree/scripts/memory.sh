#!/bin/bash
# memory.sh — Read and write worktree-projects.json entries.
#
# Usage:
#   memory.sh set-tool <worktree_path> <tool>
#     Write the git tool for a worktree.
#     <tool> must be one of: graphite, gh-stack, git
#
#   memory.sh get-tool <worktree_path>
#     Print the git tool for a worktree, or empty string if unset.
#
#   memory.sh remove <worktree_path>
#     Remove all metadata for a worktree (call on teardown).
#
# Exit codes:
#   0 — success
#   1 — argument error or invalid tool value

set -euo pipefail

MEMORY_FILE="${HOME}/.agent/memory/worktree-projects.json"
CMD="${1:?Usage: $0 <set-tool|get-tool|remove> <worktree_path> [tool]}"
WORKTREE_PATH="${2:?Missing worktree_path}"

# Ensure the memory file exists with at least an empty _worktrees key
if [ ! -f "$MEMORY_FILE" ]; then
  echo '{"_worktrees": {}}' > "$MEMORY_FILE"
elif ! jq -e '._worktrees' "$MEMORY_FILE" > /dev/null 2>&1; then
  jq '. + {"_worktrees": {}}' "$MEMORY_FILE" > /tmp/wt-mem.json && mv /tmp/wt-mem.json "$MEMORY_FILE"
fi

case "$CMD" in
  set-tool)
    TOOL="${3:?Missing tool argument (graphite, gh-stack, git)}"
    case "$TOOL" in
      graphite|gh-stack|git) ;;
      *) echo "ERROR: tool must be one of: graphite, gh-stack, git" >&2; exit 1 ;;
    esac
    jq --arg path "$WORKTREE_PATH" --arg tool "$TOOL" \
      '._worktrees[$path] = {"gitTool": $tool}' \
      "$MEMORY_FILE" > /tmp/wt-mem.json && mv /tmp/wt-mem.json "$MEMORY_FILE"
    echo "Set gitTool=$TOOL for $WORKTREE_PATH"
    ;;

  get-tool)
    jq -r --arg path "$WORKTREE_PATH" '._worktrees[$path].gitTool // empty' "$MEMORY_FILE"
    ;;

  remove)
    jq --arg path "$WORKTREE_PATH" 'del(._worktrees[$path])' \
      "$MEMORY_FILE" > /tmp/wt-mem.json && mv /tmp/wt-mem.json "$MEMORY_FILE"
    echo "Removed metadata for $WORKTREE_PATH"
    ;;

  *)
    echo "ERROR: unknown command '$CMD'. Use: set-tool, get-tool, remove" >&2
    exit 1
    ;;
esac
