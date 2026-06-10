---
name: next-component-to-build
description: Recommend which component(s) to build next in an AI-readable component library, based on what's already in `manifest.json` and what exists in the Figma file. Prioritizes by foundational dependencies (Button before Form, Input before Modal), coverage gaps, and the user's stated focus (forms, data display, navigation, feedback). Use when planning a sprint of component work, when uncertain what to build next, or whenever the user asks "what should I build next", "which component is next", "what's missing from my library", or "prioritize my component backlog".
trigger: [what should i build next, which component is next, whats missing from my library, prioritize my component backlog, what to build next, plan my sprint, recommend next components, what to do next on the library]
license: Apache-2.0
---

# Next Component To Build

## Objective

Stop the user from staring at their Figma library wondering where to start. Look at what exists in code, look at what exists in Figma, find the gap, recommend an order based on dependencies and impact.

## When to Use

- Sprint planning for component library work
- After finishing 3–5 components and wondering what's next
- The user says: "what should I build next", "what's missing", "what's the next priority"

## Workflow

### 1. Read what's already built

Open `manifest.json` → list `components` keys.

### 2. Read what exists in Figma

Use Figma MCP to walk the component pages. List every component-set name.

### 3. Diff

`missing = figma_components - manifest_components`

If `missing` is empty, congratulate the user and suggest moving to `prototype-from-brief` or building example pages.

### 4. Prioritize the gap

Rank `missing` by:

1. **Foundational dependency** — components other components depend on. Button is foundational (Modal uses Button, Banner uses Button). Build Button first.
2. **Frequency in product** — Buttons appear on every screen; SuccessIllustration appears once. Build the high-frequency ones first.
3. **Family completeness** — if Input exists but Select / Combobox / Textarea don't, the form story is half-built. Finishing the family makes prototypes possible.
4. **User's stated focus** — if they're prototyping forms, prioritize form components. Ask: "What kind of prototype are you trying to build first?"

Common dependency order:

```
Foundation:        Button, Icon, Tag, Avatar, Spinner
Inputs:            Input, Textarea, Checkbox, Radio, Toggle, Select, Combobox
Layout primitives: Card, Divider, Stack
Feedback:          Banner, Alert, Toast, Tooltip
Navigation:        Tabs, Breadcrumb, Sidebar, Topbar, PageHeader
Data display:      Table, List, Pagination
Overlays:          Modal, Popover, Dropdown, PopupMenu
Advanced:          DatePicker, FileUpload, ProgressStepper, Calendar
```

Within each tier, build foundation → inputs → feedback → navigation → data display → overlays → advanced.

### 5. Output a recommendation

```
# Components in your library: [N]
# Components in Figma: [N]
# Missing: [N]

## Top recommendation
**Build [Component] next.** Reasons:
- [Component A] and [Component B] both depend on it (will unblock them)
- Appears in [X] places across the Figma product screens
- Foundational tier

## Next 3 after that
1. **[Component]** — [reason]
2. **[Component]** — [reason]
3. **[Component]** — [reason]

## Tier-by-tier remaining
- Foundation: [list]
- Inputs: [list]
- Feedback: [list]
- Navigation: [list]
- Data display: [list]
- Overlays: [list]
- Advanced: [list]

## Recommended sprint (5 components)
[Ordered list with rationale]
```

### 6. Offer to start the next one

End with: "Want me to start `component-from-figma` for [top recommendation] now?"

## Output

A prioritized list with rationale + a suggested next-step prompt.
