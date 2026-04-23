---
name: agent-browser
description: >-
  Browser automation for verifying UI changes and interacting with web apps.
  Use this skill proactively whenever you have made CSS, layout, component, or
  any frontend code changes and need to verify they look or behave correctly —
  don't wait for the user to ask. Also use when the user asks to "open the
  dashboard", "check this in the browser", "take a screenshot", "test this
  page", "see if this looks right", "open localhost", or any task that requires
  interacting with or visually inspecting a running web app. When in doubt about
  whether a frontend change is correct, use this skill to check rather than
  asking the user to verify manually.
allowed-tools:
  - "Bash(agent-browser:*)"
  - "Bash(lsof:*)"
---

# Browser Automation with agent-browser

Use this skill to visually verify UI changes, interact with running web apps, and
automate browser tasks. The general flow is: ensure the dev server is running for
the right codebase → load auth → navigate → snapshot/screenshot → report.

## Step 0: Check for a Playbook

Playbooks capture hard-won knowledge about navigating an app — non-obvious routes,
tricky UI patterns, localStorage tricks, multi-step flows — so future sessions can skip
rediscovery. Before doing anything else, check whether one applies to this task.

### 1. Identify the current repo

```bash
gh repo view --json nameWithOwner -q .nameWithOwner
# → "acmecorp/my-app"
```

### 2. Read the index

```bash
cat ~/.agent/memory/agent-browser-playbooks/index.json
```

The index maps playbook keys to metadata:

```json
{
  "my-app": {
    "playbook": "~/.agent/memory/agent-browser-playbooks/my-app.md",
    "description": "Main marketing site and admin dashboard",
    "repos": ["acmecorp/my-app", "acmecorp/my-app-staging"],
    "when_to_use": "Any task involving the admin panel, onboarding flow, or settings pages — these have non-obvious navigation the playbook documents.",
    "last_updated": "2026-04-20"
  }
}
```

If the index file doesn't exist yet, skip ahead — no playbooks have been saved.

### 3. Decide whether to load a playbook

Find entries where the current `org/repo` appears in `repos`. For each match, read
`when_to_use` and decide: does it apply to what the user is asking you to do right now?

- If yes → read the full playbook file before proceeding. Keep its contents in mind
  throughout the session — it may save you several steps.
- If no match or `when_to_use` doesn't apply → proceed without a playbook.

---

## Step 1: Ensure the Dev Server Is Running

Before opening any localhost URL, verify the dev server is running **from the current
working directory** — not from a different worktree on the same port.

### Find the project config

Read `~/.agent/memory/agent-browser-projects.json` and match a project entry to the
current repo. Match by checking whether the CWD path contains a project key as a
substring (e.g., CWD `.../my-app/packages/web` matches `my-app`). If ambiguous,
list the available project names and ask the user which applies.

Project config shape:

```json
{
  "my-app": {
    "dev": {
      "command": "yarn dev",
      "cwd": "packages/web",
      "port": 3000,
      "readyPattern": "ready"
    },
    "stateFile": "~/.agent/memory/my-app-auth.json",
    "refreshInstructions": "How to refresh auth when it expires (plain English)",
    "sourceOrigin": "https://my-app.example.com"
  }
}
```

`dev.cwd` is relative to the repo root (handles monorepos). If omitted, run from repo root.

### Check if a server is already running on the expected port

```bash
lsof -ti tcp:<port>   # returns PID(s) listening on that port, empty if none
```

If a PID is found, check whether it belongs to the current repo:

```bash
lsof -p <pid> | grep cwd   # macOS: shows the process's working directory
```

- If the process CWD is within the current repo root → **use it**, note the actual port
- If the CWD is from a different directory (another worktree) → **start a new server** on a free port

### Find a free port if needed

```bash
# Scan for a free port starting from the default
for port in $(seq <default_port> <default_port+20>); do
  lsof -ti tcp:$port > /dev/null 2>&1 || { echo $port; break; }
done
```

### Start the dev server

Run the dev command in the background, redirecting output to a temp log so you can
tail it for the ready signal:

```bash
cd <repo_root>/<dev.cwd> && <dev.command> > /tmp/devserver-<project>.log 2>&1 &
DEV_PID=$!

# Wait for ready signal (tail the log until readyPattern appears or timeout)
timeout 60 bash -c "until grep -q '<readyPattern>' /tmp/devserver-<project>.log 2>/dev/null; do sleep 1; done"
```

If `dev.port` is configurable via env var (common with Next.js), pass it:

```bash
PORT=<free_port> yarn dev > /tmp/devserver-<project>.log 2>&1 &
```

Once the server is up, note the actual URL (e.g. `http://localhost:3001`).

---

## Step 2: Load Auth State

```bash
agent-browser state load <stateFile from project config>
```

This pre-loads cookies and localStorage so the app sees you as authenticated.
Skip this step if there's no project config or no `stateFile`.

### Origin mismatch: inject localStorage manually

State files store localStorage entries under the origin they were captured from
(e.g. `https://dashboard.example.com`). When the dev server runs on a different
origin (e.g. `http://localhost:3000`), `state load` will **not** inject those
entries — the browser silently ignores them.

After `state load`, read the state file and check whether any `origins` entries
have a different origin than the dev server. If they do:

1. Open the dev server URL first (so the correct origin is active in the browser)
2. For **each** localStorage entry under any origin in the state file, inject it:

```bash
agent-browser open http://localhost:<port>
agent-browser wait --load networkidle

# For each {name, value} in stateFile.origins[*].localStorage:
agent-browser eval "localStorage.setItem('<name>', '<value>')"
```

Then reload the page so the app picks up the injected values:

```bash
agent-browser open http://localhost:<port>
agent-browser wait --load networkidle
```

You can read and inject all entries with a shell one-liner:

```bash
python3 -c "
import json, subprocess, sys
data = json.load(open(sys.argv[1]))
for origin in data.get('origins', []):
    for entry in origin.get('localStorage', []):
        val = json.dumps(entry['value'])
        subprocess.run(['agent-browser', 'eval', f\"localStorage.setItem({json.dumps(entry['name'])}, {val})\"])
" ~/.agent/memory/<project>-auth.json
```

---

## Step 3: Navigate and Verify

```bash
agent-browser open http://localhost:<port>
agent-browser wait --load networkidle
agent-browser snapshot -i
```

### Check for auth failure

After navigating, snapshot the page and check whether you landed on a login/auth page.
Signs of auth failure: URL contains `/login`, `/signin`, `/auth`; snapshot contains
"Sign in", "Log in", "Email" + "Password" inputs.

If auth appears to have failed, first check whether it's an **origin mismatch** (state
file origin differs from localhost) — if so, follow the localStorage injection steps in
Step 2 above before concluding the token is expired.

If auth is truly expired:

1. Stop — do not attempt to fill credentials
2. Tell the user which project's auth expired
3. Show them the `refreshInstructions` from the config
4. Wait for confirmation before retrying with a fresh state load

### DOM verification

Check the snapshot for:

- Expected elements present (navigation, key components, headings)
- No error states (stack traces, "Something went wrong", 404/500 text)
- Correct text content where verifiable

### Visual verification via screenshot

If DOM looks structurally correct but you need to confirm visual appearance (layout,
CSS, spacing, colors), take an annotated screenshot:

```bash
agent-browser screenshot --annotate
```

Read the screenshot image and reason about what you see. Report specifically:

- What looks correct
- Any visual issues (misalignment, overflow, missing styles, wrong colors)
- Whether the change you made is reflected as expected

If you find a visual issue, **describe it clearly to the user and ask before attempting
a fix.** Don't silently modify code after a verification step.

---

## Core Commands Reference

```bash
# State / auth
agent-browser state load <file>       # Load cookies + localStorage
agent-browser state save <file>       # Save current session state

# Navigation
agent-browser open <url>              # Navigate
agent-browser close                   # Close browser

# Snapshot (DOM)
agent-browser snapshot -i             # Interactive elements with @refs
agent-browser snapshot -i -C          # Include cursor-interactive elements
agent-browser snapshot -s "#selector" # Scope to CSS selector

# Interaction
agent-browser click @e1
agent-browser fill @e2 "text"
agent-browser type @e2 "text"         # Type without clearing
agent-browser select @e1 "option"
agent-browser check @e1
agent-browser press Enter
agent-browser scroll down 500
agent-browser scroll down 500 --selector "div.content"

# Read page info
agent-browser get text @e1
agent-browser get url
agent-browser get title

# Wait
agent-browser wait @e1                # Wait for element
agent-browser wait --load networkidle
agent-browser wait --url "**/page"
agent-browser wait 2000

# Capture
agent-browser screenshot              # Screenshot to temp dir
agent-browser screenshot --full       # Full page
agent-browser screenshot --annotate   # Annotated with numbered labels
agent-browser pdf output.pdf

# Diff
agent-browser diff snapshot           # Compare current vs last snapshot
agent-browser diff screenshot --baseline before.png
agent-browser diff url <url1> <url2>
```

## Command Chaining

```bash
# Chain when you don't need intermediate output
agent-browser open https://example.com && agent-browser wait --load networkidle && agent-browser snapshot -i

# Run separately when you need to parse output first (e.g. read @refs from snapshot)
agent-browser snapshot -i
# ... read refs ...
agent-browser click @e3
```

## Ref Lifecycle

Refs (`@e1`, `@e2`) are invalidated on every page change. Re-snapshot after:

- Navigation (link clicks, form submits)
- Dynamic DOM changes (modals, dropdowns opening)

## Semantic Locators (Alternative to Refs)

```bash
agent-browser find text "Sign In" click
agent-browser find label "Email" fill "user@test.com"
agent-browser find role button click --name "Submit"
agent-browser find placeholder "Search" type "query"
agent-browser find testid "submit-btn" click
```

## JavaScript Evaluation

```bash
agent-browser eval 'document.title'

agent-browser eval --stdin <<'EVALEOF'
JSON.stringify(window.__REDUX_STATE__ || {})
EVALEOF
```

---

## Step 4: Decide Whether to Update the Playbook

After completing the browser session, before closing, review what you did and ask:
**would any of this have been faster if a playbook entry had existed?**

### Things worth saving

- A URL you had to discover by clicking through navigation (could have gone direct)
- A modal, drawer, or panel that required a non-obvious sequence to open
- A UI element that looked or behaved differently than expected (wrong label, hidden state, timing issue)
- A `localStorage` key or flag you set manually to enable something
- A multi-step flow where choosing the wrong option at any step would cost significant backtracking
- A gotcha you hit — even if you recovered quickly, future sessions won't have the context you have now

### Things not worth saving

- Navigating to the root URL or any URL that's obvious from the project name
- Standard CRUD interactions on clearly-labeled forms
- Anything already documented in the existing playbook

### If something is worth saving

Tell the user concisely what you'd save and why it would help:

> "I had to click through 4 menus to find the webhook configuration page — the URL is `/settings/integrations/webhooks` and it's not in the main nav. Worth adding to the playbook so next time I can go direct. Add it?"

One question, one yes/no. If yes, write or update the playbook and index (see the section below). If no, move on.

If nothing new was discovered, skip this step silently — don't ask the user about the playbook if there's nothing useful to save.

---

## Saving Knowledge to a Playbook

Playbooks live at `~/.agent/memory/agent-browser-playbooks/<key>.md`, registered in
`~/.agent/memory/agent-browser-playbooks/index.json`.

### When to write or update a playbook

**Proactively offer** to save knowledge when you:
- Navigated a multi-step flow to reach a page (more than 2 clicks from home)
- Worked around a tricky UI element (custom dropdowns, multi-pane layouts, lazy-loaded modals)
- Injected localStorage or cookies manually to enable a feature or bypass a gate
- Discovered a non-obvious URL that skips the normal navigation path
- Hit a gotcha that would cost time to rediscover (timing issue, required scroll, hidden button)

**Always save** when the user explicitly asks to "save this", "remember this", "add this
to the playbook", or similar.

### Creating a new playbook

1. Copy the template into the playbooks directory:

```bash
mkdir -p ~/.agent/memory/agent-browser-playbooks
cp ~/.agents/skills/agent-browser/references/playbook-template.md \
   ~/.agent/memory/agent-browser-playbooks/<key>.md
```

2. Fill in the playbook sections with what you discovered.

3. Add an entry to `index.json` (create the file if it doesn't exist yet):

```json
{
  "<key>": {
    "playbook": "~/.agent/memory/agent-browser-playbooks/<key>.md",
    "description": "One sentence on what app/product this covers",
    "repos": ["org/repo"],
    "when_to_use": "Plain-English description of which tasks benefit from this playbook. Be specific — e.g. 'navigating to the billing or team settings pages, which require 3+ clicks and are easy to miss'.",
    "last_updated": "YYYY-MM-DD"
  }
}
```

Get the `org/repo` value from `gh repo view --json nameWithOwner -q .nameWithOwner`.
Add additional repos to the array if the same app is served from multiple repos (e.g. a
staging fork).

### Updating an existing playbook

Read the file first, then add or revise sections. Don't delete existing entries unless
they're confirmed stale — old knowledge is usually still useful.

After editing, update `last_updated` in the playbook file **and** in `index.json`.
If the scope of what the playbook covers has changed meaningfully, update `when_to_use`
in the index too — that's what future sessions will read to decide whether to load it.

When you finish a session having discovered something worth saving, tell the user:
> "I found a non-obvious step for [X]. Want me to save that to the playbook so future sessions can skip it?"

---

## Adding a New Project Config

When the user wants to register a new project, read the current
`~/.agent/memory/agent-browser-projects.json` (create it if missing) and add an entry.

Ask the user for:

- **Project name** — should match a folder/repo name (used for CWD matching)
- **dev.command** — how to start the dev server (e.g. `yarn dev`, `npm run dev`)
- **dev.cwd** — subdirectory to run it from, relative to repo root (omit if root)
- **dev.port** — default port (e.g. `3000`)
- **dev.readyPattern** — string to watch for in server output (e.g. `"ready"`, `"listening"`)
- **stateFile** — where auth state will be written (suggest `~/.agent/memory/<name>-auth.json`)
- **refreshInstructions** — plain English: what does the user do when auth expires?
- **sourceOrigin** — the live app URL the auth comes from

Example completed entry:

```json
{
  "my-app": {
    "dev": {
      "command": "pnpm dev",
      "cwd": "apps/web",
      "port": 3000,
      "readyPattern": "ready on"
    },
    "stateFile": "~/.agent/memory/my-app-auth.json",
    "refreshInstructions": "Log into https://my-app.com and re-export your auth state",
    "sourceOrigin": "https://my-app.com"
  }
}
```
