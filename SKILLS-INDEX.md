# Design System Skills — Index

Nine skills for bootstrapping and maintaining AI-readable component libraries. They follow the conventions in `DESIGNER-PLAYBOOK.md`.

You don't invoke this file directly. It's a reference for which skill to reach for at each phase.

## Tier 1 — Bootstrap (use in this order)

| Skill | When | What it produces |
|---|---|---|
| `library-scaffold` | Empty folder, Day 1 | Vite + React + TS project shape, empty `manifest.json`, `prompt-rules.md`, `tokens/`, `components/`, `prototypes/`, `reference/` |
| `figma-readiness-check` | Before extracting tokens | Punch list of Figma hygiene fixes (Variables, naming, auto-layout, variants, layer names) |
| `figma-tokens-extract` | Once Figma is ready | `tokens/colors.css`, `tokens/spacing.css`, `tokens/typography.css` |
| `codebase-conventions-scan` | After tokens | Markdown report answering the 8 conventions questions; drops into `prompt-rules.md` |

## Tier 2 — Component building (the daily loop)

| Skill | When | What it produces |
|---|---|---|
| `component-from-figma` | Adding a new component | `Component.tsx` + `.css` + manifest entry + prompt-rules section + barrel export |
| `verify-component` | After each component | Pass/fail report; catches missing wiring + hex codes |
| `next-component-to-build` | When unsure what to do next | Prioritized list with rationale |

## Tier 3 — Quality + prototype (when ready)

| Skill | When | What it produces |
|---|---|---|
| `library-lint` | Periodically, pre-commit | File-line report of drift: hex codes, Tailwind, banned patterns |
| `prototype-from-brief` | Validating real flows | Working prototype HTML/TSX in `prototypes/`; stops if components are missing |

## Recommended sequence on a fresh project

```
Day 1:
  library-scaffold        # 5 min
  figma-readiness-check   # 15 min (then ~hours fixing Figma)

Day 2:
  figma-tokens-extract       # 10 min
  codebase-conventions-scan  # 10 min
  [manually fill in prompt-rules.md hard rules]

Day 3:
  component-from-figma Button   # ~15-30 min
  verify-component Button       # 1 min
  component-from-figma Input    # ~15 min
  ...repeat

Week 2:
  prototype-from-brief "settings page"
  library-lint
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
       ▼     ▼
   component-from-figma
       │
       ▼
   verify-component
       │
       ▼
   (more components)
       │
       ▼
prototype-from-brief ── library-lint
```

## Where these live

All nine `SKILL.md` files are at `~/.claude/skills/[skill-name]/SKILL.md`. They're user-level, so they work across every Claude Code project on this machine.

To distribute to teammates: copy the folders to their `~/.claude/skills/`, or package as a plugin via the Anthropic plugin registry (use the `anthropic-skills:skill-creator` skill for that workflow).

## Want to evolve these?

- Edit any `SKILL.md` directly — changes take effect immediately on next prompt.
- The `description` field is what triggers auto-invocation. If a skill isn't firing when you expect, the description doesn't include the user's phrasing — expand the trigger phrases.
- Add a `references/` subfolder inside a skill for templates or examples it should load.
- Use the `anthropic-skills:skill-creator` skill to optimize trigger descriptions or run evals.
