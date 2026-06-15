---
title: Use async/await Over .then/.catch
impact: HIGH
impactDescription: keeps async code readable and avoids scattered state updates
tags: async, await, promises, then, catch, apollo, callbacks
---

## Use async/await Over .then/.catch

Always use `async`/`await` with `try`/`catch` for asynchronous code. Avoid
`.then`/`.catch` chains — they fragment control flow, make error handling
harder to follow, and encourage updating state in callbacks instead of in
the main function body.

**Incorrect (.then/.catch chain):**

```tsx
const handleSave = (values: FormValues) => {
  createItem({ variables: { input: values } })
    .then((result) => {
      if (result.data?.result?.item) {
        setItem(result.data.result.item);
        toast({ title: "Saved", status: "success", position: "bottom-right" });
        onClose();
      }
    })
    .catch((error) => {
      setError(error.message);
      toast({ title: "Error", status: "error", position: "bottom-right" });
    });
};
```

State updates are buried inside callbacks. Adding more logic (field errors,
validation, redirects) makes the chain increasingly hard to follow.

**Correct (async/await with try/catch):**

```tsx
const handleSave = async (values: FormValues) => {
  try {
    const result = await createItem({ variables: { input: values } });

    if (result.data?.result?.item) {
      toast({ title: "Saved", status: "success", position: "bottom-right" });
      onClose();
    }
  } catch (error) {
    toast({ title: "Error", status: "error", position: "bottom-right" });
  }
};
```

Linear flow, easy to add steps between await and the success handling.

---

### Don't update state in Apollo callbacks

Apollo's `onCompleted` and `onError` mutation callbacks run outside the normal
function flow. Updating state in them splits logic across two locations — the
call site and the hook options — making it hard to trace what happens after a
mutation.

**Incorrect (state updates in onCompleted):**

```tsx
const [createItem, { loading }] = useMutation(CREATE_ITEM, {
  onCompleted: (data) => {
    setItem(data.result.item);
    setIsOpen(false);
    toast({ title: "Saved", status: "success", position: "bottom-right" });
  },
  onError: (error) => {
    setError(error.message);
  },
});

const handleSubmit = (values: FormValues) => {
  createItem({ variables: { input: values } });
};
```

A reader must jump between `handleSubmit` and the `useMutation` options to
understand the full flow. Adding error partitioning or conditional logic
becomes awkward.

**Correct (handle everything at the call site):**

```tsx
const [createItem, { loading }] = useMutation(CREATE_ITEM);

const handleSubmit = async (values: FormValues) => {
  try {
    const result = await createItem({ variables: { input: values } });

    if (result.data?.result?.errors) {
      handleErrors(result.data.result.errors);
      return;
    }

    toast({ title: "Saved", status: "success", position: "bottom-right" });
    onClose();
  } catch (error) {
    toast({ title: "Error", status: "error", position: "bottom-right" });
  }
};
```

All mutation logic lives in one place. The `useMutation` call is clean and
the handler reads top to bottom.
