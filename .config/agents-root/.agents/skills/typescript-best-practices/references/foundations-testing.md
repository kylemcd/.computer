---
title: Testing Functions and Utilities
impact: HIGH
impactDescription: catches regressions and documents expected behavior
tags: testing, vitest, typescript
---

## Testing Functions and Utilities

Write tests for shared helpers, validators, transformers, and any function with
non-trivial logic. Tests document expected behavior and prevent regressions.
Not every function needs tests — focus on functions that are reused across the
codebase, handle edge cases, or have a history of bugs.

We use Vitest. Test files live alongside the source as `filename.test.ts`.

**When to write tests:**

- The function is reused across multiple modules
- The function handles edge cases or complex logic (parsing, validation,
  transformation, sanitization)
- You are fixing a bug or regression in existing logic

**When to fix a bug, write a failing test first:**

Start by writing a test that reproduces the broken behavior — it should fail.
Fix the issue, then verify the test passes. This proves the fix addresses the
actual problem and prevents the same bug from returning.

**Incorrect (fix without verification):**

```typescript
// Someone reports that flattenObject drops empty arrays.
// You read the code, spot the issue, fix it, and move on.
// No test — the same bug can silently return in a future refactor.
```

**Correct (failing test -> fix -> passing test):**

```typescript
// 1. Write a test that reproduces the bug
test("preserves empty arrays", () => {
  const input = { tags: [] };
  expect(flattenObject(input)).toEqual({ tags: [] });
});

// 2. Run the test — it fails, confirming the bug
// 3. Fix the implementation
// 4. Run the test again — it passes, confirming the fix
```

**Test structure for a utility function:**

```typescript
import { describe, expect, test } from "vitest";

import flattenObject from "./flattenObject";

describe("flattenObject", () => {
  test("flattens nested objects with dot notation", () => {
    const input = { user: { name: "Alice", age: 30 } };
    expect(flattenObject(input)).toEqual({
      "user.name": "Alice",
      "user.age": 30,
    });
  });

  test("flattens arrays with bracket notation", () => {
    const input = { tags: ["a", "b", "c"] };
    expect(flattenObject(input)).toEqual({
      "tags[0]": "a",
      "tags[1]": "b",
      "tags[2]": "c",
    });
  });
});
```

**Test structure for a validator:**

```typescript
import { describe, expect, test } from "vitest";
import { createConditionSchema } from "./validation";

describe("createConditionSchema", () => {
  const schema = createConditionSchema({ completions: [{ label: "data.order_id" }] });

  test("validates when variable exists in completions", () => {
    const result = schema.safeParse({ variable: "data.order_id", operator: "equal_to", argument: "123" });
    expect(result.success).toBe(true);
  });

  test("fails when variable is not in scope", () => {
    const result = schema.safeParse({ variable: "data.nonexistent", operator: "equal_to", argument: "123" });
    expect(result.success).toBe(false);
  });
});
```

Use `vi.fn()` for mock functions and `vi.mock()` for module mocking. Keep tests
focused on one behavior per test case.

### Test edge cases and unhappy paths

Don't only test the happy path. Functions should handle invalid input, empty
data, boundary conditions, and error cases. Write tests that verify these
scenarios.

```typescript
describe("prepareForSubmission", () => {
  test("strips __typename from nested objects", () => {
    const input = { name: "test", nested: { __typename: "Foo", value: 1 } };
    expect(prepareForSubmission(input)).toEqual({ name: "test", nested: { value: 1 } });
  });

  test("handles empty object", () => {
    expect(prepareForSubmission({})).toEqual({});
  });

  test("handles null and undefined values", () => {
    const input = { name: null, description: undefined };
    expect(prepareForSubmission(input)).toEqual({ name: null, description: undefined });
  });

  test("handles deeply nested arrays", () => {
    const input = { items: [{ __typename: "Item", id: "1" }] };
    expect(prepareForSubmission(input)).toEqual({ items: [{ id: "1" }] });
  });
});
```

Cover at minimum: empty inputs, null/undefined values, boundary values,
malformed data, and thrown errors (`expect(() => fn()).toThrow()`).
