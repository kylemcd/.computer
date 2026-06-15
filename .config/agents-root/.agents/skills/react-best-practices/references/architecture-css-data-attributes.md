---
title: CSS Files and Data Attribute Targeting
impact: HIGH
impactDescription: prevents style drift and keeps styling tied to component state
tags: architecture, css, data-attributes, styling
---

## CSS Files and Data Attribute Targeting

Custom CSS files should almost never be needed. Telegraph props handle the vast
majority of styling. Only introduce a `.styles.css` file when you need selectors
impossible through props — transitions, pseudo-selectors, targeting nested
third-party elements, or state-driven selectors requiring CSS specificity.

When CSS is unavoidable, target elements using data attributes rather than class
names. Data attributes let you drive style changes from React state by setting
attribute values, keeping styling declarative.

**Incorrect (className conditionals):**

```tsx
<Stack className={isOpen ? "switcher-open" : ""} direction="row">
  <Icon icon={ChevronRight} className={isOpen ? "chevron-rotated" : ""} />
</Stack>
```

```css
.chevron-rotated { transform: rotate(90deg); }
```

Class names are fragile — they can collide and don't communicate what state
drives the style.

**Correct (data attributes driven by React state):**

```tsx
<Stack direction="row" data-branch-switcher-button data-branch-switcher-button-open={isOpen}>
  <Icon icon={ChevronRight} aria-hidden data-branch-switcher-chevron />
</Stack>
```

```css
[data-branch-switcher-chevron] {
  transform: rotate(0deg);
  transition: all 0.2s ease-in-out;
}
[data-branch-switcher-button-open="true"] [data-branch-switcher-chevron] {
  transform: rotate(90deg);
}
```

**State-driven visibility:**

```tsx
<Stack data-vbe-block-content={open ? "open" : "closed"}>
  <Stack data-vbe-block-actions={isActive ? "visible" : "hidden"}>
    {/* action buttons */}
  </Stack>
</Stack>
```

```css
[data-vbe-block-actions] {
  pointer-events: none;
  opacity: 0;
}
[data-vbe-block-actions="visible"],
[data-vbe-block-actions]:focus-within,
[data-vbe-block]:focus-within [data-vbe-block-actions] {
  pointer-events: auto;
  opacity: 1;
}
```

**Naming conventions for data attributes:**

- Prefix with the component name: `data-branch-switcher-*`, `data-vbe-block-*`
- Descriptive suffixes for state: `data-*-open`, `data-*-active`
- String values for multi-state: `"open"` / `"closed"`, `"visible"` / `"hidden"`
- Boolean attributes render as `"true"` / `"false"` when set from React state

**When to use CSS:** transitions and animations, pseudo-selectors (`:hover`,
`:focus-within`) combined with data attributes, targeting deeply nested
third-party elements (CodeMirror, resize panels).

**When not to:** anything Telegraph props support (spacing, color, layout,
dimensions, borders, background, rounded corners). For simple conditionals use
Telegraph props directly: `bg={isSelected ? "gray-2" : undefined}`.
