---
name: react-best-practices
description: Use when writing, reviewing, or refactoring react code within the /dashboard directory to ensure clean and consistent code. Trigger on tasks involving react components and next.js pages.
---

# Knock react best practices

Comprehensive guide to writing react and next.js code at Knock. Contains 32
rules across 4 categories, prioritized by impact to guide code generation and
review.

## When to apply

- Writing new react components or next.js pages.
- Reviewing react components or next.js pages.
- Refactoring existing react components or next.js pages.

## Rule Categories by Priority

| Priority | Category                | Impact | Prefix          |
| -------- | ----------------------- | ------ | --------------- |
| 1        | Component Architecture  | HIGH   | `architecture-` |
| 2        | Performance             | HIGH   | `perf-`         |
| 3        | State Management        | MEDIUM | `state-`        |
| 4        | Implementation Patterns | MEDIUM | `patterns-`     |

## Quick Reference

### 0. Always Read (CRITICAL)

Read these reference files before writing any code:

- `references/patterns-use-telegraph-primitives.md` - Always use Telegraph primitives (`Box`, `Stack`, `Text`, `Button`, `Icon`) from `@telegraph/*` instead of `@chakra-ui/react` or raw HTML. Use token-based props (`bg`, `p`, `rounded`, `gap`) over inline `style`. Use `tgphRef` instead of `ref` for refs. When you edit or import from a file with Chakra imports and the swap is trivial, ask the user before migrating.
- `references/patterns-telegraph-package-readmes.md` - Fetch the README from `https://raw.githubusercontent.com/knocklabs/telegraph/main/packages/<package-name>/README.md` for any `@telegraph/*` package used for the first time or with unverified sub-components/props. Skip when following existing usage patterns in the file.

### 1. Component Architecture (HIGH)

- `references/architecture-avoid-boolean-props.md` - Replace boolean props like `isThread`, `isEditing`, `isDMThread` with explicit variant components (`ThreadComposer`, `EditComposer`, `DMThreadComposer`) that compose only the pieces they need.
- `references/architecture-compound-components.md` - Structure complex components as compound components with shared context. Export as `ComponentName.Frame`, `ComponentName.Input`, `ComponentName.Submit`, etc. Subcomponents access shared state via context, not props.
- `references/architecture-css-data-attributes.md` - Use `data-component-name` attributes (e.g., `data-branch-switcher-button`) for CSS targeting, never `className` strings. Only use `.styles.css` for transitions, pseudo-selectors, or targeting third-party elements.
- `references/architecture-headless-compound-components.md` - For complex reusable components, use two layers: `Primitives/` with logic-only contexts and render props, and a styled layer wrapping Primitives. Export both so consumers can override rendering while sharing logic.
- `references/architecture-folder-structure.md` - Complex components: `ComponentName/` folder with `index.ts` barrel, `ComponentName.tsx` main file matching folder name, and supporting files (`types.ts`, `helpers.ts`, `constants.ts`). Simple components can be single files.
- `references/architecture-no-jsx-outside-return.md` - Never store JSX in variables (`const content = <JSX />`) or local render functions (`const renderX = () => <JSX />`). Extract complex sections as proper sibling components with their own props.

### 2. Performance (HIGH)

- `references/perf-avoid-unnecessary-memoization.md` - Only memoize for confirmed performance problems (expensive computations or values passed to memoized children). Don't wrap trivial operations like `items.length` or simple callbacks in `useMemo`/`useCallback`.
- `references/perf-extract-memoized-components.md` - Extract expensive work into `memo`-wrapped child components to enable early returns. When a parent has an early return, `useMemo` still runs; a memoized child lets React skip it entirely.
- `references/perf-narrow-effect-dependencies.md` - Depend on primitives (`user.id`) instead of objects (`user`) in `useEffect`. For derived state, compute outside the effect (`const isMobile = width < 768`) and depend on the boolean.
- `references/perf-skip-memo-for-primitives.md` - Don't wrap simple primitive expressions (e.g., `user.isLoading || notifications.isLoading`) in `useMemo`. The overhead of `useMemo` exceeds the expression cost.
- `references/perf-subscribe-derived-state.md` - Subscribe to derived booleans (`useMediaQuery("(max-width: 767px)")`) instead of continuous values (`useWindowWidth()`). Derive booleans inline (`const isEmpty = items.length === 0`) rather than storing redundant state.
- `references/perf-useref-for-transient-values.md` - Use `useRef` for values that change frequently but don't drive UI (mouse trackers, interval IDs, previous values, debounce flags). Reserve `useState` for values the component renders.
- `references/perf-usesyncexternalstore.md` - Use `useSyncExternalStore` instead of manual `useState` + `useEffect` subscriptions for external data (browser APIs, third-party stores). It prevents tearing in concurrent renders and simplifies cleanup.

### 3. State Management (MEDIUM)

- `references/state-decouple-implementation.md` - Providers own how state is managed (`useState`, Formik, redux). UI components consume only the context interface (`state`, `actions`, `meta`) and don't know the implementation.
- `references/state-derive-during-render.md` - If a value can be calculated from existing props or state, compute it inline during rendering. Do not store it in state and sync it with an effect — that causes an extra render with stale values.
- `references/state-fetch-with-cleanup.md` - Every `fetch`/`axios` call inside a `useEffect` must have a cleanup function that sets an `ignore` flag or aborts via `AbortController` to prevent race conditions from out-of-order responses. Prefer Apollo hooks when available.
- `references/state-interaction-logic-in-handlers.md` - Put interaction logic in event handlers (`onClick`, `onSubmit`), not state + effect. Don't model actions as `useState(false)` with a `useEffect` watching it — run side effects directly in the handler.
- `references/state-functional-set-state.md` - Use functional setState (`setItems((curr) => [...curr, ...newItems])`) when updating based on current state to prevent stale closures and create stable callback references.
- `references/state-lazy-initialization.md` - Pass a function to `useState` for expensive initial values (`useState(() => buildSearchIndex(items))`) so the initializer runs only once, not on every render.
- `references/state-lift-state.md` - Move state into dedicated provider components so sibling components outside the main UI can access/modify state via context without prop drilling or refs.
- `references/state-no-effect-chains.md` - Do not chain multiple effects where each sets state that triggers the next. Compute derived values during rendering and batch related state updates in the originating event handler.
- `references/state-notify-parent-in-handler.md` - Notify parent components about state changes in the event handler that triggers the change, not in an effect watching the state. This avoids an extra render pass.
- `references/state-reset-with-key.md` - When a component should fully reset its state in response to a prop change, pass a `key` tied to the identity prop. Do not reset state fields individually in an effect.
- `references/state-status-over-booleans.md` - Use a single status union (`"idle" | "loading" | "error" | "success"`) instead of multiple booleans (`isLoading`, `isError`). Derive status from library booleans at the query boundary.

### 4. Implementation Patterns (MEDIUM)

- `references/patterns-accessibility.md` - Every interactive element needs an accessible name. Use `icon={{ icon: Trash, alt: "Delete item" }}` for icon-only buttons, `aria-hidden` for decorative icons, `a11yTitle` for modals, link inputs to labels with `aria-labelledby`.
- `references/patterns-children-over-render-props.md` - Use `children` for composition instead of `renderX` props. Only use render props when the parent provides data to the child (e.g., `renderItem={({ item, index }) => <Item />}`).
- `references/patterns-descriptive-callback-props.md` - Use descriptive controlled prop pairs: `value`/`onValueChange`, `open`/`onOpenChange`, `checked`/`onCheckedChange`. Avoid generic `onChange`, Chakra patterns like `isOpen`/`onClose`, or leaking setters like `setSelectedUsers`.
- `references/patterns-explicit-variants.md` - Create explicit variant components (`ThreadComposer`, `EditMessageComposer`) instead of one component with many boolean props. Each variant composes what it needs and is self-documenting.
- `references/patterns-import-react-directly.md` - Import React hooks and types as named imports (`import { useState, type ReactNode } from "react"`) and call them bare. Never import the default `React` namespace to reach `React.useState`/`React.ReactNode`. Convert a whole file when you touch one that still uses the namespace.
- `references/patterns-testing.md` - Write tests for complex, widely reused components using Vitest + RTL. Test files: `ComponentName.test.tsx` alongside the component. Prefer `userEvent` over `fireEvent`. Test error cases, empty states, and validation failures.
- `references/patterns-no-redundant-comments.md` - Don't add comments that restate what the code does. Comments should explain _why_ (business rules, workarounds, constraints), not _what_. Self-documenting code with clear names is preferred.
