---
name: typescript-best-practices
description: Use when writing, reviewing, or refactoring TypeScript code within the /dashboard directory to ensure type-safe and consistent code. Trigger on tasks involving TypeScript files, type definitions, and utility functions.
---

# Knock TypeScript best practices

Comprehensive guide to writing TypeScript code at Knock. Contains 10 rules
across 2 categories.

## When to apply

- Writing new TypeScript files, utility functions, or type definitions.
- Reviewing TypeScript code for type safety and consistency.
- Refactoring existing TypeScript code.

## Rule Categories by Priority

| Priority | Category    | Impact | Prefix         |
| -------- | ----------- | ------ | -------------- |
| 1        | Foundations | HIGH   | `foundations-` |
| 2        | Code Style  | MEDIUM | `style-`       |

## Quick Reference

### 0. Always Read (CRITICAL)

Read these reference files before writing any code:

- `references/foundations-barrel-imports.md` - Import directly from source files (e.g., `lucide-react/dist/esm/icons/check`) instead of barrel files to avoid loading unused modules, or configure `optimizePackageImports` in `next.config.js`.
- `references/style-code-conventions.md` - Always use `const` arrow functions (never `function` declarations), `const` by default (only `let` for genuine reassignment), and prefer array methods (`map`, `filter`, `reduce`, `find`, `some`, `every`, `flatMap`) over `for` loops.

### 1. Foundations (HIGH)

- `references/foundations-testing.md` - Write tests for shared helpers, validators, and transformers with non-trivial logic in `filename.test.ts`. When fixing bugs, write a failing test first, then fix, then verify the test passes.

### 2. Code Style (MEDIUM)

- `references/style-async-await-over-then.md` - Always use `async`/`await` with `try`/`catch` instead of `.then`/`.catch` chains. Don't update state in Apollo `onCompleted`/`onError` callbacks — handle mutation logic at the call site.
- `references/style-defining-types.md` - Use `type` for all type definitions (not `interface`). Use objects with `as const` instead of `enum` (e.g., `const CHANNEL_TYPES = { push: "push" } as const; type ChannelType = (typeof CHANNEL_TYPES)[keyof typeof CHANNEL_TYPES]`).
- `references/style-error-handling.md` - Guard against missing data with early returns (`if (!data) return null`), provide fallback UI for loading/error/empty states, wrap async in `try`/`catch`, narrow `unknown` errors (`error instanceof Error ? error.message : "..."`).
- `references/style-descriptive-comments.md` - Only comment non-obvious "why" logic, workarounds, business rules, and constraints — never narrate what code does. Complex components should have a block comment at the top describing what they do and when to use them.
- `references/style-early-exit.md` - Use early returns and guard clauses to keep functions flat. Check preconditions at the top (`if (!order) return { error: "..." }`). Avoid nested `if`/`else` blocks and unnecessary `else` clauses.
- `references/style-named-exports.md` - Always use named exports (`export const formatDate`, `export type ButtonProps`) — never `export default` or `export *`. Barrel files use explicit named re-exports (`export { Button } from "./Button"`).
- `references/style-no-duplicate-types.md` - Consolidate identical or near-identical type definitions into one. If two types have the same shape and represent the same concept, use one type.
