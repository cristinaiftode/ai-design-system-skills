---
name: library-freshness-check
description: Audit a whole Figma component library against the local prototyping library (`manifest.json` + `tokens/*.css` + `prompt-rules.md`) and produce a unified drift report — what's new in Figma but missing in code, what's stale in code but gone from Figma, what's been renamed, what variants have been added or removed, what token values have changed, what new designer annotations have appeared in description fields, and what's been marked deprecated. Walks every page of the Figma file (not just one node), batches the probes in parallel, and produces two outputs in one pass — a Slack-pasteable summary for designers / PMs and an engineer-readable action list that names which skill to run for each fix. Designed to be run weekly (or pre-release) as a maintenance check — pairs with the `schedule` skill for automated runs. Use when the user asks "is our library up to date with Figma", "what's behind in our library", "library freshness check", "audit library vs Figma", "is anything stale", "library sync status", "what's changed in Figma", "did the designer add new components", "weekly library health check", "library maintenance report", or "are we drifting from Figma". Requires the Figma MCP server.
trigger: [library freshness check, is our library up to date, whats behind in our library, audit library vs figma, library sync status, whats changed in figma, did the designer add new components, weekly library health check, library maintenance report, are we drifting from figma, library drift audit, is anything stale]
license: Apache-2.0
---

# Library Freshness Check

## Objective

Component libraries drift. Designers add components, rename variant sets, tune token values, mark things deprecated. Code lags. Without a deliberate check, the prototyping library (`manifest.json` + `tokens/*.css` + `prompt-rules.md`) silently falls behind what designers are actually working with in Figma — and prototypes start looking subtly off, designers stop trusting the library, and engineers spend a sprint catching up under pressure.

This skill is the **maintenance counterpart** to the build skills. It walks the entire Figma file (every page, every component-set), snapshots the local library, and produces a unified drift report aimed at designers / PMs first, engineers second. Run it weekly. Treat it as the team's design-system health check.

## When to Use

- Weekly recurring check (pair with the `schedule` skill)
- Before a release or sprint planning
- Returning to a library after time away
- Onboarding a new team member to a library
- When prototypes start looking subtly off and you suspect the library has drifted
- The user says: "library freshness check", "is our library up to date with Figma", "what's behind in our library", "audit library vs Figma", "did the designer add new components", "are we drifting"

Do NOT use when:
- The Figma MCP isn't available — this skill needs it
- There's no local library yet (run `library-scaffold` and the bootstrap skills first)
- You only want token drift — use `token-drift-check` directly
- You only want the coverage gap (missing in code) — use `next-component-to-build`

## Prerequisites

1. Figma MCP server connected (`mcp__*__get_metadata`, `mcp__*__get_design_context`, `mcp__*__get_variable_defs`, `mcp__*__get_screenshot`)
2. Current working directory is the library root
3. `manifest.json`, `tokens/*.css`, and (ideally) `prompt-rules.md` exist
4. The Figma file URL — auto-detected from `manifest.json → library.figmaFileKey` if present; otherwise asked

## Two rename-detection modes

- **Conservative (default)** — only flag possible renames when variant prop structure AND bound Variables match exactly between a "new in Figma" and a "stale in code" pair. Fewer false positives; may miss renames where the designer also restructured variants.
- **Heuristic (`--detect-renames=heuristic`)** — additionally compares a perceptual hash of each pair's screenshot. Catches more renames but adds one `get_screenshot` MCP call per candidate pair.

## The seven drift classes

| # | Class | What "behind" looks like |
|---|---|---|
| 1 | **New in Figma, not in code** | Designer shipped 3 new components (Banner v2, EmptyState, KeyValuePair); manifest doesn't have them |
| 2 | **Stale in code, gone in Figma** | `LegacyTag` in `manifest.json` but the Figma node is deleted; should be removed or deprecated in code |
| 3 | **Renamed** | `Tag/Counter` is now `Counter/Filled`; same variant structure, same Variables, just renamed. Flagged for human confirmation. |
| 4 | **Variant added / removed** | `Button` had `primary / secondary / tertiary` last sync; Figma now also has `destructive`. Variant exists in Figma, missing from the manifest enum. |
| 5 | **Token value changed** | `--action-primary-hover` was `#0635C0`, now `#0834C7` in Figma. Delegated to `token-drift-check` and folded into the report. |
| 6 | **Annotation changed** | Description field on a component / Variable updated since last sync (the Erwin "Overlay = Trans/Black/30" class of finding). |
| 7 | **Deprecated in Figma** | Variable / component description says "Deprecated" or "Do not use"; code still references it — plan migration. |

## Workflow

### 1. Gather inputs

- **Figma file URL or `fileKey`** — auto-detect from `manifest.json → library.figmaFileKey` if present; otherwise ask
- **Rename mode** — default `conservative`; `--detect-renames=heuristic` opt-in
- **Output path** — default `./library-freshness-report-YYYY-MM-DD.md`; `--no-save` to print only

### 2. Walk the Figma file

Use `mcp__*__get_metadata` on the file root to list pages. For each page, identify children of type `COMPONENT_SET` (and `COMPONENT` if the project uses standalone components instead of sets).

Many libraries put each component on its own page — walk them all. Skip pages clearly marked as non-component (e.g. `Cover`, `Changelog`, `Specs`, `Examples`, `Archive`) — but only by name pattern; do not skip silently.

### 3. Snapshot every component-set in parallel

For each component-set discovered, batch in groups of 8 (or whatever the MCP cap allows):
- `mcp__*__get_design_context` — variant props, dimensions, child structure
- `mcp__*__get_variable_defs` — bound Variables
- `mcp__*__get_metadata` — name, description field, parent page

Do NOT serialize. A 60-component library should complete this step in ~30–60 seconds.

Build the Figma snapshot:

```
figma = {
  "Button": { variants: [primary, secondary, tertiary, destructive], variables: {...}, description: "...", page: "Buttons", nodeId: "12:34" },
  "Banner v2": { ... },
  ...
}
```

### 4. Snapshot the local library

Read in parallel:
- `manifest.json → components.*` — name, props.variant.values, figmaNodeId, figmaName, description
- `tokens/*.css` — every `:root { --name: value }` declaration
- `prompt-rules.md` — per-component sections (used to detect references to removed components)

Build the code snapshot:

```
code = {
  "Button": { variants: [primary, secondary, tertiary], figmaNodeId: "12:34", figmaName: "Button", referenced_in_prompt_rules: true },
  "LegacyTag": { ... },
  ...
}
```

### 5. Compute the seven drift classes

**Class 1 — New in Figma, not in code**
`figma.keys() − code.keys() = new_components`

**Class 2 — Stale in code, gone in Figma**
`code.keys() − figma.keys() = stale_components` (before rename resolution)

**Class 4 — Variant added / removed**
For each name in both: `figma[name].variants △ code[name].props.variant.values`

**Class 5 — Token value changed**
Delegate to `token-drift-check` (invoke as a subroutine; embed its findings under section 5 of this report). Do not re-implement the diff.

**Class 6 — Annotation changed**
Description-field text on every Figma component / Variable. Store the hash of the description in the previous report (if it exists at `./library-freshness-report-*.md`) and compare. If no previous report, surface every non-empty description as "new" (first run).

**Class 7 — Deprecated in Figma**
Description field contains `"deprecated"`, `"do not use"`, `"will be removed"`, `"replaced by"` (case-insensitive). For each, check whether the deprecated thing is still referenced in code:
- Deprecated component → search `prototypes/**`, `examples/**`, `prompt-rules.md` for usage
- Deprecated Variable → search `components/**/*.css`, `prototypes/**/*.css` for `var(--name)` references

### 6. Detect renames (conservative)

For each pair `(new_components × stale_components)`, compute a similarity score:

- **Variant structure match** (40% weight) — same variant prop names and same enum values
- **Variables match** (40% weight) — overlapping set of bound Figma Variables
- **Page-location proximity** (20% weight) — same page, or page name shares a token

Threshold: **score ≥ 0.8 AND variant structure is identical** → flag as "likely rename, confirm".

In **heuristic mode** (opt-in), additionally:
- Pull `get_screenshot` for each candidate pair (only the surviving candidates above 0.5)
- Compute pHash (perceptual hash) of each screenshot
- If pHash distance ≤ 8 (out of 64), boost the score by +0.2

Confirmed renames move out of `new_components` and `stale_components` into a separate **`renamed`** list.

### 7. Render the dual output

#### A. Slack-pasteable summary (top of report, always printed to terminal)

```
# Atlas Library Freshness Report — 2026-06-10
Figma file: tripletex-design-library
Sync target: cristinaiftode/tripletex-component-library (commit 9159655)

📊 Freshness score: 87% (last week: 91%)

What's behind:
• 4 new components in Figma not in code: Banner v2, EmptyState, KeyValuePair, Toast
• 2 components renamed (please confirm): Tag/Counter → Counter/Filled · Modal/Overlay → Modal/Default
• 1 component variant added: Button gained 'destructive' variant
• 3 token values changed: --action-primary-hover, --text-muted, --surface-info-rest
• 2 new designer annotations: Modal/Default ("Overlay = Trans/Black/30"), Button/Primary ("Hover tuned darker May 26")
• 1 deprecated token still used: --surface-automation-rest (referenced in components/Banner.css)

✅ Looking good:
• 56 components in sync
• 198 / 201 tokens in sync
• 0 stale-in-code components

Full report: ./library-freshness-report-2026-06-10.md
```

Freshness score formula: `1 - (drift_items / total_items)` rounded to whole percent. `drift_items` = sum across the seven classes weighted equally; `total_items` = components in Figma + tokens defined.

#### B. Engineer action list (full markdown report, saved to disk)

For each drift class, a section with:
- The specific items
- The exact skill / command to run to fix each
- File paths and line numbers where applicable

```markdown
## 1. New components in Figma (4) — run component-from-figma

| Component | Figma node | Suggested next step |
|---|---|---|
| Banner v2  | 4521:889  | `component-from-figma "Banner v2"` — likely replacement for current Banner |
| EmptyState | 5102:1043 | `component-from-figma EmptyState` |
| KeyValuePair | 4990:2287 | `component-from-figma KeyValuePair` |
| Toast | 4711:1502 | `component-from-figma Toast` — then auto-chains verify, showcase, interactive-behavior |

## 2. Stale in code (0)

✅ Nothing in `manifest.json` is missing from Figma.

## 3. Possible renames (2) — confirm before acting

| Was | Now | Similarity | Confidence | Action |
|---|---|---|---|---|
| Tag/Counter | Counter/Filled | 0.92 | High | If confirmed: update `manifest.json → Counter.figmaNodeId` and `figmaName` |
| Modal/Overlay | Modal/Default | 0.85 | Medium | If confirmed: update `manifest.json → Modal.figmaNodeId` and `figmaName` |

⚠️ Conservative mode only matched these on variant structure + Variables. Re-run with `--detect-renames=heuristic` to also compare screenshots.

## 4. Variant changes (1)

- **Button** — Figma has `[primary, secondary, tertiary, destructive]`; manifest has `[primary, secondary, tertiary]`.
  - Action: add `"destructive"` to `manifest.json → Button.props.variant.values`
  - Then: `component-from-figma Button --variant destructive` to build the new visual

## 5. Token value changes (3) — delegated to token-drift-check

[Full diff from `token-drift-check`; abbreviated here for length]
- `--action-primary-hover`: `#0635C0` → `#0834C7` (5 component CSS files reference)
- `--text-muted`: `#818794` → `#6B7280` (12 component CSS files)
- `--surface-info-rest`: unchanged value, but description field updated

To apply: re-run `figma-tokens-extract` for a full refresh, OR edit the three lines manually in `tokens/colors.css`.

## 6. New designer annotations (2)

- **Modal/Default** (Figma description, new since 2026-06-03):
  > "Overlay = Trans/Black/30 (NOT 50 — we tested both and 30 won)"
  → Verify: `--surface-modal` is currently `rgba(46,56,77,0.3)` = Trans/Black/30. ✅ matches.
  → Action: thread this note into the prompt-rules section for Modal so future generations preserve it.

- **Button/Primary** (Figma description, new since 2026-05-26):
  > "Hover tuned darker — #0834C7"
  → Matches the token value change in section 5. ✅ One action covers both findings.

## 7. Deprecated in Figma, still used in code (1)

- **`--surface-automation-rest`** — Variable description: "Deprecated, do not use in new components."
  - Currently referenced in: `components/Banner.css:38`
  - Suggested action: discuss with designer — replace with `--surface-info-rest`, or leave as-is until a deprecation deadline
```

### 8. Save and timestamp

Write the report to `./library-freshness-report-YYYY-MM-DD.md` by default. If a previous report exists, link to it ("Last report: `./library-freshness-report-2026-06-03.md`") and compute the freshness-score delta (`+3 pp` or `-2 pp`).

### 9. Suggest scheduling

End the run with:

```
This skill is most useful as a recurring check. To run it every Monday morning:

  schedule "library-freshness-check" --cron "0 9 * * 1" --post-to slack

Or pair with the `loop` skill for a quick local re-check:

  loop 1h library-freshness-check
```

## Output

- **Always:** the Slack-pasteable summary printed to terminal
- **By default:** the full engineer report saved to `./library-freshness-report-YYYY-MM-DD.md`
- **Never:** changes to `manifest.json`, `tokens/*.css`, or `prompt-rules.md`. This skill is read-only by design. Acting on the report is the user's responsibility (often by chaining to `component-from-figma`, `figma-tokens-extract`, or a manual edit).

## Common failure modes

- **Serializing the Figma crawl.** A 60-component library serialized = 5+ minutes; batched = under 1 minute. Always batch.
- **False-positive renames.** Conservative mode is the default for a reason — flagging `Toast` as a "rename of `Banner`" because they share two Variables is worse than missing a rename. Always require human confirmation. Never auto-update `figmaNodeId` from this skill.
- **Treating every annotation as new on first run.** No previous report = every non-empty description shows as "new". Make sure the summary says "first run — all annotations surfaced" so the user knows what to expect.
- **Counting deprecation as drift.** A deprecated-but-still-used token is a maintenance item, not "behind." Surface in section 7 but don't dock the freshness score for it.
- **Skipping pages by silent guess.** If a page is named `Specs` or `Archive`, mention you're skipping it. The user may want it included.
- **Walking subcomponents recursively.** A `Button/Primary/Medium` variant is part of the `Button` set, not a separate component. Crawl at the `COMPONENT_SET` level, not every child node, or the report will be a wall of variants.

## Companion skills

- `token-drift-check` — called as a subroutine to compute section 5 of the report. Can also be run standalone for token-only audits.
- `next-component-to-build` — similar but narrower (coverage gap only). This skill's section 1 covers what it does, plus the other six drift classes.
- `figma-batch-probe` — same parallel-probe pattern this skill uses internally; usable standalone for ad-hoc multi-node digests.
- `figma-readiness-check` — different angle. Readiness = "is the Figma file ready for code generation?". Freshness = "has the code drifted from the Figma file?". Run readiness once before bootstrapping; run freshness weekly forever after.
- `schedule` — pairs naturally with this skill for weekly automated runs.
