# Design System Skills — Index

Sixteen skills for bootstrapping and maintaining AI-readable component libraries. They follow the conventions in `DESIGNER-PLAYBOOK.md`.

You don't invoke this file directly. It's a reference for which skill to reach for at each phase.

## Tier 1 — Bootstrap (use in this order)

| Skill | When | What it produces |
|---|---|---|
| `library-scaffold` | Empty folder, Day 1 | Vite + React + TS project shape, empty `manifest.json`, `prompt-rules.md`, `tokens/`, `components/`, `prototypes/`, `reference/` |
| `figma-readiness-check` | Before extracting tokens | Punch list of Figma hygiene fixes + a separate "annotations to honor" pass that surfaces designer notes from description fields |
| `figma-tokens-extract` | Once Figma is ready | `tokens/colors.css`, `tokens/spacing.css`, `tokens/typography.css` |
| `codebase-conventions-scan` | After tokens | Markdown report answering the 8 conventions questions; drops into `prompt-rules.md` |

## Tier 2 — Component building (the daily loop)

| Skill | When | What it produces |
|---|---|---|
| `figma-batch-probe` | Before a batch of related components | One digest per node (variants, dimensions, variables, screenshot) — all probes in parallel |
| `component-from-figma` | Adding a new component | `Component.tsx` + `.css` + schema-complete manifest entry + prompt-rules section + barrel export. Auto-chains `verify-component` and `showcase-page-generator`. |
| `manifest-styling-from-css` | After editing a component's CSS | Updated `styling` + `colorMapping` blocks in `manifest.json`. Idempotent. |
| `verify-component` | Mandatory final step of `component-from-figma` | 9-point pass/fail report (files, exports, manifest schema completeness, hex codes, undefined token refs, banned patterns) |
| `showcase-page-generator` | Pairs with `component-from-figma` | `examples/<Name>Page.tsx` (or `src/pages/<Name>Page.tsx`) with variant + size + state matrices |
| `component-interactive-behavior` | Pairs with `component-from-figma` (auto-chained for interactive categories) | Audited or filled interaction contract — handlers, ARIA, keyboard navigation, focus management. Safe to retrofit. |
| `screenshot-diff` | Before committing or opening a PR | Side-by-side Figma-vs-code diff. MCP-default (zero install) or precision mode (Playwright + pixelmatch). |
| `next-component-to-build` | When unsure what to do next | Prioritized list with rationale |

## Tier 3 — Quality + prototype (when ready)

| Skill | When | What it produces |
|---|---|---|
| `library-lint` | Periodically, pre-commit | File-line report of drift: hex codes, Tailwind, banned patterns, undefined `var(--name)` references |
| `demo-compliance-scanner` | Before shipping a demo, pre-commit hook | Stricter report scoped to `prototypes/` + `demos/` + `examples/`. Raw HTML affordances are errors. |
| `token-drift-check` | After Figma updates, before releases | Three-direction drift report (Figma→code, code→Figma, undefined refs) + designer annotations from Variable descriptions |
| `prototype-from-brief` | Validating real flows | Working prototype HTML/TSX in `prototypes/`; stops if components are missing |

## Recommended sequence on a fresh project

```
Day 1:
  library-scaffold         # 5 min
  figma-readiness-check    # 15 min (then ~hours fixing Figma)

Day 2:
  figma-tokens-extract        # 10 min
  codebase-conventions-scan   # 10 min
  [manually fill in prompt-rules.md hard rules]

Day 3+:
  figma-batch-probe (for the next batch of nodes)
  component-from-figma Button
    └─ auto-chains: verify-component, showcase-page-generator
  screenshot-diff Button         # confirm visual parity
  ...repeat

Week 2:
  prototype-from-brief "settings page"
  library-lint
  demo-compliance-scanner
  token-drift-check
```

## How skills chain together

```
library-scaffold
       │
       ▼
figma-readiness-check ─── (fix Figma) ───┐
       │                                  │
       ▼                                  │
figma-tokens-extract                      │
       │                                  │
       ▼                                  │
codebase-conventions-scan                 │
       │                                  │
       ▼                                  │
       │     ┌── next-component-to-build ─┘
       │     │
       ▼     ▼
   figma-batch-probe          (optional: batch survey first)
       │
       ▼
   component-from-figma  ──────┐
       │                       │  (auto-chained)
       ├───► verify-component ─┤
       ├───► showcase-page-generator
       ├───► component-interactive-behavior  (if interactive category)
       └───► manifest-styling-from-css   (re-run after CSS edits)
       │
       ▼
   screenshot-diff
       │
       ▼
   (more components)
       │
       ▼
prototype-from-brief ── library-lint ── demo-compliance-scanner ── token-drift-check
```

## Where these live

All sixteen `SKILL.md` files are at `~/.claude/skills/[skill-name]/SKILL.md`. They're user-level, so they work across every Claude Code project on this machine.

To distribute to teammates: copy the folders to their `~/.claude/skills/`, or package as a plugin via the Anthropic plugin registry (use the `anthropic-skills:skill-creator` skill for that workflow).

## Want to evolve these?

- Edit any `SKILL.md` directly — changes take effect immediately on next prompt.
- The `description` field is what triggers auto-invocation. If a skill isn't firing when you expect, the description doesn't include the user's phrasing — expand the trigger phrases.
- Add a `references/` subfolder inside a skill for templates or examples it should load.
- Use the `anthropic-skills:skill-creator` skill to optimize trigger descriptions or run evals.
