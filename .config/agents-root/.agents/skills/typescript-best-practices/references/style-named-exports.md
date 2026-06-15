---
title: Always Use Named Exports
impact: MEDIUM
impactDescription: prevents naming mismatches and makes imports greppable
tags: typescript, modules, exports, imports
---

## Always Use Named Exports

Use named exports exclusively. Never use `export default` or `export *`.
Named exports enforce a consistent name across the codebase, making it easy to
search for all usages. Default exports let every consumer pick a different name,
which leads to confusion and makes refactoring harder.

**Incorrect (default export):**

```typescript
// helpers.ts
const formatDate = (date: Date) => { ... };
export default formatDate;

// consumer A
import formatDate from "./helpers";

// consumer B — different name, same function
import dateFormatter from "./helpers";
```

The function has two names in the codebase. Searching for `formatDate` misses
consumer B entirely.

**Incorrect (export star):**

```typescript
// index.ts
export * from "./Button";
export * from "./Input";
export * from "./helpers";
```

`export *` can accidentally expose internal modules and makes it unclear what
the public API is. A name collision between re-exported modules silently
shadows one of them.

**Correct (named exports):**

```typescript
// helpers.ts
export const formatDate = (date: Date) => { ... };

// consumer
import { formatDate } from "./helpers";
```

```typescript
// index.ts
export { Button } from "./Button";
export { Input } from "./Input";
export { formatDate } from "./helpers";
export type { ButtonProps } from "./Button";
```

Every export is explicit and greppable. The barrel file documents exactly what
the module exposes, and consumers always use the canonical name.

**Applies to all files** — components, hooks, utilities, types, constants. The
`index.ts` barrel file in each component folder should use named re-exports to
define the public API.
