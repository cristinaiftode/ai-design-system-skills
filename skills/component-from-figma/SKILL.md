---
name: component-from-figma
description: Build a new component for an AI-readable component library end-to-end from a Figma node, matching production code conventions. Reads `manifest.json`, `prompt-rules.md`, `tokens/*.css`, and `reference/` files, fetches the Figma design context, generates `Component.tsx` + `Component.css`, updates the barrel export, adds the manifest entry, and writes a per-component section into `prompt-rules.md`. Use when adding a component to a library you're bootstrapping with the designer playbook, when porting a component from Figma to code, or whenever the user asks to "build the [Component] component", "generate [Component] from Figma", "add a new component", or "port this Figma node to React". Requires the Figma MCP server.
trigger: [build the component, generate component from figma, add a new component, port this figma node, create component from figma, build component from figma node]
license: Apache-2.0
---

# Component From Figma

## Objective

Take one Figma component and produce a production-ready library entry: TSX file, CSS file, barrel export, manifest entry, prompt-rules section. The output should be visually 1:1 with Figma and code-1:1 with the user's real product (via `reference/` files). The user gets one component closer to a complete library, with no manual cleanup needed.

This is the highest-frequency skill in the design-system toolkit. The user will run it dozens of times. Make it predictable.

## When to Use

- Adding a new component to a library built with the designer playbook conventions
- Porting a single Figma node to a React + CSS component
- The user says: "build the Button", "generate [Component] from Figma node [URL]", "add a new component", "port this Figma node"

Do NOT use when:
- The component already exists in `manifest.json` (read it, don't rebuild — suggest `verify-component` instead)
- The Figma file isn't ready (e.g. no Variables, no auto-layout — suggest running `figma-readiness-check` first)
- The library doesn't have `tokens/` set up yet (suggest `figma-tokens-extract` first)

## Prerequisites

1. Figma MCP server connected (`mcp__*__get_design_context`, `mcp__*__get_screenshot`)
2. Current working directory is the library root
3. `manifest.json`, `prompt-rules.md`, and `tokens/*.css` exist
4. Optional but strongly recommended: `reference/` folder with 1–3 production component files

If any prerequisite is missing, stop and tell the user what to do first.

## Inputs to gather

Ask the user for:
1. **Component name** in PascalCase (e.g., `Button`, `DateRangePicker`)
2. **Figma node URL** (e.g., `https://figma.com/design/abc123/My-File?node-id=12-34`)
3. **Reference file** (optional) — path to a production component to mirror. If `reference/` has files, default to using all of them.

## Workflow

### Step 1: Read library context (don't skip)

In this exact order, READ:
1. `manifest.json` — note: library framework, styling approach, naming convention. Note: does this component already exist? If yes, STOP and ask the user.
2. `prompt-rules.md` — note: hard rules (banned patterns, font, radius, class prefix), color tokens, existing component patterns.
3. `tokens/colors.css`, `tokens/spacing.css`, `tokens/typography.css` — note exact variable names.
4. `components/index.ts` — note the existing export pattern.
5. `reference/*` (if present) — read every file. These define the code shape.
6. (Optional) One existing component in the library that's structurally similar — e.g. for a new feedback component, read `Banner.tsx` + `Banner.css`. This gives Claude a worked example in the library's exact style.

Show the user a one-line summary of what was read.

### Step 2: Fetch Figma design context

Use the Figma MCP:
- `get_screenshot` on the node — for visual reference
- `get_design_context` on the node — for dimensions, layout, types
- `get_variable_defs` on the node — for tokens used

If the node references variables not in the library's `tokens/*.css`, STOP and ask: add the missing tokens first (suggest `figma-tokens-extract`) or proceed with hex fallbacks (not recommended).

### Step 3: Plan the component

Before writing code, output a short plan to the user:
- Props (variants, sizes, states, optional slots)
- File structure (e.g., `Button.tsx` + `Button.css`)
- Class hierarchy (BEM: `tt-button`, `tt-button__icon`, `tt-button--primary`)
- Variant CSS strategy (modifier classes? data-attributes? CSS variables?)
- Dependencies (does this need icons? other library components?)
- Risk callouts (anything ambiguous from Figma that needs clarification)

Wait for user confirmation before proceeding. This is the most important step. Most bad components come from skipping this.

### Step 4: Generate the component files

Write:
1. `components/[ComponentName].tsx`
2. `components/[ComponentName].css`

Rules for the TSX file:
- Match imports, type declaration style, export style, and component patterns from `reference/*` or the worked-example library component
- TypeScript types exported alongside the component
- Props typed strictly (no `any`)
- Variants implemented as discriminated unions or string enums per the library's existing style
- ARIA where applicable (`aria-label`, `aria-expanded`, `role`)
- No inline styles
- No external dependencies the library doesn't already use

Rules for the CSS file:
- Every color is a `var(--token)`, never a hex
- Every spacing is a `var(--spacing-*)` or a calc on tokens
- BEM class names matching the library's prefix (typically `tt-`)
- Variants and sizes implemented as modifier classes
- Transitions use the library's standard duration (typically `0.15s ease`)
- No vendor prefixes unless required (rely on the bundler/PostCSS)
- One blank line between rule blocks; no double blank lines

### Step 5: Wire up the barrel export

In `components/index.ts`, add:

```ts
export { ComponentName } from "./ComponentName";
export type { ComponentNameProps, ComponentNameVariant, ComponentNameSize } from "./ComponentName";
```

(Adjust which types are exported based on what the component actually exports.)

Insert in the right place — usually grouped with similar components in the existing file, not at the bottom.

### Step 6: Add the manifest entry

In `manifest.json`, find the `components` object and insert a new entry alphabetically or in the existing category grouping. Use the shape that other entries use. At minimum:

```json
"ComponentName": {
  "description": "One-line description of what it does.",
  "import": "import { ComponentName } from \"./components\";",
  "props": {
    "variant": { "type": "enum", "values": [...], "default": "..." },
    "size": { "type": "enum", "values": [...], "default": "..." },
    ...
  },
  "styling": {
    "dimensions": { ... },
    "radius": "...",
    "typography": { ... }
  },
  "usage": "<ComponentName variant=\"primary\">...</ComponentName>"
}
```

If the existing entries have richer fields (e.g., `colorMapping`, `accessibility`, `keyboard`), match the depth.

### Step 7: Add the prompt-rules section

In `prompt-rules.md`, find the section that lists per-component CSS (in the Atlas template this is Section 6). Add a new subsection in the right numerical position. Include:

- A one-line description
- Sizes/variants table (if applicable)
- A short CSS skeleton showing the class structure
- A TSX usage example
- "When to use this vs other components" guidance if there's ambiguity (e.g., Banner vs Alert)

### Step 8: Verify

Run through the verification checklist (or invoke `verify-component` if the user prefers):
- [ ] `components/[ComponentName].tsx` exists and exports the component + its types
- [ ] `components/[ComponentName].css` exists, no hex codes (`grep '#[0-9a-fA-F]' --color`)
- [ ] `components/index.ts` has the new export line
- [ ] `manifest.json` has the new entry with all required fields
- [ ] `prompt-rules.md` has a new subsection
- [ ] No banned patterns from `prompt-rules.md` are present in the new files

### Step 9: Report and suggest next step

Print a summary:
- Files created / modified
- One-line description of the component
- The exact import statement the user can copy
- A short usage snippet
- Suggested next step: "Build the next component? Run `next-component-to-build` to see the recommended order."

## Output

Five things touched:
1. `components/[ComponentName].tsx` (created)
2. `components/[ComponentName].css` (created)
3. `components/index.ts` (modified)
4. `manifest.json` (modified)
5. `prompt-rules.md` (modified)

Plus a summary report to the user.

## Common failure modes to avoid

- **Skipping the plan step.** Component shape decisions made silently are decisions made wrong. Always pause for confirmation after Step 3.
- **Using hex codes instead of tokens.** Grep your own CSS output for `#` before finishing. The only allowed `#` is in comments.
- **Drifting from production code shape.** If the user provided `reference/` files, they EXPECT the output to mirror them. Match the imports, the TypeScript style, the comment style, all of it.
- **Inventing new tokens.** If Figma uses a color that isn't in `tokens/colors.css`, the answer is to add the token first, not to use the hex inline.
- **Forgetting to update the manifest.** The manifest is what makes the library AI-readable. A component without a manifest entry is invisible to the next prompt.
