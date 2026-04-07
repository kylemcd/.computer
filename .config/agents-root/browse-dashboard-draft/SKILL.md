---
name: browse-dashboard
description: >-
  Open and interact with the local Knock dashboard (localhost:3000) in an
  authenticated browser session using agent-browser. Use when you need to
  visually inspect UI, debug CSS, take screenshots, or verify behavior in the
  running dashboard. Triggers include "open the dashboard", "check this in the
  browser", "inspect the UI", "take a screenshot", or any task requiring a live
  authenticated dashboard session.
allowed-tools:
  - "Bash(npx agent-browser:*)"
  - "Bash(agent-browser:*)"
---

# Browse Dashboard

Open an authenticated browser session against the local Knock dashboard.

## When to apply

- Visually inspecting or debugging dashboard UI
- Taking screenshots of components or pages
- Verifying CSS / layout issues in the running app
- Any task that requires interacting with the live dashboard

## Authentication

The dashboard uses Redux Persist with localStorage key `persist:@knocklabs`.
Before the session is usable you must inject this value and reload.

### Setup sequence

```bash
# 1. Open the dashboard
npx agent-browser open http://localhost:3000

# 2. Inject auth state (replace <AUTH_JSON> with the actual value)
npx agent-browser eval --stdin <<'EVALEOF'
localStorage.setItem('persist:@knocklabs', '<AUTH_JSON>');
EVALEOF

# 3. Reload to hydrate the auth state
npx agent-browser eval 'location.reload()'

# 4. Wait for the page to settle
npx agent-browser wait --load networkidle

# 5. Verify you're logged in
npx agent-browser snapshot -i
```

### Getting the auth value

Ask the user for their current `persist:@knocklabs` localStorage value.
They can copy it from Firefox/Chrome DevTools → Application → Local Storage →
`http://localhost:3000` → key `persist:@knocklabs`.

The value is a JSON string containing `auth`, `context`, and `_persist` keys.
It includes a JWT that expires, so it may need to be refreshed between sessions.

## Debugging CSS

For CSS debugging (the primary use case), use `eval` to inspect computed styles:

```bash
# Get computed styles for a specific selector
npx agent-browser eval --stdin <<'EVALEOF'
const el = document.querySelector('[data-tgph-combobox-trigger]');
const styles = window.getComputedStyle(el);
JSON.stringify({
  boxShadow: styles.boxShadow,
  border: styles.border,
  outline: styles.outline,
  cssVarBoxShadow: el.style.getPropertyValue('--box-shadow'),
});
EVALEOF
```

## Tips

- The dashboard dev server must be running (`yarn run dev` in `dashboard/`).
- `agent-browser` uses Chromium, not Firefox. Visual differences are possible
  but CSS debugging results are generally reliable.
- Re-snapshot after every navigation or DOM change to get fresh element refs.
- Use `npx agent-browser screenshot --annotate` for annotated screenshots.
