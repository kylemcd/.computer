#!/bin/bash
# setup-worktree.sh — Run post-create setup for a new git worktree.
#
# Reads per-project config from ~/.agent/memory/worktree-projects.json,
# matches the source repo to a project key, then:
#   1. Copies files listed in copyFiles
#   2. Creates symlinks for dirs in symlinkDirs
#   3. Runs postCreate hooks inside the new worktree
#
# Usage:
#   ./setup-worktree.sh <source_repo_path> <new_worktree_path>
#
# Both paths must be absolute.
#
# Exit codes:
#   0 — success (or no config found for this project, which is also fine)
#   1 — argument error or config parse failure

set -euo pipefail

SOURCE="${1:?Usage: $0 <source_repo_path> <new_worktree_path>}"
DEST="${2:?Usage: $0 <source_repo_path> <new_worktree_path>}"
CONFIG_FILE="${HOME}/.agent/memory/worktree-projects.json"

if [ ! -d "$SOURCE" ]; then
  echo "ERROR: source path does not exist: $SOURCE" >&2
  exit 1
fi

if [ ! -d "$DEST" ]; then
  echo "ERROR: worktree path does not exist: $DEST" >&2
  exit 1
fi

# ── Find matching project key ───────────────────────────────────────────────
if [ ! -f "$CONFIG_FILE" ]; then
  echo "No worktree config found at $CONFIG_FILE — skipping setup."
  exit 0
fi

PROJECT_KEY=$(jq -r --arg path "$SOURCE" '
  to_entries[]
  | select($path | contains(.key))
  | .key
' "$CONFIG_FILE" | head -1)

if [ -z "$PROJECT_KEY" ]; then
  echo "No project config matches source path: $SOURCE — skipping setup."
  exit 0
fi

echo "Using project config: $PROJECT_KEY"

# ── Copy files ───────────────────────────────────────────────────────────────
COPY_FILES=$(jq -r --arg key "$PROJECT_KEY" '.[$key].copyFiles // [] | .[]' "$CONFIG_FILE")

while IFS= read -r rel_path; do
  [ -z "$rel_path" ] && continue
  src="$SOURCE/$rel_path"
  dst="$DEST/$rel_path"
  if [ -f "$src" ]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    echo "Copied: $rel_path"
  else
    echo "WARN: copyFile not found at source, skipping: $rel_path"
  fi
done <<< "$COPY_FILES"

# ── Symlink dirs ─────────────────────────────────────────────────────────────
SYMLINK_DIRS=$(jq -r --arg key "$PROJECT_KEY" '.[$key].symlinkDirs // [] | .[]' "$CONFIG_FILE")

while IFS= read -r rel_path; do
  [ -z "$rel_path" ] && continue
  src="$SOURCE/$rel_path"
  dst="$DEST/$rel_path"
  if [ -e "$src" ]; then
    # Remove destination if it already exists (e.g. empty dir from git worktree add)
    rm -rf "$dst"
    ln -s "$src" "$dst"
    echo "Symlinked: $rel_path -> $src"
  else
    echo "WARN: symlinkDir not found at source, skipping: $rel_path"
  fi
done <<< "$SYMLINK_DIRS"

# ── postCreate hooks ─────────────────────────────────────────────────────────
HOOKS=$(jq -r --arg key "$PROJECT_KEY" '.[$key].hooks.postCreate // [] | .[]' "$CONFIG_FILE")

if [ -n "$HOOKS" ]; then
  echo "Running postCreate hooks in: $DEST"
  cd "$DEST"
  while IFS= read -r cmd; do
    [ -z "$cmd" ] && continue
    echo "  + $cmd"
    eval "$cmd"
  done <<< "$HOOKS"
fi

echo "Worktree setup complete."
