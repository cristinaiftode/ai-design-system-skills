---
name: prototype-from-brief
description: Build a complete prototype (page, screen, or flow) for an AI-readable component library from a natural-language brief, using only components that exist in `manifest.json` and tokens that exist in `tokens/*.css`. If anything required by the brief is missing from the library, STOP and report the gap before generating — never invent. Output is a standalone HTML or TSX prototype file in `prototypes/`. Use when prototyping a feature using an existing library, when validating that the library is complete enough for a real flow, or whenever the user asks to "build a prototype for [feature]", "make a settings page using our design system", "prototype a [page]", or "create a flow with our components".
trigger: [build a prototype, make a prototype, create a prototype, prototype this page, build a flow, prototype a feature]
license: Apache-2.0
---

# Prototype From Brief

## Objective

Turn a natural-language brief into a complete prototype that uses ONLY the existing library — and refuse to fudge with custom components or invented colors. This is where the library proves its worth: a real screen, built fast, on-brand.

## When to Use

- Validating the library covers a real user flow
- Building a stakeholder demo
- The user says: "build a prototype for [X]", "make a [feature] page using our design system", "prototype a [flow]"

Do NOT use when:
- The user wants production code (this generates a prototype, not a shipping feature)
- The library has fewer than 10 components (too thin to prototype anything real — go build more components first)

## Workflow

### 1. Read the library context

In order:
1. `manifest.json` — complete component inventory + props
2. `prompt-rules.md` — hard rules and banned patterns
3. `tokens/*.css` — available tokens
4. (If exists) `prototypes/*.html` — match the existing prototype style and folder conventions

### 2. Take the brief

Examples of what "brief" looks like:
- "A settings page where users can change their name, email, and notification preferences"
- "A dashboard showing recent transactions with a sidebar and filter"
- "A modal for confirming a destructive action"

Ask for clarification if the brief is too vague (one screen vs. flow, mobile vs. desktop, what should happen on submit, etc.).

### 3. Decompose the brief into components needed

For each UI element in the brief, identify the library component:
- "settings page layout" → AppShell + Sidebar + Topbar + PageHeader
- "form to change name and email" → Input × 2 + Button
- "notification preferences" → Toggle × N or CheckboxGroup
- "save action" → PageHeader's `primaryAction` slot or sticky footer with Button

Output the list to the user for confirmation.

### 4. Coverage check (critical step)

Cross-reference each needed component against `manifest.json`. If any are MISSING, STOP. Output:

```
⚠️ Cannot complete prototype — the following components are missing from the library:

- CheckboxGroup (needed for: notification preferences)
- Toast (needed for: post-save confirmation)

Recommendation:
1. Run `component-from-figma CheckboxGroup` to add it.
2. Run `component-from-figma Toast` to add it.
3. Re-run this skill once the components are in the library.

OR — confirm you want me to substitute existing components:
- CheckboxGroup → multiple `Checkbox` components in a stack
- Toast → `Banner` with variant="success"
```

Do not silently invent or substitute. Make the user confirm.

### 5. Plan the prototype file

Output a short plan:
- File name and path (e.g., `prototypes/settings-page.html` or `prototypes/settings-page.tsx`)
- Top-level structure (AppShell → Sidebar + Topbar + PageHeader + main content)
- Component list with their props pre-filled
- Token usage (which CSS variables will be applied)
- Interactivity scope: static markup, hover-only, or full interactive (forms, modals)

Wait for confirmation.

### 6. Generate the prototype

Rules:
- Match the existing prototype convention in `prototypes/` — same HTML scaffold, same `<style>` block structure, same script pattern
- Tokens only — no hex codes, no Tailwind, no inline styles
- Use the exact import statement from `manifest.json` for each component (if TSX)
- For HTML prototypes: reproduce the component markup using the library's `tt-` BEM classes
- Add a top comment naming the brief and date

### 7. Verify

Run an inline lint check:
- Grep for `#[0-9a-fA-F]` in the new file — should only match comments
- Grep for `className="px-` Tailwind utilities — should be zero
- Confirm every used class has the project's prefix (typically `tt-`)
- Confirm `style={{...}}` is absent

If anything fails, fix before finishing.

### 8. Report

Print:
- File created (with path)
- Component count used
- One-line summary of the screens
- Suggested follow-up: "Want me to add interactive behaviors (form submit, modal open)?" or "Want to run `library-lint` for a deeper check?"

## Common failure modes

- **Inventing a missing component.** Don't. Stop and surface the gap (Step 4).
- **Using hex codes for one-off styling.** Don't. If the token doesn't exist, ask the user whether to add it.
- **Mixing HTML and TSX conventions.** Pick one based on what already exists in `prototypes/`. Default to standalone HTML for fast iteration.
- **Skipping the plan step.** Decomposing the brief into components is the most valuable step — don't skip to code generation.

## Output

A working prototype file at `prototypes/[descriptive-name].{html,tsx}` plus a short report.
