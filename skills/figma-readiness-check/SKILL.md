---
name: figma-readiness-check
description: Audit a Figma file (or a specific component within one) against the AI-readable component library readiness checklist — Variables, naming conventions, Component Properties for variants, auto-layout, named layers, state coverage, and description fields. Produces a punch list of issues the designer needs to fix in Figma BEFORE running component generation. Use when bootstrapping a new component library, when a designer is preparing their Figma file for AI handoff, or whenever the user asks to "audit my Figma file", "check Figma readiness", "is my Figma ready for AI", or "find issues in my Figma components". Requires the Figma MCP server.
trigger: [audit my figma file, check figma readiness, is my figma ready for ai, find issues in my figma components, figma hygiene check, figma component audit]
license: Apache-2.0
---

# Figma Readiness Check

## Objective

Stop the user from building components from a broken Figma file. Run a checklist against the file and return a prioritized punch list of fixes. Anything that fails this check will produce off-spec components later, so it's much cheaper to catch in Figma than in code.

## When to Use

- Before running `figma-tokens-extract` or `component-from-figma` for the first time
- After a Figma overhaul or rebrand
- When components-from-Figma are producing weird output and the suspect is the Figma file itself
- The user says: "audit my Figma", "is my Figma ready", "find issues in my Figma"

## Prerequisites

- Figma MCP server connected
- A Figma file URL (whole file) or a specific component node

## The checklist

For each component scanned, evaluate:

### A. Tokens (highest priority)
1. **Does the component use Figma Variables for colors?** Hardcoded fills (not bound to a variable) are an error.
2. **Does it use Variables for spacing?** Manually entered padding/gap values that don't match the spacing scale are a warning.
3. **Does it use Variables for typography?** Inline font sizes/weights/families instead of text styles are an error.

### B. Structure
4. **Is auto-layout enabled?** Free-form positioned layers are an error.
5. **Are layer names meaningful?** `Frame 12`, `Group 47`, `Rectangle 8` are errors. `button`, `icon-left`, `label` pass.
6. **Are there nested components?** Reusing primitives (Icon, Avatar inside Button) is good; copy-pasted SVG paths are a warning.

### C. Naming & variants
7. **Component name uses the `/` hierarchy?** `Button/Primary/Medium` passes. `PrimaryButton` is a warning.
8. **Are variants modeled as Component Properties?** If `Button/Primary` and `Button/Secondary` are separate Figma components (not variants of one set), that's an error.
9. **Does the component have a description field filled in?** Empty is a warning.

### D. State coverage
10. **Does the component show all relevant states?** For interactive components: rest, hover, active, focus, disabled. Missing hover is a warning, missing disabled is an error if the prop exists.
11. **Are error / loading / empty states shown if applicable?** Forms, inputs, modals should have at least error + loading.

### E. Edge cases
12. **Is there a long-text example?** Buttons / Tags / Chips with super long labels — does the component handle wrap or truncate gracefully?
13. **Is there an empty example?** What does a Table look like with no rows? A Dropdown with no options?

## Workflow

### 1. Gather inputs

- **Figma file URL** (whole file) OR component-set URL
- **Scope**: `all` (full file), `top-5` (Button, Input, Modal, Tag, Dropdown — the most common ones), or a specific component name

### 2. Walk the Figma structure

Use `get_design_context` and `get_variable_defs` on each component scope. For a whole-file audit, list all pages, then iterate the component pages.

### 3. Evaluate each component against the checklist

For each component, produce a result block:

```
## Button/Primary/Medium
Status: ⚠️ 3 issues, 2 warnings

❌ Errors
- A1: 1 fill uses hardcoded `#0a41fa` (not bound to a Variable). Fix: bind to `action/primary/rest`.
- B5: 2 layers named `Frame 23` and `Rectangle 4`. Fix: rename to `button` and `icon-left`.

⚠️ Warnings
- C9: Description field is empty.
- D11: No disabled state shown.

✅ Passes
- B4: Auto-layout enabled
- C7: Name follows `/` hierarchy
- C8: Uses Component Properties for variant + size
```

### 4. Aggregate and prioritize

At the end, produce a summary in this shape:

```
# Figma readiness report
File: [file name] · Scope: [all/top-5/Component] · Date: [date]

## Summary
- Components scanned: 23
- Ready: 8
- Needs minor fixes: 11
- Needs major fixes: 4

## Top blockers (fix these first)
1. **Button/Primary** — 1 hardcoded fill (errors any token-aware generator)
2. **Input** — 4 separate components instead of one with variants (will produce 4 React components instead of 1)
3. **Modal** — no auto-layout (will produce a broken layout in code)

## Components ready to ship
- Tag, Chip, Avatar, Spinner, Divider, Tooltip, Badge, Toggle

## Components with minor fixes (proceed with caution)
[list]

## Components needing major work
[list with specific issues]

## Recommended next step
Fix the top 3 blockers, then re-run this skill. Once at 80%+ "ready", run `figma-tokens-extract` and start building components.
```

### 5. Offer to write the report to a file

Default location: `./figma-readiness-report.md` in the current project. Useful for sharing with the design team.

## Severity rubric

- **Error** (❌) — will break code generation or produce visibly wrong output
- **Warning** (⚠️) — works but produces lower-quality code (missing types, fragile classes, inconsistent variants)
- **Pass** (✅) — meets the standard

## Output

A markdown report (printed and optionally saved) with:
- Per-component pass/fail breakdown
- Aggregate counts
- Prioritized top-blockers list
- Recommended next step

## Common follow-ups

- If most components fail on tokens (A1–A3): run a session with the designer to migrate styles to Variables before doing anything else.
- If most components fail on variants (C8): the Figma file has a major structural issue — consolidate copies into variant sets.
- If only a handful fail: fix manually, re-run the check, then proceed.
