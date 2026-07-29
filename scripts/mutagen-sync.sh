#!/usr/bin/env bash

set -euo pipefail

log()  { printf "[mutagen] %s\n" "$*"; }
warn() { printf "[mutagen][warn] %s\n" "$*" >&2; }
err()  { printf "[mutagen][error] %s\n" "$*" >&2; exit 1; }

# Make brew-installed tools reachable even from a minimal environment.
[[ -d /opt/homebrew/bin ]] && PATH="/opt/homebrew/bin:${PATH}"

# --- What/where we sync -------------------------------------------------------
# workbench is the source of truth; this machine keeps a real local copy of
# ~/projects so dev servers, file-watching and the browser run at native speed.
# The endpoint is a full Tailscale MagicDNS name + user, so this needs NO
# ~/.ssh/config alias and works from any network Tailscale can reach.
WORKBENCH_USER="kyle"
WORKBENCH_HOST="workbench.tail43f50e.ts.net"
REMOTE_DIR="/home/kyle/projects"
LOCAL_DIR="${HOME}/projects"
SESSION="projects"

# --- 1. Ensure mutagen is installed ------------------------------------------
# Kept out of the shared Brewfile on purpose: mutagen only belongs on machines
# that actually sync, so it's installed on demand here.
if ! command -v mutagen >/dev/null 2>&1; then
  command -v brew >/dev/null 2>&1 || err "Homebrew not found. Run 'computer init' first."
  log "Installing mutagen..."
  # Newer Homebrew refuses third-party taps until trusted; harmless on older brew.
  brew trust mutagen-io/mutagen >/dev/null 2>&1 || true
  brew install mutagen-io/mutagen/mutagen
fi
log "mutagen $(mutagen version)"

# --- 2. Daemon (launchd agent, survives reboot) ------------------------------
mutagen daemon register >/dev/null 2>&1 || true   # no-op if already registered
mutagen daemon start    >/dev/null 2>&1 || true   # no-op if already running

# --- 3. Preflight: the two things that can't be automated --------------------
# Make sure the default key is offered to the daemon's ssh (persists in the
# macOS keychain so it survives reboots / a fresh agent).
if [[ -f "${HOME}/.ssh/id_ed25519" ]]; then
  if [[ "$(uname)" == "Darwin" ]]; then
    ssh-add --apple-use-keychain "${HOME}/.ssh/id_ed25519" >/dev/null 2>&1 || true
  else
    ssh-add "${HOME}/.ssh/id_ed25519" >/dev/null 2>&1 || true
  fi
fi

if command -v tailscale >/dev/null 2>&1 && ! tailscale status >/dev/null 2>&1; then
  err "Tailscale isn't up. Start it (open the app or 'tailscale up'), then re-run: computer mutagen"
fi

if ! ssh -o StrictHostKeyChecking=accept-new -o BatchMode=yes -o ConnectTimeout=10 \
        "${WORKBENCH_USER}@${WORKBENCH_HOST}" 'true' 2>/dev/null; then
  err "Can't SSH to ${WORKBENCH_HOST}. Two one-time, per-machine prerequisites:
    1) Tailscale running and logged in on this machine.
    2) This machine's key (~/.ssh/id_ed25519.pub) added to
       workbench:~/.ssh/authorized_keys.
  Fix those, then re-run: computer mutagen"
fi

# --- 4. Write the canonical sync config --------------------------------------
mkdir -p "${LOCAL_DIR}"
cat > "${LOCAL_DIR}/mutagen.yml" <<EOF
sync:
  defaults:
    # two-way-safe never silently clobbers: if this machine and workbench edit
    # the SAME file at once, that one file pauses and is flagged; everything
    # else keeps flowing. Use two-way-resolved to make alpha (this side) win.
    mode: two-way-safe
    ignore:
      vcs: false            # DO sync .git so 'git status' works locally
      paths:
        - node_modules      # install per-machine; never synced (keeps it fast)
        - .next
        - dist
        - build
        - .turbo
        - .cache
        - .direnv
        - result            # nix build symlinks (point into /nix/store)
        - "result-*"
        - .DS_Store
        - mutagen.yml       # the project file + its lock live in the sync root;
        - mutagen.yml.lock  # ignore both so they never sync or conflict
  projects:
    alpha: "."
    beta: "${WORKBENCH_USER}@${WORKBENCH_HOST}:${REMOTE_DIR}"
EOF

# --- 5. Start (or leave running) the sync session ----------------------------
# Capture then substring-match, rather than piping into `grep -q`: under
# `set -o pipefail`, grep -q exits early on a match and SIGPIPEs the upstream
# `mutagen sync list`, which pipefail then reports as a failed pipeline *even
# on a match* — wrongly sending us down the "start" path on every re-run.
existing="$(mutagen sync list 2>/dev/null || true)"
if [[ "${existing}" == *"Name: ${SESSION}"* ]]; then
  log "Session '${SESSION}' already running; resuming in case it was paused."
  mutagen sync resume "${SESSION}" >/dev/null 2>&1 || true
else
  log "Starting sync session '${SESSION}'..."
  ( cd "${LOCAL_DIR}" && mutagen project start )
fi

# --- 6. Report ---------------------------------------------------------------
log "Current status:"
mutagen sync list 2>&1 | grep -iE 'Name:|URL:|Connected:|Status:|Conflicts:' | sed 's/^/    /' || true
log "Done. Manage with: mutagen sync list | mutagen sync monitor ${SESSION} | mutagen project pause|resume"
