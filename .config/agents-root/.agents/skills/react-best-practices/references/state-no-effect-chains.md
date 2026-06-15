---
title: Avoid Chaining Effects That Trigger Each Other
impact: HIGH
impactDescription: prevents cascading re-renders and makes state transitions predictable
tags: useEffect, chains, state, re-renders, performance
---

## Avoid Chaining Effects That Trigger Each Other

Do not chain multiple effects where each one sets state that triggers the next.
This causes cascading re-renders (one per effect in the chain) and produces
rigid logic that breaks when requirements change. Instead, compute derived
values during rendering and batch state updates in the event handler that
started the chain.

**Incorrect (chain of effects):**

```tsx
const Game = () => {
  const [card, setCard] = useState<Card | null>(null);
  const [goldCardCount, setGoldCardCount] = useState(0);
  const [round, setRound] = useState(1);
  const [isGameOver, setIsGameOver] = useState(false);

  useEffect(() => {
    if (card?.gold) setGoldCardCount((c) => c + 1);
  }, [card]);

  useEffect(() => {
    if (goldCardCount > 3) {
      setRound((r) => r + 1);
      setGoldCardCount(0);
    }
  }, [goldCardCount]);

  useEffect(() => {
    if (round > 5) setIsGameOver(true);
  }, [round]);
  // 4 effects, 4 potential re-renders per card placement
};
```

**Correct (derive + compute in handler):**

```tsx
const Game = () => {
  const [card, setCard] = useState<Card | null>(null);
  const [goldCardCount, setGoldCardCount] = useState(0);
  const [round, setRound] = useState(1);

  // Derived — no state needed
  const isGameOver = round > 5;

  const handlePlaceCard = (nextCard: Card) => {
    if (isGameOver) throw new Error("Game already ended.");

    setCard(nextCard);
    if (nextCard.gold) {
      if (goldCardCount < 3) {
        setGoldCardCount(goldCardCount + 1);
      } else {
        setGoldCardCount(0);
        setRound(round + 1);
      }
    }
  };
};
```

### Checklist

- Does an effect's only job set state that another effect watches? Collapse
  the chain into the originating event handler.
- Can any of the intermediate state values be derived from other state?
  Compute them inline instead of storing them.
- The only valid use of chained effects is when each effect synchronizes with
  a _different external system_ (e.g., dropdown options fetched based on a
  previous dropdown's selection).

Reference: [You Might Not Need an Effect — Chains of computations](https://react.dev/learn/you-might-not-need-an-effect#chains-of-computations)
