---
title: Testing Components
impact: HIGH
impactDescription: catches regressions and documents expected behavior
tags: testing, vitest, patterns
---

## Testing Components

Write tests for complex, widely reused components. Tests document expected
behavior and prevent regressions as the component evolves. Not every component
needs tests — focus on components that have meaningful logic, are shared across
many consumers, or have a history of bugs.

We use Vitest with React Testing Library. Test files live alongside the
component as `ComponentName.test.tsx`.

**When to write tests:**

- The component is reusable and used in multiple places
- The component has non-trivial logic (conditional rendering, state machines,
  validation, computed values)
- You are fixing a bug or regression in an existing component

**Incorrect (fixing a bug without a test):**

```tsx
// Someone reports that onValueChange fires with stale data.
// You read the code, spot the issue, fix it, and move on.
// No test — the same bug can silently return in a future refactor.
```

**Correct (write a failing test first, then fix):**

```tsx
test("calls onValueChange with the updated value, not stale data", async () => {
  const onValueChange = vi.fn();
  render(
    <ConditionsBuilder value={[createConditionGroup()]} onValueChange={onValueChange} />,
  );

  fireEvent.change(screen.getByTestId("variable-input"), { target: { value: "order.name" } });

  expect(onValueChange).toHaveBeenCalledWith([
    { operator: "AND", conditions: [{ variable: "order.name", operator: "EQUAL_TO", argument: "test@example.com" }] },
  ]);
});
// 2. Run the test — it fails, confirming the bug
// 3. Fix the implementation
// 4. Run the test again — it passes, confirming the fix
```

**Example test structure:**

```tsx
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, test, vi } from "vitest";
import { DateInput } from "./DateInput";

describe("DateInput", () => {
  test("calls onValueChange when a date is selected", async () => {
    const user = userEvent.setup();
    const onValueChange = vi.fn();
    render(
      <DateInput value={new Date("2026-06-20T12:00:00Z")} onValueChange={onValueChange} timeZone="UTC" />,
    );

    await user.click(screen.getByLabelText("Open calendar"));
    await user.click(screen.getByRole("button", { name: "21" }));

    expect(onValueChange).toHaveBeenCalled();
    const [nextDate] = onValueChange.mock.calls[0];
    expect(nextDate).toBeInstanceOf(Date);
  });

  test("disables input when disabled prop is true", () => {
    render(<DateInput value={null} onValueChange={vi.fn()} disabled />);
    expect(screen.getByLabelText("Open calendar")).toBeDisabled();
  });
});
```

Prefer `userEvent` over `fireEvent` for user interactions — it simulates real
browser behavior. Use `screen` queries (`getByRole`, `getByLabelText`,
`getByText`) over test IDs when possible.

### Test error cases and unhappy paths

Don't only test the happy path. Components should handle errors, empty states,
missing data, and invalid input gracefully. Write tests that verify these
scenarios.

```tsx
describe("WorkflowEditor", () => {
  test("shows error state when query fails", () => {
    render(<WorkflowEditor workflow={null} error={new Error("Not found")} />);
    expect(screen.getByText("Failed to load workflow")).toBeInTheDocument();
  });

  test("shows empty state when no steps exist", () => {
    render(<WorkflowEditor workflow={{ ...mockWorkflow, steps: [] }} />);
    expect(screen.getByText("Add your first step")).toBeInTheDocument();
  });

  test("disables save when form has validation errors", async () => {
    const user = userEvent.setup();
    render(<WorkflowEditor workflow={mockWorkflow} />);

    await user.clear(screen.getByLabelText("Name"));
    expect(screen.getByRole("button", { name: "Save" })).toBeDisabled();
  });
});
```

Cover at minimum: error states, empty/missing data, validation failures,
disabled/read-only states, and permission-gated actions.
