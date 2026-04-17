#!/bin/bash
# install.sh — One-time setup for the worktree skill.
#
# Run this once on a new machine after stowing the dotfiles.
# Safe to re-run — all steps are idempotent.
#
# What it does:
#   1. Checks for required dependencies (jq, fzf, git)
#   2. Creates ~/.agent/memory/ if missing
#   3. Initializes ~/.agent/memory/worktree-projects.json if missing
#   4. Creates ~/.local/worktree/ if missing
#   5. Checks that opencode.json has the required permissions

set -euo pipefail

BOLD=$(tput bold 2>/dev/null || true)
RESET=$(tput sgr0 2>/dev/null || true)
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }
fail() { echo -e "${RED}✗${NC} $*"; ERRORS=$((ERRORS + 1)); }

ERRORS=0

echo "${BOLD}Worktree skill setup${RESET}"
echo ""

# ── 1. Dependencies ───────────────────────────────────────────────────────────
echo "${BOLD}Checking dependencies...${RESET}"

for cmd in git jq fzf; do
  if command -v "$cmd" &>/dev/null; then
    ok "$cmd ($(command -v "$cmd"))"
  else
    fail "$cmd not found — install with: brew install $cmd"
  fi
done

echo ""

# ── 2. Agent memory directory ─────────────────────────────────────────────────
echo "${BOLD}Setting up agent memory...${RESET}"

MEMORY_DIR="${HOME}/.agent/memory"
if [ ! -d "$MEMORY_DIR" ]; then
  mkdir -p "$MEMORY_DIR"
  ok "Created $MEMORY_DIR"
else
  ok "$MEMORY_DIR exists"
fi

# ── 3. worktree-projects.json ─────────────────────────────────────────────────
MEMORY_FILE="${MEMORY_DIR}/worktree-projects.json"
if [ ! -f "$MEMORY_FILE" ]; then
  cat > "$MEMORY_FILE" << 'EOF'
{
  "_worktrees": {
  }
}
EOF
  ok "Created $MEMORY_FILE"
  warn "Add per-project config to $MEMORY_FILE as needed. Example:"
  echo '     {
       "my-org/my-repo": {
         "copyFiles": [".env", "backend/dev.env"],
         "symlinkDirs": [],
         "hooks": {
           "postCreate": ["yarn install"],
           "preDelete": []
         }
       },
       "_worktrees": {}
     }'
else
  ok "$MEMORY_FILE exists"
  # Ensure _worktrees key exists
  if ! jq -e '._worktrees' "$MEMORY_FILE" > /dev/null 2>&1; then
    jq '. + {"_worktrees": {}}' "$MEMORY_FILE" > /tmp/wt-install.json && mv /tmp/wt-install.json "$MEMORY_FILE"
    ok "Added missing _worktrees key to $MEMORY_FILE"
  fi
fi

echo ""

# ── 4. Worktree base directory ────────────────────────────────────────────────
echo "${BOLD}Setting up worktree directory...${RESET}"

WT_BASE="${HOME}/.local/worktree"
if [ ! -d "$WT_BASE" ]; then
  mkdir -p "$WT_BASE"
  ok "Created $WT_BASE"
else
  ok "$WT_BASE exists"
fi

echo ""

# ── 5. OpenCode permissions ───────────────────────────────────────────────────
echo "${BOLD}Checking OpenCode config...${RESET}"

OC_CONFIG="${HOME}/.config/opencode/opencode.json"
if [ ! -f "$OC_CONFIG" ]; then
  warn "OpenCode config not found at $OC_CONFIG"
  warn "Add the following to your opencode.json permission.external_directory:"
  echo '     "~/.agent/**": "allow"'
  echo '     "~/.local/worktree/**": "allow"'
else
  MISSING_PERMS=()
  jq -e '.permission.external_directory["~/.agent/**"]' "$OC_CONFIG" > /dev/null 2>&1 \
    || MISSING_PERMS+=('~/.agent/**')
  jq -e '.permission.external_directory["~/.local/worktree/**"]' "$OC_CONFIG" > /dev/null 2>&1 \
    || MISSING_PERMS+=('~/.local/worktree/**')

  if [ ${#MISSING_PERMS[@]} -eq 0 ]; then
    ok "OpenCode permissions look correct"
  else
    for p in "${MISSING_PERMS[@]}"; do
      warn "Missing OpenCode permission: $p — add to opencode.json permission.external_directory"
    done
  fi
fi

echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
if [ "$ERRORS" -eq 0 ]; then
  echo -e "${GREEN}${BOLD}Setup complete.${RESET}"
  echo ""
  echo "Next steps:"
  echo "  • Add project config to ~/.agent/memory/worktree-projects.json"
  echo "  • Reload your shell: source ~/.zshrc"
  echo "  • Create a worktree: wt <branch-name>"
  echo "  • Pick a worktree interactively: wts"
else
  echo -e "${RED}${BOLD}Setup finished with $ERRORS error(s). Fix the issues above before using the skill.${RESET}"
  exit 1
fi
