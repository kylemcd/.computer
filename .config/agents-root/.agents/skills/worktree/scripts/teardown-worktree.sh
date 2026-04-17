#!/bin/bash
# teardown-worktree.sh — Run pre-delete hooks for a git worktree.
#
# Reads per-project config from ~/.agent/memory/worktree-projects.json,
# matches the source repo to a project key, then runs preDelete hooks
# inside the worktree before it is removed.
#
# Usage:
#   ./teardown-worktree.sh <source_repo_path> <worktree_path>
#
# Both paths must be absolute.
#
# Exit codes:
#   0 — success (or no config found, which is also fine)
#   1 — argument error

set -euo pipefail

SOURCE="${1:?Usage: $0 <source_repo_path> <worktree_path>}"
WORKTREE="${2:?Usage: $0 <source_repo_path> <worktree_path>}"
CONFIG_FILE="${HOME}/.agent/memory/worktree-projects.json"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "No worktree config found — skipping teardown."
  exit 0
fi

PROJECT_KEY=$(jq -r --arg path "$SOURCE" '
  to_entries[]
  | select($path | contains(.key))
  | .key
' "$CONFIG_FILE" | head -1)

if [ -z "$PROJECT_KEY" ]; then
  echo "No project config matches source path: $SOURCE — skipping teardown."
  exit 0
fi

echo "Using project config: $PROJECT_KEY"

# ── preDelete hooks ──────────────────────────────────────────────────────────
HOOKS=$(jq -r --arg key "$PROJECT_KEY" '.[$key].hooks.preDelete // [] | .[]' "$CONFIG_FILE")

if [ -z "$HOOKS" ]; then
  echo "No preDelete hooks configured — nothing to do."
  exit 0
fi

if [ ! -d "$WORKTREE" ]; then
  echo "WARN: worktree path does not exist, skipping hooks: $WORKTREE"
  exit 0
fi

echo "Running preDelete hooks in: $WORKTREE"
cd "$WORKTREE"
while IFS= read -r cmd; do
  [ -z "$cmd" ] && continue
  echo "  + $cmd"
  eval "$cmd"
done <<< "$HOOKS"

echo "Worktree teardown complete."
