---
title: Keep JSX in the Return Statement
impact: HIGH
impactDescription: prevents broken reconciliation and hidden component boundaries
tags: jsx, architecture, components, render, extract
---

## Keep JSX in the Return Statement

Never store JSX in variables or local render functions inside a component body.
It breaks React's reconciliation (elements remount instead of updating),
prevents memoization, and hides component boundaries that should be explicit.
If a section of JSX is complex enough to name, extract it as a proper
component.

**Incorrect (JSX in a variable):**

```tsx
const ChannelList = ({ channels, isLoading }: ChannelListProps) => {
  const content = isLoading ? (
    <Skeleton />
  ) : (
    <Stack direction="column" gap="2">
      {channels.map((ch) => (
        <ChannelRow key={ch.id} channel={ch} />
      ))}
    </Stack>
  );

  return (
    <Box p="4">
      <Text as="h2" size="3">Channels</Text>
      {content}
    </Box>
  );
};
```

**Incorrect (local render function):**

```tsx
const ChannelList = ({ channels, isLoading }: ChannelListProps) => {
  const renderChannels = () => (
    <Stack direction="column" gap="2">
      {channels.map((ch) => (
        <ChannelRow key={ch.id} channel={ch} />
      ))}
    </Stack>
  );

  return (
    <Box p="4">
      <Text as="h2" size="3">Channels</Text>
      {isLoading ? <Skeleton /> : renderChannels()}
    </Box>
  );
};
```

Local render functions create new function references every render. React
can't optimize them, and they remount their subtree if the parent re-renders.
They also obscure the actual component tree.

**Correct (extract to a component):**

```tsx
const ChannelItems = ({ channels }: { channels: Channel[] }) => {
  return (
    <Stack direction="column" gap="2">
      {channels.map((ch) => (
        <ChannelRow key={ch.id} channel={ch} />
      ))}
    </Stack>
  );
};

const ChannelList = ({ channels, isLoading }: ChannelListProps) => {
  if (isLoading) return <Skeleton />;

  return (
    <Box p="4">
      <Text as="h2" size="3">Channels</Text>
      <ChannelItems channels={channels} />
    </Box>
  );
};
```

**Correct (simple inline conditional is fine):**

```tsx
const ChannelList = ({ channels, isLoading }: ChannelListProps) => {
  return (
    <Box p="4">
      <Text as="h2" size="3">Channels</Text>
      {isLoading ? <Skeleton /> : channels.map((ch) => (
        <ChannelRow key={ch.id} channel={ch} />
      ))}
    </Box>
  );
};
```

Short ternaries directly in JSX are fine. The rule targets storing JSX in
named variables or render functions that masquerade as components.

### IIFEs in ternaries

IIFEs (immediately invoked function expressions) inside ternaries are a sign
that the logic should be extracted to a component.

**Incorrect (IIFE in ternary):**

```tsx
{condition ? (
  (() => {
    const parsed = parseValue(value);
    const handleChange = (field: string, newValue: string) => {
      onChange(JSON.stringify({ ...parsed, [field]: newValue }));
    };
    return (
      <Stack>
        <Input value={parsed.min} onChange={(e) => handleChange("min", e.target.value)} />
        <Input value={parsed.max} onChange={(e) => handleChange("max", e.target.value)} />
      </Stack>
    );
  })()
) : (
  <Input value={value} onChange={onChange} />
)}
```

**Correct (extract to component):**

```tsx
{condition ? (
  <RangeInput value={value} onChange={onChange} />
) : (
  <Input value={value} onChange={onChange} />
)}
```

### The test

If you're about to write `const something = (<JSX />)`,
`const renderSomething = () => <JSX />`, or `(() => { ... return <JSX /> })()`
inside a component, extract it as a sibling component with its own props instead.
