---
title: Code Style Conventions
impact: HIGH
impactDescription: keeps the codebase consistent and predictable
tags: style, arrow-functions, const, let, array-methods, loops
---

## Code Style Conventions

### Use const arrow functions, not function declarations

Always declare functions with `const` and arrow syntax. This applies to
components, hooks, helpers, and callbacks. Never use `function` declarations.

**Incorrect:**

```tsx
function formatDate(date: Date): string {
  return date.toISOString().split("T")[0];
}

function UserCard({ name }: UserCardProps) {
  return <Text as="span">{name}</Text>;
}
```

**Correct:**

```tsx
const formatDate = (date: Date): string => {
  return date.toISOString().split("T")[0];
};

const UserCard = ({ name }: UserCardProps) => {
  return <Text as="span">{name}</Text>;
};
```

---

### Use const by default, avoid let

Always use `const`. Only use `let` when reassignment is genuinely necessary
and provides a clear performance benefit (e.g., building a string in a tight
loop with thousands of iterations). If you reach for `let`, consider whether
the code can be restructured with `const` and array methods instead.

**Incorrect:**

```tsx
let result = "";
for (let i = 0; i < items.length; i++) {
  result += items[i].name + ", ";
}

let filtered = items;
if (query) {
  filtered = items.filter((item) => item.name.includes(query));
}
```

**Correct:**

```tsx
const result = items.map((item) => item.name).join(", ");

const filtered = query
  ? items.filter((item) => item.name.includes(query))
  : items;
```

---

### Prefer array methods over for loops

Use `map`, `filter`, `reduce`, `find`, `some`, `every`, and `flatMap` instead
of `for` or `for...of` loops. Array methods are declarative, composable, and
less error-prone.

**Incorrect:**

```tsx
const activeNames: string[] = [];
for (const item of items) {
  if (item.isActive) {
    activeNames.push(item.name);
  }
}

let total = 0;
for (let i = 0; i < items.length; i++) {
  total += items[i].amount;
}

let found = null;
for (const item of items) {
  if (item.id === targetId) {
    found = item;
    break;
  }
}
```

**Correct:**

```tsx
const activeNames = items
  .filter((item) => item.isActive)
  .map((item) => item.name);

const total = items.reduce((sum, item) => sum + item.amount, 0);

const found = items.find((item) => item.id === targetId) ?? null;
```

### When a for loop is acceptable

- Performance-critical code processing very large datasets (10k+ items) where
  early termination or avoiding intermediate arrays matters
- Complex iteration logic that doesn't map cleanly to a single array method
  chain (e.g., building multiple outputs from one pass)

Even in these cases, add a comment explaining why the loop is preferred.
