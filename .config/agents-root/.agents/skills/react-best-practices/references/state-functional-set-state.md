---
title: Use Functional setState Updates
impact: MEDIUM
impactDescription: prevents stale closures and unnecessary callback recreations
tags: react, hooks, useState, useCallback, callbacks, closures
---

## Use Functional setState Updates

When updating state based on the current state value, use the functional update
form of setState instead of directly referencing the state variable. This
prevents stale closures, eliminates unnecessary dependencies, and creates
stable callback references.

**Incorrect (requires state as dependency):**

```tsx
function TodoList() {
  const [items, setItems] = useState(initialItems);

  // Callback must depend on items, recreated on every items change
  const addItems = useCallback((newItems: Item[]) => {
    setItems([...items, ...newItems]);
  }, [items]); // items dependency causes recreations

  // Risk of stale closure if dependency is forgotten
  const removeItem = useCallback((id: string) => {
    setItems(items.filter((item) => item.id !== id));
  }, []); // missing items dependency — will use stale items
  
  return <ItemsEditor items={items} onAdd={addItems} onRemove={removeItem} />;
}
```

The first callback is recreated every time `items` changes, which can cause
child components to re-render unnecessarily. The second callback has a stale
closure bug — it will always reference the initial `items` value.

**Correct (stable callbacks, no stale closures):**

```tsx
function TodoList() {
  const [items, setItems] = useState(initialItems);

  const addItems = useCallback((newItems: Item[]) => {
    setItems((curr) => [...curr, ...newItems]);
  }, []);

  const removeItem = useCallback((id: string) => {
    setItems((curr) => curr.filter((item) => item.id !== id));
  }, []);
  
  return <ItemsEditor items={items} onAdd={addItems} onRemove={removeItem} />;
}
```

### When to use functional updates

- Any setState that depends on the current state value
- Inside `useCallback`/`useMemo` when state is needed
- Event handlers that reference state
- Async operations that update state

### When direct updates are fine

- Setting state to a static value: `setCount(0)`
- Setting state from props/arguments only: `setName(newName)`
- State doesn't depend on previous value

If [React Compiler](https://react.dev/learn/react-compiler) is enabled it can
optimize some cases automatically, but functional updates are still recommended
for correctness and to prevent stale closure bugs.
