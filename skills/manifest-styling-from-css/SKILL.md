---
name: manifest-styling-from-css
description: Read a component's CSS file and emit (or update) the `styling` and `colorMapping` blocks in `manifest.json` so they accurately reflect the actual styles. Parses dimensions (height, padding, gap, icon size), radius, border, typography (font-family, size, line-height, weight), shadow, focus ring, and per-variant background/text colors from the CSS, then writes them in the project's existing manifest schema. Idempotent — re-running keeps the manifest in sync after CSS edits. Use after editing a component's CSS, when auditing manifest completeness across the whole library, when a styling block is missing or incomplete, or whenever the user asks to "sync the manifest styling", "refresh the manifest from CSS", "fill in the styling block for [Component]", "enrich the manifest", "extract styling to manifest", or "audit manifest styling coverage".
trigger: [sync the manifest styling, refresh the manifest from css, fill in the styling block, enrich the manifest, extract styling to manifest, audit manifest styling coverage, manifest styling drift]
license: Apache-2.0
---

# Manifest Styling From CSS

## Objective

The `styling` and `colorMapping` blocks in `manifest.json` are how AI tools (Claude, v0, Lovable, Figma Make) know what a component *actually looks like* without reading the CSS. When those blocks are missing, stale, or partial, every downstream prompt has to fall back to guessing or re-reading the source, and components drift between what the manifest claims and what the code ships.

This skill closes that gap. It reads the CSS, derives the structured blocks, and writes them into the manifest in the project's existing schema. Re-running it after any CSS edit re-syncs the blocks. This replaces the one-time "agent dispatch enrichment" pass with a routine, idempotent step.

## When to Use

- After editing `components/<Name>.css` (the canonical follow-up)
- When `verify-component` flags a missing or incomplete `styling` block
- When auditing the whole library — pass `--all` and re-sync every component
- The user says: "sync the manifest styling", "refresh the manifest from CSS", "fill in the styling block", "enrich the manifest", "audit manifest styling coverage"

Do NOT use when:
- The component doesn't have a CSS file (the manifest's `styling` block is then editorial, not derived — leave it alone)
- The user wants to invent new styling (this skill only mirrors what exists in the code)

## Prerequisites

1. Current working directory is the library root
2. `manifest.json` exists with at least one populated component entry (used as the schema reference)
3. `components/<Name>.css` exists for the target component(s)

## Workflow

### 1. Determine the schema

Read `manifest.json` and pick the most populated component entry as the **schema reference**. For Tripletex Atlas, this is typically `Button`. The schema reference defines:

- Which sub-keys belong under `styling` (e.g. `dimensions`, `border`, `radius`, `typography`, `focusRing`, `states`, `shadow`)
- Which sub-keys belong under `colorMapping` (e.g. `primary.bg`, `primary.hoverBg`, `primary.activeBg`, `primary.text`, `disabled.bg`, `disabled.text`)
- Value style (e.g. `"40px (medium) / 32px (small)"` vs `{ "medium": "40px", "small": "32px" }`)

**Do not invent a schema.** If the project's manifest uses different sub-keys (e.g. `padding` instead of `dimensions.paddingX`), match what's there.

### 2. Identify the target

Two modes:
- **Single component** — user provided a name like `Modal` or `Tab`
- **All components** — user said "audit", "all", "library-wide"

For `all`, build a list from `manifest.json → components.*` keys, intersected with `components/*.css` files. Skip anything in the manifest that doesn't have a CSS file.

### 3. Parse each component's CSS

For each target, read `components/<Name>.css` and extract:

#### Dimensions
- `height` — from `.tt-<name>` (or `.tt-<name>--size-*` for per-size values)
- `min-height`, `max-height`
- `padding` (`paddingX` / `paddingY` if split) — capture per-size if a modifier exists
- `gap` (CSS grid / flex)
- Icon sizing — typically from `.tt-<name>__icon { width / height }`

#### Radius
- `border-radius` on the root — flag if it's a hex value instead of `var(--radius-*)`

#### Border
- `border-width`, `border-style` from the root (and per-state if hover changes width)

#### Typography
- `font-family`, `font-size`, `line-height`, `font-weight`, `letter-spacing`
- Pull from the root rule unless explicitly overridden in a modifier

#### Focus ring
- Look for `:focus-visible` or `:focus` rules — capture `outline`, `box-shadow` (for `--border-focus` halos), and `outline-offset`

#### States
- Each `:hover`, `:active`, `:focus`, `:disabled`, `[data-state="loading"]` rule that changes background or text or cursor — write a one-line summary into `states.<name>` (e.g. `"loading": "cursor: progress; spinner animation: 0.8s linear infinite"`)

#### Shadow
- `box-shadow` rules — capture as a string

#### Per-variant colors → `colorMapping`
- For each `--variant-*` modifier in the CSS, grab `background`, `background-color`, `color`, `border-color` for `rest`, `:hover`, `:active`, `:disabled` selectors
- Emit them under `colorMapping.<variant>.{bg, hoverBg, activeBg, text, border}` — preserving the schema reference's exact key names

### 4. Format values to match the schema reference

Common project patterns to mirror exactly:

- **Token + hex fallback** — Atlas uses `"var(--action-primary-rest) / #0A41FA"`. If the schema reference uses this dual notation, you must too. Look up the hex by reading the variable's value from `tokens/colors.css`.
- **Per-size compact form** — Atlas uses `"40px (medium) / 32px (small)"` for height. Match that when multiple values exist.
- **Plain string vs nested object** — `"radius": "4px"` (Atlas) vs `"radius": { "default": "4px" }`. Mirror the schema reference.

### 5. Diff against the existing manifest

For each component, compute the diff between the parsed `styling`/`colorMapping` and what's currently in `manifest.json`. Output:

```
# Manifest styling sync — Modal

## Diff
- styling.dimensions.height: missing → "640px (desktop) / 100% (mobile)"
- styling.radius: "8px" → "var(--radius-default) / 4px (desktop top corners only on mobile: 16px)"
- styling.focusRing: missing → { "width": "2px", "color": "var(--border-focus) / #6C8DFC", "offset": "-2px" }
- colorMapping.overlay.bg: missing → "var(--surface-modal) / #2E384D4D"

## No changes
- styling.typography
- colorMapping.primary

## Total
4 changes, 2 unchanged.
```

### 6. Confirm before writing

For single-component runs, show the diff and ask: "Apply these changes to `manifest.json`?"

For `--all` runs, group by component and show a compact summary first; then ask once for blanket approval (or `pick` mode where the user accepts/rejects per component).

### 7. Write the changes

Edit `manifest.json` in place. Preserve formatting (2-space indent, key order). Do not touch any other top-level keys.

### 8. Verify

After writing:
- Re-read the entry; confirm it parses as valid JSON
- Confirm every value that references a CSS variable (`var(--...)`) corresponds to a real variable in `tokens/*.css`
- For dual-notation entries, confirm the hex in the slash matches the variable's actual value

### 9. Report

```
Manifest styling synced:
- Modal: 4 fields updated (height, radius, focusRing, overlay.bg)
- Tab: 2 fields updated
- Banner: no changes

Token references: 14 (all resolved)
Hex fallbacks: 14 (all match their CSS variable values)
```

Suggest: `verify-component <Name>` to re-run the standard checklist now that the manifest is up to date.

## Output

Modified `manifest.json` (one or more `styling` / `colorMapping` blocks updated) plus a diff report. Read-only mode (`--check`) prints the diff without writing — useful for CI.

## Common failure modes

- **Inventing schema keys.** The project's manifest has the schema. Read an existing entry first. Don't add `styling.spacing` if the schema reference uses `styling.dimensions.gap`.
- **Skipping the hex fallback.** If the schema uses `"var(--token) / #HEX"`, you must look up the hex from `tokens/colors.css`. Don't write only the variable name.
- **Over-parsing.** This skill mirrors what the CSS says. It does not invent missing properties. If the CSS has no `box-shadow`, the manifest should have no `styling.shadow`.
- **Touching unrelated entries.** Edit only the target component's block. Do not reformat the whole file.
