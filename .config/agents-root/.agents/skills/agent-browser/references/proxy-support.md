# Proxy Support

Proxy configuration for geo-testing, rate limiting avoidance, and corporate environments.

**Related**: [commands.md](commands.md) for global options, [SKILL.md](../SKILL.md) for quick start.

## Basic Proxy Configuration

```bash
# Via CLI flag
agent-browser --proxy "http://proxy.example.com:8080" open https://example.com

# Via environment variable
export HTTP_PROXY="http://proxy.example.com:8080"
export HTTPS_PROXY="http://proxy.example.com:8080"
agent-browser open https://example.com
```

## Authenticated Proxy

```bash
export HTTP_PROXY="http://username:password@proxy.example.com:8080"
agent-browser open https://example.com
```

## SOCKS Proxy

```bash
export ALL_PROXY="socks5://proxy.example.com:1080"
# With auth:
export ALL_PROXY="socks5://user:pass@proxy.example.com:1080"
agent-browser open https://example.com
```

## Proxy Bypass

```bash
agent-browser --proxy "http://proxy.example.com:8080" --proxy-bypass "localhost,*.internal.com" open https://example.com

# Via environment variable
export NO_PROXY="localhost,127.0.0.1,.internal.company.com"
```

## Common Use Cases

### Geo-Location Testing

```bash
PROXIES=("http://us-proxy.example.com:8080" "http://eu-proxy.example.com:8080" "http://asia-proxy.example.com:8080")

for proxy in "${PROXIES[@]}"; do
    export HTTP_PROXY="$proxy"
    export HTTPS_PROXY="$proxy"
    region=$(echo "$proxy" | grep -oP '^\w+-\w+')
    agent-browser --session "$region" open https://example.com
    agent-browser --session "$region" screenshot "./screenshots/$region.png"
    agent-browser --session "$region" close
done
```

### Rotating Proxies for Scraping

```bash
PROXY_LIST=("http://proxy1.example.com:8080" "http://proxy2.example.com:8080")
URLS=("https://site.com/page1" "https://site.com/page2")

for i in "${!URLS[@]}"; do
    proxy_index=$((i % ${#PROXY_LIST[@]}))
    export HTTP_PROXY="${PROXY_LIST[$proxy_index]}"
    export HTTPS_PROXY="${PROXY_LIST[$proxy_index]}"
    agent-browser open "${URLS[$i]}"
    agent-browser get text body > "output-$i.txt"
    agent-browser close
    sleep 1
done
```

## Verifying Proxy Connection

```bash
agent-browser open https://httpbin.org/ip
agent-browser get text body
# Should show proxy's IP, not your real IP
```

## Best Practices

1. Use environment variables -- don't hardcode proxy credentials
2. Set `NO_PROXY` appropriately to avoid routing local traffic through proxy
3. Test proxy connectivity with `curl -x http://proxy:port https://httpbin.org/ip` before automation
4. Rotate proxies for large scraping jobs to distribute load and avoid bans
