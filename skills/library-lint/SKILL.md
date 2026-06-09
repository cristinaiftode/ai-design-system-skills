---
name: library-lint
description: Lint a component library project for off-brand drift — hardcoded hex codes instead of CSS variables, Tailwind utility classes, non-Rubik (or non-canonical) font references, inline styles, custom HTML buttons/inputs instead of library components, missing BEM prefixes, `var(--name)` references to tokens that aren't defined anywhere (the `--spacing-150` silent-evaluates-to-empty bug), and any pattern explicitly banned in `prompt-rules.md`. Returns a structured punch list with file:line references. Use after building components or prototypes, in a pre-commit hook, when auditing an existing project for design-system compliance, or whenever the user asks to "lint the library", "check for off-brand code", "scan for token violations", "audit the library", "audit the prototypes", "compliance check", "is anything off-brand", "design review the code", "check for issues", "scan for design-system violations", "find hex codes", or "are we using the tokens". For demo / prototype folders specifically (where raw `<button>` / `<input>` should be errors not warnings), prefer `demo-compliance-scanner`.
trigger: [lint the library, check for off-brand code, scan for token violations, audit the library, audit the prototypes, compliance check, is anything off-brand, design review the code, check for issues, scan for design-system violations, find hex codes, are we using the tokens]
license: Apache-2.0
---

# Library Lint

## Objective

Catch design-system drift before it ships. Component libraries die a slow death from a hundred small "I'll just use this one hex code" decisions — this skill finds them.

## When to Use

- After building a batch of components or a prototype
- Before committing to main
- When auditing a long-lived library for cumulative drift
- The user says: "lint", "check for off-brand", "scan the prototypes", "find hex codes"

Do NOT use for:
- General code quality (use `scored-code-review`)
- Type errors (use `tsc`)
- Accessibility audits (different skill)

## What it checks

Read `prompt-rules.md` first to learn the project's banned patterns. Default checks if `prompt-rules.md` doesn't list them:

### Tier 1 — Errors (will fail the lint)

| # | Check | Pattern |
|---|---|---|
| 1 | No hardcoded hex colors | grep `#[0-9a-fA-F]{3,6}` in `components/**/*.css` and `prototypes/**/*.html|css` — flag every match that isn't inside a comment, a `:root { --token: #... }` declaration in `tokens/*.css`, or a clearly-decorative SVG `fill` |
| 2 | No Tailwind classes | grep `className="[^"]*\b(p-|m-|px-|py-|w-\d|h-\d|flex-row|flex-col|gap-\d|text-(xs|sm|md|lg|xl)|bg-(white|gray|blue|red))\b` |
| 3 | No inline styles in JSX | grep `style=\{\{` in `components/**/*.tsx` and `prototypes/**/*.tsx` |
| 4 | No custom `<button>` in prototypes | grep `<button` in prototypes (allowed only inside `components/` source files) |
| 5 | No banned libraries | grep import lines for libraries listed under "Banned patterns" in `prompt-rules.md` (e.g., styled-components, emotion, @mui/, @chakra-ui/) |
| 6 | **All `var(--name)` references resolve** | Build the set of defined CSS variables from `tokens/*.css`. Grep `var\(--[a-z0-9-]+\)` across `components/**/*.css`, `prototypes/**/*.{css,html,tsx}`, and `examples/**/*.{tsx,css}`. Every reference must exist in the set. This catches `var(--spacing-150)` / `var(--spacing-250)` typos that silently evaluate to nothing and are invisible until you diff against Figma. Suggest the closest defined token by edit distance for each violation. |

### Tier 2 — Warnings

| # | Check | Pattern |
|---|---|---|
| 6 | Class names follow BEM with the project's prefix | sample class attributes — if `prompt-rules.md` says prefix `tt-`, flag any `class="some-class"` that doesn't start with `tt-` (except in the rare exempt list) |
| 7 | Font family is the project's font | grep `font-family:` — flag any value other than the one in `tokens/typography.css` or `prompt-rules.md` |
| 8 | Border-radius is from tokens | grep `border-radius:` — flag values that aren't `var(--radius-*)` or `0` |
| 9 | No magic spacing | grep `padding:` and `margin:` for values not in the spacing scale (`4|8|12|16|24|32|48px`) |
| 10 | Every component file has a manifest entry | for each `components/[Name].tsx`, check `manifest.json` has a `components.[Name]` entry |

### Tier 3 — Informational

| # | Check | Pattern |
|---|---|---|
| 11 | No console.log in production code | grep `console\.` in non-test files |
| 12 | TODO/FIXME comments | grep `TODO\|FIXME\|HACK\|XXX` — list, don't fail |

## Workflow

### 1. Locate the project

Confirm cwd has `manifest.json` and `components/`. If not, ask the user for the project root.

### 2. Read `prompt-rules.md`

Pull the "Hard rules" / "Banned patterns" section. Add any explicit bans to the check list. If `prompt-rules.md` doesn't exist, run with defaults and warn the user.

### 3. Run each check

Use `grep` / `rg` (ripgrep is preferred when available — `rg --type css '#[0-9a-fA-F]{3,6}' components/ prototypes/`).

For each match, capture:
- File path (relative to project root)
- Line number
- The offending content (trimmed)
- A suggested fix (e.g., "use `var(--action-primary-rest)`")

### 4. Cross-reference with tokens

For hex code matches, try to identify which CSS variable maps to that hex. Read `tokens/colors.css` to build a `hex → token-name` map, then suggest the right token in the fix.

### 5. Output the report

In this shape:

```
# Library lint report
Project: [name] · Date: [date] · Files scanned: [N]

## Summary
- ❌ Errors: 12
- ⚠️ Warnings: 7
- ℹ️ Info: 3

## Errors (must fix)

### 1. Hardcoded hex codes (4)
- `components/Button.css:42` — `color: #0a41fa;` → use `var(--text-action)`
- `components/Modal.css:18` — `background: #ffffff;` → use `var(--surface-default)`
- `prototypes/dashboard.html:120` — `border: 1px solid #d5d7db` → use `var(--border-muted)`
- `prototypes/dashboard.html:144` — `color: #2e384d` → use `var(--text-primary)`

### 2. Tailwind classes detected (3)
- `prototypes/settings.html:88` — `className="px-4 py-2 flex-row gap-2"`
- ...

### 3. Inline styles in JSX (1)
- `components/CustomCard.tsx:55` — `style={{ marginTop: "16px" }}` → use a CSS class

### 4. Banned libraries (4)
- `prototypes/settings.html:3` — imports `styled-components` (banned in prompt-rules.md)
- ...

## Warnings (should fix)
[similar shape]

## Info (FYI)
[similar shape]

## How to apply fixes
- Run `[Tool] auto-fix` (not implemented — you fix manually)
- Or paste the report back to Claude with "apply these fixes" and the model will apply them
```

### 6. Offer to auto-fix Tier-1 issues

For hex-code → token replacements where the mapping is unambiguous (the hex appears in exactly one CSS variable in `tokens/colors.css`), offer to apply the fix. Ask the user before editing files.

## Output

A lint report (printed and optionally saved to `./library-lint-report.md`). Plus an optional auto-fix step for unambiguous replacements.

## Note on accuracy

This is a pattern-matching lint, not a full AST analyzer. False positives happen — hex codes inside SVG `fill=""` attributes for decorative illustrations are OK, hex codes inside CSS variable declarations in `tokens/*.css` are OK. Use judgment when reporting.

## Companion skills

- `demo-compliance-scanner` — stricter scan focused on `prototypes/` + `demos/` + `examples/`, with raw HTML affordances as Tier 1 errors. Use it when you specifically want to audit demo hygiene.
- `verify-component` — single-component version of this (includes the schema-completeness check that this skill skips).
- `token-drift-check` — diffs the current `tokens/*.css` against Figma. Pair with this skill to catch *both* "code drifted from tokens" and "tokens drifted from Figma."
