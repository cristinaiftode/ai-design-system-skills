---
name: showcase-page-generator
description: Generate a showcase / examples page for a component in an AI-readable component library — TSX file under `examples/<Name>Page.tsx`, `src/pages/<Name>Page.tsx`, or wherever the project's existing showcase pages live. Auto-detects the folder, reads an existing showcase page as the template, and produces a header section, variant matrix, size matrix, state matrix, anatomy notes, usage notes, and a "Don't" list — using only props and tokens already defined for the component. Pairs with `component-from-figma` so component + showcase ship together. Use after generating a new component, when building a styleguide site, or whenever the user asks to "generate a showcase for [Component]", "build the [Component] examples page", "add a demo page for [Component]", "make a styleguide page for [Component]", "create the [Component]Page", or "showcase the component".
trigger: [generate a showcase, build the examples page, add a demo page, make a styleguide page, create the component page, showcase the component, generate the page]
license: Apache-2.0
---

# Showcase Page Generator

## Objective

Every time a component is added, an examples / showcase page should be added with it. Without one, the team has no canonical place to see all variants, sizes, and states; reviewers can't sanity-check the implementation visually; and Figma-to-code drift goes unnoticed.

This skill produces that page in one shot, using only the component's existing props and the project's existing showcase conventions. No new components are invented, no new tokens, no inline magic numbers — every section is a faithful render of what the component is supposed to do.

## When to Use

- Immediately after `component-from-figma` finishes (chain it)
- Catching up on showcase coverage for components built before this skill existed
- The user says: "generate a showcase", "build the examples page", "add a demo page", "create the [Component]Page", "showcase the component"

Do NOT use when:
- The component doesn't exist yet (run `component-from-figma` first)
- The project has no showcase folder (`examples/`, `src/pages/`, `stories/`, `docs/`) — stop and ask the user which folder to create
- The user is asking for a prototype (a multi-component flow) — use `prototype-from-brief` instead

## Prerequisites

1. Component already built and registered in `manifest.json`
2. Current working directory is the library root
3. A showcase folder exists OR the user agrees to create one

## Workflow

### 1. Find the showcase folder

Probe in this order, stopping at the first hit:

1. `examples/` (Tripletex Atlas convention — see `examples/StatesPage.tsx`)
2. `src/pages/`
3. `stories/`
4. `docs/components/`
5. `app/` (if a Next.js-style app)

If none exist, ask the user: "I don't see a showcase folder. Should I create `examples/` (Atlas convention), `src/pages/`, or something else?"

### 2. Read an existing showcase page as the template

Pick the most recently-edited file in the folder and read it cover to cover. This is the gold-standard template — match:
- Import style (deep paths vs barrel)
- Page-level wrapper (`<>` fragment vs a layout component)
- Section structure (`<section className="page-section">`, `<h2>` page title, `<h3>` sub-heading)
- Demo wrapper class (`.demo-row`, `.placeholder`, etc.)
- How variants are iterated (`.map()` over a typed array, hardcoded list, etc.)
- Where inline `style={{}}` is used (in showcase pages this is typically OK for one-off demo layout — match what's already there)

If the folder is empty, fall back to the structure below as a default.

### 3. Read the component's manifest entry

From `manifest.json`, pull:
- `props` — every variant, size, state value
- `styling` — dimensions, radius, focus ring
- `usage` — the canonical example string

If `manifest.json` is missing the component, STOP and run `verify-component` first.

### 4. Read the component's TSX file

`components/<Name>.tsx` — confirm the exported types and their values (don't guess from the manifest; the source is the source of truth).

### 5. Plan the page

Output a plan to the user:

```
Showcase page plan for <Name>:
- File: examples/<Name>Page.tsx
- Sections (in order):
  1. Header — page title + one-line description + list of components used
  2. Variant matrix — one demo per `variant` value (e.g. primary / secondary / tertiary / icon)
  3. Size matrix — one demo per `size` value (e.g. medium / small)
  4. State matrix — rest / hover / focus / active / disabled / loading (where applicable)
  5. Combination matrix — variant × size grid (compact)
  6. Anatomy — labeled diagram or annotated breakdown if the component has nameable parts (icon-left, label, icon-right)
  7. Usage notes — when to use this vs. its neighbours (Banner vs Alert vs Toast)
  8. "Don't" list — pulled from prompt-rules.md per-component section if present, otherwise inferred
```

Wait for confirmation. If the project's existing pages skip a section (e.g., no "Anatomy"), skip it too.

### 6. Generate the file

Rules:
- **Imports** — exactly match the existing pages. If they use `import { Button } from "../components/Button"`, do the same. If they use `import { Button } from "../components"`, use that. Do not mix.
- **No invented props** — every prop value in the demos must exist in `manifest.json → components.<Name>.props.*.values`. If a prop has no enum, render a representative sample (3 values) not a guess.
- **No inline hex** — except where existing showcase pages already inline hex for demo wrapper layout (color: `#51596a` for muted demo captions is a known pattern in Atlas's `examples/`). Match what's there; do not introduce new ones.
- **No new tokens** — only reference tokens already in `tokens/*.css`.
- **Section IDs** — give each section an `id` attribute (`id="variants"`, `id="sizes"`) so the page can be linked-to.
- **One state per Alert / one row per ActionButton status** — render the *real* component in each cell, not a screenshot or mock.

### 7. Wire the page (if applicable)

If the project has a router (`App.tsx` with React Router, or a Next.js `app/` directory), add a route entry. If unclear, stop and ask — don't guess the routing config.

For Atlas-style projects: `App.tsx` typically has a top-level switch on a path / tab — add the new page to that switch with a sensible label.

### 8. Verify

Run an inline check:
- File exists at the chosen path
- Imports resolve (every `import` references a real file or manifest entry)
- Every prop value used in the page exists in the manifest
- No `<button>`, `<input>`, `<select>` raw HTML elements — use library components
- No hex codes outside known-acceptable patterns

If anything fails, fix before finishing.

### 9. Report

```
Showcase page generated:
- examples/<Name>Page.tsx (NN lines)
- App.tsx updated to route to /<name>

Components rendered: <Name> (N variants × M sizes × K states = X cells)

Visit: http://localhost:5173/<name>

Next step: run `screenshot-diff <Name>` to compare against Figma, or `verify-component <Name>` if you haven't yet.
```

## Output

One file created (`examples/<Name>Page.tsx` or equivalent), optionally `App.tsx` modified to add the route, and a short report.

## Common failure modes

- **Skipping the template-read step.** Every showcase page in the folder is a contract about what "good" looks like in this project. Match it. Don't ship a generic structure that diverges from the existing pages.
- **Demoing props that don't exist.** Read the manifest. If `size` doesn't include `"xl"`, don't render a `<Button size="xl">` cell.
- **Hardcoding a router edit when there's no router.** Look first. Some projects use file-based routing (Next.js), some use React Router, some use no router at all.
- **Inventing "Don't" examples.** The "Don't" list should be lifted from `prompt-rules.md`'s per-component section, not generated freehand. If `prompt-rules.md` has nothing, omit the section.
