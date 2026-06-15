---
title: Subscribe to Derived State
impact: MEDIUM
impactDescription: reduces re-render frequency
tags: rerender, derived-state, media-query, optimization
---

## Subscribe to Derived State

Subscribe to derived boolean state instead of continuous values to reduce
re-render frequency. When a component only cares about a threshold (mobile vs.
desktop, empty vs. non-empty), subscribe to the derived boolean — not the raw
value it was computed from.

**Incorrect (re-renders on every pixel change):**

```tsx
const Sidebar = () => {
  const width = useWindowWidth();
  const isMobile = width < 768;

  return (
    <Stack direction={isMobile ? "column" : "row"}>
      <Navigation />
    </Stack>
  );
};
```

The component re-renders every time `width` changes (e.g. 767, 766, 765...),
even though the layout only changes at the 768 threshold.

**Correct (re-renders only when boolean changes):**

```tsx
const Sidebar = () => {
  const isMobile = useMediaQuery("(max-width: 767px)");

  return (
    <Stack direction={isMobile ? "column" : "row"}>
      <Navigation />
    </Stack>
  );
};
```

The hook internally subscribes to the media query and only triggers a re-render
when the boolean result flips.

---

### Derived state from collections

The same principle applies to collections. If you only need a count or an
emptiness check, derive it before subscribing.

**Incorrect (re-renders when any item changes):**

```tsx
const ItemList = ({ items }: { items: Item[] }) => {
  const [showEmpty, setShowEmpty] = useState(items.length === 0);

  useEffect(() => {
    setShowEmpty(items.length === 0);
  }, [items]);

  if (showEmpty) return <EmptyState />;
  return <DataTable data={items} />;
};
```

Stores redundant state that mirrors `items.length === 0`, and the effect
re-runs on every items reference change.

**Correct (derive inline, no extra state):**

```tsx
const ItemList = ({ items }: { items: Item[] }) => {
  const isEmpty = items.length === 0;

  if (isEmpty) return <EmptyState />;
  return <DataTable data={items} />;
};
```

No `useState` or `useEffect` needed — the boolean is derived directly from
props each render. See
`react-best-practices/references/perf-narrow-effect-dependencies.md` for
narrowing effect dependencies to primitives.
