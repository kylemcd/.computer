---
title: Use useRef for Transient Values
impact: MEDIUM
impactDescription: avoids unnecessary re-renders on frequent updates
tags: rerender, useref, state, performance
---

## Use useRef for Transient Values

When a value changes frequently and doesn't need to drive UI updates (e.g.,
mouse trackers, intervals, transient flags), store it in `useRef` instead of
`useState`. Updating a ref does not trigger a re-render. Reserve `useState`
for values the component renders.

**Incorrect (re-renders on every mouse move):**

```tsx
const Tracker = () => {
  const [lastX, setLastX] = useState(0);

  useEffect(() => {
    const onMove = (e: MouseEvent) => setLastX(e.clientX);
    window.addEventListener("mousemove", onMove);
    return () => window.removeEventListener("mousemove", onMove);
  }, []);

  return (
    <Box
      position="fixed"
      top="0"
      w="2"
      h="2"
      bg="gray-12"
      style={{ left: lastX }}
    />
  );
};
```

Every pixel of mouse movement triggers a state update and full re-render.

**Correct (updates DOM directly, no re-render):**

```tsx
const Tracker = () => {
  const lastXRef = useRef(0);
  const dotRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const onMove = (e: MouseEvent) => {
      lastXRef.current = e.clientX;
      if (dotRef.current) {
        dotRef.current.style.transform = `translateX(${e.clientX}px)`;
      }
    };
    window.addEventListener("mousemove", onMove);
    return () => window.removeEventListener("mousemove", onMove);
  }, []);

  return (
    <Box
      tgphRef={dotRef}
      position="fixed"
      top="0"
      w="2"
      h="2"
      bg="gray-12"
      style={{ transform: "translateX(0px)" }}
    />
  );
};
```

### Other common useRef-over-useState cases

- **Interval/timeout IDs** — stored to clear later, never rendered.
- **Previous value tracking** — comparing current vs. previous without
  re-rendering on every change.
- **Debounce flags** — marking whether a debounced action is pending.

If the value drives visible UI, use `useState`. If it's bookkeeping that other
code reads imperatively, use `useRef`.
