---
name: token-drift-check
description: Diff the local `tokens/*.css` files against the latest Figma Variables (via the Figma MCP) and produce a punch list of drifts — variables added in Figma but missing in code, variables renamed in Figma, variables whose value changed in Figma, and any designer-authored notes left in Figma Variable `description` fields (the "Trans/Black/30 overlay" kind of message that gets lost between design and code). Three drift directions, one report. Also flags `var(--name)` references in `components/**/*.css` that point to tokens not defined anywhere — the "I typed `--spacing-150` and it silently evaluated to nothing" class of bug. Use on a schedule (after every Figma update), before a release, when components look slightly off, or whenever the user asks to "check token drift", "diff tokens against figma", "are my tokens stale", "did designer change anything", "find token mismatches", or "audit tokens vs figma".
trigger: [check token drift, diff tokens against figma, are my tokens stale, did designer change anything, find token mismatches, audit tokens vs figma, token drift check]
license: Apache-2.0
---

# Token Drift Check

## Objective

Tokens are the contract between design and code. When that contract drifts — because the designer renamed a variable, changed a hex value, or added a new spacing step — the codebase quietly diverges from Figma and nobody notices until a designer review surfaces it.

This skill catches three classes of drift in one pass:

1. **Figma → code drift** — variables added / renamed / re-valued in Figma that haven't propagated to `tokens/*.css`
2. **Designer annotations** — text left in Figma Variable `description` fields (e.g. "Overlay = Trans/Black/30 (NOT 50)") that often encode a design decision nobody copied into code
3. **Code-internal drift** — `var(--name)` references in `components/**/*.css` and `prototypes/**/*.css` that reference tokens not defined in `tokens/*.css` (the silent-evaluates-to-empty bug)

## When to Use

- Periodically — after every Figma update, before each release
- When components look "slightly off" and you suspect a value shifted
- After `figma-tokens-extract` to verify the extraction is in sync with what's actually in Figma now
- The user says: "check token drift", "diff tokens against Figma", "are my tokens stale", "did designer change anything", "find token mismatches", "audit tokens vs Figma"

Do NOT use when:
- The Figma MCP is unavailable (this skill needs it)
- The library has no `tokens/*.css` yet (run `figma-tokens-extract` instead)

## Prerequisites

1. Figma MCP server connected (`mcp__*__get_variable_defs`, `mcp__*__get_metadata`)
2. `tokens/*.css` exist in the library
3. The Figma file URL or `fileKey`

## Workflow

### 1. Load the local snapshot

Read `tokens/colors.css`, `tokens/spacing.css`, `tokens/typography.css`, and any other files listed in `manifest.json → library.tokenFiles`. Build a map:

```
{
  "--surface-modal": { value: "rgba(46,56,77,0.3)", file: "tokens/colors.css", line: 88 },
  "--spacing-12":    { value: "12px",              file: "tokens/spacing.css", line: 6 },
  ...
}
```

### 2. Load the Figma snapshot

Call `mcp__*__get_variable_defs` on the Figma file. For each Variable, capture:
- Name (e.g. `surface/modal`)
- Value (resolved for the default mode; if there are multiple modes, capture all)
- Description field (the annotations bucket — never skip this)
- Last-modified timestamp if available

Normalize Figma names to the project's CSS variable convention: `surface/modal` → `--surface-modal`. Use the same convention `figma-tokens-extract` uses.

### 3. Compute drift in three directions

#### A. Figma → code

For each Figma variable not in the local map: **MISSING IN CODE.**
For each name match where the value differs: **VALUE CHANGED.**

For each name in code not in Figma: **STALE IN CODE** (the designer renamed or removed the variable).

#### B. Designer annotations

For each Figma variable with a non-empty `description` field: surface the text. Categorize:
- Looks like a design rule (`"Use only for overlays"`, `"Trans/Black/30 NOT 50"`) — flag for code review (is the rule reflected anywhere?)
- Looks like a TODO (`"Replace once redesign ships"`) — flag as informational
- Looks like a deprecation (`"Deprecated, do not use"`) — flag as warning

#### C. Code-internal undefined references

For every `components/**/*.css` and `prototypes/**/*.css` file, grep `var\(--[a-z0-9-]+\)` and check each reference against the local map. Any reference not in the map is **UNDEFINED** — this is the `--spacing-150` class of bug.

For each undefined reference, suggest the closest defined token by edit distance.

### 4. Output the punch list

```
# Token drift check
Figma file: tripletex-design-library (4WZWeGkM…)
Local tokens: 198 variables across tokens/{colors,spacing,typography}.css
Figma tokens: 207 variables
Date: 2026-06-09

## A. Figma → code (9 drifts)

### Missing in code (3)
- `--surface-info-strong` (#3B67FB) — added in Figma 2 weeks ago; not in tokens/colors.css
- `--text-on-warning` (#0F131A) — added in Figma; not in code
- `--spacing-2` (2px) — added in Figma; not in code

### Value changed (4)
- `--action-primary-hover`
  - Figma: #0834C7
  - Code: #0635C0
  - Difference: small but real; designer likely re-tuned the hover
- `--text-muted`
  - Figma: #6B7280
  - Code: #818794
  - Difference: ⚠️ different greys — likely intentional rename, double-check
- ...

### Stale in code (2)
- `--surface-info-soft` — not in Figma anymore. Likely renamed → `--surface-info-rest`. Code references: 4 (components/Banner.css, components/Alert.css, …)
- `--text-on-disabled` — not in Figma. Possibly dropped.

## B. Designer annotations (3)

- `surface/modal` — description: "Overlay = Trans/Black/30 (NOT 50 — we tested both and 30 won)"
  → Code value matches (`rgba(46,56,77,0.3)` = Trans/Black/30). ✅
- `action/primary/hover` — description: "Tuned darker after the May review."
  → Code value (#0635C0) is the OLD value. ❌ Update to #0834C7.
- `surface/automation/rest` — description: "Deprecated, do not use in new components."
  → Code references: 1 (components/Banner.css:38). ⚠️ Investigate.

## C. Undefined references in code (3)

- `components/Modal.css:88` — `padding: var(--spacing-150)` → undefined. Closest defined: `--spacing-16` (#16px), `--spacing-12` (#12px)
- `components/Modal.css:104` — `margin-top: var(--spacing-250)` → undefined. Closest: `--spacing-24`, `--spacing-32`
- `prototypes/dashboard.html:42` — `color: var(--text-secundary)` → typo? Closest: `--text-secondary` (no, doesn't exist either) or `--text-muted`

## Recommended actions

1. Apply the 3 missing-in-code additions to tokens/colors.css and tokens/spacing.css (or re-run figma-tokens-extract for a full refresh).
2. Update --action-primary-hover from #0635C0 to #0834C7. (Fix the designer-annotation discrepancy at the same time.)
3. Fix the 3 undefined references — likely typos (--spacing-150 → --spacing-16; --text-secundary → --text-muted).
4. Decide on --surface-info-soft: rename or remove? 4 component files reference it.
```

### 5. Offer to apply unambiguous fixes

For:
- **Missing-in-code** → offer to append the new variables to the right `tokens/*.css` files
- **Undefined references** where the closest match has edit distance ≤ 2 → suggest, do not auto-apply
- **Stale tokens** → never auto-remove (the user must investigate references first)

### 6. Optional: scheduled run

If the user asks for a periodic check, suggest pairing with the `schedule` skill — e.g. weekly token-drift-check that posts the report to Slack.

## Output

A markdown report (printed and optionally saved to `./token-drift-report.md`) with three drift sections, designer annotations, and a recommended actions list.

## Common failure modes

- **Skipping the description field.** This is where designer notes live. Every Variable in Figma can have a description; many won't, but the ones that do are the most valuable signal in this report.
- **Auto-removing stale tokens.** A token in code but not in Figma might still be in use across many files. Always require human review before deleting.
- **Confusing value drift with rounding.** Some Figma exports round (e.g. `rgba(46,56,77,0.30000001)`); normalize to the same precision before comparing.
- **Treating mode-aware tokens as single values.** Figma supports multiple modes (light/dark). If the local tokens are light-only, compare against the light mode; flag dark-mode-only Figma values as informational, not as drift.
