---
title: Add Cleanup to Data-Fetching Effects to Prevent Race Conditions
impact: MEDIUM
impactDescription: prevents displaying stale/wrong data from out-of-order network responses
tags: useEffect, fetch, race-condition, cleanup, data-fetching
---

## Add Cleanup to Data-Fetching Effects to Prevent Race Conditions

When fetching data in an effect, always return a cleanup function that ignores
stale responses. Without cleanup, fast-changing dependencies (e.g., a search
query) fire multiple requests whose responses can arrive out of order, showing
data for an old query.

**Incorrect (no cleanup — race condition):**

```tsx
const SearchResults = ({ query }: { query: string }) => {
  const [results, setResults] = useState([]);

  useEffect(() => {
    fetchResults(query).then((json) => {
      setResults(json); // May set results for an outdated query
    });
  }, [query]);
};
```

**Correct (cleanup ignores stale responses):**

```tsx
const SearchResults = ({ query }: { query: string }) => {
  const [results, setResults] = useState([]);

  useEffect(() => {
    let ignore = false;

    fetchResults(query).then((json) => {
      if (!ignore) {
        setResults(json);
      }
    });

    return () => {
      ignore = true;
    };
  }, [query]);
};
```

### Prefer dedicated data-fetching solutions

In this codebase, prefer Apollo Client hooks (`useQuery`, `useLazyQuery`) or
custom data hooks over raw `useEffect` + `fetch`. These tools handle
cancellation, caching, and race conditions out of the box.

Only use the manual pattern above when a dedicated solution isn't available
(e.g., one-off non-GraphQL fetches).

### Checklist

- Every `fetch`/`axios`/`post` call inside a `useEffect` must have a cleanup
  function that either sets an `ignore` flag or aborts the request via
  `AbortController`.
- If the effect depends on a value that changes frequently (search input,
  pagination), cleanup is critical.

Reference: [You Might Not Need an Effect — Fetching data](https://react.dev/learn/you-might-not-need-an-effect#fetching-data)
