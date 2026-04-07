# Browser Verification

How to verify UI work using `npx agent-browser`. No installation needed — `npx` handles it.

Use this skill for any task touching frontend code, UI components, API calls from the browser, accessibility, or performance. Use `skills/run-checks.md` for backend-only tasks.

---

## Common dev server ports

Try these in order if no port is specified: 3000 (Next.js, Create React App), 5173 (Vite), 4200 (Angular), 8080 (generic), 8000 (Django/Python).

---

## Standard verification checklist

Run this in order after any UI change. Clear buffers first so only signals from this session appear.

```bash
# 1. Open the dev server
npx agent-browser open http://localhost:3000

# 2. Clear all buffers
npx agent-browser errors --clear
npx agent-browser console --clear
npx agent-browser network requests --clear

# 3. Snapshot to discover interactive elements
npx agent-browser snapshot -i
# Output gives refs: @e1 [button] "Submit", @e2 [input] etc.

# 4. Perform the action being verified
npx agent-browser click @e1
npx agent-browser wait --load networkidle

# 5. Capture visual state
npx agent-browser screenshot

# 6. Check for JS exceptions
npx agent-browser errors

# 7. Check console output (warnings, errors, deprecations)
npx agent-browser console

# 8. Check for failed network requests
npx agent-browser network requests --type xhr,fetch --status 400-599
```

Re-snapshot after any navigation or DOM change — refs (`@e1`, `@e2`) are invalidated when the page changes.

---

## Network request inspection

```bash
# All captured requests
npx agent-browser network requests

# Filter by URL pattern
npx agent-browser network requests --filter "api"

# Failed requests only (4xx and 5xx)
npx agent-browser network requests --status 400-599

# Filter by type
npx agent-browser network requests --type xhr,fetch

# Full request + response body for a specific request
npx agent-browser network request <id>

# Record a complete HAR file for deep inspection
npx agent-browser network har start
# ... perform actions ...
npx agent-browser network har stop ./capture.har
```

What to look for: 4xx/5xx responses, unexpected response shapes, missing auth headers, CORS errors (`net::ERR_FAILED` on cross-origin requests), requests that should have fired but didn't.

---

## Console and JS errors

```bash
# All console output: log, warn, error, info
npx agent-browser console
npx agent-browser console --json     # machine-readable

# JS exceptions and uncaught errors only
npx agent-browser errors
npx agent-browser errors --json

# Clear buffers between actions
npx agent-browser console --clear
npx agent-browser errors --clear
```

Pattern: clear → perform the action → capture. This isolates signals to the action being tested.

What to look for: React hydration errors, unhandled promise rejections, failed dynamic imports, deprecation warnings from framework APIs, console.error calls from your own code.

---

## Dev server errors

Browser tools only show client-side signals. The dev server terminal captures build and HMR errors that never reach the browser.

If tmux is running:
```bash
# Read the last 50 lines of the dev server pane
tmux capture-pane -p -J -t {dev-server-pane} -S -50
```

Otherwise, look at the terminal running the dev server directly, or start it and capture output:
```bash
npm run dev 2>&1 | tee /tmp/dev-server.log &
sleep 3
cat /tmp/dev-server.log
```

What to look for: module not found errors, TypeScript compilation errors emitted by the dev server, HMR update failures, circular dependency warnings.

---

## Visual diff (before/after)

```bash
# Take baseline before making changes
npx agent-browser screenshot /tmp/before.png

# Make the change, then compare
npx agent-browser diff screenshot --baseline /tmp/before.png
```

Useful for confirming a visual change was applied and nothing else moved.

---

## Accessibility scan

```bash
# Open the page
npx agent-browser open http://localhost:3000

# Run axe-core for automated accessibility violations
npx agent-browser eval --stdin <<'EOF'
const script = document.createElement('script');
script.src = 'https://cdnjs.cloudflare.com/ajax/libs/axe-core/4.8.2/axe.min.js';
script.onload = () => axe.run().then(r => console.log(JSON.stringify(r.violations)));
document.head.appendChild(script);
EOF

# Screenshot for manual inspection
npx agent-browser screenshot --annotate
```

---

## Performance timing

```bash
# Start a Chrome DevTools profile
npx agent-browser profiler start

# Navigate and interact
npx agent-browser open http://localhost:3000
npx agent-browser wait --load networkidle

# Stop and save trace
npx agent-browser profiler stop /tmp/trace.json
```

Open `/tmp/trace.json` in Chrome DevTools (Performance panel → Load profile) or at `https://ui.perfetto.dev/`.
