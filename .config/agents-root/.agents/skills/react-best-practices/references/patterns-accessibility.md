---
title: Accessibility Standards
impact: HIGH
impactDescription: ensures the dashboard is usable by everyone including assistive technology users
tags: accessibility, a11y, aria, keyboard, focus, screen-reader
---

## Accessibility Standards

All UI must be accessible. This means keyboard navigable, screen reader
compatible, and properly labeled. Telegraph components handle much of this
automatically, but you must still provide labels, manage focus, and ensure
keyboard interactions work.

### Labels and ARIA attributes

Every interactive element needs an accessible name. Use visible labels when
possible; fall back to `aria-label` for icon-only controls.

**Incorrect:**

```tsx
<Button variant="ghost" icon={{ icon: Trash }} onClick={onDelete} />
```

**Correct:**

```tsx
<Button variant="ghost" icon={{ icon: Trash, alt: "Delete item" }} onClick={onDelete} />
```

For decorative icons that duplicate adjacent text, use `aria-hidden`:

```tsx
<Icon icon={CheckCircle} aria-hidden />
<Text as="span">Connected</Text>
```

For modals, always provide `a11yTitle`:

```tsx
<Modal.Root open={open} onOpenChange={onOpenChange} a11yTitle="Edit workflow">
  <Modal.Content>...</Modal.Content>
</Modal.Root>
```

### Form field relationships

Link labels to inputs. Use `aria-labelledby` and `aria-describedby` when the
label or description is rendered separately from the input:

```tsx
<Box>
  <Text as="label" id="name-label">Name</Text>
  <Text as="p" id="name-desc" color="gray">A unique identifier</Text>
  <Input aria-labelledby="name-label" aria-describedby="name-desc" />
</Box>
```

### Keyboard navigation

All interactive elements must be reachable and operable via keyboard. For
custom interactive widgets (grids, pickers, drag targets), add arrow key
handlers:

```tsx
const handleKeyDown = (e: React.KeyboardEvent) => {
  if (e.key === "ArrowDown") {
    e.preventDefault();
    focusNext();
  }
  if (e.key === "ArrowUp") {
    e.preventDefault();
    focusPrevious();
  }
};
```

### Dynamic content

Use `aria-live` for content that updates without a page reload (status
messages, counters, notifications):

```tsx
<Text as="span" aria-live="polite">{itemCount} items found</Text>
```

### Visually hidden text

When an element needs a screen reader label but no visible text, use
`VisuallyHidden` from Radix:

```tsx
import { VisuallyHidden } from "@radix-ui/react-visually-hidden";

<VisuallyHidden>Remove condition row {index + 1}</VisuallyHidden>
```

### Checklist for new components

- [ ] Every button/link has an accessible name (visible text or `aria-label`)
- [ ] Icon-only buttons have `alt` text on the icon prop
- [ ] Decorative icons use `aria-hidden`
- [ ] Modals have `a11yTitle` and trap focus
- [ ] Form inputs are linked to labels
- [ ] Custom widgets are keyboard navigable
- [ ] Dynamic updates use `aria-live`
- [ ] Test with keyboard-only navigation (no mouse)
