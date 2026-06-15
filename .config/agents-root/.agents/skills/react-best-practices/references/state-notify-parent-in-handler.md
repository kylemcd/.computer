---
title: Notify Parent Components in Event Handlers, Not Effects
impact: MEDIUM
impactDescription: eliminates extra render passes from effect-based parent notification
tags: useEffect, callbacks, parent-child, events, controlled-components
---

## Notify Parent Components in Event Handlers, Not Effects

When a child component needs to notify its parent about a state change, call
the parent callback in the same event handler that changes state — not in an
effect that watches the state. An effect fires _after_ render, causing a second
render pass. Calling both in the handler lets React batch them into one pass.

**Incorrect (notifying parent via effect):**

```tsx
const Toggle = ({ onChange }: { onChange: (isOn: boolean) => void }) => {
  const [isOn, setIsOn] = useState(false);

  // Fires after render — parent updates trigger a second pass
  useEffect(() => {
    onChange(isOn);
  }, [isOn, onChange]);

  return <Button onClick={() => setIsOn(!isOn)}>Toggle</Button>;
};
```

**Correct (notifying parent in the handler):**

```tsx
const Toggle = ({ onChange }: { onChange: (isOn: boolean) => void }) => {
  const [isOn, setIsOn] = useState(false);

  const updateToggle = (nextIsOn: boolean) => {
    setIsOn(nextIsOn);
    onChange(nextIsOn); // Both updates batched into one render
  };

  return <Button onClick={() => updateToggle(!isOn)}>Toggle</Button>;
};
```

### Prefer fully controlled components

If the parent already tracks the value, remove internal state entirely:

```tsx
const Toggle = ({
  checked,
  onCheckedChange,
}: {
  checked: boolean;
  onCheckedChange: (checked: boolean) => void;
}) => {
  return <Button onClick={() => onCheckedChange(!checked)}>Toggle</Button>;
};
```

See `react-best-practices/references/patterns-descriptive-callback-props.md`
for naming conventions on controlled prop pairs.

Reference: [You Might Not Need an Effect — Notifying parent components about state changes](https://react.dev/learn/you-might-not-need-an-effect#notifying-parent-components-about-state-changes)
