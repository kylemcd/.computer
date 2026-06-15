---
title: Defining Types
impact: MEDIUM
impactDescription: consistent type definitions, no unnecessary runtime code
tags: typescript, types, style
---

## Defining Types

Use `type` for all type definitions — it supports unions, intersections, and
mapped types more naturally than `interface`. Use objects with `as const` instead
of `enum` — enums generate extra runtime JavaScript and behave differently from
standard objects.

**Incorrect (interface):**

```typescript
interface ButtonProps {
  variant: "ghost" | "outline";
  onClick: () => void;
}

interface ApiResponse {
  data: unknown;
  status: number;
}
```

`interface` is less flexible for unions and conditional types, and allows
accidental declaration merging across files.

**Correct (type):**

```typescript
type ButtonProps = {
  variant: "ghost" | "outline";
  onClick: () => void;
};

type ApiResponse = {
  data: unknown;
  status: number;
};
```

**Incorrect (enum):**

```typescript
enum ButtonVariant {
  Ghost = "ghost",
  Outline = "outline",
}

enum ChannelType {
  Push = "push",
  Email = "email",
  SMS = "sms",
}

function sendNotification(channel: ChannelType) {
  // ...
}

sendNotification(ChannelType.Email);
```

Enums compile to a runtime object with reverse mappings, adding code that
doesn't need to exist. They also don't work well with `keyof` or mapped types.

**Correct (object + as const):**

```typescript
const BUTTON_VARIANTS = {
  ghost: "ghost",
  outline: "outline",
} as const;

type ButtonVariant = keyof typeof BUTTON_VARIANTS;

const CHANNEL_TYPES = {
  push: "push",
  email: "email",
  sms: "sms",
} as const;

type ChannelType = (typeof CHANNEL_TYPES)[keyof typeof CHANNEL_TYPES];

function sendNotification(channel: ChannelType) {
  // ...
}

sendNotification(CHANNEL_TYPES.email);
```

When you only need the union and don't need a runtime lookup object, a plain
union type is sufficient:

```typescript
type ChannelType = "push" | "email" | "sms";
```
