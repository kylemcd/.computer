---
title: Do Not Wrap Simple Primitive Expressions in useMemo
impact: MEDIUM
impactDescription: wasted computation on every render
tags: rerender, useMemo, optimization
---

## Do Not Wrap Simple Primitive Expressions in useMemo

When an expression is simple (few logical or arithmetic operators) and returns
a primitive (boolean, number, string), don't wrap it in `useMemo`. The overhead
of calling `useMemo` and comparing dependencies is likely greater than the
expression itself.

**Incorrect:**

```tsx
const Header = ({ user, notifications }: HeaderProps) => {
  const isLoading = useMemo(() => {
    return user.isLoading || notifications.isLoading;
  }, [user.isLoading, notifications.isLoading]);

  if (isLoading) return <Skeleton />;
  return <Box>...</Box>;
};
```

**Correct:**

```tsx
const Header = ({ user, notifications }: HeaderProps) => {
  const isLoading = user.isLoading || notifications.isLoading;

  if (isLoading) return <Skeleton />;
  return <Box>...</Box>;
};
```

### When useMemo *is* warranted

Reserve `useMemo` for expensive computations (filtering/sorting large lists,
complex transforms) or when referential stability matters (objects/arrays
passed to memoized children). See
`react-best-practices/references/perf-avoid-unnecessary-memoization.md` for
the full guidance on when to memoize.
