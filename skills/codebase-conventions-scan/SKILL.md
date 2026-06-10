---
name: codebase-conventions-scan
description: Analyze a production codebase (local path or GitHub URL) to detect framework, styling approach, class-naming convention, file structure, type system, import style, icon strategy, and any banned patterns. Produces a markdown report that drops directly into `prompt-rules.md` for a new AI-readable component library. Use when bootstrapping a component library from an existing product, when documenting conventions for the first time, or whenever the user asks to "analyze our production code", "detect our code conventions", "scan our codebase for conventions", "answer the 8 conventions questions", or "extract style rules from our app".
trigger: [analyze our production code, detect our code conventions, scan our codebase, answer the 8 conventions questions, extract style rules, document our conventions, what conventions does our codebase use, how do we write code, whats our style, generate prompt rules from production]
license: Apache-2.0
---

# Codebase Conventions Scan

## Objective

Given a real product codebase, produce a structured markdown report answering eight questions about how that codebase is built. The output is meant to drop straight into the `prompt-rules.md` of a new AI-readable component library, so AI tools (Claude Code, Claude.ai, v0, etc.) generate components that match the real product's conventions on day one.

Without this skill, the user has to interview a tech lead. With it, they have a starting draft in 5 minutes that they can correct in 15.

## When to Use

- Bootstrapping a new component library for an existing product
- Writing the first version of `prompt-rules.md`
- Auditing convention drift across an existing codebase
- The user says: "scan our codebase", "what conventions does our app use", "extract style rules", "answer the 8 conventions questions"

Do NOT use when:
- The user wants a deep architectural review (that's a different skill — use `scored-code-review` or similar)
- The codebase is brand-new and has no patterns yet
- The user just wants to read one specific file (use `Read` directly)

## The eight questions

1. **Framework** — React + TypeScript? Vue? Svelte? Vanilla JS? Other? What version?
2. **Styling approach** — Plain CSS files? CSS Modules? Styled-components? Emotion? Tailwind? CSS-in-JS? Inline?
3. **Class naming convention** — BEM (`btn btn--primary`)? camelCase modules (`styles.button`)? Utility (`px-4 py-2`)? Atomic? Custom?
4. **File structure** — `Component/Component.tsx + Component.css + index.ts`? Flat `Component.tsx + Component.css`? In an `atoms/molecules/` taxonomy?
5. **Type system** — Inline TypeScript types? Separate `.types.ts` files? PropTypes? JSDoc? None?
6. **Import style** — Named exports (`import { Button } from "./Button"`)? Default exports? Mixed?
7. **Icon strategy** — Inline SVG components? SVG imports as files? Icon font? Icon library (lucide, heroicons, etc.)?
8. **Banned patterns** — Anything in ESLint config, prettier config, internal `STYLE_GUIDE.md`, or `CONTRIBUTING.md` that says "do not use X"? Banned libraries, banned syntax, banned colors?

## Workflow

### 1. Gather inputs

Ask the user for:
- **Codebase location** — local path (e.g. `~/work/our-product`) OR GitHub URL (`https://github.com/org/product`) OR a specific subfolder (`~/work/our-product/packages/ui`)
- **Where to write the report** — defaults to `./CODEBASE-CONVENTIONS.md` in current dir, or appends to `prompt-rules.md` if it exists

If GitHub URL, use `gh repo clone` to clone into a temp dir, or use `gh` CLI to fetch individual files. Avoid web scraping.

### 2. Pick representative files

Don't read the whole codebase — be efficient. Find 5–10 representative component files:

- Look for a `components/` or `ui/` folder (most likely location)
- Pick by name diversity: one Button-ish, one Input-ish, one Modal-ish, one Table-ish, one layout primitive
- Avoid auto-generated files (search for `generated`, `__generated__`, `*.d.ts`)
- Avoid test files (`.test.`, `.spec.`)

Also fetch (if they exist):
- `package.json` — answers framework and dependency questions
- `tsconfig.json` — confirms TypeScript settings
- `.eslintrc*` — banned patterns
- `.prettierrc*` — formatting conventions
- `tailwind.config.*` — confirms if Tailwind is in use
- `vite.config.*`, `next.config.*`, `webpack.config.*` — bundler/framework
- `STYLE_GUIDE.md`, `CONTRIBUTING.md`, `CONVENTIONS.md`, `docs/style.md` — explicit conventions
- `.github/copilot-instructions.md`, `CLAUDE.md`, `.cursorrules` — AI-tool guidance already written

### 3. Analyze and answer each question

For each of the 8 questions, look for direct evidence:

| Question | Where to look |
|---|---|
| Framework | `package.json` dependencies, file extensions, framework imports |
| Styling | Imports (`styled`, `emotion`, `@apply`, `.module.css`), file types alongside components |
| Class naming | Sample 10 class names from the picked files; look for patterns |
| File structure | The folder tree of the picked components |
| Types | TS file extensions, `interface`/`type` density, PropTypes imports |
| Imports | Sample 20 imports; count named vs default |
| Icons | Search for `<svg`, icon library imports, `.svg?import` patterns |
| Banned patterns | ESLint `rules`, prettier overrides, lines in STYLE_GUIDE.md |

Be honest about uncertainty. If you can't tell from 5 files whether the team uses CSS Modules or plain CSS, say so and recommend the user confirm.

### 4. Produce the report

Write a markdown file in this exact shape:

```markdown
# Codebase conventions — [project name]

_Scanned [date]. Source: [path or URL]. Files analyzed: [list]._

## 1. Framework
**[Framework] [version]**, e.g. React 18 + TypeScript 5.6 with Vite 5.

Evidence: `package.json` lists `react@^18`, `typescript@^5.6`, `vite@^5.4`.

## 2. Styling approach
**Plain CSS files alongside components.** No CSS-in-JS. No Tailwind detected.

Evidence: Every `Component.tsx` has a sibling `Component.css`. No `styled-components`, `emotion`, or `tailwindcss` imports found in the sampled files. No `tailwind.config.js` present.

## 3. Class naming
**BEM with `tt-` prefix.** Pattern: `tt-component`, `tt-component__element`, `tt-component--modifier`.

Sample class names found:
- `tt-button tt-button--primary tt-button__icon-left`
- `tt-input tt-input--error`
- `tt-modal tt-modal__header`

## 4. File structure
**Flat under `components/`**, one `.tsx` + one `.css` per component, barrel export via `components/index.ts`.

Tree:
```
components/
├── Button.tsx
├── Button.css
├── Input.tsx
├── Input.css
└── index.ts
```

## 5. Type system
**Inline TypeScript types.** Component props are declared as `type [Component]Props = { ... }` exported from the component file. No separate `.types.ts` files.

## 6. Import style
**Named exports throughout.** No default exports in component files. Barrel `index.ts` re-exports named.

## 7. Icons
**Inline SVG components** in a single `Icons.tsx`. No icon libraries. SVG uses `currentColor` for monochrome support.

## 8. Banned patterns
From ESLint config + sampling:
- No Tailwind (no `tailwind.config.js`, no utility classes in sampled JSX)
- No CSS-in-JS libraries
- No `any` types (`noImplicitAny: true` in tsconfig)
- No inline styles (`style={{...}}`) — `react/forbid-dom-props` may be configured
- No `console.log` in committed code (eslint `no-console: error`)

## Recommendation: paste into prompt-rules.md

The "Hard rules" and "Banned patterns" sections of your `prompt-rules.md` should incorporate findings #2, #3, and #8. Sections #4–#7 inform how the per-component scaffolding should be structured.

## Uncertainty flags
- Could not determine whether CSS variables are imported globally (in `App.tsx`?) or per-component. Confirm with tech lead.
- Found 1 file using `forwardRef`. Sample size too small to know if this is convention or one-off.
```

### 5. Offer to merge into prompt-rules.md

After writing the standalone report, ask the user: "Want me to merge the relevant sections into `prompt-rules.md` for you?" If yes, look for existing sections and append/update; if no existing `prompt-rules.md`, offer to create one using this skill's output as Section 0.

## Output

A markdown report file + a clear summary of:
- 8 answered questions
- Banned patterns list
- Uncertainty flags
- Recommended next step
