---
title: Avoid Unnecessary Memoization
impact: HIGH
impactDescription: prevents complexity overhead and false sense of optimization
tags: performance, useMemo, useCallback, referential equality, rerender
---

## Avoid Unnecessary Memoization

Don't wrap every value in `useMemo` or every function in `useCallback`. These
hooks add complexity and indirection. Only memoize when there is a confirmed
performance problem — expensive computations or values passed to memoized
children where referential stability matters.

**Incorrect (memoizing a trivial operation):**

```tsx
const Component = ({ items }: { items: string[] }) => {
  const count = useMemo(() => items.length, [items]);
  const handleClick = useCallback(() => {
    console.log("clicked");
  }, []);

  return <Button onClick={handleClick}>{count} items</Button>;
};
```

Property access and simple callbacks are cheap. The hooks add overhead without
measurable benefit.

**Correct (derive inline, skip memoization):**

```tsx
const Component = ({ items }: { items: string[] }) => {
  return <Button onClick={() => console.log("clicked")}>{items.length} items</Button>;
};
```

Reserve `useMemo` for filtering/sorting large lists or expensive transforms.
Reserve `useCallback` for callbacks passed to children wrapped in `React.memo`.

---

## Non-Primitive Values Create New References Every Render

Objects, arrays, and functions declared inside a component are recreated on
every render. When passed as props or effect dependencies, they trigger
unnecessary re-renders or effect re-runs because React compares by reference,
not by value.

**Incorrect (new object every render):**

```tsx
const FilterPanel = ({ status }: { status: string }) => {
  const filters = { status, page: 1 };

  return <DataTable filters={filters} />;
};
```

`filters` is a new object reference on every render, so `DataTable` re-renders
even when `status` hasn't changed.

**Correct (memoize when referential stability matters):**

```tsx
const FilterPanel = ({ status }: { status: string }) => {
  const filters = useMemo(() => ({ status, page: 1 }), [status]);

  return <DataTable filters={filters} />;
};
```

**Incorrect (inline object in effect dependency):**

```tsx
const useFetchData = ({ endpoint, params }: { endpoint: string; params: Record<string, string> }) => {
  useEffect(() => {
    fetch(endpoint, { params });
  }, [endpoint, params]);
};

// Caller — new params object every render triggers the effect every render
const Page = () => {
  useFetchData({ endpoint: "/api/items", params: { status: "active" } });
};
```

**Correct (stabilize at the call site or destructure primitives):**

```tsx
const useFetchData = ({ endpoint, status }: { endpoint: string; status: string }) => {
  useEffect(() => {
    fetch(endpoint, { params: { status } });
  }, [endpoint, status]);
};
```

Prefer primitive dependencies in hooks and effects. When an object must be
passed, memoize it at the call site or destructure the primitives your hook
actually needs. See `react-best-practices/references/perf-narrow-effect-dependencies.md`
for more on narrowing dependencies.
