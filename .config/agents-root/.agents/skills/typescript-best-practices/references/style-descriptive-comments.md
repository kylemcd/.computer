---
title: Write Descriptive Comments for Complex Code
impact: HIGH
impactDescription: helps future developers understand non-obvious intent and decisions
tags: comments, readability, maintainability, documentation
---

## Write Descriptive Comments for Complex Code

Leave comments that explain _why_, not _what_. Simple code that reads clearly
doesn't need comments. Complex logic, workarounds, business rules, and
non-obvious decisions always do.

**Incorrect (narrating what the code does):**

```tsx
// Loop through the items
items.forEach((item) => {
  // Check if the item is active
  if (item.isActive) {
    // Add to the result array
    result.push(item);
  }
});
```

The comments restate what the code already says. They add noise without value.

**Incorrect (no comment on complex logic):**

```tsx
const getDeliveryWindow = (channel: Channel, timezone: string) => {
  const now = DateTime.now().setZone(timezone);
  const hour = now.hour;

  if (channel.type === "push" && hour >= 22) {
    return { delay: true, resumeAt: now.plus({ days: 1 }).set({ hour: 9 }) };
  }

  if (channel.quietHours?.includes(hour)) {
    const nextOpen = channel.quietHours[channel.quietHours.length - 1] + 1;
    return { delay: true, resumeAt: now.set({ hour: nextOpen }) };
  }

  return { delay: false };
};
```

A future developer has to reverse-engineer the business rules from the
conditionals.

**Correct (comments explain intent and business rules):**

```tsx
const getDeliveryWindow = (channel: Channel, timezone: string) => {
  const now = DateTime.now().setZone(timezone);
  const hour = now.hour;

  // Push notifications after 10pm are delayed to 9am to avoid waking users
  if (channel.type === "push" && hour >= 22) {
    return { delay: true, resumeAt: now.plus({ days: 1 }).set({ hour: 9 }) };
  }

  // Respect per-channel quiet hours configured by the customer
  if (channel.quietHours?.includes(hour)) {
    const nextOpen = channel.quietHours[channel.quietHours.length - 1] + 1;
    return { delay: true, resumeAt: now.set({ hour: nextOpen }) };
  }

  return { delay: false };
};
```

### Component-level descriptions

Complex components should have a block comment at the top describing what the
component does, how it works, and when to use it. This is especially important
for shared/core components, compound components, and anything with non-obvious
behavior.

```tsx
/**
 * DataPanels provides a two-panel layout for list + detail views.
 *
 * It manages loading, empty, and error states via a `status` prop derived
 * from `getStatus()`. The left panel renders a scrollable item list; the
 * right panel renders detail content for the selected item.
 *
 * Use this for any page that follows the "select from list, view details"
 * pattern (e.g., workflows, translations, API keys).
 */
export const DataPanels = { Root, Panel, Header, Item, Column };
```

Skip this for simple, self-explanatory components where the name and props
tell the full story.

### When to comment

- **Component overviews** — what it does, how it works, when to use it
- **Business rules** — why a threshold is 22, why a field is checked
- **Workarounds** — link to the issue or explain why the obvious approach
  doesn't work
- **Non-obvious dependencies** — when code relies on ordering, timing, or
  side effects that aren't apparent from the signature
- **Complex algorithms** — a one-line summary of the approach before the
  implementation
- **API contracts** — when a function has constraints callers must respect
  that types alone can't enforce

### When not to comment

- The code is self-explanatory (variable names, function names tell the story)
- The comment restates what the next line does
- The comment will immediately go stale when the code changes
