---
name: figma-tokens-extract
description: Extract design tokens (colors, spacing, typography, radii, borders) from a Figma file via the Figma MCP and convert them to CSS custom properties in `tokens/colors.css`, `tokens/spacing.css`, `tokens/typography.css`. Use when bootstrapping a new AI-readable component library, when refreshing tokens after a Figma rebrand, or whenever the user asks to "extract tokens from Figma", "convert Figma variables to CSS", "build my tokens files", "pull design tokens", or "generate tokens.css from Figma". Requires the Figma MCP server to be connected.
trigger: [extract tokens from figma, convert figma variables to css, build my tokens files, pull design tokens, generate tokens.css from figma, refresh tokens, sync design tokens, set up tokens, tokens from figma, i need tokens, pull tokens]
license: Apache-2.0
---

# Figma Tokens Extract

## Objective

Take a Figma file and produce three clean, AI-readable CSS files: `tokens/colors.css`, `tokens/spacing.css`, `tokens/typography.css`. Every Figma Variable becomes a CSS custom property. Naming converts directly: `surface/info/rest` → `--surface-info-rest`. Hex codes survive only as the values, never as standalone references in component code.

This skill produces the foundation that the rest of the component library is built on. Get this right and every downstream component will use real tokens.

## When to Use

- Bootstrapping a new component library from an existing Figma file
- Refreshing tokens after a Figma rebrand or system update
- Migrating a library that hardcoded hex values back onto a token system
- The user says: "extract tokens from Figma", "build my tokens files", "convert Figma variables to CSS", "pull design tokens"

Do NOT use when:
- The user only needs a single token value (just read it inline)
- There are no Figma Variables yet (this skill won't invent semantic names — surface that as a blocker)
- The user wants to write tokens by hand (they have their reasons; respect that)

## Prerequisites

1. Figma MCP server must be connected. Verify by checking that `mcp__*__get_variable_defs` or `mcp__*__get_design_context` tools are available. If they aren't, stop and tell the user to install the Figma MCP first.
2. The user must provide a Figma file URL or fileKey + a node ID (usually the cover page or a "Variables" page).

## Workflow

### 1. Gather inputs

Ask the user for:
- **Figma file URL** (or `fileKey` + `nodeId`)
- **Project root** if not already in it (where `tokens/` will be written)
- **Naming convention** — confirm they want the default `surface/info/rest` → `--surface-info-rest` mapping. Slashes and spaces become hyphens; everything lowercases.

If any input is missing, stop and ask. Do not guess.

### 2. Verify project layout

Before writing anything, check the project root:
- If `tokens/` already exists, ask: overwrite, merge, or write to a new subfolder (e.g. `tokens/v2/`)?
- If `manifest.json` exists, plan to reference the new token files from its `library.tokenFiles` array as a final step.

### 3. Pull Figma Variables

Use the Figma MCP `get_variable_defs` tool on the file. If that doesn't return enough, fall back to `get_design_context` on the variables page (`?node-id=...`).

Group results into buckets:
- **Colors** — anything with a hex value or color reference
- **Spacing** — numeric values used for padding/margin/gap
- **Typography** — font families, sizes, weights, line heights, letter spacing
- **Radii** — corner-radius values
- **Borders** — border widths and (optionally) border colors that are already in Colors
- **Sizes** — element heights, icon sizes
- **Other** — anything that doesn't fit (write to a comment block, ask the user to categorize)

If the Figma file uses a semantic/global split (e.g., `blue/100` as global, `action/primary/rest` as semantic that references `blue/100`), preserve the split as TWO sections in `tokens/colors.css`: a `/* Global palette */` block at the top, then a `/* Semantic tokens */` block that uses the global names as CSS variable references where possible — but emit hex values as fallback for any tool that doesn't support nested vars.

### 4. Generate the three files

**`tokens/colors.css`** template:

```css
/* ============================================================
   COLOR TOKENS — extracted from Figma file [FILE_NAME]
   Source: figma.com/design/[FILE_KEY]
   Generated: [DATE]
   Do not edit hex values by hand. Re-run figma-tokens-extract to refresh.
============================================================ */

:root {
  /* Global palette */
  --global-blue-05:  #f2f5ff;
  --global-blue-100: #0a41fa;
  /* ... */

  /* Surfaces */
  --surface-default:       #ffffff;
  --surface-background:    #f7f8fc;
  --surface-info-rest:     #f2f5ff;
  /* ... */

  /* Text */
  --text-primary: #2e384d;
  /* ... */

  /* Borders */
  --border-muted: #d5d7db;
  /* ... */

  /* Actions */
  --action-primary-rest:  #0a41fa;
  --action-primary-hover: #0834c7;
  /* ... */
}
```

**`tokens/spacing.css`** template:

```css
:root {
  --spacing-0:  0;
  --spacing-4:  4px;
  --spacing-8:  8px;
  --spacing-12: 12px;
  /* ... */

  --radius-default: 4px;
  --radius-full:    99999px;

  --element-height-small:  24px;
  --element-height-medium: 32px;
  --element-height-large:  40px;

  --icon-size-small:  20px;
  --icon-size-medium: 24px;
}
```

**`tokens/typography.css`** template:

```css
:root {
  --font-family-base: "Rubik", sans-serif;

  --font-size-xs: 12px;
  --font-size-sm: 14px;
  --font-size-md: 16px;
  --font-size-lg: 20px;
  --font-size-xl: 28px;

  --font-weight-regular: 400;
  --font-weight-medium:  500;

  --line-height-tight:   1.3;
  --line-height-default: 1.4;
  --line-height-relaxed: 1.6;
}
```

### 5. Optional: create `tokens/index.css`

Single import target for consumers:

```css
@import "./colors.css";
@import "./spacing.css";
@import "./typography.css";
```

### 6. Update `manifest.json` if it exists

In `library.tokenFiles`, ensure all three files are listed. Also populate the top-level `tokens` block with a compact JSON mirror of the most-used semantic tokens (so AI tools that read the manifest see the tokens without opening another file).

### 7. Verify and report

After writing files:
- Print a summary: how many color / spacing / typography variables were extracted
- Flag any Figma Variables that didn't fit a category (give the user a list to categorize)
- Show one CSS snippet from each file as a sanity-check sample

## Naming convention rules

- `path/to/value` → `--path-to-value`
- Spaces → hyphens
- All lowercase
- camelCase becomes kebab-case (`primaryAction` → `primary-action`)
- Numeric scales preserve their numbers (`grey/100` → `--grey-100`)

If the Figma file uses non-conforming names (e.g. emojis, special characters), warn the user and suggest cleanup in Figma before re-running.

## Output

Three files written:
1. `tokens/colors.css`
2. `tokens/spacing.css`
3. `tokens/typography.css`

Plus optionally:
4. `tokens/index.css` (if it doesn't already exist)

A summary report including:
- Count of variables extracted per category
- List of any uncategorized variables (with the user's input needed)
- Path to each written file

## When this skill is done

Hand control back to the user. Suggest the natural next step: "Now you can build your manifest.json. Try the `component-from-figma` skill, or write the manifest skeleton manually using these tokens as the foundation."
