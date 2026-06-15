---
title: Reset Component State with key Instead of Effects
impact: HIGH
impactDescription: avoids stale-value renders and eliminates manual state-reset effects
tags: useEffect, key, state-reset, props
---

## Reset Component State with key Instead of Effects

When a component should fully reset its internal state in response to a prop
change (e.g., navigating between profiles), pass a `key` tied to the identity
prop. Do not reset state in an effect — that renders once with stale values
before the effect fires.

**Incorrect (resetting state via effect):**

```tsx
const ProfilePage = ({ userId }: { userId: string }) => {
  const [comment, setComment] = useState("");

  // Renders once with the previous user's comment, then clears it
  useEffect(() => {
    setComment("");
  }, [userId]);

  return <Input value={comment} onValueChange={setComment} />;
};
```

Every nested component with state would also need its own reset effect.

**Correct (key-based reset):**

```tsx
const ProfilePage = ({ userId }: { userId: string }) => {
  return <Profile userId={userId} key={userId} />;
};

const Profile = ({ userId }: { userId: string }) => {
  // Automatically resets when key (userId) changes
  const [comment, setComment] = useState("");

  return <Input value={comment} onValueChange={setComment} />;
};
```

React treats components with different `key` values as distinct instances,
unmounting the old one and mounting a fresh one. All nested state resets
automatically — no effects needed.

### When to use this pattern

- Switching between user profiles, tabs, or detail views where all form state
  should reset.
- Any scenario where the entire subtree should start fresh when an identity
  prop changes.

### When NOT to use this pattern

If you only need to adjust _part_ of the state while keeping the rest, derive
the value during rendering instead (see
`react-best-practices/references/state-derive-during-render.md`).

Reference: [You Might Not Need an Effect — Resetting all state when a prop changes](https://react.dev/learn/you-might-not-need-an-effect#resetting-all-state-when-a-prop-changes)
