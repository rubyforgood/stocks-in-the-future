# Design Migration Instructions

> **Process document** for the Stocks in the Future UI migration on the `stocksdesign`
> branch. This file records *how* we work. [`design.md`](design.md) records *what* the
> UI should look like. The live page-by-page backlog is [`design-todo.md`](design-todo.md).
>
> Read all three before starting UI work.

## Purpose

Migrate all 70 pages of the application to a single, consistent, accessible design
system. Every page must end up:

1. Consistent with the design system in `design.md`.
2. WCAG 2.2 AA compliant.
3. Responsive at both supported tiers (375px and 1366px).
4. Committed, with the backlog updated.

## Sources of truth, in precedence order

When these conflict, the higher entry wins. This ordering matters because the design
system document was adapted from another project and still carries assumptions that
do not hold here.

| # | Source | Authority |
|---|--------|-----------|
| 1 | `docs/responsive-design-guidelines.md` | Responsive rules, breakpoints, touch targets. Project-specific and written for our actual users. |
| 2 | `design.md` | Visual design system: typography scale, colour reasoning, component patterns, spacing, states, rationale. |
| 3 | This file | Process: workflow, checkpoints, review gates. |
| 4 | Existing code | Where the above are silent, follow established repo convention rather than inventing. |

### Why `docs/responsive-design-guidelines.md` outranks `design.md`

Our users are **students on school Chromebooks (1366x768)**. That document is written
for them and mandates:

- **Only two responsive tiers**: `base` and `lg:`. Do not introduce `sm:`, `md:`, `xl:`
  or `2xl:` variants, even though `design.md` uses them freely.
- **Buttons are 40px (`h-10`)** - design.md's height token, used by `.tw-btn-*` and the
  admin button helpers. WCAG 2.5.8 (AA) asks 24x24, so 40px clears it; 44px is AAA / Apple
  HIG. **44px applies to bare tap targets** with no other affordance: icon-only controls,
  sidebar nav rows, table row actions.
- **Test at 375px and 1366px** before every checkpoint.
- **WCAG AA minimum.**

`design.md` is the authority on how things *look*; it is not the authority on how
things *reflow*.

## Design principles

The design system is informed by established industry practice. Apply the reasoning,
not a surface imitation of any single product.

- **Stripe** - calm, dense-but-legible data presentation. Generous whitespace around
  tables and forms. Restrained colour: colour carries meaning, never decoration.
  Numbers and money right-aligned and tabular.
- **Airbnb** - warm, trustworthy, human. Soft radii, clear photographic/illustrative
  hierarchy, friendly empty states, plain-language microcopy.
- **Material Design** - elevation and state layers as a consistent system, motion with
  purpose and short duration, touch-target sizing, predictable component anatomy.
- **Google / Material accessibility guidance** - contrast, focus visibility, and
  never encoding meaning in colour alone.
- **HCI fundamentals** - the principles that outrank fashion:
  - *Visibility of system status*: every action produces immediate, visible feedback.
  - *Recognition over recall*: labels and affordances stay on screen; avoid hidden state.
  - *Error prevention over error messages*: constrain inputs, confirm destructive acts.
  - *Consistency*: identical concepts look and behave identically across pages.
  - *Fitts's law*: frequent or large-consequence targets get more area and closer proximity.
  - *Hick's law*: reduce simultaneous choices; progressive disclosure over dense menus.
  - *User control*: reversible actions, obvious escape routes, no dead ends.

### Audience constraint

Most users are **middle-school students**. This raises the bar on clarity:
plain language, unambiguous labels, forgiving interactions, and no reliance on
conventions an adult professional would know but a twelve-year-old would not.

## Tailwind conventions for this repo

This app is **already Tailwind v4** with a shadcn-style token layer. This migration is
*not* a framework port; it is a consistency and quality pass. There is no Bootstrap in
this codebase, so any Bootstrap-migration guidance in `design.md` does not apply.

### Build

- Entry point: `app/assets/tailwind/application.css`, which imports
  `shadcn.css`, `tailwind.config.css`, `navbar.css`, `tables.css`, `buttons.css`,
  `forms.css`, `admin.css`.
- Watcher: `bin/rails tailwindcss:watch` (via `bin/dev`). Output lands in
  `app/assets/builds/tailwind.css`.
- We use **`tailwindcss-rails`**, not `cssbundling-rails`. The `build:css` script in
  `package.json` is a no-op stub. Ignore any instruction to run an npm CSS build.

### Tokens over raw values

`app/assets/tailwind/tailwind.config.css` defines semantic tokens as HSL CSS variables:
`--color-primary`, `--color-destructive`, `--color-success`, `--color-info`,
`--color-attention`, `--color-muted`, `--color-card`, `--color-border`, and radii.

**Use the token, not the literal.** Arbitrary hex values in markup are the single
biggest source of inconsistency in the current UI. There are 9 distinct hardcoded hex
values across the views today; migrating a page means replacing them with tokens.

Do not write `bg-[#00698c]`. Use the brand token.

### Layouts

- `app/views/layouts/application.html.erb` - signed-in and signed-out app shell.
- `app/views/layouts/admin.html.erb` - admin area.
- `app/views/layouts/_navbar.html.erb` - primary navigation (12KB; needs decomposition).

### Components

Reusable partials live in `app/views/components/ui/`: `_button`, `_checkbox`, `_input`,
`_label`, `_textarea`, plus `app/views/components/_action_icon_button`.

- **Extend this set rather than restyling inline.** If a page needs a card, badge,
  table wrapper, or empty state, add it to `components/ui/` so the next page inherits it.
- `admin/component_demo` is the existing component gallery. Register new components
  there so they are visually reviewable in one place. It renders at
  **`/admin/component_demo`**, signed in as **admin**, and exists in development and test
  only - `config/routes.rb` guards it with `Rails.env.local?`. Nothing in the app links to
  it: a component gallery is a developer tool, and the field keeps those outside the product
  (Storybook is a separate app; Polaris, Primer and Lightning are separate sites; Rails'
  own `/rails/info` is reached by URL). `bin/rails routes | grep component_demo` finds it.

  **It is currently behind.** It renders three of the eleven partials in
  `components/ui/` - `_callout`, `_page_header`, and `_badge` via `boolean_badge` - so it is
  not a reliable index of what exists. Read `app/views/components/ui/` as well until that is
  closed out.

### Custom CSS

`docs/responsive-design-guidelines.md` states **Tailwind-only, no custom CSS**. The repo
already contradicts this with six hand-written CSS partials. Resolution for this migration:

- **Do not add** new custom CSS for one-off page styling. Use utilities.
- **Do** keep custom CSS for genuine primitives that utilities cannot express
  (`shadcn.css` token definitions, complex table/nav behaviour).
- Where a page's custom CSS exists only to work around missing utilities, remove it
  during migration and note the removal in the commit.

## Brand palette and measured contrast

Ratios below are computed against the page background `#f7f9f3`, or against the stated
background. WCAG 2.2 AA requires **4.5:1** for body text, **3:1** for large text
(>=24px, or >=18.66px bold) and for non-text UI boundaries.

| Colour | Use | On | Ratio | Verdict |
|--------|-----|----|-------|---------|
| `#00698c` brand blue | primary actions, links | page bg | **5.82** | passes AA for body text |
| white | button label | `#00698c` | **6.18** | passes AA |
| `#004f6b` dark blue | headings, nav, hover | page bg | **8.50** | passes AA comfortably |
| white | label | `#004f6b` | **9.01** | passes AA comfortably |
| `#d3df44` lime | accent fills only | page bg | **1.37** | **FAILS - never use for text or icons** |
| `#004f6b` | text on lime fill | `#d3df44` | **6.18** | passes AA |
| black | text on lime fill | `#d3df44` | **14.41** | passes AA |
| `gray-500` `#6b7280` | muted/meta text | page bg | **4.56** | passes AA, but only just - do not lighten |
| `gray-400` `#9ca3af` | - | page bg | **2.39** | **FAILS - never use for text** |

### Hard rules from the table

1. **`#d3df44` lime is a fill, never a foreground.** It is a 1.37:1 accent. Any text or
   icon placed on the page background in lime is unreadable. Pair it as a *background*
   with dark blue or black on top.
2. **`gray-400` is never a text colour.** Use `gray-500` as the lightest text on the
   page background. This matches `design.md`'s equivalent rule about avoiding
   `slate-400`.
3. `gray-500` at 4.56:1 has almost no margin. If the surface is darker than
   `#f7f9f3` (for example inside a tinted card), re-measure before using it.

## Accessibility gate (WCAG 2.2 AA)

Every page must pass this checklist before its checkpoint. No page is "done" without it.

### Structure and semantics
- [ ] Exactly one `<h1>` per page, and heading levels descend without skipping.
- [ ] Landmarks present: `<main>`, `<nav>`, and headers/footers where applicable.
- [ ] Lists marked up as lists; tabular data in `<table>` with `<th scope="col">`/`<th scope="row">`
      and a `<caption>` or accessible name.
- [ ] Buttons that act are `<button>`; things that navigate are `<a>`. Never a clickable `<div>`.

### Names, labels, and text
- [ ] Every input has a programmatically associated `<label>` (`for`/`id`), not just a placeholder.
- [ ] Placeholder text is never the only label.
- [ ] Every image has meaningful `alt`, or `alt=""` if purely decorative.
- [ ] Icon-only controls have an accessible name (`aria-label` or visually-hidden text).
- [ ] Link text makes sense out of context. No bare "click here" / "read more".

### Colour and contrast
- [ ] Text meets 4.5:1; large text and UI boundaries meet 3:1. Measure, do not guess.
- [ ] No `gray-400` (or lighter) as a text colour. No lime `#d3df44` foreground.
- [ ] Meaning is never carried by colour alone - pair with text, icon, or pattern.
      Gains/losses need a sign or arrow, not just green/red.

### Keyboard and focus
- [ ] Every interactive element is reachable and operable by keyboard alone.
- [ ] Focus is always visible, with a ring meeting 3:1 against its background.
      Never `outline: none` without an equivalent replacement.
- [ ] Tab order follows visual order.
- [ ] Modals trap focus, restore it on close, and close on `Esc`.
      This applies to `shared/_modal` (the trading modal), used app-wide.
- [ ] No keyboard trap anywhere.

### Forms and errors
- [ ] Errors are announced, not only coloured - associate via `aria-describedby`.
- [ ] Error text names the field and says how to fix it.
- [ ] Required fields are marked in text, not by colour or asterisk alone.
- [ ] Destructive actions require confirmation.

### Motion and zoom
- [ ] Animation respects `prefers-reduced-motion`.
- [ ] Page remains usable at 200% zoom and at 320px equivalent reflow without
      horizontal scrolling.

## Responsiveness gate

Per `docs/responsive-design-guidelines.md`. Every page, every checkpoint.

- [ ] Verified at **375px** (phone) and **1366px** (Chromebook - our primary target).
- [ ] Only `base` and `lg:` tiers used. No `sm:`/`md:`/`xl:`/`2xl:`.
- [ ] Mobile-first: unprefixed styles target the small screen; `lg:` scales up.
- [ ] Buttons on the 40px `h-10` token; bare tap targets (icon-only controls, nav rows,
      table row actions) >= 44x44px.
- [ ] No horizontal overflow at 375px.
- [ ] Tables: either horizontally scrollable in a labelled container, or restructured
      into stacked cards at base width. Never a squeezed, unreadable grid.
- [ ] Forms single-column at base width.
- [ ] Navigation collapses correctly; the mobile menu toggle is keyboard-operable.

## Per-page migration workflow

Run these steps for each page. Do not batch several pages into one unreviewed change.

1. **Read** the current template and note what it does. Identify the data it renders and
   every interactive element.
2. **Inventory the debt**: hardcoded hex values, inline one-off styling, missing labels,
   `div`-as-button, absent focus states, non-responsive tables.
3. **Check for an existing component** in `app/views/components/ui/`. Use it. If the page
   needs a new primitive, build it there first and register it in `admin/component_demo`
   (`/admin/component_demo`, as admin, development and test only).
4. **Rewrite** the markup against `design.md`'s type scale, spacing, and component
   patterns - using tokens, and only `base`/`lg:` tiers.
5. **Run the accessibility gate** above.
6. **Run the responsiveness gate** above.
7. **Run the tests**: `bin/rails test` plus the relevant `test/system/` test.
   Lint with `bin/lint`.
8. **Checkpoint**: commit, push, tick the page off in `design-todo.md`.

### Behaviour must not change

This is a visual and accessibility migration. Do not alter business logic, routes,
queries, or permissions while restyling. If a page appears functionally broken, note it
in `design-todo.md` and raise it separately rather than fixing it inside a style commit.

## Checkpoint protocol

A checkpoint is **one page, or one coherent group of small related pages**.

At every checkpoint:

1. `bin/rails test` and `bin/lint` pass.
2. Both gates above pass.
3. Commit with a message naming the page and what changed.
4. Push to the `stocksdesign` branch.
5. Update `design-todo.md`.
6. If the change has a long-term blast radius, add it to `migration.md` **as part
   of the same commit** - removing a capability, changing data behaviour, adding
   or dropping a dependency, establishing a convention, or altering a flow that
   tests depend on. The test is whether it would surprise someone six months from
   now. Routine styling and copy edits do not belong there.

Architecture work needs a **migration map** in `migration.md` before any code
moves: current structure, target structure, the order of moves, and what each step
breaks.

Commits stay small and page-scoped so any regression is easy to bisect and revert.


## Known blockers and deviations

Recorded here so they are not rediscovered. Update as they are resolved.

### 1. Pushing to GitHub is currently blocked

The checkpoint protocol says "commit and push". **The push half cannot run yet.**

- Remote `origin` is `git@github.com:rubyforgood/stocks-in-the-future.git` over SSH.
- SSH authentication works (`giacoelho`), and fetch/pull work.
- `git push` is rejected: `Permission to rubyforgood/stocks-in-the-future.git denied to giacoelho`.
- No fork exists under `giacoelho`.

Until either a fork is created or write access is granted, checkpoints **commit locally
only**. Commits accumulate on `stocksdesign` and can be pushed in one go once a
destination exists. Nothing is lost, but nothing is backed up off-machine either.

### 2. `design.md` is adapted from another project

`design.md` originates from the Ruby for Good **CASA** project's design system
(`rubyforgood/casa`), pulled in as a starting point and rebranded. Credit to that team.
It has **not** yet been reconciled with this codebase. Known mismatches:

- **Bootstrap migration premise** - CASA runs Tailwind alongside legacy Bootstrap 5 and
  migrates page-by-page across two layouts. This repo has no Bootstrap. The
  "Status & approach", "Migrating a page (playbook)" and "Migration status" sections
  describe a problem we do not have.
- **Build pipeline** - references npm CSS builds via `cssbundling-rails`. We use
  `tailwindcss-rails`.
- **Palette** - prescribes `slate`; this codebase uses `gray` in ~820 places. Until a
  deliberate decision is made, **stay with `gray`** and keep it consistent.
- **Typography** - prescribes self-hosted Figtree. Not set up here.
- **Dangling identifiers** - after rebranding, names like `stocks_in_the_future_cases`,
  `stocks_in_the_future_org`, `stocks_in_the_future_app`, `StocksInTheFutureCaseDecorator`
  and `all_stocks_in_the_future_admin` look local but correspond to nothing in this repo.
  They are CASA's models, layouts and admin scopes.
- **Foreign domain language** - surviving prose refers to volunteers, supervisors, court
  dates, placements, reimbursements and chapters. Our domain is Student, Teacher,
  Classroom, Portfolio, Stock, Order, Quarter, GradeBook.
- **Breakpoints** - uses the full Tailwind tier set; we permit only `base` and `lg:`.
- One sentence lists "Stocks in the Future" as an example of an *acronym*, an artifact of
  the rebrand. It is not one.

**Practical rule:** take from `design.md` the *portable* material - type scale, contrast
rules, spacing, component anatomy, states, and the documented rationale. Ignore its
build, layout, breakpoint and domain specifics. Reconcile the document itself as the
migration proceeds, so it converges on describing *this* app.

### 3. Pre-existing repo state

- `app/.DS_Store` and `app/assets/.DS_Store` are tracked and deleted in the working tree.
  They should not be tracked at all.
- Font Awesome 6.4.0 loads from a CDN in `application.html.erb`. This is a
  performance and privacy dependency on a third party, and it means icons break offline.
  Worth replacing with local SVGs during the migration.
- `db/seeds/partials/users.rb` cannot create the teacher account: it sets `name` but not
  `username`, and `username` is validated for presence, so `save` silently returns false.
- `db/seeds/partials/portfolio_transactions.rb` and `orders.rb` use unguarded `.create`,
  so re-running the full seed duplicates transactions and inflates balances.

### 4. Login is by username

Devise is configured with `config.authentication_keys = [:username]`. Sign in with
`admin` / `teacher` / `student` / `mike` and password `password` - **not** email.
