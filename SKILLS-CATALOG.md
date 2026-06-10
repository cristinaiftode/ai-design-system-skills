# Skills Catalog

A human-readable reference for every skill in this pack — what it does, what it takes as input, what it produces, and the natural-English phrasings that trigger it.

This is the "what does each skill actually do" doc. For the **dependency diagram + recommended sequence**, see [`SKILLS-INDEX.md`](./SKILLS-INDEX.md). For the **install instructions**, see [`README.md`](./README.md). For the full **workflow recipes**, open the individual `skills/<name>/SKILL.md` files.

---

## Tier 1 — Bootstrap (Day 1–2, use once per project)

### 1. `library-scaffold`

Creates an empty-but-correctly-shaped library repo from scratch.

- **Inputs:** project name, class prefix (default `tt-`), target folder
- **Produces:** Vite + React + TS project with `tokens/`, `components/`, `prototypes/`, `reference/` folders; placeholder `manifest.json`, `prompt-rules.md`, `CLAUDE.md`, `README.md`
- **Triggers:** *"scaffold a component library"*, *"start a new library project"*, *"initialize a component library"*, *"fresh start design system"*

### 2. `figma-readiness-check`

Audits a Figma file for AI-handoff hygiene before you generate anything.

- **Inputs:** Figma file URL (whole file or component-set)
- **Checks 16 things** across 6 sections: Tokens (Variables for colors/spacing/typography), Structure (auto-layout, layer names), Naming & variants (Component Properties), State coverage, Edge cases, and **Designer annotations** (surfaces text in component/Variable description fields, e.g. *"Overlay = Trans/Black/30, NOT 50"*)
- **Produces:** prioritized punch list + a separate "annotations to honor" section
- **Triggers:** *"audit my Figma file"*, *"is my Figma ready for AI"*, *"are there designer notes I missed"*

### 3. `figma-tokens-extract`

Pulls every Figma Variable and writes them as CSS custom properties.

- **Inputs:** Figma file URL + project root
- **Produces:** `tokens/colors.css`, `tokens/spacing.css`, `tokens/typography.css` (+ optional `tokens/index.css`)
- **Convention:** `surface/info/rest` → `--surface-info-rest`. Preserves the global-vs-semantic split if Figma uses it.
- **Triggers:** *"extract tokens from Figma"*, *"build my tokens files"*, *"refresh tokens"*

### 4. `codebase-conventions-scan`

Analyzes a production codebase to answer 8 conventions questions (framework, styling, class naming, file structure, types, imports, icons, banned patterns).

- **Inputs:** local path or GitHub URL of your real product
- **Produces:** a markdown report ready to drop into `prompt-rules.md`
- **Triggers:** *"analyze our production code"*, *"scan our codebase"*, *"how do we write code"*, *"what's our style"*

---

## Tier 2 — Component loop (the daily work)

### 5. `figma-batch-probe` 🆕

Fans out 4 Figma MCP calls in parallel across N nodes — turns 30+ sequential calls into one round trip.

- **Inputs:** 2+ Figma URLs / `fileKey:nodeId` pairs
- **Per node:** `get_design_context` + `get_screenshot` + `get_variable_defs` + `get_metadata` — all batched
- **Produces:** one table-per-node digest + a "shared findings" block (variables used by multiple nodes, missing tokens, designer annotations from description fields)
- **Triggers:** *"probe these Figma nodes"*, *"batch fetch Figma context"*, *"look at all these nodes at once"*

### 6. `component-from-figma`

The headline skill. Builds a component end-to-end from a Figma node.

- **Inputs:** PascalCase component name + Figma node URL + (optional) reference files
- **Produces:** `Component.tsx` + `Component.css` + barrel export update + **schema-complete** manifest entry (every key the project's most-populated entry has) + prompt-rules section
- **Auto-chains:** `verify-component` (mandatory final step) and `showcase-page-generator` (if a showcase folder exists)
- **Triggers:** *"build the Button component"*, *"generate this from Figma"*, *"port this Figma node"*, *"wrap this Figma node"*

### 7. `manifest-styling-from-css` 🆕

Reads a component's CSS and emits the `styling` + `colorMapping` blocks in `manifest.json`. Idempotent — re-run after any CSS edit to keep manifest in sync.

- **Inputs:** component name (or `--all` for library-wide sync)
- **Parses:** dimensions (height/padding/gap/icon size), radius, border, typography, focus ring, shadow, states, per-variant background/text colors
- **Produces:** updated manifest entry matching the project's existing schema (preserves `"var(--token) / #HEX"` dual notation if that's what's used)
- **Triggers:** *"sync the manifest styling"*, *"fill in the styling block"*, *"audit manifest styling coverage"*

### 8. `verify-component`

Mandatory final gate after every component build. Nine checks:

1. TSX file exists
2. CSS file exists
3. Barrel export present
4. Manifest entry present
5. **Manifest entry schema-complete** (vs. the most-populated reference entry)
6. Prompt-rules section present
7. No hardcoded hex codes
8. **Every `var(--name)` reference resolves to a defined token** (catches `--spacing-150` silent-evaluates-empty)
9. No banned patterns

- **Produces:** compact pass/fail table with line numbers for failures
- **Triggers:** *"verify Modal"*, *"is the component correct"*, *"did the component finish properly"*

### 9. `showcase-page-generator` 🆕

Generates `examples/<Name>Page.tsx` (or `src/pages/`, `stories/`, `docs/components/` — auto-detected) for a component, mirroring the project's existing showcase template.

- **Inputs:** component name + (optional) showcase folder override
- **Produces:** TSX file with header, variant matrix, size matrix, state matrix, anatomy section, usage notes, "Don't" list — using only props/tokens already defined for the component
- **Triggers:** *"generate a showcase for Tab"*, *"build the Modal examples page"*, *"create the ButtonPage"*

### 10. `screenshot-diff` 🆕

Visual diff between live component and Figma export. Catches shape / spacing / icon mistakes that pass `verify-component`.

- **Two modes:**
  - **MCP-default (zero install)** — Figma MCP `get_screenshot` + Claude Preview MCP `preview_screenshot`, then visual region-by-region comparison
  - **Precision (opt-in)** — Playwright + Figma REST API + pixelmatch, produces `code.png` / `figma.png` / `diff.png` and a mismatch percentage
- **Inputs:** component name + Figma node URL + dev URL + viewport
- **Produces:** side-by-side report with per-region verdict (shape, color, spacing, iconography, composition) + recommended fix
- **Triggers:** *"diff Modal against Figma"*, *"is this visually correct"*, *"does this match the design"*

### 11. `next-component-to-build`

Diffs `manifest.json` against Figma; recommends what to build next.

- **Prioritizes by:** foundational dependencies (Button before Form), frequency in product, family completeness, your stated focus
- **Produces:** top recommendation + next 3 + tier-by-tier remaining list + recommended sprint of 5
- **Triggers:** *"what should I build next"*, *"prioritize my backlog"*, *"plan my sprint"*

---

## Tier 3 — Quality + prototyping (Week 2+)

### 12. `library-lint`

Broad off-brand-drift scan across the whole library.

- **Tier 1 errors:** hardcoded hex codes, Tailwind classes, inline styles, raw `<button>` in prototypes, banned-library imports, **undefined `var(--name)` references**
- **Tier 2 warnings:** BEM prefix violations, wrong font-family, magic spacing, missing manifest entries
- **Tier 3 info:** `console.log`, TODO/FIXME comments
- **Produces:** punch list with file:line + suggested fixes; offers auto-fix for unambiguous cases
- **Triggers:** *"lint the library"*, *"audit the library"*, *"is anything off-brand"*, *"design review the code"*, *"check for issues"*

### 13. `demo-compliance-scanner` 🆕

Strict, prototype/demo-scoped version of `library-lint`. Raw `<button>` / `<input>` / `<select>` / `<table>` / `<dialog>` are errors (not warnings).

- **Scope:** `prototypes/**`, `demos/**`, `examples/**`
- **Includes:** pre-commit hook recipe + CI YAML
- **Suggests:** library-component swaps for each raw affordance (looks up the right import from `manifest.json`)
- **Triggers:** *"scan the demos"*, *"audit the prototypes"*, *"are the demos clean"*, *"find raw HTML in prototypes"*

### 14. `token-drift-check` 🆕

Three-direction drift report between `tokens/*.css` and Figma Variables.

- **A. Figma → code:** new Variables, value changes, stale-in-code (renamed/removed upstream)
- **B. Designer annotations:** non-empty `description` fields on Variables — categorized as design rule / state spec / token override / deprecation
- **C. Code-internal:** every `var(--name)` reference resolves (catches `--spacing-150`)
- **Produces:** punch list with closest-match suggestions; offers to append missing Variables to the right token file
- **Triggers:** *"check token drift"*, *"diff tokens against Figma"*, *"are my tokens stale"*, *"did designer change anything"*

### 15. `prototype-from-brief`

Turns a natural-language brief into a real prototype using only existing library components. Refuses to invent missing ones.

- **Inputs:** brief (e.g. *"settings page where users can change name, email, notification preferences"*)
- **Coverage check:** if any required component is missing, STOPS and surfaces the gap with a recommendation
- **Produces:** standalone HTML or TSX at `prototypes/[descriptive-name].{html,tsx}`
- **Triggers:** *"build a prototype for settings"*, *"prototype this page"*, *"mock up a screen"*, *"design a page using our system"*

---

## How they chain

```
library-scaffold
  → figma-readiness-check (fix Figma)
    → figma-tokens-extract
      → codebase-conventions-scan
        → figma-batch-probe (survey a batch)
          → component-from-figma
              ├─ auto: verify-component
              ├─ auto: showcase-page-generator
              └─ later: manifest-styling-from-css (re-run after CSS edits)
            → screenshot-diff (visual gate)
              → (more components)
                → prototype-from-brief → library-lint → demo-compliance-scanner → token-drift-check
```

---

## The 6 new skills in one line each

| Skill | Closes which gap |
|---|---|
| `figma-batch-probe` | 30+ sequential Figma calls on multi-node requests |
| `manifest-styling-from-css` | 48/57 components shipped with no styling block; manifest drifts after every CSS edit |
| `showcase-page-generator` | Components built without a matching showcase page |
| `screenshot-diff` | Tab-counter-as-chip / Modal phantom divider / wrong topnav shell (visual bugs that pass lint) |
| `demo-compliance-scanner` | Raw `<button>` / `<input>` in demo pages that live for weeks before anyone notices |
| `token-drift-check` | `--spacing-150` silent-evaluates-empty + designer annotations getting lost between Figma and code |

---

## Want more detail?

Open the individual `SKILL.md` files under [`skills/`](./skills/) — each one has the full workflow, prerequisites, output contract, and common failure modes.
