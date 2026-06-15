---
title: Use Telegraph Primitives Over Chakra or Raw HTML
impact: CRITICAL
impactDescription: ensures design system consistency and prevents one-off styles
tags: primitives, telegraph, design-system, patterns
---

## Use Telegraph Primitives Over Chakra or Raw HTML

Always use Telegraph primitives (`Box`, `Stack`, `Text`, `Button`, `Icon`, etc.)
for layout, typography, and interaction. Never introduce `@chakra-ui/react`
imports or raw HTML elements with inline styles. Check `dashboard/package.json`
for the full list of available `@telegraph/*` packages. Telegraph packages export
their own prop types (`StackProps`, `TextProps`, `ButtonProps`) — use these with
`TgphElement` from `@telegraph/helpers` for type-safe prop composition.

### Migrate Chakra in files you touch

When you edit or import from a file that has `@chakra-ui/react` imports,
check if the swap to Telegraph is trivial (e.g., `Stack`, `Box`, `Flex`
→ `@telegraph/layout`). If so, ask the user before migrating. This applies
to files you modify directly **and** files you import/reuse. If the migration
is non-trivial (custom Chakra theme tokens, complex responsive styles,
Chakra-specific hooks), note the remaining Chakra usage but don't attempt it.

This ask is mandatory, not optional. Before you finalize work that touches
or reuses Chakra files, explicitly tell the user:
1) which file has the trivial migration,
2) that you can migrate it now as a low-risk cleanup, and
3) wait for a direct yes/no before changing it.

**Incorrect (Chakra components):**

```tsx
import { Box, Flex, Icon, IconButton } from "@chakra-ui/react";

const Toast = ({ title, description, onClose }: ToastProps) => {
  return (
    <Flex bgColor="white" p={3} borderRadius="md" alignItems="center">
      <Icon as={CheckCircle} backgroundColor="green.50" color="green.500" borderRadius="full" />
      <Flex ml={3} flexDir="column">
        <Text as="p" size="2" weight="medium">{title}</Text>
        {description && <Text as="p" size="2" color="gray">{description}</Text>}
      </Flex>
      <IconButton icon={<Icon as={X} />} aria-label="Close" variant="unstyled" ml="auto" />
    </Flex>
  );
};
```

**Incorrect (raw HTML with inline styles):**

```tsx
const ProfileCard = ({ name, role }: ProfileCardProps) => {
  return (
    <div style={{ padding: "16px", background: "#fff", borderRadius: "8px" }}>
      <h2 style={{ fontSize: "14px", fontWeight: 600 }}>{name}</h2>
      <p style={{ fontSize: "12px", color: "#6b7280" }}>{role}</p>
    </div>
  );
};
```

**Correct (Telegraph primitives with design tokens):**

```tsx
import { Button } from "@telegraph/button";
import { Icon } from "@telegraph/icon";
import { Stack } from "@telegraph/layout";
import { Text } from "@telegraph/typography";
import { CheckCircle, X } from "lucide-react";

const Toast = ({ title, description, onClose }: ToastProps) => {
  return (
    <Stack direction="row" align="center" bg="surface-1" p="3" border="px" rounded="2" gap="3">
      <Icon icon={CheckCircle} color="green" size="1" aria-hidden />
      <Stack direction="column" gap="1">
        <Text as="p" size="2" weight="medium">{title}</Text>
        {description && <Text as="p" size="2" color="gray">{description}</Text>}
      </Stack>
      <Button variant="ghost" size="0" color="gray" ml="auto" icon={{ icon: X, alt: "Close" }} onClick={onClose} />
    </Stack>
  );
};
```

```tsx
import { Box, Stack } from "@telegraph/layout";
import { Text } from "@telegraph/typography";

const ProfileCard = ({ name, role }: ProfileCardProps) => {
  return (
    <Box bg="surface-1" p="4" rounded="2">
      <Stack direction="column" gap="1">
        <Text as="h2" size="2">{name}</Text>
        <Text as="p" size="1" color="gray">{role}</Text>
      </Stack>
    </Box>
  );
};
```

**Extending Telegraph primitives:**

Use package-exported prop types to preserve the full prop surface:

```tsx
import { Stack, type StackProps } from "@telegraph/layout";
import { Text } from "@telegraph/typography";
import { type TgphElement } from "@telegraph/helpers";

type CardProps<T extends TgphElement = "div"> = StackProps<T> & {
  title: string;
};

const Card = <T extends TgphElement = "div">({
  title,
  children,
  ...props
}: CardProps<T>) => {
  return (
    <Stack direction="column" gap="2" p="4" border="px" rounded="2" {...props}>
      <Text as="h3" size="2" weight="medium">{title}</Text>
      {children}
    </Stack>
  );
};
```

Prefer token-based props (`bg`, `p`, `rounded`, `gap`, `color`, `overflow`,
`position`, `maxW`) over inline `style`. Reserve `style` only for values
Telegraph cannot express like `filter` or `aspectRatio`.

**Refs use `tgphRef`, not `ref`:**

Telegraph components use `tgphRef` to forward refs. Passing `ref` will not
work.

```tsx
const containerRef = useRef<HTMLDivElement>(null);

<Box tgphRef={containerRef} p="2">...</Box>

<Stack tgphRef={(el) => measureElement(el)} direction="row">...</Stack>
```
