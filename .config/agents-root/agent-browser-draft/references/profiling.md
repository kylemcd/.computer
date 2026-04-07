# Profiling

Capture Chrome DevTools performance profiles during browser automation.

**Related**: [commands.md](commands.md) for full command reference, [SKILL.md](../SKILL.md) for quick start.

## Basic Profiling

```bash
agent-browser profiler start

agent-browser navigate https://example.com
agent-browser click "#button"
agent-browser wait 1000

agent-browser profiler stop ./trace.json
```

## Profiler Commands

```bash
agent-browser profiler start                                          # Start with default categories
agent-browser profiler start --categories "devtools.timeline,v8.execute,blink.user_timing"  # Custom categories
agent-browser profiler stop ./trace.json                              # Stop and save
```

## Categories

| Category | Description |
|---|---|
| `devtools.timeline` | Standard DevTools performance traces |
| `v8.execute` | Time spent running JavaScript |
| `blink` | Renderer events |
| `blink.user_timing` | `performance.mark()` / `performance.measure()` calls |
| `latencyInfo` | Input-to-latency tracking |
| `renderer.scheduler` | Task scheduling and execution |
| `toplevel` | Broad-spectrum basic events |

## Use Cases

### Diagnosing Slow Page Loads

```bash
agent-browser profiler start
agent-browser navigate https://app.example.com
agent-browser wait --load networkidle
agent-browser profiler stop ./page-load-profile.json
```

### Profiling User Interactions

```bash
agent-browser navigate https://app.example.com
agent-browser profiler start
agent-browser click "#submit"
agent-browser wait 2000
agent-browser profiler stop ./interaction-profile.json
```

## Viewing Profiles

- **Chrome DevTools**: Performance panel > Load profile (`Ctrl+Shift+I` > Performance)
- **Perfetto UI**: https://ui.perfetto.dev/ -- drag and drop the JSON file
- **Trace Viewer**: `chrome://tracing` in any Chromium browser

## Limitations

- Only works with Chromium-based browsers (Chrome, Edge). Not supported on Firefox or WebKit.
- Trace data capped at 5 million events. Stop profiling promptly after the area of interest.
- 30-second timeout on stop -- if browser is unresponsive, stop command may fail.
