# <project-name> Browser Playbook

_Last updated: YYYY-MM-DD_

<!--
  This file is read by the agent-browser skill when the index.json entry for this
  project matches the current repo and task. Keep entries concise and actionable.

  Discovery metadata (repos, when_to_use, description) lives in index.json — not here.
  This file is pure knowledge: how to navigate, what's tricky, what to remember.
-->

## Routes

<!--
  One section per page or feature area. Include the direct URL, how to reach it
  if navigation is non-obvious, notable elements, and any gotchas.
-->

### Home / Dashboard
**URL:** `/`
**How to reach it:** Navigate directly.

**Key elements:**
- _(describe notable buttons, panels, inputs here)_

**Gotchas:**
- _(none known)_

---

<!--
### Settings > Profile
**URL:** `/settings/profile`
**How to reach it:** Click avatar top-right → "Settings" → "Profile" tab.

**Key elements:**
- `Save` button — disabled until a field changes; no visible confirmation — wait 1s after click
- `Danger zone` — collapsed by default, click "Show" to expand

**Gotchas:**
- `Save` looks identical when enabled vs disabled — check `aria-disabled` in snapshot before clicking
-->

## Complex Flows

<!--
  Step-by-step sequences for multi-click or stateful flows that are easy to get wrong.
  Include these when there's meaningful state involved or when the wrong path is costly.
-->

<!--
### Create a new workspace
1. Click "New" in the sidebar
2. Select "Workspace" from dropdown (not "Project" — opens a different modal)
3. Fill name → click "Next"
4. On permissions step, set role to "Editor" before clicking "Create"
   (default "Viewer" can't be changed later without admin access)
5. Lands on `/workspaces/<id>`
-->

## Shortcuts & Tricks

<!--
  Direct URLs, localStorage overrides, feature flags, keyboard shortcuts — anything
  that lets you skip steps or unlock hidden behavior.
-->

- _(none yet)_

<!--
- **Skip onboarding:** Navigate directly to `/dashboard` — redirect only fires on first-ever load
- **Enable dark mode:** `localStorage.setItem('theme', 'dark')` then reload
- **Admin panel:** `/admin` — only visible when `window.__ENV__.isAdmin === true`
  Inject via: `agent-browser eval "window.__ENV__.isAdmin = true"` then reload
-->

## Auth Notes

<!--
  Project-specific auth quirks beyond what's in agent-browser-projects.json.
-->

- _(none yet)_

<!--
- Token expires after 1 hour of inactivity — re-run `agent-browser state load` to refresh
- Impersonation: append `?as=<user-id>` to any URL (requires admin token)
-->
