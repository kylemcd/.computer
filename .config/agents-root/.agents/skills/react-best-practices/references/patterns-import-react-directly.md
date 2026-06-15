---
title: Import React Hooks and Types Directly
impact: MEDIUM
impactDescription: keeps imports consistent and call sites free of namespace noise
tags: imports, react, readability
---

## Import React Hooks and Types Directly

Import React hooks and types as named imports and call them bare. Never import
the default `React` namespace just to reach hooks or types through `React.*`.

This applies to hooks (`useState`, `useRef`, `useEffect`, `useCallback`,
`useMemo`, etc.) and types (`ReactNode`, `ComponentProps`, `RefObject`, etc.).
The modern JSX transform means a component file does not need `React` in scope
to render JSX, so the namespace import is pure noise.

**Incorrect (React namespace):**

```tsx
import React from "react";

type Props = {
  children: React.ReactNode;
};

const Card = ({ children }: Props) => {
  const [open, setOpen] = React.useState(false);
  const ref = React.useRef<HTMLDivElement>(null);
  React.useEffect(() => {
    // ...
  }, []);
  return <div ref={ref}>{children}</div>;
};
```

**Correct (named imports):**

```tsx
import { useEffect, useRef, useState, type ReactNode } from "react";

type Props = {
  children: ReactNode;
};

const Card = ({ children }: Props) => {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    // ...
  }, []);
  return <div ref={ref}>{children}</div>;
};
```

### When editing existing files

If you touch a file that still uses the `React.*` namespace, convert the whole
file rather than leaving it mixed: drop every `React.` prefix and replace
`import React from "react"` with the named imports the file actually uses. A
file with some bare hooks and some `React.`-prefixed ones is worse than either
convention applied consistently.
