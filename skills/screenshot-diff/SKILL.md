---
name: screenshot-diff
description: Compare a rendered component against its Figma source visually — render the component at its dev URL or showcase page in headless Chrome (or via the Claude Preview MCP), fetch the Figma node's export image, and produce a visual diff with annotated regions and a pass/fail verdict. Catches shape, color, spacing, and icon-vs-pill mistakes that pass `verify-component` but fail a real designer's review (e.g. a Tab counter built as a chip when Figma showed a filled disc; a Modal with a footer divider Figma didn't have; a topnav rendered with the wrong shell). Two modes: MCP-default (zero install, uses Figma MCP + Claude Preview MCP) and precision (Playwright + pixelmatch, opt-in for pixel-exact diffs). Use after building or editing a component, before opening a PR, or whenever the user asks to "diff [Component] against Figma", "is [Component] visually correct", "screenshot diff", "visual regression check", "compare with Figma", or "does this match the design".
trigger: [diff component against figma, is component visually correct, screenshot diff, visual regression check, compare with figma, does this match the design, figma vs code diff]
license: Apache-2.0
---

# Screenshot Diff

## Objective

`verify-component` confirms a component is *structurally* correct (files exist, exports wired, no hex codes). It cannot tell you whether the component *looks* like Figma. This skill closes that gap: render the live component, export the Figma node, and compare them.

This is the gate between "Claude says it built the component" and "the designer accepts the component." It catches the failure modes that the rest of the pack cannot:

- Tab counter rendered as a chip when Figma showed a filled red disc
- Modal with a footer divider that doesn't exist in Figma
- Standalone prototype URL using a custom slim shell instead of the real App shell
- Wrong padding, wrong icon size, wrong border radius — all of which lint clean but look wrong

## When to Use

- After `component-from-figma` finishes (chain it, after `verify-component`)
- Before opening a PR that touches a component's TSX or CSS
- When the user says: "diff against Figma", "is it visually correct", "compare with Figma", "does this match the design", "screenshot diff", "visual regression check"

Do NOT use when:
- The component doesn't have a showcase page (run `showcase-page-generator` first — the diff needs a live URL)
- The Figma file isn't accessible to the MCP (the diff has no reference)
- The user wants AAA accessibility checking (that's a different skill)

## Prerequisites

1. Figma MCP server connected
2. Dev server running (default: `http://localhost:5173`) OR Claude Preview MCP available
3. A showcase / examples page exists for the component (`examples/<Name>Page.tsx` or equivalent)
4. The component's Figma node URL or `fileKey:nodeId`

## Two modes

### Mode A — MCP-default (zero install)

Best for fast iteration during development. Lower fidelity (no pixel-exact diff), but catches the categorical errors (wrong shape, wrong color family, missing element).

Stack: Figma MCP `get_screenshot` + Claude Preview MCP `preview_screenshot` + visual inspection.

### Mode B — Precision (opt-in)

Best for pre-PR gates and CI. Pixel-exact, with a measurable diff percentage.

Stack: Playwright + Figma REST API + pixelmatch. Requires:
- `npm install --save-dev playwright pixelmatch pngjs`
- A Figma personal-access token in `FIGMA_TOKEN` env var
- Optional: a `scripts/screenshot-diff.mjs` script (template below)

Default to Mode A unless the user explicitly asks for "pixel diff", "precision", or "CI".

## Workflow — Mode A

### 1. Gather inputs

Ask the user for:
- **Component name** (PascalCase)
- **Figma node URL** (or `fileKey:nodeId`)
- **Dev URL** (default: `http://localhost:5173/<name>` based on the showcase page convention)
- **Viewport** (default: desktop 1440×900; offer mobile 390×844)

### 2. Capture both images

In a single tool-call batch:
- `mcp__*figma*__get_screenshot` on the Figma node — at 2× scale if available
- `mcp__Claude_Preview__preview_start` then `mcp__Claude_Preview__preview_screenshot` on the dev URL — at the same viewport, same scale

If the showcase page has multiple cells (variants × states), screenshot the *specific cell* — give Claude Preview a CSS selector like `[data-demo="primary-rest"]` and have it screenshot that region. If the showcase doesn't tag cells, ask the user to add `id`s in `showcase-page-generator`.

### 3. Compare visually

Lay the two images side by side in the response (markdown image syntax pointing at the MCP-returned URLs). For each region, evaluate:

- **Shape** — same outline? same corners? same proportions?
- **Color** — same fill family? Note: small hue shifts can be a token mismatch (caught by `library-lint`) — flag those for cross-check
- **Spacing** — same padding? Same gap between children?
- **Iconography** — if Figma has an icon-left, does code render an icon-left?
- **Composition** — same elements? Anything in Figma that's missing in code, or vice versa?

### 4. Output the verdict

```
# Screenshot diff — Modal (primary, rest)

Figma:    [link to MCP screenshot]
Code:     [link to Claude Preview screenshot]
Viewport: 1440×900

## Regions

✅ Shape — rounded card, 4px corners, matches
✅ Header — title + close icon, matches
❌ Footer — code has a 1px divider above the button row; Figma has no divider
✅ Overlay — semi-transparent dark, matches `--surface-modal`
✅ Padding — 24px all sides, matches

## Verdict
FAIL — 1 issue (footer divider).

## Recommended fix
In `components/Modal.css`, remove the `border-top: 1px solid var(--border-faint)` from `.tt-modal__footer`.
```

### 5. Offer to apply the fix

For unambiguous fixes (remove a property, change a token, swap a class), offer to apply via `Edit`. Ask before editing.

## Workflow — Mode B (precision)

### 1. Verify deps

Check `package.json` for `playwright` and `pixelmatch`. If missing, print the install command and stop — do not auto-install.

### 2. Verify the script

Check for `scripts/screenshot-diff.mjs`. If missing, offer to create it from this template:

```js
// scripts/screenshot-diff.mjs
// Usage: node scripts/screenshot-diff.mjs <componentName> <figmaNodeId> [viewport]
//
// Renders the dev URL in headless Chrome, fetches the Figma export via the
// Figma REST API, runs pixelmatch, writes diff.png and prints a verdict.

import { chromium } from "playwright";
import fs from "node:fs/promises";
import path from "node:path";
import { PNG } from "pngjs";
import pixelmatch from "pixelmatch";

const [, , componentName, figmaNodeId, viewport = "desktop"] = process.argv;
const FIGMA_TOKEN = process.env.FIGMA_TOKEN;
const FIGMA_FILE = process.env.FIGMA_FILE_KEY;
if (!FIGMA_TOKEN || !FIGMA_FILE) {
  console.error("Set FIGMA_TOKEN and FIGMA_FILE_KEY env vars.");
  process.exit(2);
}

const sizes = { desktop: { width: 1440, height: 900 }, mobile: { width: 390, height: 844 } };
const size = sizes[viewport] ?? sizes.desktop;

// 1. Render dev URL
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: size });
await page.goto(`http://localhost:5173/${componentName.toLowerCase()}`, { waitUntil: "networkidle" });
const codeBuf = await page.screenshot({ fullPage: false });
await browser.close();

// 2. Fetch Figma export
const figmaUrl = `https://api.figma.com/v1/images/${FIGMA_FILE}?ids=${figmaNodeId}&format=png&scale=2`;
const figmaMeta = await fetch(figmaUrl, { headers: { "X-Figma-Token": FIGMA_TOKEN } }).then((r) => r.json());
const figmaImgUrl = figmaMeta.images[figmaNodeId];
const figmaBuf = Buffer.from(await fetch(figmaImgUrl).then((r) => r.arrayBuffer()));

// 3. Diff
const out = path.resolve("./screenshot-diff-output");
await fs.mkdir(out, { recursive: true });
await fs.writeFile(path.join(out, "code.png"), codeBuf);
await fs.writeFile(path.join(out, "figma.png"), figmaBuf);

const code = PNG.sync.read(codeBuf);
const figma = PNG.sync.read(figmaBuf);
const { width, height } = code;
const diff = new PNG({ width, height });
const mismatched = pixelmatch(code.data, figma.data, diff.data, width, height, { threshold: 0.1 });
await fs.writeFile(path.join(out, "diff.png"), PNG.sync.write(diff));

const pct = (mismatched / (width * height)) * 100;
console.log(JSON.stringify({ componentName, viewport, mismatchedPixels: mismatched, mismatchPercent: pct.toFixed(2), threshold: 0.5 }));
process.exit(pct > 0.5 ? 1 : 0);
```

### 3. Run

```bash
FIGMA_FILE_KEY=<key> FIGMA_TOKEN=<token> node scripts/screenshot-diff.mjs Modal 12-34
```

Read the JSON output, write a report in the same shape as Mode A, plus a link to the `diff.png`.

### 4. Threshold

Default: `0.5%` mismatched pixels = fail. Configurable via `--threshold`. Anti-alias jitter typically lands below 0.2%, so 0.5% is a forgiving but not loose default.

## Output

A markdown verdict + side-by-side image references. In Mode B, also writes `screenshot-diff-output/{code,figma,diff}.png`.

## Common failure modes

- **Diffing the whole page instead of one component.** Tag cells (`id` or `data-demo`) and screenshot the region — full-page diffs drown in false positives.
- **Comparing at different scales.** Match the Figma export scale to the viewport DPR. Use 2× for both, or 1× for both.
- **No dev URL.** This skill cannot run if there's no showcase page. Run `showcase-page-generator` first.
- **Treating anti-alias jitter as a fail.** Real visual bugs produce dense diff regions. Scattered single-pixel mismatches across the whole image are anti-alias noise — adjust threshold or use the `threshold` argument to `pixelmatch`.
