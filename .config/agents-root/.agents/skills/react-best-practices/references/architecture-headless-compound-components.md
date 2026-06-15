---
title: Headless Compound Components for Complex UI
impact: HIGH
impactDescription: enables full customization while keeping core logic reusable
tags: architecture, compound-components, headless, render-props, overrides
---

## Headless Compound Components for Complex UI

For complex, reusable components that need to support multiple contexts with
different field types, layouts, or behaviors, use a two-layer architecture:
a **headless primitives layer** that owns all logic, and a **styled layer**
that provides default rendering. Consumers compose the styled layer but can
drop down to primitives for full control.

This pattern is used by `ConditionsBuilder` and is the preferred approach for
any core component where different consumers need substantially different
rendering while sharing the same state management and logic.

### Architecture overview

```
ComponentName/
├── Primitives/
│   ├── Primitives.tsx    # Logic-only: contexts, state, render props
│   └── index.ts
├── ComponentName.tsx      # Styled defaults wrapping Primitives
├── index.ts               # Barrel: exports styled + Primitives
├── helpers.ts
├── schema.ts
└── types.ts
```

### Layer 1: Headless primitives

Primitives manage state via nested contexts and expose data through render
props. They render no UI themselves.

```tsx
const RootContext = createContext<RootContextValue | null>(null);
const ItemContext = createContext<ItemContextValue | null>(null);

function PrimitiveRoot({ value, onValueChange, children }: RootProps) {
  return (
    <RootContext value={{ value, onValueChange }}>
      {children}
    </RootContext>
  );
}

function PrimitiveItem({ index, children }: ItemProps) {
  const { value, onValueChange } = use(RootContext);
  const item = value[index];

  const onItemChange = (updates: Partial<Item>) => {
    const next = [...value];
    next[index] = { ...next[index], ...updates };
    onValueChange(next);
  };

  return (
    <ItemContext value={{ item, index, onItemChange }}>
      {children}
    </ItemContext>
  );
}

function PrimitiveField({ children }: { children: (ctx: FieldRenderProps) => React.ReactNode }) {
  const { item, onItemChange } = use(ItemContext);
  const error = useFieldError(item);

  return children({
    value: item.field,
    onValueChange: (val) => onItemChange({ field: val }),
    error,
  });
}

function PrimitiveRemove({ children }: { children: (ctx: { onClick: () => void }) => React.ReactNode }) {
  const { index } = use(ItemContext);
  const { value, onValueChange } = use(RootContext);

  const onClick = () => onValueChange(value.filter((_, i) => i !== index));

  return children({ onClick });
}

const Primitives = {
  Root: PrimitiveRoot,
  Item: PrimitiveItem,
  Field: PrimitiveField,
  Remove: PrimitiveRemove,
};
```

### Layer 2: Styled components

The public API wraps primitives with Telegraph components. Consumers compose
these by default.

```tsx
function Root({ value, onValueChange, status, children, ...props }: StyledRootProps) {
  return (
    <BuilderContext value={{ status }}>
      <Primitives.Root value={value} onValueChange={onValueChange}>
        <Stack direction="column" gap="2" {...props}>
          {children}
        </Stack>
      </Primitives.Root>
    </BuilderContext>
  );
}

function Field() {
  return (
    <Primitives.Field>
      {({ value, onValueChange, error }) => (
        <Combobox value={value} onValueChange={onValueChange} error={error} />
      )}
    </Primitives.Field>
  );
}

function RemoveButton() {
  return (
    <Primitives.Remove>
      {({ onClick }) => (
        <Button variant="ghost" icon={{ icon: Trash, alt: "Remove" }} onClick={onClick} />
      )}
    </Primitives.Remove>
  );
}

const Builder = { Root, Field, RemoveButton, Primitives };
```

### Consumer usage: default

Most consumers use the styled layer directly:

```tsx
<Builder.Root value={conditions} onValueChange={setConditions} status="editing">
  {conditions.map((_, i) => (
    <Builder.Item key={i} index={i}>
      <Builder.Field />
      <Builder.RemoveButton />
    </Builder.Item>
  ))}
</Builder.Root>
```

### Consumer usage: override via primitives

When a consumer needs a custom field (e.g., a domain-specific selector),
they drop down to the primitives layer for that part only:

```tsx
<Builder.Root value={conditions} onValueChange={setConditions} status="editing">
  {conditions.map((_, i) => (
    <Builder.Item key={i} index={i}>
      {/* Override just the field with a custom implementation */}
      <Builder.Primitives.Field>
        {({ value, onValueChange, error }) => (
          <WorkflowVariableSelector
            value={value}
            onValueChange={onValueChange}
            error={error}
          />
        )}
      </Builder.Primitives.Field>
      <Builder.RemoveButton />
    </Builder.Item>
  ))}
</Builder.Root>
```

The consumer replaces rendering while the primitives layer still manages
state, validation, and change handlers.

### When to use this pattern

- The component is used in 3+ contexts with different field types or layouts
- Different consumers need to swap out individual parts but share core logic
- The component manages non-trivial state (validation, nested data, schemas)

For simpler compound components where consumers only need to rearrange parts,
the standard compound component pattern is sufficient — see
`react-best-practices/references/architecture-compound-components.md`.
