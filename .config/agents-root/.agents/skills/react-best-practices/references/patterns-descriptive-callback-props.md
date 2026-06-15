---
title: Use Descriptive Controlled Prop Pairs
impact: MEDIUM
impactDescription: consistent APIs reduce learning curve across components
tags: props, controlled-components, patterns
---

## Use Descriptive Controlled Prop Pairs

Controlled components should expose prop pairs that accurately describe the
value being managed: `value` / `onValueChange`, `open` / `onOpenChange`,
`checked` / `onCheckedChange`. Avoid generic names like `onChange`, Chakra
patterns like `isOpen` / `onClose`, or leaking state setters as props.

**Incorrect (generic `onChange`):**

```tsx
type ComboboxProps = {
  value: string;
  onChange: (value: string) => void;
};
```

`onChange` is ambiguous — it could refer to a native DOM event or a value
callback.

**Incorrect (Chakra `isOpen` / `onClose` pattern):**

```tsx
type ConfirmDialogProps = {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
};
```

`isOpen` uses a boolean prefix instead of describing the state directly, and
`onClose` only handles one direction of the change.

**Incorrect (leaking state setters):**

```tsx
type UserPickerProps = {
  selectedUsers: Array<ExternalUser>;
  setSelectedUsers: (users: Array<ExternalUser>) => void;
};
```

Setter names couple the consumer to the implementation.

**Correct (descriptive prop pairs):**

```tsx
type ComboboxProps = {
  value: string;
  onValueChange: (value: string) => void;
};

type ConfirmDialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onConfirm: () => void;
};

type UserPickerProps = {
  value: Array<ExternalUser>;
  onValueChange: (users: Array<ExternalUser>) => void;
};
```

The prop describes the state (`value`, `open`, `checked`) and the callback
describes the change event (`onValueChange`, `onOpenChange`,
`onCheckedChange`). This aligns with Telegraph component APIs and makes every
controlled component feel familiar.
