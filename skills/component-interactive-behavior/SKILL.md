---
name: component-interactive-behavior
description: Codify and enforce the interaction contract for interactive components — Tooltip on hover, Dropdown/Menu on click + arrow-key navigation, Modal focus trap + escape-to-close, Tabs arrow keys + aria-selected, Toast auto-dismiss + pause-on-hover, etc. Two modes — AUDIT (single component or `--all` library-wide, reports what handlers / ARIA / keyboard behavior is missing per the component's category) and FILL (writes the missing pieces using the project's existing utility hooks where they exist, or minimal inline equivalents where they don't). Updates the showcase page to demo the interactive states explicitly so designers can verify "the dropdown actually opens" in the showcase. Auto-chained from `component-from-figma` for components in known interactive categories so new interactive components ship working. Safe to retrofit across an existing library. Use after building a new interactive component, when retrofitting interactive behavior across an existing library, when a designer reports "the tooltip doesn't work" or "the dropdown doesn't open", or whenever the user asks to "make this component interactive", "is the tooltip working", "does the dropdown open", "audit interactive behavior", "wire up the modal", "retrofit interactivity", "check keyboard navigation", "is this accessible", or "make the components actually work".
trigger: [make this component interactive, is the tooltip working, does the dropdown open, audit interactive behavior, wire up the modal, retrofit interactivity, check keyboard navigation, is this accessible, make the components actually work, interaction audit, wire up the dropdown, make the tooltip work on hover]
license: Apache-2.0
---

# Component Interactive Behavior

## Objective

A Figma node shows what a component *looks like*. It does not show what it *does*. `component-from-figma` produces a structurally correct, visually accurate component — but does not guarantee that Tooltip appears on hover, that Dropdown opens on click, that Modal traps focus, or that Tabs respond to arrow keys.

This skill closes that gap. It codifies the **interaction contract** per component category, audits whether a component implements it, and fills in what's missing. Two modes:

- **Audit** — report what's missing without writing code (single component or `--all`)
- **Fill** — write the handlers, state, ARIA, and keyboard behavior to satisfy the contract

Designed to be safe to run on existing components (retrofit) as well as new ones.

## When to Use

- **Auto-chained** by `component-from-figma` for components in known interactive categories (the user shouldn't have to ask)
- After building a new interactive component manually
- One-shot library-wide retrofit (`--all`) when interactive coverage across the library is unknown
- When a designer reports "the tooltip doesn't work" / "the dropdown doesn't open" / "the modal doesn't close on escape"
- When the user says: "make this component interactive", "is the tooltip working", "does the dropdown open", "audit interactive behavior", "wire up the modal", "retrofit interactivity", "check keyboard navigation", "is this accessible"

Do NOT use when:
- The component is purely visual (Tag, Badge, Avatar, Divider, Spinner, Skeleton, MediaPlaceholder, illustrations) — these have no interactive contract
- The component is a layout primitive (AppShell, Sidebar, Topbar, Card, PageHeader) — interactivity belongs to the things *inside* them, not the shell

## Prerequisites

1. Current working directory is the library root
2. `manifest.json` exists with the target component(s) registered
3. `components/<Name>.tsx` exists for each target

## The interaction contracts

Each interactive component category has a known contract. Detect the category from the component name (and confirm via `manifest.json → components.<Name>.props` when ambiguous).

### Disclosure widgets
**Components:** Accordion, Disclosure, Details, ExpandablePanel
**Contract:**
- Toggle state controlled by `isOpen` (or `expanded`) prop, with internal state fallback
- `onClick` on the trigger toggles state
- `onKeyDown` on the trigger: Enter and Space toggle (preventDefault on Space to avoid page scroll)
- `aria-expanded={isOpen}` on the trigger
- `aria-controls={panelId}` on the trigger, matching `id={panelId}` on the panel
- Panel conditionally rendered or controlled via CSS (`max-height` transition, etc.) based on `isOpen`
- Animated chevron / arrow rotates with `isOpen`

### Tooltip
**Components:** Tooltip, MultilineTooltip, InfoTooltip
**Contract:**
- Show on `onMouseEnter` and `onFocus` of the trigger; hide on `onMouseLeave` and `onBlur`
- Show delay ~150ms (configurable); hide delay ~0ms
- `role="tooltip"` on the tooltip element
- `aria-describedby={tooltipId}` on the trigger
- Positioned relative to trigger (top / bottom / left / right based on `arrow` or `placement` prop)
- Hides on Escape if currently visible
- Never blocks interaction with the trigger (`pointer-events: none` on the tooltip itself)

### Popover
**Components:** Popover, PopoverOpener
**Contract:**
- `onClick` on the trigger toggles open
- Click outside the popover closes it (use a click-outside detector)
- Escape closes it
- `aria-haspopup="dialog"` and `aria-expanded={isOpen}` on the trigger
- `role="dialog"` on the popover; `aria-labelledby` if there's a visible heading
- Restores focus to the trigger when closed

### Menu / Dropdown
**Components:** Dropdown, PopupMenu, PopupMenuItem, ContextMenu, ActionMenu
**Contract:**
- `onClick` on the trigger opens; clicking again (or on an item) closes
- Arrow Down / Up navigate items (with wrap or clamp — match the project's existing menu behavior)
- Enter / Space activates the focused item
- Home / End jump to first / last item
- Escape closes and restores focus to the trigger
- Click outside closes
- `aria-haspopup="menu"` and `aria-expanded={isOpen}` on the trigger
- `role="menu"` on the list; `role="menuitem"` on each item
- `tabindex={-1}` on items; focus moves via `activeIndex` state
- First item focused on open (or the previously-selected item if there is one)

### Select / Combobox
**Components:** Select, Combobox, MultiSelect
**Contract:** Menu / Dropdown contract PLUS:
- Selected item shown in the trigger (displayValue)
- Combobox: typing in the input filters the list; arrow keys navigate filtered list
- `aria-activedescendant` on the input (combobox) pointing at the focused item's id
- Selecting an item updates the value and closes the listbox
- `role="combobox"` on the trigger input; `role="listbox"` on the list; `role="option"` on items

### Dialog / Modal
**Components:** Modal, Dialog, Drawer, Sheet, FilterDialog, ConfirmDialog
**Contract:**
- Focus trap: Tab cycles only within the dialog; Shift+Tab cycles backward
- Initial focus: the first focusable element OR an element with `autoFocus` OR a passed `initialFocusRef`
- Escape closes (unless `closeOnEscape={false}`)
- Backdrop click closes (unless `closeOnBackdropClick={false}`)
- Restores focus to the previously-focused element on close
- `aria-modal="true"`, `role="dialog"`
- `aria-labelledby={titleId}` if there's a title; `aria-describedby={descId}` for additional description
- Body scroll locked while open (toggle a class on `<body>` or use a hook)

### Tabs
**Components:** Tabs, ContentSwitcher, TabBar, TabList
**Contract:**
- Click a tab to activate
- Arrow Left / Right (horizontal) or Up / Down (vertical) move focus between tabs
- Enter / Space activates focused tab (or use "automatic activation" where focus = activation)
- Home / End jump to first / last tab
- `role="tablist"` on the container; `role="tab"` on each tab; `role="tabpanel"` on each panel
- `aria-selected={isActive}` on each tab; `aria-controls={panelId}` linking tab → panel
- `tabindex={0}` on the active tab, `tabindex={-1}` on inactive tabs
- Tab panels: `tabindex={0}` and `aria-labelledby={tabId}`

### Toast / Snackbar
**Components:** Toast, Snackbar, NotificationToast
**Contract:**
- Auto-dismiss after N seconds (default 5; 0 = persistent)
- Pause auto-dismiss on hover and focus
- Dismiss button always available
- `role="status"` for info/success; `role="alert"` for warning/error
- `aria-live="polite"` (status) or `aria-live="assertive"` (alert)
- Slide-in / slide-out animations don't block dismissal

### Form input
**Components:** Input, Textarea, Checkbox, Radio, Toggle, NumberInput, PasswordInput
**Contract:**
- Native focus management (no custom handlers needed unless adding visible focus ring beyond `:focus-visible`)
- `aria-invalid={hasError}` when in error state
- Error message linked via `aria-describedby={errorId}` pointing at a `<span id={errorId}>` for the error
- Disabled state actually prevents interaction (`disabled` attribute, not just opacity)
- Checkbox / Radio / Toggle: clicking the label toggles the input (use `<label>` wrapping or `htmlFor`)

### Date / Calendar
**Components:** DatePicker, DateRangePicker, Calendar
**Contract:** Popover contract PLUS:
- Arrow keys navigate days (Left/Right ±1 day, Up/Down ±1 week)
- PageUp / PageDown navigate months; Shift+PageUp / PageDown navigate years
- Enter selects the focused date
- Escape closes the calendar
- `aria-label` on each day with the full readable date ("June 10, 2026")
- `aria-selected={isSelected}` on the selected day(s)
- For range: clearly indicate start, hover-range, and end states

### Slider / Range
**Components:** Slider, RangeSlider
**Contract:**
- Arrow Left / Right adjust by step; Up / Down (vertical) same
- Home / End jump to min / max
- PageUp / PageDown adjust by larger step (10%)
- `role="slider"`; `aria-valuemin`, `aria-valuemax`, `aria-valuenow`, `aria-valuetext` (human-readable)

## Workflow

### 1. Determine the target

- **Single component** — user provided a name like `Modal`
- **Multiple** — user provided a list
- **All** — user said "audit all", "library-wide", "retrofit everything", or `--all`

For `--all`, build the list from `manifest.json → components.*` keys.

### 2. Categorize each target

Map each name to a category from the table above. Use this hierarchy:

1. **Exact name match** (e.g. `Modal` → Dialog / Modal)
2. **Name suffix match** (e.g. `FilterDialog` → Dialog / Modal because it ends in `Dialog`)
3. **Manifest props heuristic** — if props include `onOpen` / `onClose` / `isOpen`, treat as overlay; if props include `value` / `onChange` + an enum, treat as Select-like
4. **Skip with explanation** if category can't be determined — never invent a contract

### 3. Read the component file

For each interactive target, read `components/<Name>.tsx` cover to cover. Note:
- Imports (which utility hooks does this project use? `useClickOutside`, `useFocusTrap`, `useEscape`?)
- Current event handlers
- Current ARIA attributes
- Current state (`useState`, `useReducer`)
- Current keyboard handling

### 4. Look for project utility patterns (don't invent new ones)

Before writing code, find what the project already uses. Grep for:
- `useClickOutside`, `useOutsideClick`, `useOnClickOutside` — click-outside detection
- `useFocusTrap`, `FocusTrap` — focus trapping
- `useEscape`, `useEscapeKey`, `useKeyDown` — keyboard handlers
- `usePopper`, `useFloating`, `@floating-ui` — positioning
- `useId` — stable IDs for ARIA

If the project has these, IMPORT them. If it doesn't, write **minimal inline equivalents in the component itself** — do NOT introduce a new `hooks/` folder, and do NOT add a new dependency (`react-focus-lock`, `@floating-ui/react`, `radix-ui/*`) without explicit user approval.

### 5. Audit each target against its contract

For each required behavior in the contract, mark:
- ✅ Implemented
- ❌ Missing
- ⚠️ Implemented but doesn't match the contract (e.g. uses `onMouseOver` instead of `onMouseEnter`, or has the handler but no keyboard equivalent)

### 6. Output the audit report

```
# Interactive behavior audit — Modal

Category: Dialog / Modal
File: components/Modal.tsx (88 lines)
Showcase: examples/ModalPage.tsx

## Required behavior

✅ Open/close controlled by isOpen + onClose props
✅ aria-modal="true" set on dialog
✅ role="dialog" set
❌ Focus trap — Tab can escape the dialog (no useFocusTrap or focus-trap implementation)
❌ Escape to close — onKeyDown handler missing
⚠️ Backdrop click — onClick on .tt-modal__overlay calls onClose, but propagation isn't stopped on the dialog body, so clicks inside the dialog also close it
❌ Restore focus on close — no previouslyFocusedElement ref captured
❌ Body scroll lock — body keeps scrolling while modal is open
❌ aria-labelledby — title exists but isn't linked to the dialog
✅ Initial focus — first focusable element receives focus on mount

## Recommendation

7 changes to make. Project has no existing focus-trap or click-outside hooks — propose minimal inline implementations (no new files, no new deps). Showcase needs an "Escape to close" demo cell.

Apply fixes? [Y/n]
```

For `--all`, group by category and show a one-line summary per component first, then a section per component with missing items.

### 7. Fill the missing pieces (with confirmation)

For single-component runs: show the proposed diff, ask for confirmation, then apply.

For `--all`: confirm per category (e.g. "Apply Dialog/Modal contract to Modal, Drawer, FilterDialog?") rather than per file. Lets the user accept broad swaths without 50 individual prompts.

**Implementation rules:**
- Use the project's existing utility hooks if they exist (Step 4)
- If not, inline a minimal implementation in the component itself (or a sibling `Component.behavior.ts` if the project already separates behavior from JSX)
- Don't introduce new dependencies — use what's there
- Match the existing TypeScript style (interfaces vs types, named vs default exports)
- Match the existing event-handler style (inline arrow functions vs `useCallback`)
- Use `useId` for stable ARIA IDs (React 18+); fall back to `useRef` + a counter only if the project pre-dates React 18

### 8. Update the showcase to demo the interactivity

For each filled behavior, add a demo cell to the component's showcase page that exercises it. Examples:

- **Tooltip:** "Hover the trigger to see the tooltip" cell with a visible trigger
- **Dropdown:** "Click to open" cell + "Use arrow keys to navigate" cell
- **Modal:** "Open Modal" button cell + "Press Escape to close" note + "Click outside to close" note + "Try Tab — focus should cycle within the dialog"
- **Tabs:** "Use arrow keys to switch tabs" cell

If the showcase page doesn't exist, invoke `showcase-page-generator` first.

### 9. Verify

Re-run the audit on the just-updated component. All required-behavior items should now be ✅. If anything is still ❌, surface why (e.g. "couldn't add focus trap because the project uses a portal pattern that needs special handling — please review manually").

### 10. Report

```
Modal — interactive behavior wired up
- Added useFocusTrap (inline) to .tt-modal__dialog
- Added useEscapeKey listener calling onClose
- Added previouslyFocusedElement ref + restore on close
- Added body scroll lock via .tt-modal-open class on <body>
- Linked title via aria-labelledby
- Backdrop-click handling now stops propagation on dialog body

Files changed:
- components/Modal.tsx (+34, -2)
- components/Modal.css (+4, -0)
- examples/ModalPage.tsx (+18, -0)

Next: open the Modal in your dev server and Tab through — focus should cycle only within the dialog. Press Escape — should close. Click outside — should close. Click inside the dialog body — should NOT close.
```

## Output

Modified component file(s), modified showcase file(s), and a per-component report. In audit-only mode (`--check`), prints the report without writing.

## Common failure modes

- **Inventing utility hooks.** If the project doesn't have `useFocusTrap`, write minimal inline focus-trap logic in the component — do NOT create `hooks/useFocusTrap.ts` without asking, and do NOT add `react-focus-lock` as a dependency.
- **Skipping the project-pattern search step.** Always look first. A project with `useFocusTrap` already used in `Drawer.tsx` should not get a re-invented focus-trap in `Modal.tsx`.
- **Inferring contracts.** If a component name doesn't match any known category, do NOT guess at a contract. Skip with a one-line explanation and let the user clarify.
- **Wiring behavior the design didn't show.** If Figma shows a `Toast` with no dismiss button, don't add a dismiss button just because the contract says so — surface the gap as a question. The design is the source of truth for *what* the component does; this skill is the source of truth for *how* it does it.
- **Adding `aria-*` attributes that conflict with semantic HTML.** Don't put `role="button"` on a `<button>`. Don't put `aria-pressed` on a checkbox. Match the right pattern for the right element.
- **Forgetting the showcase update.** A component that's now interactive but whose showcase doesn't demo the interactivity is half-done. The showcase is where designers verify the behavior.
- **Trapping focus when there's nothing focusable.** A Modal with no buttons / inputs needs at least one focusable element (the close button, or `tabindex={0}` on the dialog itself) — otherwise the focus trap traps focus on `<body>` and Tab does nothing.

## Companion skills

- `component-from-figma` — auto-chains this skill after `showcase-page-generator` when the new component is in an interactive category
- `verify-component` — has a 10th check that confirms the interactive contract is satisfied (this skill *fills* the contract; verify-component just confirms)
- `screenshot-diff` — visual fidelity check; orthogonal to this skill (you can have correct screenshots with broken behavior, and vice versa)
