---
title: Component Folder Structure
impact: HIGH
impactDescription: keeps complex components navigable and imports predictable
tags: architecture, organization, file-structure
---

## Component Folder Structure

Complex components should live in a folder named after the component. The folder
contains an `index.ts` barrel file, a main component file matching the folder
name, and supporting files as needed. Simple components that are a single file
with no supporting logic do not need this structure.

**When to use a folder:** the component has types worth extracting, constants,
helper functions, tests, sub-components, or is expected to grow.

**When a single file is fine:** the component is small, self-contained, and
unlikely to gain supporting files.

**Incorrect (everything in one file):**

```
components/
└── ConditionsBuilder.tsx   ← 800+ lines mixing types, constants, helpers, sub-components
```

**Incorrect (missing barrel file or mismatched names):**

```
components/
└── ConditionsBuilder/
    ├── Main.tsx            ← doesn't match folder name
    ├── types.ts
    └── helpers.ts          ← no index.ts, consumers import deep paths
```

**Correct (complex component):**

```
ConditionsBuilder/
├── index.ts                    ← barrel: named exports for the public API
├── ConditionsBuilder.tsx       ← main component, matches folder name
├── ConditionsBuilder.styles.css ← scoped styles (optional)
├── types.ts                    ← shared type definitions
├── constants.ts                ← constants and config
├── helpers.ts                  ← utility functions
├── helpers.test.ts             ← co-located tests
├── Primitives/                 ← nested sub-component folder
│   ├── index.ts
│   └── Primitives.tsx
└── Fields/                     ← another nested sub-component folder
    ├── index.ts
    ├── OperatorField.tsx
    └── ArgumentField.tsx
```

The `index.ts` exports only the public API:

```tsx
export { ConditionsBuilder } from "./ConditionsBuilder";
export { OperatorField, ArgumentField } from "./Fields";
export { filterEmptyConditions } from "./helpers";
export type { ConditionSchema } from "./types";
```

Consumers import from the folder without knowing the internal structure:

```tsx
import { ConditionsBuilder, OperatorField } from "./ConditionsBuilder";
```

**Correct (simple component — folder not required):**

```
Avatar/
├── index.ts
└── Avatar.tsx
```

```tsx
// index.ts
export { Avatar, type AvatarProps } from "./Avatar";
```

If the component is trivially small, a standalone file without a folder is also
acceptable.

**`.styles.css` files** should be extremely rare — only for CSS genuinely
impossible through Telegraph props (targeting third-party elements via data
attributes, complex pseudo-selectors). Name it after the component and import
directly:

```css
/* Reasoning.styles.css */
[data-agent-conversation-reasoning] .agent-markdown .tgph-text {
  color: var(--tgph-gray-11);
}
```

```tsx
// Reasoning.tsx
import "./Reasoning.styles.css";
```

**Nested sub-components** follow the same pattern — own folder with `index.ts`
when they have supporting files, or a single file in a `components/` directory:

```
CodeEditor/
├── index.ts
├── CodeEditor.tsx
├── types.ts
├── constants.ts
├── hooks/
│   └── usePartialCompletions.tsx
└── components/
    ├── PopoutCodeEditor.tsx
    └── SingleLineCodeEditor.tsx
```
