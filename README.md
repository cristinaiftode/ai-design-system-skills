# AI Design System Skills

Fifteen [Claude Code](https://claude.com/claude-code) skills for bootstrapping and maintaining AI-readable component libraries — the kind that Claude, v0, Lovable, Figma Make, and friends all understand without you having to re-explain your design system on every prompt.

These skills follow the workflow in the [Designer's Playbook](https://github.com/cristinaiftode/tripletex-component-library/blob/main/DESIGNER-PLAYBOOK.md). Each one automates a phase of that workflow: from "empty folder" → "tokens extracted from Figma" → "components generated 1:1 from Figma matching your production code" → "linted prototype that uses only your library."

---

## What's in the pack

### Tier 1 — Bootstrap (use once, on Day 1–2)

| Skill | What it does |
|---|---|
| **`library-scaffold`** | Creates an empty-but-correctly-shaped repo (folders, `package.json`, `manifest.json`, `prompt-rules.md`, `CLAUDE.md`, `README.md`) |
| **`figma-readiness-check`** | Audits a Figma file for hygiene issues before you generate anything (Variables, naming, auto-layout, variants) |
| **`figma-tokens-extract`** | Pulls every Figma Variable and writes `tokens/colors.css`, `tokens/spacing.css`, `tokens/typography.css` |
| **`codebase-conventions-scan`** | Reads your production code and answers the 8 conventions questions automatically for `prompt-rules.md` |

### Tier 2 — Daily component loop (use every day)

| Skill | What it does |
|---|---|
| **`component-from-figma`** | Builds a complete component end-to-end: TSX + CSS + manifest entry (schema-complete) + prompt-rules section + barrel export, then auto-chains `verify-component` and `showcase-page-generator` |
| **`manifest-styling-from-css`** | Reads `components/X.css` and writes the `styling` + `colorMapping` blocks to `manifest.json`. Idempotent — re-run after CSS edits to keep manifest in sync |
| **`verify-component`** | 9-point pass/fail check: files + exports + manifest schema completeness + no hex codes + every `var(--name)` resolves + no banned patterns |
| **`showcase-page-generator`** | Generates `examples/<Name>Page.tsx` (or `src/pages/`) for a component, mirroring the project's existing showcase template |
| **`screenshot-diff`** | Renders the live component, fetches the Figma export, and visually diffs them. Catches shape / spacing / icon mistakes that pass lint |
| **`next-component-to-build`** | Looks at Figma vs. your manifest, recommends what to build next based on dependencies |

### Tier 3 — Quality + prototyping (use from Week 2)

| Skill | What it does |
|---|---|
| **`library-lint`** | Scans for off-brand drift (hex codes, Tailwind classes, banned patterns, undefined `var(--name)` references) |
| **`demo-compliance-scanner`** | Strict lint for `prototypes/` + `demos/` + `examples/` — raw `<button>` / `<input>` are errors, not warnings. Pre-commit hook recipe included |
| **`token-drift-check`** | Diffs `tokens/*.css` against the latest Figma Variables. Surfaces value changes, new variables, designer-authored annotations in description fields |
| **`figma-batch-probe`** | Fans out `get_design_context` + `get_screenshot` + `get_variable_defs` + `get_metadata` across many Figma nodes in parallel. Turns a multi-node "what are these?" request from 30+ sequential calls into one round trip |
| **`prototype-from-brief`** | Turns a natural-language brief into a real prototype using only existing components — refuses to invent missing ones |

A more detailed reference with the dependency diagram is in [`SKILLS-INDEX.md`](./SKILLS-INDEX.md). For a per-skill catalog (inputs, outputs, trigger phrases for each of the 15), see [`SKILLS-CATALOG.md`](./SKILLS-CATALOG.md).

---

## Install

### Option 1 — One-liner install script (recommended)

```bash
git clone https://github.com/cristinaiftode/ai-design-system-skills.git /tmp/ai-design-system-skills && \
  bash /tmp/ai-design-system-skills/install.sh && \
  rm -rf /tmp/ai-design-system-skills
```

The script copies the fifteen skill folders into `~/.claude/skills/` and prints a checklist of what was installed.

### Option 2 — Manual install

```bash
git clone https://github.com/cristinaiftode/ai-design-system-skills.git
mkdir -p ~/.claude/skills
cp -r ai-design-system-skills/skills/* ~/.claude/skills/
```

### Option 3 — Pick and choose

If you only want some of the skills, copy just those folders:

```bash
mkdir -p ~/.claude/skills
cp -r ai-design-system-skills/skills/component-from-figma ~/.claude/skills/
cp -r ai-design-system-skills/skills/figma-tokens-extract ~/.claude/skills/
# ...etc
```

---

## Verify

After installing, open a fresh Claude Code session and ask:

> *"List all skills available to me right now."*

You should see the fifteen skills above. If any are missing, copy the folder again.

---

## How to use them

You don't have to memorize skill names. They auto-trigger on natural English. Three real examples:

**Day 1 — bootstrap a new library:**

> *"Scaffold a new component library project called 'acme-design-system' in this folder."*

`library-scaffold` fires.

**Day 2 — pull tokens from Figma:**

> *"Extract tokens from this Figma file: https://figma.com/design/xyz/My-Library"*

`figma-tokens-extract` fires.

**Day 3 — build your first component:**

> *"Build the Button component from this Figma node: https://figma.com/design/xyz/My-Library?node-id=12-34. Match the conventions from `reference/ProductionButton.tsx`."*

`component-from-figma` fires. You get a working component + manifest entry + prompt-rules update + barrel export in ~15 minutes, with Claude pausing for you to confirm each step.

---

## Prerequisites

- [Claude Code](https://claude.com/claude-code) installed
- The [Figma MCP server](https://help.figma.com/hc/en-us/articles/32132100833559-Guide-to-the-Dev-Mode-MCP-Server) connected (for any skill that touches Figma)
- A project structured according to the [Designer's Playbook](https://github.com/cristinaiftode/tripletex-component-library/blob/main/DESIGNER-PLAYBOOK.md) (or one you're bootstrapping with `library-scaffold`)

---

## When to install (the honest timing)

Do the first 3–5 components manually first. Skills automate a workflow — if you've never done the workflow by hand, you won't notice when the skill does something subtly wrong. Manual rounds 1–3 teach you what "correct output" looks like. From component #4 onward, the skills shine.

Practical sequence:

- **Day 1–3:** No skills. Read the playbook. Build Button, Input, Tag manually.
- **Day 4:** Install the skill pack. Re-build a fourth component with `component-from-figma` and compare to your manual ones.
- **Week 2+:** Skills become your default.

---

## Editing or evolving a skill

A skill is just a markdown file. To improve any of them on your machine:

```bash
code ~/.claude/skills/component-from-figma/SKILL.md
```

Edit the workflow, save, and the next prompt picks up the change. No reload, no build step.

Two fields matter most:
- **`description`** in the YAML frontmatter — the trigger language. Add new phrasings here when a skill should fire on words it currently misses.
- **The workflow body** — the recipe. If a skill keeps missing a step, add an explicit step for it.

If you want to upstream improvements, open a PR against this repo.

---

## Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| I typed the trigger phrase but no skill fired | Description doesn't match closely enough | Edit `~/.claude/skills/[skill]/SKILL.md` and add your phrasing to `description` and `trigger` |
| Skill fires but produces wrong output | Workflow is outdated for your project | Edit the `SKILL.md` — changes take effect immediately |
| Multiple skills compete and the wrong one fires | Overlapping descriptions | Make each description more specific about its unique input |
| Skill can't find `manifest.json` | You're not in the right directory | `cd` into your library project root |
| Figma-based skill says "MCP not available" | Figma MCP isn't connected | Install/reconnect via Claude Code → Settings → MCP Servers |

---

## License

Apache-2.0. See [LICENSE](./LICENSE).

---

## Credits

Built by [Cristina Iftode](https://github.com/cristinaiftode), Design Systems Lead at e-conomic, alongside [Claude](https://claude.com/claude). Tested in production on the [Tripletex Atlas Component Library](https://github.com/cristinaiftode/tripletex-component-library).
