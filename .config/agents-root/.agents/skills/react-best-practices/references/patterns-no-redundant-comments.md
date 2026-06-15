---
title: Remove Redundant Comments
impact: MEDIUM
impactDescription: reduces noise and prevents comments from going stale
tags: readability, comments, documentation
---

## Remove Redundant Comments

Don't add comments that restate what the code does. Well-named components,
functions, and variables are self-documenting. Comments should explain *why*,
not *what*.

**Incorrect (redundant comments):**

```tsx
// Handle is_between operator
if (condition?.operator === EvaluationOperator.IsBetween) {
  return <NumericBetweenInput value={value} onChange={onChange} />;
}

// If the operator is a datetime operator, show the datetime field
if (DATETIME_OPERATORS.includes(condition?.operator)) {
  return <DateTimeField value={value} onChange={onChange} />;
}
```

The code already says it checks for `IsBetween` and datetime operators. The
comments add no value and will go stale if the behavior changes.

**Correct (self-documenting code):**

```tsx
if (condition?.operator === EvaluationOperator.IsBetween) {
  return <NumericBetweenInput value={value} onChange={onChange} />;
}

if (DATETIME_OPERATORS.includes(condition?.operator)) {
  return <DateTimeField value={value} onChange={onChange} />;
}
```

### When to comment

- **Business rules**: Why a limit is 20, why a field is required
- **Non-obvious behavior**: When code does something unexpected for a reason
- **Workarounds**: Link to issue or explain why the obvious approach doesn't work
- **External constraints**: API limits, browser quirks, accessibility requirements

```tsx
// Cap at 20 items to keep the dropdown performant on low-end devices
const MAX_VISIBLE_ITEMS = 20;

// Safari doesn't support `scrollIntoView({ block: "nearest" })` correctly,
// so we manually calculate the scroll position
const scrollToItem = (index: number) => {
  // ...
};
```
