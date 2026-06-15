---
title: Extract to Memoized Components
impact: MEDIUM
impactDescription: enables early returns
tags: rerender, memo, useMemo, optimization
---

## Extract to Memoized Components

Extract expensive work into memoized components to enable early returns before
computation. When a parent has an early return (loading, error), any `useMemo`
in that parent still runs on every render where the early return doesn't fire.
Moving the expensive work into a child component lets React skip it entirely
via `memo`.

**Incorrect (computes avatar even when loading):**

```tsx
function Profile({ user, loading }: Props) {
  const avatar = useMemo(() => {
    const id = computeAvatarId(user);
    return <Avatar id={id} />;
  }, [user]);

  if (loading) return <Skeleton />;
  return <Box>{avatar}</Box>;
}
```

`useMemo` runs before the `loading` check, so `computeAvatarId` executes on
every render regardless.

**Correct (skips computation when loading):**

```tsx
const UserAvatar = memo(function UserAvatar({ user }: { user: User }) {
  const id = useMemo(() => computeAvatarId(user), [user]);
  return <Avatar id={id} />;
});

function Profile({ user, loading }: Props) {
  if (loading) return <Skeleton />;
  return (
    <Box>
      <UserAvatar user={user} />
    </Box>
  );
}
```

When `loading` is true, `UserAvatar` never renders and `computeAvatarId` never
runs. When `loading` is false, `memo` prevents re-renders unless `user`
changes. This pattern pairs well with compound component extraction — see
`react-best-practices/references/architecture-compound-components.md`.
