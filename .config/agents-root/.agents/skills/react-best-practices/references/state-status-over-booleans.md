---
title: Use a Status Union Over Multiple Booleans
impact: HIGH
impactDescription: eliminates impossible states and simplifies conditional logic
tags: state, booleans, union, status, discriminated-union
---

## Use a Status Union Over Multiple Booleans

Represent mutually exclusive states with a single status string union instead of
multiple boolean variables. Booleans create impossible combinations
(`isLoading && isError && isSuccess` can all be true simultaneously), lead to
defensive checks, and make it hard to reason about which state the component is
actually in.

**Incorrect (multiple booleans, impossible states possible):**

```tsx
const ChannelStatus = ({ channelId }: ChannelStatusProps) => {
  const [isLoading, setIsLoading] = useState(true);
  const [isError, setIsError] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);

  if (isLoading) return <Skeleton />;
  if (isError) return <Text color="red">Failed to load</Text>;
  if (isSuccess) return <Text color="green">Connected</Text>;
  return null;
};
```

Nothing prevents `isLoading` and `isError` from both being true. Every
consumer must check booleans in the right order.

**Correct (single status union, impossible states impossible):**

```tsx
type Status = "idle" | "loading" | "error" | "success";

const ChannelStatus = ({ channelId }: ChannelStatusProps) => {
  const [status, setStatus] = useState<Status>("loading");

  if (status === "loading") return <Skeleton />;
  if (status === "error") return <Text color="red">Failed to load</Text>;
  if (status === "success") return <Text color="green">Connected</Text>;
  return null;
};
```

Only one state is active at a time. Adding a new state (e.g., `"retrying"`) is
a single union member, not another boolean plus new conditional ordering.

---

### Derive status from library booleans

Libraries like Apollo return boolean flags (`loading`, `error`, `data`). Don't
pass these booleans through your components individually. Derive a status
string at the boundary and use that downstream.

**Incorrect (spreading library booleans through the component):**

```tsx
const WorkflowPage = ({ slug }: WorkflowPageProps) => {
  const { data, loading, error } = useQuery(GET_WORKFLOW, {
    variables: { slug },
  });

  return (
    <WorkflowDetail
      workflow={data?.workflow}
      isLoading={loading}
      isError={!!error}
      isEmpty={!loading && !error && !data?.workflow}
    />
  );
};
```

`WorkflowDetail` now has three boolean props that duplicate the same state
machine Apollo already manages.

**Correct (derive a status at the query boundary):**

```tsx
type WorkflowStatus = "loading" | "error" | "empty" | "ready";

const deriveStatus = (
  loading: boolean,
  error: unknown,
  data: unknown,
): WorkflowStatus => {
  if (loading) return "loading";
  if (error) return "error";
  if (!data) return "empty";
  return "ready";
};

const WorkflowPage = ({ slug }: WorkflowPageProps) => {
  const { data, loading, error } = useQuery(GET_WORKFLOW, {
    variables: { slug },
  });

  const status = deriveStatus(loading, error, data?.workflow);

  if (status === "loading") return <Skeleton />;
  if (status === "error") return <Text color="red">Failed to load</Text>;
  if (status === "empty") return <EmptyState />;

  return <WorkflowDetail workflow={data!.workflow} />;
};
```

The status derivation happens once at the query boundary. Downstream
components receive either the resolved data or nothing — no boolean
combinations to manage.
