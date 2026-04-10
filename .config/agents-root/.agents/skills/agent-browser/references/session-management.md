# Session Management

Multiple isolated browser sessions with state persistence and concurrent browsing.

**Related**: [authentication.md](authentication.md) for login patterns, [SKILL.md](../SKILL.md) for quick start.

## Named Sessions

Use `--session` flag to isolate browser contexts:

```bash
agent-browser --session auth open https://app.example.com/login
agent-browser --session public open https://example.com

agent-browser --session auth fill @e1 "user@example.com"
agent-browser --session public get text body
```

Each session has independent: cookies, localStorage/SessionStorage, IndexedDB, cache, browsing history, open tabs.

## Session State Persistence

```bash
# Save cookies, storage, and auth state
agent-browser state save /path/to/auth-state.json

# Restore saved state
agent-browser state load /path/to/auth-state.json
agent-browser open https://app.example.com/dashboard
```

## Common Patterns

### Authenticated Session Reuse

```bash
STATE_FILE="/tmp/auth-state.json"

if [[ -f "$STATE_FILE" ]]; then
    agent-browser state load "$STATE_FILE"
    agent-browser open https://app.example.com/dashboard
else
    agent-browser open https://app.example.com/login
    agent-browser snapshot -i
    agent-browser fill @e1 "$USERNAME"
    agent-browser fill @e2 "$PASSWORD"
    agent-browser click @e3
    agent-browser wait --load networkidle
    agent-browser state save "$STATE_FILE"
fi
```

### Concurrent Scraping

```bash
agent-browser --session site1 open https://site1.com &
agent-browser --session site2 open https://site2.com &
agent-browser --session site3 open https://site3.com &
wait

agent-browser --session site1 get text body > site1.txt
agent-browser --session site2 get text body > site2.txt
agent-browser --session site3 get text body > site3.txt

agent-browser --session site1 close
agent-browser --session site2 close
agent-browser --session site3 close
```

### A/B Testing Sessions

```bash
agent-browser --session variant-a open "https://app.com?variant=a"
agent-browser --session variant-b open "https://app.com?variant=b"

agent-browser --session variant-a screenshot /tmp/variant-a.png
agent-browser --session variant-b screenshot /tmp/variant-b.png
```

## Session Cleanup

```bash
agent-browser --session auth close
agent-browser session list
```

## Best Practices

1. Name sessions semantically (`github-auth`, `docs-scrape` not `s1`, `s2`)
2. Always close sessions when done to avoid leaked processes
3. Don't commit state files -- they contain auth tokens (`echo "*.auth-state.json" >> .gitignore`)
4. Use `timeout` for long-running automated sessions
