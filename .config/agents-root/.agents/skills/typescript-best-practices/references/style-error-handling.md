---
title: Handle Error Cases Explicitly
impact: HIGH
impactDescription: prevents silent failures and unhandled edge cases
tags: errors, error-handling, edge-cases, guard-clauses, validation
---

## Handle Error Cases Explicitly

Always handle the unhappy path. Don't assume data exists, operations succeed,
or inputs are valid. Every function, component, and async operation should
account for what happens when things go wrong.

### Guard against missing data

**Incorrect (assumes data exists):**

```tsx
const WorkflowHeader = ({ workflow }: WorkflowHeaderProps) => {
  return (
    <Stack direction="row" gap="2">
      <Text as="h1">{workflow.name}</Text>
      <Text as="span" color="gray">{workflow.steps.length} steps</Text>
    </Stack>
  );
};
```

If `workflow` is `null` or `steps` is `undefined`, this crashes.

**Correct (handle missing data):**

```tsx
const WorkflowHeader = ({ workflow }: WorkflowHeaderProps) => {
  if (!workflow) return null;

  return (
    <Stack direction="row" gap="2">
      <Text as="h1">{workflow.name}</Text>
      <Text as="span" color="gray">{workflow.steps?.length ?? 0} steps</Text>
    </Stack>
  );
};
```

### Return early for invalid states

Check preconditions at the top of functions and return early. Don't nest the
happy path inside defensive checks.

**Incorrect:**

```tsx
const processItems = (items: Item[] | undefined) => {
  if (items) {
    if (items.length > 0) {
      return items.map((item) => transform(item));
    } else {
      return [];
    }
  } else {
    return [];
  }
};
```

**Correct:**

```tsx
const processItems = (items: Item[] | undefined) => {
  if (!items || items.length === 0) return [];

  return items.map((item) => transform(item));
};
```

### Provide fallback UI for error states

Components that fetch data or depend on external state should always render
something meaningful when things fail — not just crash or show a blank screen.

```tsx
const ChannelDetail = ({ channelId }: ChannelDetailProps) => {
  const { data, loading, error } = useQuery(GET_CHANNEL, {
    variables: { id: channelId },
  });

  if (loading) return <Skeleton />;
  if (error) return <Text color="red">Failed to load channel</Text>;
  if (!data?.channel) return <EmptyState title="Channel not found" />;

  return <ChannelEditor channel={data.channel} />;
};
```

### Handle async errors at every call site

Every `await` that can fail needs a `try`/`catch` or the error propagates
unhandled. See
`typescript-best-practices/references/style-async-await-over-then.md`.

```tsx
const handleDelete = async (id: string) => {
  try {
    await deleteItem({ variables: { input: { id } } });
    toast({ title: "Deleted", status: "success", position: "bottom-right" });
  } catch (error) {
    toast({
      title: "Failed to delete",
      description: error instanceof Error ? error.message : "Unknown error",
      status: "error",
      position: "bottom-right",
    });
  }
};
```

### Narrow unknown errors

Caught errors are `unknown`. Narrow them before accessing properties.

**Incorrect:**

```tsx
catch (error) {
  toast({ title: error.message, status: "error" });
}
```

**Correct:**

```tsx
catch (error) {
  const message = error instanceof Error ? error.message : "An unexpected error occurred";
  toast({ title: message, status: "error", position: "bottom-right" });
}
```

### Checklist

- [ ] Components handle `null`/`undefined` data without crashing
- [ ] Loading, error, and empty states are rendered explicitly
- [ ] Async operations are wrapped in `try`/`catch`
- [ ] Caught errors are narrowed from `unknown` before use
- [ ] Optional chaining (`?.`) and nullish coalescing (`??`) are used where
      data may be missing
