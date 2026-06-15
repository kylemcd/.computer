---
title: Put Interaction Logic in Event Handlers
impact: MEDIUM
impactDescription: avoids effect re-runs and duplicate side effects
tags: rerender, useEffect, events, side-effects, dependencies
---

## Put Interaction Logic in Event Handlers

If a side effect is triggered by a specific user action (submit, click, drag),
run it in that event handler. Do not model the action as state + effect; it
makes effects re-run on unrelated changes and can duplicate the action.

**Incorrect (event modeled as state + effect):**

```tsx
const Form = () => {
  const [submitted, setSubmitted] = useState(false);
  const theme = useContext(ThemeContext);

  useEffect(() => {
    if (submitted) {
      post("/api/register");
      showToast("Registered", theme);
    }
  }, [submitted, theme]);

  return <Button onClick={() => setSubmitted(true)}>Submit</Button>;
};
```

The effect also re-runs when `theme` changes, potentially duplicating the
POST request. The `submitted` flag is redundant state that mirrors "the user
clicked submit."

**Correct (logic in the handler):**

```tsx
const Form = () => {
  const theme = useContext(ThemeContext);

  const handleSubmit = () => {
    post("/api/register");
    showToast("Registered", theme);
  };

  return <Button onClick={handleSubmit}>Submit</Button>;
};
```

No effect, no extra state. The side effect runs exactly once when the user
clicks.

Reference: [Should this code move to an event handler?](https://react.dev/learn/removing-effect-dependencies#should-this-code-move-to-an-event-handler)
