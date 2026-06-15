---
title: Use useSyncExternalStore for External Subscriptions
impact: MEDIUM
impactDescription: prevents tearing and simplifies manual subscription/cleanup effects
tags: useSyncExternalStore, useEffect, subscriptions, external-store
---

## Use useSyncExternalStore for External Subscriptions

When subscribing to data outside of React state (browser APIs, third-party
stores, global variables), use `useSyncExternalStore` instead of a manual
`useState` + `useEffect` subscription. It handles subscription lifecycle,
avoids tearing during concurrent renders, and supports server rendering.

**Incorrect (manual subscription in effect):**

```tsx
const useOnlineStatus = () => {
  const [isOnline, setIsOnline] = useState(true);

  useEffect(() => {
    const update = () => setIsOnline(navigator.onLine);
    update();
    window.addEventListener("online", update);
    window.addEventListener("offline", update);
    return () => {
      window.removeEventListener("online", update);
      window.removeEventListener("offline", update);
    };
  }, []);

  return isOnline;
};
```

**Correct (useSyncExternalStore):**

```tsx
const subscribe = (callback: () => void) => {
  window.addEventListener("online", callback);
  window.addEventListener("offline", callback);
  return () => {
    window.removeEventListener("online", callback);
    window.removeEventListener("offline", callback);
  };
};

const useOnlineStatus = () =>
  useSyncExternalStore(
    subscribe,
    () => navigator.onLine, // client snapshot
    () => true // server snapshot
  );
```

### When to use

- Subscribing to `window` events (`online`/`offline`, `resize`, `storage`).
- Reading from browser APIs (`matchMedia`, `IntersectionObserver`).
- Integrating with non-React state libraries that expose a subscribe function.

### When NOT to use

- Data already managed by React state or context — use `useState`/`useContext`.
- Data fetched from a network — use Apollo, React Query, or a framework's
  data-fetching mechanism.

Reference: [You Might Not Need an Effect — Subscribing to an external store](https://react.dev/learn/you-might-not-need-an-effect#subscribing-to-an-external-store)
