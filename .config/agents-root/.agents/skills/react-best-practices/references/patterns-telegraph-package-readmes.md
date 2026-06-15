---
title: Check Telegraph Package READMEs Before Using Components
impact: CRITICAL
impactDescription: prevents incorrect sub-component composition and missed features
tags: telegraph, compound-components, documentation
---

## Check Telegraph Package READMEs Before Using Components

Before using any `@telegraph/*` package, fetch its README from GitHub to
understand the correct component API, sub-component composition, and available
props. Do not guess at component APIs based on naming conventions alone.

README URL pattern:

```
https://raw.githubusercontent.com/knocklabs/telegraph/main/packages/<package-name>/README.md
```

Replace `<package-name>` with the part after `@telegraph/` — e.g. for
`@telegraph/modal` fetch `.../packages/modal/README.md`.

### When to check

- First time using any `@telegraph/*` component in a task.
- Using sub-components or props you haven't verified.
- Wrapping or extending a Telegraph component in a new abstraction.

### What to look for

1. **Quick Start** — the canonical composition pattern showing which
   sub-components exist and how they nest.
2. **API Reference** — every sub-component's props, defaults, and types.
3. **Sub-component relationships** — which parts are containers vs content
   vs controls, and which are required vs optional.

### Why this matters

Telegraph compound components often have sub-parts with similar names that
serve different roles. Guessing leads to broken composition — e.g. passing
text directly to a container component instead of using the correct text
sub-component, or missing interactive sub-components like close buttons.

The README is the source of truth for every package's API surface.
