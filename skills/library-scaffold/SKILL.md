---
name: library-scaffold
description: Scaffold a brand-new AI-readable component library project from scratch — Vite + React + TypeScript, folder structure (`tokens/`, `components/`, `prototypes/`, `reference/`), placeholder `manifest.json`, `prompt-rules.md`, `CLAUDE.md`, `README.md`, and a minimal `index.html`. The output is an empty but correctly-shaped repo ready for `figma-tokens-extract` and `component-from-figma`. Use when starting a brand-new component library, when bootstrapping the playbook's Phase 3, or whenever the user asks to "scaffold a component library", "start a new library project", "set up a new AI-readable design system", or "initialize a component library".
trigger: [scaffold a component library, start a new library project, set up a new design system, initialize a component library, bootstrap a component library, create a new component library project, fresh start design system, empty folder to library]
license: Apache-2.0
---

# Library Scaffold

## Objective

Create the empty-but-correctly-shaped repo that the rest of the playbook will fill. Get the user from "empty folder" to "ready to run `figma-tokens-extract`" in one shot.

## When to Use

- Brand-new project, empty directory
- Phase 3 of the designer playbook
- The user says: "scaffold", "start a new library", "set up a new design system", "bootstrap a component library"

Do NOT use when:
- The directory isn't empty (refuse, or offer to create a subfolder)
- The user already has tokens/manifest/etc. — use the individual skills to fill gaps instead

## Workflow

### 1. Confirm intent

Ask:
- **Project name** (kebab-case, used as folder name and `package.json` name)
- **Component class prefix** (default `tt-`, but ask — every project has its own convention)
- **Where to create it** (defaults to a new subfolder of the current working dir)
- **Framework** — default React + TypeScript + Vite. Ask if they want something else (Vue / Svelte / vanilla).
- **Styling approach** — default plain CSS files + CSS custom properties. Ask if they want CSS Modules.

### 2. Run the Vite scaffold

```bash
npm create vite@latest [project-name] -- --template react-ts
cd [project-name]
npm install
```

### 3. Add the design-system folder structure

Create:

```
tokens/
├── colors.css         (placeholder with comments)
├── spacing.css        (placeholder)
├── typography.css     (placeholder)
└── index.css          (imports the above)

components/
└── index.ts           (empty barrel; will be filled by component-from-figma)

prototypes/             (empty)
reference/              (empty, with a one-line README explaining its purpose)
```

### 4. Write the three magic file skeletons

**`manifest.json`** skeleton:

```json
{
  "$schema": "https://ai-component-manifest.org/v1",
  "$description": "Component manifest for [PROJECT_NAME] — designed to be consumed by AI tools (Claude Code, Claude.ai, Figma Make, v0, Lovable, etc.) for prototyping.",
  "library": {
    "name": "[PROJECT_NAME]",
    "package": "[PROJECT_NAME]",
    "repo": "",
    "framework": "React 18 + TypeScript (Vite)",
    "styling": "css-variables",
    "tokenFiles": ["tokens/colors.css", "tokens/spacing.css", "tokens/typography.css", "tokens/index.css"],
    "barrelExport": "components/index.ts",
    "classPrefix": "[PREFIX]"
  },
  "tokens": {
    "colors": {},
    "spacing": {},
    "typography": {}
  },
  "components": {}
}
```

**`prompt-rules.md`** skeleton — copy the section headers from the Atlas template (Hard Rules / Color palette / Typography / Spacing / Per-component sections) and leave them empty for the user to fill via `figma-tokens-extract` and `component-from-figma`.

**`CLAUDE.md`** skeleton:

```markdown
# CLAUDE.md — Project rules

Before writing any code:
1. Read `manifest.json` to see what components exist
2. Read `prompt-rules.md` for styling rules
3. Read `tokens/*.css` for available tokens

Never:
- Invent new colors, tokens, or components (ask first)
- Use frameworks/libraries not listed in `prompt-rules.md` "Banned patterns"
```

**`README.md`** skeleton with: project name, one-paragraph description, install/run commands, link to `DESIGNER-PLAYBOOK.md` (if it's in the repo).

### 5. Wire `tokens/index.css` into `main.tsx` / `index.html`

Make sure `import "./tokens/index.css"` is the first import in the app entry. Without this the tokens won't be available globally.

### 6. Configure git

```bash
git init
git add .
git commit -m "Initial scaffold from library-scaffold skill"
```

Do NOT push to a remote — the user adds that themselves later.

### 7. Print the next steps

```
Library scaffolded at [path]. Files created:
- package.json, tsconfig.json, vite.config.ts (Vite defaults)
- tokens/{colors,spacing,typography,index}.css (placeholders)
- components/index.ts (empty)
- prototypes/, reference/ (empty)
- manifest.json (skeleton)
- prompt-rules.md (skeleton)
- CLAUDE.md (skeleton)
- README.md (skeleton)

Next steps (in order):
1. Connect the Figma MCP if you haven't already.
2. Run the `figma-tokens-extract` skill with your Figma file URL.
3. Run the `codebase-conventions-scan` skill against your production repo.
4. Manually edit `prompt-rules.md` to add hard rules and banned patterns.
5. Drop 1–3 reference component files into `reference/`.
6. Run `component-from-figma` to build your first component.

You're at Phase 4 of the designer playbook. Good luck!
```

## Output

A working, empty-but-correctly-shaped project ready for the rest of the skills.
