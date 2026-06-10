---
name: verify-component
description: Verify a single component in an AI-readable component library is fully wired up — TSX file exists, CSS file exists, barrel export updated, manifest entry present AND schema-complete (every key the project's most-populated entry has, this one has too), prompt-rules section present, no hardcoded hex codes, no banned patterns, every `var(--name)` reference in the component CSS resolves to a token actually defined in `tokens/*.css` (catches the `var(--spacing-150)` silent-evaluates-to-empty bug), AND — for components in interactive categories (Tooltip / Dropdown / Modal / Tabs / Toast / etc.) — the expected interaction contract is implemented (handlers, ARIA, keyboard support). Returns a pass/fail report. **Mandatory final step of `component-from-figma`** — never skipped. Also use after manually editing a component, before merging a PR that touches a component, or whenever the user asks to "verify the [Component]", "check that [Component] is fully wired", "validate this component", "is [Component] correct", "audit this component", or "did the component finish properly".
trigger: [verify component, check the component is wired, validate component, is the component fully integrated, audit component, is the component correct, did the component finish properly]
license: Apache-2.0
---

# Verify Component

## Objective

Confirm a single component has everything it needs to be considered "done" in an AI-readable component library: source files, exports, manifest entry, prompt-rules section, no token violations. This is the gate between "Claude said it generated the component" and "the component actually works."

## When to Use

- **Mandatory final step of `component-from-figma`.** Always runs at the end. Not optional.
- After manually editing a component
- Before merging a PR that touches a component
- When the user says: "verify [Component]", "did Claude finish the [Component]?", "is [Component] fully wired?", "is [Component] correct", "audit this component"

## Workflow

### 1. Take the component name

Argument is required. PascalCase (e.g., `Button`, `DateRangePicker`). If not provided, ask.

### 2. Run the ten checks

For component named `Foo`:

| # | Check | Pass criterion |
|---|---|---|
| 1 | TSX file exists | `components/Foo.tsx` is readable |
| 2 | CSS file exists | `components/Foo.css` is readable (skip if library convention is CSS-in-JS — read `prompt-rules.md` to confirm) |
| 3 | Barrel export present | `components/index.ts` contains `export { Foo }` (or `export * from "./Foo"`) |
| 4 | Manifest entry present | `manifest.json` has `components.Foo` with at minimum `description`, `import`, `props`, `usage` |
| 5 | **Manifest entry schema-complete** | Compare `components.Foo` against the most-populated existing entry (the "schema reference"). Every top-level key the schema reference has, `Foo` has too. Specifically check for `colorMapping`, `styling.dimensions`, `styling.radius`, `styling.typography`, and (where the project tracks it) `figmaNodeId`, `figmaName`, `muiPrimitive`. Partial entries fail. |
| 6 | Prompt-rules section present | `prompt-rules.md` contains a heading that mentions `Foo` (in the components section) |
| 7 | No hardcoded hex codes | `grep '#[0-9a-fA-F]\{3,6\}'` on `Foo.css` returns zero matches (excluding comments) |
| 8 | **All `var(--name)` references resolve** | Build the set of defined CSS variables from `tokens/*.css` (`:root { --name: value }` declarations). Grep `var\(--[a-z0-9-]+\)` in `Foo.css` and `Foo.tsx`. Every reference must exist in the set. This catches the `var(--spacing-150)` / `var(--spacing-250)` class of bug where a typo silently evaluates to empty. |
| 9 | No banned patterns | Read banned-patterns list from `prompt-rules.md` and grep `Foo.tsx` + `Foo.css` against each |
| 10 | **Interactive contract satisfied** (if applicable) | Detect the component's category from its name and manifest props (see `component-interactive-behavior` for the category table). If the component is in an interactive category (Tooltip / Popover / Menu / Dropdown / Select / Modal / Tabs / Toast / Form input / Date / Slider), confirm the TSX includes the required handlers (`onClick`, `onMouseEnter`/`onFocus`, `onKeyDown`), state, and ARIA attributes for that category. If the component is purely visual (Tag, Badge, Avatar, Divider, Spinner, AppShell, Sidebar, Card), skip this check with a "no interactive contract needed" note. |

### 3. Output

Print a compact pass/fail table:

```
# Verify Modal

✅ 1. components/Modal.tsx exists (88 lines)
✅ 2. components/Modal.css exists (142 lines)
✅ 3. Barrel export present in components/index.ts:24
✅ 4. Manifest entry present (props: isOpen, onClose, title, children)
❌ 5. Manifest entry incomplete — missing `colorMapping`, `styling.focusRing`. Schema reference (Button) has these. Run `manifest-styling-from-css Modal` to derive from the CSS, or fill manually.
✅ 6. Prompt-rules section present at Section 6.18
❌ 7. Hex code found: components/Modal.css:33 — `color: #0a41fa;` (use `var(--text-action)`)
❌ 8. Undefined token referenced: components/Modal.css:88 — `padding: var(--spacing-150)`. Closest defined: `--spacing-16` (16px), `--spacing-12` (12px).
✅ 9. No banned patterns detected
❌ 10. Interactive contract incomplete — Modal is in the Dialog category. Missing: focus trap (Tab can escape the dialog), Escape-to-close (no onKeyDown handler), restore-focus-on-close (no previouslyFocusedElement ref), aria-labelledby (title not linked to dialog). Run `component-interactive-behavior Modal` to wire these up.

Result: 6/10 PASSED. 4 issues to fix.

To fix:
1. Replace `#0a41fa` on Modal.css:33 with `var(--text-action)`.
2. Replace `var(--spacing-150)` on Modal.css:88 with `var(--spacing-16)` (or whichever the design intends).
3. Run `manifest-styling-from-css Modal` to fill the missing manifest sub-blocks from the CSS.
4. Run `component-interactive-behavior Modal` to wire the Dialog interaction contract.
```

### 4. Optional: offer to fix

For unambiguous fixes — hex codes where exactly one token maps to that hex, or `manifest-styling-from-css` for missing styling blocks, or `component-interactive-behavior` for the interactive contract — offer to apply (or chain the relevant skill). For undefined tokens, suggest the closest defined match but require user confirmation before editing.

## Output

A short pass/fail report with exact line numbers for any failures.
