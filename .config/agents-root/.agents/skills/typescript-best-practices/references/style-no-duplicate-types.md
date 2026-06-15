---
title: Consolidate Duplicate Types
impact: MEDIUM
impactDescription: reduces maintenance burden and prevents type drift
tags: types, DRY, refactoring
---

## Consolidate Duplicate Types

When two types have identical or near-identical shapes, consolidate them into
one. Duplicate types create maintenance burden and can drift apart over time.

**Incorrect (duplicate types):**

```tsx
type StatusIconProps = {
  status: string | null | undefined;
  referenceType: AudienceReferenceType;
  activeUntil?: string | null;
};

type StatusIconInput = {
  status: string | null | undefined;
  referenceType: AudienceReferenceType;
  activeUntil?: string | null;
};

const getStatusIconProps = (input: StatusIconInput) => { ... };
const StatusIcon = (props: StatusIconProps) => { ... };
```

These types are identical. If one changes, the other should too—but they can
easily drift apart.

**Correct (single type):**

```tsx
type StatusIconProps = {
  status: string | null | undefined;
  referenceType: AudienceReferenceType;
  activeUntil?: string | null;
};

const getStatusIconProps = (props: StatusIconProps) => { ... };
const StatusIcon = (props: StatusIconProps) => { ... };
```

### When separate types are appropriate

- Types have the same shape *now* but represent different concepts that may diverge
- One type is a subset of another (use `Pick<T, K>` or `Omit<T, K>` instead)
- Types are in different modules with no shared dependency

```tsx
// Good: ApiUser and DisplayUser have similar shapes but different purposes
type ApiUser = { id: string; email: string; createdAt: string };
type DisplayUser = { id: string; email: string; displayName: string };

// Good: Derived type using Pick
type UserSummary = Pick<User, "id" | "email">;
```
