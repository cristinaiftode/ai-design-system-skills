---
name: figma-batch-probe
description: Probe many Figma nodes in parallel — given N Figma URLs / node IDs, fan out `get_design_context`, `get_screenshot`, `get_variable_defs`, and `get_metadata` calls concurrently and return one structured digest per node (variants, dimensions, variables used, screenshot reference, layer names, description text). Use when the user pastes multiple Figma URLs and asks "what are these?" / "compare these" / "what variants do these have", when planning a multi-component build (probing the whole family before deciding which one to start with), when reverse-engineering a Figma file, or whenever the user says "probe these figma nodes", "batch fetch figma context", "give me a digest of these nodes", "look at all these nodes at once", "fan out figma probes". Requires the Figma MCP server. Replaces the 30+ sequential tool calls a typical multi-node request balloons into.
trigger: [probe these figma nodes, batch fetch figma context, give me a digest of these nodes, look at all these nodes at once, fan out figma probes, multi node figma probe, batch figma probe]
license: Apache-2.0
---

# Figma Batch Probe

## Objective

Take a batch of Figma node references (URLs or `fileKey:nodeId` pairs), fan out the four standard Figma MCP probes (`get_design_context`, `get_screenshot`, `get_variable_defs`, `get_metadata`) **in parallel**, and return one compact digest per node. The point is to compress what would otherwise be 4×N sequential tool calls into a single round trip that the user can read in seconds and use to drive the next step (which component to build first, which variants exist, which tokens are referenced).

This is the skill that turns "here are 11 Figma URLs, tell me what they are" from a multi-minute slog into a 30-second answer.

## When to Use

- The user pastes 2+ Figma URLs in a single message and asks any question about them
- Before running `component-from-figma` across a family of related nodes (Button/Primary/Medium, Button/Primary/Small, Button/Secondary/Medium…) — probe them first to see what's shared
- Auditing a Figma file by sampling a representative set of nodes
- The user says: "probe these nodes", "batch fetch", "look at all these", "give me a digest"

Do NOT use when:
- The user provides one Figma URL — just call the Figma MCP tools directly
- The user wants a full readiness audit — use `figma-readiness-check` instead

## Prerequisites

1. Figma MCP server connected (`mcp__*__get_design_context`, `mcp__*__get_screenshot`, `mcp__*__get_variable_defs`, `mcp__*__get_metadata`)
2. At least 2 node references from the user

## Workflow

### 1. Collect and normalize the inputs

Accept any of:
- Figma URLs: `https://figma.com/design/<fileKey>/<File-Name>?node-id=12-34`
- `fileKey:nodeId` pairs
- A space- or newline-separated list

Normalize each to a `{ fileKey, nodeId, label }` triple. `label` defaults to the path tail of the URL (so the digest is readable). If the user provided custom labels (e.g. `Button/Primary/Medium`), use those.

If any URL is malformed, stop and ask — do not skip silently.

### 2. Fan out the probes

For each node, queue four parallel calls:
- `mcp__*__get_design_context` — dimensions, layout, variant props, layers
- `mcp__*__get_screenshot` — visual reference (keep the asset reference, do not embed)
- `mcp__*__get_variable_defs` — every Variable bound to this node
- `mcp__*__get_metadata` — name, type, description field, parent

**Critical:** all calls go in a single tool-call batch (one message, multiple tool uses). Do not serialize. Probing 11 nodes ≈ 44 tool calls — these all run concurrently.

If the MCP server caps concurrency, fall back to batches of 4–8, but never one-at-a-time.

### 3. Aggregate the digest

Produce a table of one row per node:

```
# Figma batch probe — 11 nodes

| Label | Size | Variants | Variables used | Screenshot | Notes |
|---|---|---|---|---|---|
| Button/Primary/Medium | 120×40 | variant=primary, size=medium | --action-primary-rest, --text-on-action, --radius-default | ✓ | — |
| Button/Primary/Small  | 96×32  | variant=primary, size=small  | --action-primary-rest, --text-on-action, --radius-default | ✓ | — |
| Tag/Counter           | 24×20  | type=counter                 | --surface-error-active, --text-on-action, --radius-full   | ✓ | Description: "filled red disc — NOT a chip" |
| ...                   | ...    | ...                          | ...                                                       | ✓ | ...    |
```

Then a `## Shared findings` section that highlights:
- Variables used by ≥ 2 nodes (good signal for shared tokens)
- Variables used by exactly 1 node (potential one-off, double-check)
- Variables referenced but NOT present in `tokens/*.css` (missing token alert)
- Description-field text on any node (this is where designer annotations like "Trans/Black/30 overlay" live — surface every one)

### 4. Recommend the next step

Based on what the digest reveals, end with one of:

- "These are a family of `Button` variants. Recommend running `component-from-figma Button` once — the variants will be folded into the same component."
- "Three of these (Tag/Counter, Badge, Indicator) look like they overlap. Worth deciding which one to build before generating."
- "Two missing tokens detected: `--action-quaternary-rest`, `--border-warning-strong`. Run `figma-tokens-extract` to refresh `tokens/colors.css` before building."
- "Found a description-field annotation on Modal: `Overlay = Trans/Black/30`. Verify your `--surface-modal` token matches — your current value is `Trans/Black/30 (rgba(46,56,77,0.3))`, so you're good."

## Output

A markdown table + a shared-findings block + a recommended-next-step line. No code generated, no files written — this is a read-only fan-out.

## Common failure modes

- **Serializing the calls.** Defeats the point — if the digest takes more than 30 seconds, you serialized. Always batch.
- **Embedding screenshots inline.** Bloats the response. Reference them ("✓") and let the user follow up if they want to see one.
- **Skipping the description field.** That's where designer notes live. Always include `get_metadata` and surface any non-empty description in the Notes column.
- **Inventing tokens.** If the variant uses a token that isn't in `tokens/colors.css`, say so explicitly — don't quietly hex-fall-back.
