---
name: demo-compliance-scanner
description: Tight, prototypes-and-demos-focused lint that flags raw HTML affordances (`<button>`, `<input>`, `<select>`, `<textarea>`, `<a>` styled as a button, `<table>` instead of the library `Table`), inline styles, magic numbers, and unknown class names in `prototypes/`, `demos/`, and `examples/` folders. Stricter than `library-lint` — raw HTML affordances are errors (not warnings) and a missing component is treated as a substitution-needed gap, not a permissible workaround. Includes a pre-commit-hook recipe and a CI-runnable mode. Use before shipping a demo, when auditing a prototype repo, in a pre-commit hook, or whenever the user asks to "scan the demos", "audit the prototypes", "check the demo compliance", "lint the prototypes", "are the demos clean", or "find raw HTML in prototypes".
trigger: [scan the demos, audit the prototypes, check demo compliance, lint the prototypes, are the demos clean, find raw html in prototypes, demo compliance check, prototype hygiene]
license: Apache-2.0
---

# Demo Compliance Scanner

## Objective

Demos and prototypes are where component libraries die. A developer building a demo page reaches for `<button onClick={...}>` because "it's just a demo" — and now the library has 7 raw buttons hidden inside `CompilationDemoPage.tsx` that nobody noticed for weeks. The library appears complete from the outside, but the demos prove it isn't.

This skill is `library-lint` with the gloves off: scoped to `prototypes/`, `demos/`, and `examples/` folders, and with raw HTML affordances upgraded from "warning" to "error." If you can't build the demo with library components alone, the library has a gap — surface the gap; don't paper over it.

## When to Use

- Before shipping a prototype to stakeholders
- Pre-commit (recipe included below)
- As a periodic library-coverage audit
- The user says: "scan the demos", "audit the prototypes", "check demo compliance", "are the demos clean", "find raw HTML in prototypes"

Do NOT use for:
- Source component files (`components/**/*`) — those legitimately implement primitives. Use `library-lint` instead.
- General code quality (use `scored-code-review`)

## Prerequisites

1. Current working directory is the library root
2. `manifest.json` exists (defines what components the demo *should* use)
3. `prompt-rules.md` exists (defines banned patterns)

## Scope

By default, scans every file under:
- `prototypes/**/*.{tsx,jsx,html}`
- `demos/**/*.{tsx,jsx,html}`
- `examples/**/*.{tsx,jsx}` — *with one caveat*: examples pages may legitimately use `style={{}}` for demo wrapper layout. The user's existing examples are the calibration baseline; match what they already do. Inline styles on a demo wrapper are OK; raw `<button>` is never OK.

Pass an explicit glob to override.

## The check list

### Tier 1 — Errors (will fail the scan)

| # | Check | Why |
|---|---|---|
| 1 | No raw `<button>` | Every clickable affordance should use the library's `Button`. Exception: anchor-as-button is checked separately. |
| 2 | No raw `<input>` | Use `Input`. Type-narrow: `<input type="checkbox">` → `Checkbox`, `<input type="radio">` → `Radio`, `<input type="range">` → flag as gap (no library equivalent yet?), `<input type="file">` → `FileUpload` |
| 3 | No raw `<select>` / `<option>` | Use `Select` or `Combobox` |
| 4 | No raw `<textarea>` | Use `Textarea` |
| 5 | No raw `<table>` | Use `Table` |
| 6 | No raw `<a>` styled as a button | grep for `<a` with `class*="button"` or `style="..."` containing background/border — flag |
| 7 | No raw `<dialog>` / custom modal | Use `Modal` |
| 8 | No raw `<details>` / `<summary>` | Use `Accordion` / `Disclosure` if the library has one; otherwise flag as gap |
| 9 | No hex codes outside comments | Same as `library-lint` Tier 1 |
| 10 | No Tailwind utility classes | Same as `library-lint` Tier 1 |
| 11 | No banned-library imports | Pull from `prompt-rules.md` "Banned patterns" |
| 12 | No references to undefined CSS variables | grep `var(--[a-z-]+)` — each must exist in `tokens/*.css`. The `--spacing-150` / `--spacing-250` class of bug. |

### Tier 2 — Warnings

| # | Check | Why |
|---|---|---|
| 13 | Magic spacing numbers | grep `padding|margin|gap` for numeric values not in `tokens/spacing.css` |
| 14 | Magic font sizes | grep `font-size` for values not in `tokens/typography.css` |
| 15 | Inline styles on non-wrapper elements | `style={{}}` on a component instance (e.g. `<Button style={{...}}>`) — should use a prop or a class instead |
| 16 | className with unknown prefix | If the project's prefix is `tt-`, any other prefix needs justification |

### Tier 3 — Informational

| # | Check | Why |
|---|---|---|
| 17 | Component coverage | What % of UI elements in the file use library components vs. raw HTML |
| 18 | Token coverage | What % of color/spacing values are tokens vs. hex/magic-numbers |

## Workflow

### 1. Confirm scope

Confirm the folder list (`prototypes`, `demos`, `examples`) and verify each one exists. Skip missing folders silently.

### 2. Read context

- `manifest.json` → `components.*` keys (what's available to use instead of raw HTML)
- `prompt-rules.md` → banned patterns + class prefix
- `tokens/colors.css`, `tokens/spacing.css`, `tokens/typography.css` → defined token names

### 3. Run each Tier 1 check

Use ripgrep when available, falling back to `grep -rn`. Example for raw `<button>`:

```
rg -tn --type-add 'jsxhtml:*.{tsx,jsx,html}' --type jsxhtml '<button\b' prototypes/ demos/ examples/
```

For undefined CSS variables (Tier 1.12):

1. Build the set of defined vars: `rg -No --no-filename 'var\(--[a-z0-9-]+\)' tokens/*.css | sort -u` (also grep `:root` declarations)
2. Extract every `var(--name)` reference in the scoped files
3. Set-difference — anything referenced but not defined is an error

This single check would have caught `--spacing-150` / `--spacing-250` immediately.

### 4. Cross-reference each violation with a suggested fix

For raw `<button>`: look up the library's `Button` import line in `manifest.json → components.Button.import` and suggest the swap.

For undefined variables: search `tokens/*.css` for the closest defined value (Levenshtein distance) and suggest it — e.g. `--spacing-150` not defined; closest: `--spacing-12` or `--spacing-16`.

### 5. Output

```
# Demo compliance report
Scope: prototypes/ + demos/ + examples/
Files scanned: 14
Date: 2026-06-09

## Summary
❌ Errors:    9
⚠️ Warnings:  6
ℹ️ Info:      2

## Errors

### 1. Raw <button> in prototypes (7)
- prototypes/CompilationDemoPage.tsx:142 — `<button className="trailing-rail__action">` → replace with `<Button variant="tertiary" size="small">`
- prototypes/CompilationDemoPage.tsx:158 — same
- ...
- prototypes/AuditDemoPage.tsx:88 — `<button onClick={...}>Add filter</button>` → `<Button variant="secondary">Add filter</Button>`

Suggested import (if not already present):
  `import { Button } from "../components";`

### 2. Undefined CSS variables (2)
- prototypes/CompilationDemoPage.css:88 — `padding: var(--spacing-150)` → undefined; closest defined: `--spacing-16` or `--spacing-12`
- prototypes/CompilationDemoPage.css:104 — `margin-top: var(--spacing-250)` → undefined; closest defined: `--spacing-24` or `--spacing-32`

### 3. ...

## Warnings
[same shape]

## Coverage
- Component coverage: 76% (24 library components, 8 raw HTML elements)
- Token coverage: 92% (138 token references, 11 hex/magic numbers)

## How to fix
Run with `--fix` to auto-apply suggested swaps where the mapping is unambiguous. Or paste this report back with "apply the fixes" and Claude will apply them.
```

### 6. Optional: auto-fix the unambiguous cases

For raw-`<button>` → `<Button>` where the button has no class but does have `onClick` and `children`, the substitution is unambiguous. Offer to apply.

For undefined `--spacing-150` where only one defined token is within edit distance 2, suggest but do not auto-apply — get user confirmation.

## Pre-commit hook recipe

Save the following to `.husky/pre-commit` (or your hook runner of choice):

```bash
#!/usr/bin/env bash
# Run demo compliance scan on staged files
set -e

staged=$(git diff --cached --name-only --diff-filter=ACM | grep -E '^(prototypes|demos|examples)/' || true)
if [ -z "$staged" ]; then
  exit 0
fi

echo "Running demo compliance scan on staged demo/prototype files..."
# This invokes Claude Code with the skill — alternatively, port the checks
# into a shell/Node script and call it directly here.
claude --print "Run demo-compliance-scanner on these files: $staged. Exit 1 if any Tier 1 errors."
```

Make it executable: `chmod +x .husky/pre-commit`. Note: the Claude-Code-in-hook path requires an installed CLI; teams that prefer a pure shell hook should port the Tier 1 checks (grep patterns above) into a small shell script.

## CI recipe

```yaml
# .github/workflows/demo-compliance.yml
name: Demo compliance
on: [pull_request]
jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Tier 1 checks
        run: |
          set -e
          # Raw HTML affordances
          ! rg -n '<button\b' prototypes/ demos/ examples/ 2>/dev/null
          ! rg -n '<input\b' prototypes/ demos/ examples/ 2>/dev/null
          ! rg -n '<select\b' prototypes/ demos/ examples/ 2>/dev/null
          # Undefined token references would need a small node script — see SKILL.md
```

## Output

A markdown report (printed and optionally saved to `./demo-compliance-report.md`) plus optional auto-fix step.

## Common failure modes

- **Scanning component source files.** This skill is for `prototypes`/`demos`/`examples` only. Source files (`components/`) legitimately implement primitives — that's `library-lint`'s job.
- **Treating false positives as errors.** A demo page wrapper using `style={{ padding: 24 }}` for layout is fine. A library `<Button style={{ padding: 24 }}>` is not.
- **Silent suggestion mismatches.** If the suggested swap (`<button>` → `<Button>`) doesn't preserve the user's existing props, say so explicitly — don't ship a fix that breaks the demo.
