---
title: Early Returns Over Nested Conditionals
impact: MEDIUM
impactDescription: keeps functions flat, readable, and easy to follow
tags: typescript, functions, early-return, guard-clauses
---

## Early Returns Over Nested Conditionals

Use early returns and guard clauses to keep functions at a single level of
indentation. Each condition should return early or fall through to the next
check.

**Incorrect (nested if/else):**

```typescript
const processOrder = (order: Order | null) => {
  if (order) {
    if (order.status === "paid") {
      if (order.items.length > 0) {
        return fulfillOrder(order);
      } else {
        return { error: "Order has no items" };
      }
    } else {
      return { error: "Order is not paid" };
    }
  } else {
    return { error: "No order provided" };
  }
};
```

**Correct (guard clauses):**

```typescript
const processOrder = (order: Order | null) => {
  if (!order) return { error: "No order provided" };
  if (order.status !== "paid") return { error: "Order is not paid" };
  if (order.items.length === 0) return { error: "Order has no items" };
  return fulfillOrder(order);
};
```

**Incorrect (unnecessary else):**

```typescript
const getDisplayName = (user: User) => {
  if (user.name) {
    return user.name;
  } else if (user.email) {
    return user.email;
  } else {
    return user.id;
  }
};
```

**Correct:**

```typescript
const getDisplayName = (user: User) => {
  if (user.name) return user.name;
  if (user.email) return user.email;
  return user.id;
};
```

**Incorrect (flag variables):**

```typescript
const validateUsers = (users: User[]) => {
  let hasError = false;
  let errorMessage = "";
  for (const user of users) {
    if (!user.email) { hasError = true; errorMessage = "Email required"; }
    if (!user.name) { hasError = true; errorMessage = "Name required"; }
  }
  return hasError ? { valid: false, error: errorMessage } : { valid: true };
};
```

**Correct (return on first error):**

```typescript
const validateUsers = (users: User[]) => {
  for (const user of users) {
    if (!user.email) return { valid: false, error: "Email required" };
    if (!user.name) return { valid: false, error: "Name required" };
  }
  return { valid: true };
};
```
