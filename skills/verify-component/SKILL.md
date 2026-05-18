---
name: verify-component
description: Verify a single component in an AI-readable component library is fully wired up — TSX file exists, CSS file exists, barrel export updated, manifest entry present, prompt-rules section present, no hardcoded hex codes, no banned patterns. Returns a pass/fail report. Use after generating or editing a component, as a final check after `component-from-figma`, or whenever the user asks to "verify the [Component]", "check that [Component] is fully wired", or "validate this component".
trigger: [verify component, check the component is wired, validate component, is the component fully integrated, audit component]
license: Apache-2.0
---

# Verify Component

## Objective

Confirm a single component has everything it needs to be considered "done" in an AI-readable component library: source files, exports, manifest entry, prompt-rules section, no token violations. This is the gate between "Claude said it generated the component" and "the component actually works."

## When to Use

- Immediately after `component-from-figma` runs (chain it)
- After manually editing a component
- When the user says: "verify [Component]", "did Claude finish the [Component]?", "is [Component] fully wired?"

## Workflow

### 1. Take the component name

Argument is required. PascalCase (e.g., `Button`, `DateRangePicker`). If not provided, ask.

### 2. Run the seven checks

For component named `Foo`:

| # | Check | Pass criterion |
|---|---|---|
| 1 | TSX file exists | `components/Foo.tsx` is readable |
| 2 | CSS file exists | `components/Foo.css` is readable (skip if library convention is CSS-in-JS — read `prompt-rules.md` to confirm) |
| 3 | Barrel export present | `components/index.ts` contains `export { Foo }` (or `export * from "./Foo"`) |
| 4 | Manifest entry present | `manifest.json` has `components.Foo` with at minimum `description`, `import`, `props`, `usage` |
| 5 | Prompt-rules section present | `prompt-rules.md` contains a heading that mentions `Foo` (in the components section) |
| 6 | No hardcoded hex codes | `grep '#[0-9a-fA-F]\{3,6\}'` on `Foo.css` returns zero matches (excluding comments) |
| 7 | No banned patterns | Read banned-patterns list from `prompt-rules.md` and grep `Foo.tsx` + `Foo.css` against each |

### 3. Output

Print a compact pass/fail table:

```
# Verify Foo

✅ 1. components/Foo.tsx exists (42 lines)
✅ 2. components/Foo.css exists (88 lines)
✅ 3. Barrel export present in components/index.ts:24
✅ 4. Manifest entry present (props: variant, size, onClick)
✅ 5. Prompt-rules section present at Section 6.12
❌ 6. Hex code found: components/Foo.css:33 — `color: #0a41fa;` (use `var(--text-action)`)
✅ 7. No banned patterns detected

Result: 6/7 PASSED. 1 issue to fix.

To fix: replace `#0a41fa` on line 33 of Foo.css with `var(--text-action)`.
```

### 4. Optional: offer to fix

For hex-code violations where the mapping is unambiguous, offer to apply the fix.

## Output

A short pass/fail report with exact line numbers for any failures.
