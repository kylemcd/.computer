---
title: Derive Values During Rendering Instead of Syncing with Effects
impact: HIGH
impactDescription: eliminates redundant state, extra render passes, and state-sync bugs
tags: useEffect, derived-state, rendering, redundant-state
---

## Derive Values During Rendering Instead of Syncing with Effects

If a value can be calculated from existing props or state, compute it during
rendering. Do not store it in state and sync it with an effect — that causes an
extra render with a stale value and risks state getting out of sync.

**Incorrect (redundant state synced via effect):**

```tsx
const Form = () => {
  const [firstName, setFirstName] = useState("Taylor");
  const [lastName, setLastName] = useState("Swift");

  // Redundant state + unnecessary effect
  const [fullName, setFullName] = useState("");
  useEffect(() => {
    setFullName(firstName + " " + lastName);
  }, [firstName, lastName]);

  return <Text>{fullName}</Text>;
};
```

**Correct (derived during render):**

```tsx
const Form = () => {
  const [firstName, setFirstName] = useState("Taylor");
  const [lastName, setLastName] = useState("Swift");

  // Computed inline — always in sync, single render pass
  const fullName = firstName + " " + lastName;

  return <Text>{fullName}</Text>;
};
```

### Deriving filtered/transformed lists

**Incorrect:**

```tsx
const [visibleTodos, setVisibleTodos] = useState([]);
useEffect(() => {
  setVisibleTodos(todos.filter((t) => !t.completed));
}, [todos]);
```

**Correct:**

```tsx
const visibleTodos = todos.filter((t) => !t.completed);
```

If the computation is expensive, wrap it in `useMemo` — not an effect:

```tsx
const visibleTodos = useMemo(
  () => getFilteredTodos(todos, filter),
  [todos, filter]
);
```

### Storing a derived ID instead of a derived object

**Incorrect (resetting selection via effect):**

```tsx
const [selection, setSelection] = useState<Item | null>(null);
useEffect(() => {
  setSelection(null);
}, [items]);
```

**Correct (derived from a stable ID):**

```tsx
const [selectedId, setSelectedId] = useState<string | null>(null);
const selection = items.find((item) => item.id === selectedId) ?? null;
```

### Checklist

- Can this value be computed from props or state? If yes, derive it inline.
- Is the computation expensive (>1ms on throttled CPU)? Use `useMemo`.
- Does a selection/reference depend on a changing list? Store the ID, derive the object.

Reference: [You Might Not Need an Effect — Updating state based on props or state](https://react.dev/learn/you-might-not-need-an-effect#updating-state-based-on-props-or-state)
