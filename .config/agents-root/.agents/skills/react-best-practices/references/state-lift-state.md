---
title: Lift State into Provider Components
impact: HIGH
impactDescription: enables state sharing outside component boundaries
tags: composition, state, context, providers
---

## Lift State into Provider Components

Move state management into dedicated provider components. This allows sibling
components outside the main UI to access and modify state without prop drilling
or awkward refs.

**Incorrect (state trapped inside component):**

```tsx
function ConditionsEditor() {
  const [conditions, setConditions] = useState<Condition[]>([]);
  const [errors, setErrors] = useState<ConditionError[]>([]);

  return (
    <ConditionsBuilder.Root>
      <ConditionsBuilder.Group />
      <ConditionsBuilder.AddGroup />
    </ConditionsBuilder.Root>
  );
}

// Problem: How does the save button access conditions state?
function StepConfigModal() {
  return (
    <Modal.Root open={open} onOpenChange={onOpenChange}>
      <Modal.Content>
        <InputModalHeader title="Configure step" />
        <InputModalBody>
          <ConditionsEditor />
        </InputModalBody>
        <InputModalFooter onClose={onClose} submitLabel="Save" />
        {/* Footer needs conditions + errors to validate before saving */}
      </Modal.Content>
    </Modal.Root>
  );
}
```

**Incorrect (useEffect to sync state up):**

```tsx
function ConditionsEditor({ onConditionsChange }: Props) {
  const [conditions, setConditions] = useState<Condition[]>([]);
  useEffect(() => {
    onConditionsChange(conditions);
  }, [conditions]);
}
```

Duplicated state that syncs via useEffect — a common source of stale data.

**Incorrect (reading state from ref on submit):**

```tsx
function StepConfigModal() {
  const conditionsRef = useRef<Condition[]>([]);
  return (
    <Modal.Content>
      <ConditionsEditor conditionsRef={conditionsRef} />
      <Button onClick={() => save(conditionsRef.current)}>Save</Button>
    </Modal.Content>
  );
}
```

**Correct (state lifted to provider):**

```tsx
const ConditionsContext = createContext<ConditionsContextValue | null>(null);

function ConditionsProvider({ children }: { children: React.ReactNode }) {
  const [conditions, setConditions] = useState<Condition[]>([]);
  const [errors, setErrors] = useState<ConditionError[]>([]);

  const validate = () => {
    const nextErrors = validateConditions(conditions);
    setErrors(nextErrors);
    return nextErrors.length === 0;
  };

  return (
    <ConditionsContext value={{ conditions, setConditions, errors, validate }}>
      {children}
    </ConditionsContext>
  );
}

function StepConfigModal() {
  return (
    <ConditionsProvider>
      <Modal.Root open={open} onOpenChange={onOpenChange}>
        <Modal.Content>
          <InputModalHeader title="Configure step" />
          <InputModalBody>
            <ConditionsEditor />
          </InputModalBody>
          <SaveButton />
        </Modal.Content>
      </Modal.Root>
    </ConditionsProvider>
  );
}

function SaveButton() {
  const { validate } = use(ConditionsContext);
  return <Button onClick={() => { if (validate()) save(); }}>Save</Button>;
}
```

Components that need shared state don't have to be visually nested — they just
need to be within the same provider.
