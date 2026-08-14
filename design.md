# Stocks in the Future Design System

> **Permanent, living record** of the Stocks in the Future UI refresh (`stocksdesign` branch) — the
> **single source of truth** for the new design system and the decisions behind it.
> **Refer to it for all UI work** so this direction never has to be rediscovered or
> rebuilt. Read it before building UI, and keep it current as patterns solidify.
> The live "what's left" backlog lives in [`design-todo.md`](design-todo.md).

> **Provenance.** This document began as the design system from the Ruby for Good
> **CASA** project (`rubyforgood/casa`) and was adapted for Stocks in the Future.
> Credit to that team. Sections describing CASA's own domain — volunteers,
> supervisors, court dates, placements, chapters — and its Bootstrap migration do
> **not** apply here.
>
> **Reconciliation is complete**, section by section. Sections specifying controls this app has no
> equivalent of — TomSelect multiselect, a searchable single-select, repeatable sub-forms, the
> Bootstrap-coexistence rules — are **deleted or replaced by a short "not in this app" note**, with
> their transferable rules kept: the picker ones in
> [`docs/type-ahead-and-multiselect.md`](docs/type-ahead-and-multiselect.md), the rest inline. Every
> other section keeps its rule and gets an example **that exists here**.
>
> The method matters, because the shortcut fails. A mechanical find-and-replace was tried and
> reverted: it turned CASA's history into false claims about this app — `classrooms#edit was a white
> card with a rose outline`, a `classrooms/_month_year_select` that does not exist — which is worse
> than an obviously foreign noun, because a false claim is indistinguishable from a true one. Where a
> rule's original example could not be replaced by a real one, the example was dropped and the rule
> kept.
>
> Two sections record a **deliberate divergence** from what was inherited, rather than a translation:
> the one chart here is Chart.js on a canvas where the spec called for bespoke SVG, and the sidebar's
> group labels are not uppercase, because this document's own copy rule forbids that transform.

## Status & approach

Refreshing the UI with a clean, modern look. Reference points: **Stripe** for calm
dense data and restrained colour, **Airbnb** for warmth and friendly empty states,
**Material** for elevation and touch sizing, and HCI fundamentals over fashion.

**There is no Bootstrap in this codebase.** The app is already Tailwind CSS v4
throughout, so this is not a framework port — it is a consistency, accessibility
and visual-quality pass, page by page onto shared primitives.

- Tailwind entry point: `app/assets/tailwind/application.css`, which imports
  `figtree.css`, `shadcn.css`, `tailwind.config.css` (the `@theme` block) and the
  component partials `navbar.css`, `tables.css`, `buttons.css`, `forms.css`,
  `admin.css`.
- Build: `bin/rails tailwindcss:build`, or the watcher via `bin/dev`. This project
  uses **`tailwindcss-rails`**, not `cssbundling-rails` — the `build:css` script in
  `package.json` is a no-op stub, so ignore any instruction to run an npm CSS build.
- Under a process manager with no TTY the watcher needs the `always` variant:
  `bin/rails 'tailwindcss:watch[always]'`. Without it the watcher exits
  immediately and takes the web process down with it.

### Adopted from this document, and where it was overridden

| Foundation | Status here |
|-----------|-------------|
| **Figtree**, self-hosted, no CDN | Adopted. It is a *variable* font, so one file covers 400–800; two subsets (latin, latin-ext) live in `public/vendor/figtree/`, declared in `app/assets/tailwind/figtree.css`. Shipping one file per weight would be the same bytes five times. |
| **slate** neutrals | Adopted app-wide. Contrast verified to hold: slate-500 4.76:1, slate-600 7.58:1, slate-700 10.35:1, slate-900 17.85:1 on white. |
| Type scale, sentence case, `text-xs` as chrome | Adopted verbatim. |
| Full breakpoint set (`sm:`/`md:`/`xl:`) | **Overridden.** `docs/responsive-design-guidelines.md` permits only `base` and `lg:` — because this app's layouts change shape exactly once, at the sidebar. That document wins on anything responsive, and note what the rule does *not* say: two tiers is not two widths, and everything still has to work continuously from 320px and at 200% text. |
| Brand colour | **Overridden.** Stocks in the Future keeps its own palette (`sitf-primary` teal-blue, `sitf-accent` lime) for brand moments, exposed as tokens in `tailwind.config.css`. |

## Foundations

### Typography
- **Figtree**, weights 400/500/600/700/800. Warm humanist sans. Self-hosted (latin + latin-ext
  woff2 under `public/vendor/figtree/`; `@font-face` in `app/assets/stylesheets/vendor/figtree.css`,
  `@import`ed by `tailwind.css`) — no CDN.
- Scale:
  - Page title (h1): `text-2xl font-bold tracking-tight text-slate-900`
  - Section title (h2): `text-base font-semibold text-slate-900`
  - Body: `text-sm text-slate-600`
  - Label: `text-sm font-medium text-slate-700`
  - Muted / meta: `text-xs text-slate-500` (never `text-slate-400` for text — fails AA)

**`text-xs` (12px) is chrome, not content.** It is the token for a status pill, a column header, a
**stacked** field label sitting above its value, and the signed-in account line in the nav — short,
glanceable strings. Anything the user actually *reads or transcribes* — an email address, a date, a
person's name, a note — stays at `text-sm`, even inside a dense row. WCAG sets **no** minimum font
size, so 12px `slate-500` is not a conformance failure (4.77:1, passes 1.4.3 at any size); this is a
legibility floor, and it is where the major systems put theirs (Material reserves 12px for
captions/labels, Polaris uses `bodySm` sparingly, GOV.UK warns off anything under 16px). Reported, on the app this document came from, as "the email font looks too small … very difficult to
read" one turn after an email was shrunk from `text-sm` to `text-xs`. The same shape exists here: the
teacher picker on the classroom form puts a name over an email, and the email is what tells two
teachers apart.

**Fewer type sizes is not the goal — one treatment per role is.** Shrinking *content* to dedupe sizes
trades a real problem (a control that read as metadata) for a worse one (content nobody can read). When
a card reads flat, change the role mapping — weight and colour — not the size.

### Sentence case
All UI copy — page titles, section headings, subtitles, table headers, field labels,
buttons, badges and nav — uses **sentence case**: capitalise only the first word and
proper nouns (Stocks in the Future, people's names). So "Add a student", not "Add A Student", and
never the shouty all-caps "ADD…".

**The sweep is done, and grepping views is not enough to keep it done.** A scan of headings,
labels, buttons and `<th>`s in `app/views` came back nearly clean while these were still Title
Case, because copy lives in five places a view grep misses: **`content_for :page_title`**,
**decorators**, **`config/locales`**
(`activerecord.attributes` names, Devise mail subjects) and **mailer subjects**. Two more traps: text
inside a `link_to ... do` block is on its own line, so a `link_to "..."` pattern never sees it, and a
Title Case string can be *correct* — a ticker, a company name ("Coca-Cola"), an industry classification
("Consumer Electronics"), a CamelCase class name, and "Please" starting a second sentence all tripped
the scan here.

**Renaming a shipped seed name needs a data task as well**, wherever this app grows one: seeds
`first_or_create` by name, so an existing database keeps the old row and a reseed adds a second. Nothing
in `db/seeds/` is user-visible copy today, so there is nothing to rename — the trap is recorded for when
there is.

Leave **CSV export headers** alone: they come from `titleize` on column symbols and are interchange
labels, not UI copy — the student importer's `classroom_id`, `username`, `name` are the format, not a
label. Do **not** apply the
`uppercase` CSS transform to labels; use size, weight and colour for hierarchy instead.

**No trailing colon on a heading or subtitle** (`Grade books`, not `Grade Books:`). A colon belongs
only on an inline key/value **fact label** — a `dt` such as `Held by:` — never on a section
title. Audit the views you touch: `grep '<h[123][^>]*>[^<]*:</h'` should return nothing on a
an app-layout page.

Sentence case also covers **app-shipped content**, not just view copy: seed defaults and
constants (e.g. `ContactTypeGroup::DEFAULT_CONTACT_TYPE_GROUPS`, whose names render as the
multiselect chips) are sentence-cased too. Before finishing, **scan the touched views and any
app-shipped names/defaults for Title Case or ALL-CAPS** and fix them. Proper nouns and
acronyms (Stocks in the Future, IEP, Twilio) are the exception, and never force-case free-form org data (an
org may legitimately name a type "ADHD coach"). Sentence-casing a **default constant** does
**not** fix orgs already seeded from the old names — `generate_for_org!` find_or_creates by name
and never renames — so pair the constant change with a one-time after_party rename that touches
only case-variants of a shipped default and leaves org-renamed / custom names alone
(`20260721000000_sentence_case_default_contact_types`).

### Color
Brand = **teal**, not indigo. Neutrals = slate. Semantic colours below.

| Token | Where it comes from | Use |
|---|---|---|
| `sitf-primary` | `--sitf-primary-chart1` | primary actions, active nav, links |
| `sitf-primary-dark` | `--sitf-primary-dark` | hover and focus on the above; inline links |
| `sitf-on-primary` | — | label on a filled primary |
| `sitf-surface` | `--sitf-background` | the page behind the content |
| `sitf-accent`, `sitf-accent-soft` | `--sitf-accent1-chart3` | **fill only**, never text or icons |
| `sitf-warning`, `sitf-danger` | `--sitf-accent2-chart5`, `--sitf-status-destructive` | semantic fills |
| slate-50…900 | Tailwind | text, borders, surfaces |
| emerald / amber / rose | Tailwind | success / warning / danger, one step darker than instinct |

Measured against `--sitf-background` (#f7f9f3): **`sitf-primary` 5.82:1**, **`sitf-primary-dark` 8.50:1**,
**`sitf-accent` 1.37:1 — fill only, never a foreground.**

The values live once in `shadcn.css`; `tailwind.config.css`'s `@theme` block only exposes them as
utilities, so a view never hardcodes a hex.

**There is no `brand-*` scale.** This table used to name one - `brand-50…900`, indigo, from a
`--color-brand-*` block - and it was CASA's. Nothing in this app defines those tokens, so anything
written against them renders no colour at all.

**A dozen `brand-*` mentions survive in prose below**, in sections not yet reconciled. Read them as:
`brand-600` / `brand-700` -> **`sitf-primary`** / **`sitf-primary-dark`**, `brand-50` / `brand-100` ->
**`sitf-primary/10`**. Every *copyable* class list has been corrected; what remains is descriptive
("a brand-600 parent link"), and it is listed in `design-todo.md` rather than left to be discovered.

### Spacing, radius, elevation
- 4px spacing base (Tailwind default).
- Radius: controls `rounded-lg`; cards/panels `rounded-2xl`; icon tiles `rounded-xl`.
- Surfaces: white, `border border-slate-200`, `shadow-sm`.
- Page background: `bg-slate-50`.
- **Page vertical rhythm** (index / list pages): the content wrapper carries **vertical** rhythm
  only (`py-6`) -- the layout owns the horizontal gutter, so a page never adds `px-*` of its own
  (see "Content gutter and width" below);
  header block `mb-6` (24px); the header **row** is
  `flex flex-col gap-3 lg:flex-row lg:items-{end|start} lg:justify-between`, and `_page_header` picks the
  alignment from whether a `description` was passed: **`items-end`** for a **title-only** header, so the
  40px action lands on the h1's baseline, and **`items-start`** when the title carries a **subtitle**, so
  the action top-aligns to the title rather than sinking to the subtitle. Both directions have been
  measured wrong here: `items-start` on a title-only header leaves 8px of dead space under the 32px h1
  inside a 40px row, which renders the 24px gap as 32px.

  A **plain (borderless) filter bar** gets `mb-4` so it sits **16px** above the table --
  `admin/shared/_discard_filter_tabs` is the instance, and `mb-5` or `mb-6` on a plain filter is drift. A
  filter wrapped in its own **bordered card** is a *section*, so it keeps the 24px section gap instead:
  `admin/shared/_search_filter` is `tw-card mb-6 p-5`. Stacked sections and cards separate by 24px
  (`space-y-6` on the wrapper, which is what `classrooms#show` uses -- note that `mt-6` on the first
  child of a header block collapses against the header's own `mb-6` and measures nothing).

  **Nothing paginates.** `admin/shared/_pagination` exists and `admin/shared/_table` renders it as an
  in-card footer, but it is guarded on `collection.total_pages > 1` and **no controller paginates**, so
  it has never appeared: every index renders its whole collection. A classroom is ~25 students and the
  stock list is curated, so that is fine today. Turning it on is a controller change rather than a
  styling one, and the thing to check is that `sort_link` and any filter params survive the page
  parameter.

  Verify these gaps at the pixel level (filter-bottom -> table-top), not by reading tokens;
  `test/system/spacing_test.rb` and `test/system/page_rhythm_test.rb` do exactly that.

### Measure the rendered box

**Class names describe intent. Only the rendered box describes the result.** When spacing or
alignment looks wrong, measure `getBoundingClientRect()` in a browser before changing anything -
reading the markup will usually tell you it is already correct.

This is not a general caution; it is the specific failure mode that cost three rounds on this
branch. Each time the classes said the spacing was right, and each time it was not:

| Reported | What the markup said | What it measured | Actual cause |
|---|---|---|---|
| Gap under the page title | `mb-6` = 24px | 44px | a `pb-5` left behind when the rule under the title was removed |
| Gap inside the card | `py-4` header, `p-5` body | 37px | two paddings stacking at the seam; adding a rule marks the boundary but removes no space |
| Gap under the page header | `mb-6` = 24px | 32px | a 40px action beside a 32px h1 in an `items-start` row, leaving 8px of dead space under the title |

None of the three is visible in the class list. Two of them were *caused* by removing something
and leaving its spacing behind, which is the shape to watch for: **padding that existed to hold
content off a thing you just deleted.**

`test/system/spacing_test.rb` asserts pixels rather than classes for this reason, with a 2px
tolerance and failure messages that name the usual cause.

### Page header
**Every page renders `components/ui/_page_header`.** It is the only place the h1 treatment and
the header block's spacing live, and it is what declares `content_for :own_heading`.

The *scale* was already consistent - every visible h1 in the app was
`text-2xl font-bold tracking-tight text-slate-900`, matching Typography. What was not consistent
was the header **block**: 31 pages hand-rolled the h1 and bolted spacing onto it directly
(`mb-6` on ten, `py-2` on two, `mb-2` on two), so the gap under a title depended on which page
you were on.

Hand-rolling it also broke something invisible. **The admin layout renders an `sr-only` h1 unless
the page declares `:own_heading`**, and only the component declares it, so every hand-rolled
admin page shipped **two h1s** - the visible one and a hidden one derived from breadcrumbs, which
disagreed on case (Title Case against sentence case). Nineteen admin pages were in that state.

**Auth pages are the deliberate exception.** Devise's centred card uses
`text-center text-2xl/9 ... pb-4`, which is a different layout rather than drift.

**A status pill goes in `badge:`, never in the block.** The block is the *actions* slot and it is
right-aligned, so anything passed there lands in the top-right corner - the place `Add student` and
`Edit classroom` occupy on every other page. The grade book passed its Draft pill that way and it read
as a control floating alone in the corner. `badge:` renders it on the title's line instead, which is
where Linear, Stripe and GitHub all put entity state: beside the name it describes. This is the same
fault as the trading switch in a page header one page over - **a non-action does not go in the action
area**, and the header now has a slot for the one non-action that keeps being asked for.

**The page title and its actions sit at page level, on the page background — never
inside the card.** `components/ui/_page_header` renders them: the single `h1`, an
optional supporting line, and an actions slot on the same optical line.

This is the standard arrangement rather than a preference. Tailwind UI's page headings,
Stripe's dashboard, Shopify Polaris (`Page` with `primaryAction`) and GitHub Primer all
put the title and its primary action above the content surface and leave the card
holding only data.

Every admin page used to nest both inside the table card. Three things followed from
that, and all three are fixed:

- The visible heading was an `h2` or `h3`. The only `h1` was the layout's `sr-only` one
  derived from breadcrumbs, so no admin page announced itself with a real heading.
- The card did two jobs — chrome and data — so its header strip needed a rule to
  separate them, which is the divider the next section is about.
- On show pages the card wrapped `admin_show_attributes`, which renders
  `components/ui/_card` itself. That is a card inside a card.

`_page_header` declares `content_for :own_heading`, and the admin layout reads it and
steps its hidden `h1` aside. Render the partial rather than hand-rolling an `h1`, or you
have to remember that `content_for` yourself — and forgetting it gives the page two
`h1`s, one of them invisible.

**Heading levels follow from the same structure.** Page title is `h1`, a card's title is
`h2`, a heading inside a card body is `h3`. Do not skip a level.

**Title and actions are aligned to each other, and which edge depends on the subtitle.**
Measured on the rendered page: with a title alone the action's **bottom** is flush with the h1's
bottom (`bottomDelta=0`); with a subtitle the action's **top** is flush with the h1's top
(`topDelta=0`), so the subtitle cannot push the action down.

Two conventions exist in the field. Tailwind UI's page headings centre the row
(`md:items-center`); Polaris and Primer align the action to the title. **Centring measures 28px
to the content below** rather than 24px, because a 32px h1 centred in a 40px row leaves 4px of
dead space beneath it - a smaller version of the bug in the table above. Edge alignment is the
one to use here.

**The header block is `mb-6` and nothing else.** No `pb-*`, and **`lg:items-end` unless the
title carries a subtitle**. A 40px action beside a 32px h1 makes the row 40px tall; with
`items-start` the title sits at the top and leaves 8px of dead space beneath it, so a header
that reads as `mb-6` in the markup renders a 32px gap. `items-end` puts the action on the h1's
baseline. With a subtitle the reverse applies, which is why the rule is conditional - this
document already recorded that as a measured bug once. While the title carried a
rule beneath it, the padding held content off that rule; once the rule went, the padding
was left stacking 20px on top of 24px of margin. If a gap looks too big, check for
padding left behind by something that was removed.

**Three things had to be true before that gap could be relied on**, and each was found by measuring
all 38 pages rather than by reading markup. The test is `test/system/page_rhythm_test.rb`, which
asserts the *rendered* distance from the header block to the first thing that follows it.

1. **The header block is a sibling of the content.** `orders#index` and `classrooms#index` wrapped it
   in a bare `<div>` inside a `flex flex-col h-full w-full` shell no other page used, so the 24px
   relationship did not exist to measure: an outer flex column separates the two by whatever the shell
   says. Wrapping it in `display: contents` does not fix this either - the box disappears but the DOM
   does not, and any measurement or `+`/`~` selector still walks the DOM.
2. **No margin on the content, even one that measures nothing.** `classrooms#show` carried `mt-6` on
   its section wrapper and `classrooms/_form` carried `mt-4` on its card. Both rendered exactly 24px,
   because adjacent vertical margins collapse to the larger and the header's own `mb-6` is at least as
   big - so both read as load-bearing while doing nothing. The `mt-4` then *became* load-bearing the
   moment an error summary appeared between the two, giving that one state a 16px gap. **An inert margin
   is worse than no margin**: it is indistinguishable from a working one until something moves.
3. **Every page uses this partial.** `admin/portfolio_transactions#new` and `#edit` were the only two
   pages in the app that never adopted it. They carried a `text-2xl font-bold` **`h2`** inside a card,
   which cost them three separate things: no `h1` at all (the admin layout's visually hidden fallback
   named the page "New"), a **card inside a card** because `_form` renders its own, and a gap above the
   card of **0px**, since the card was the first element after the breadcrumb. A page with no header has
   no header rhythm, which is why the audit could not see the defect until it was told to fail on the
   sr-only fallback by name.

### Deactivate a person, archive a thing

**Archiving has to reach the people the thing governs, or it is only a filing action.** Archiving a
classroom took it out of the teacher's list and stopped them opening it - `ClassroomPolicy::Scope` is
`.active` for a teacher, `check_classroom_eligibility` redirects a non-admin - and did nothing to the
students in it. Measured: a student in an archived classroom signed in, opened the trading floor and placed
a buy. The class was over, the teacher could no longer see it *or reach its trading switch*, and the
students went on trading in it.

`Classroom#trading_open?` is the gate now - the switch's position **and** a live classroom - and
`trading_enabled?` remains the switch's own position, which is what the admin badge and the form show.
Keeping them as two questions is the point: an admin archiving a class has not moved its switch, and
restoring the class puts trading back exactly as the teacher left it.

The general form: when a container is archived, ask what its contents can still do. The answer is rarely
"nothing changes", and if it is, the confirmation should say so.


One idea had **three** vocabularies: Archive/Restore on students and users, Archive/**Activate** on
classrooms, Deactivate/Reactivate on teachers. The split is by *kind* now, which is what the field does and
the only rule that survives being said out loud.

| | Verb | Inverse | Status | What it does |
| --- | --- | --- | --- | --- |
| **A person** -- student, teacher, user | Deactivate | Reactivate | Deactivated | cannot sign in; everything kept |
| **A thing** -- classroom | Archive | Restore | Archived | leaves the lists and cannot be opened; nobody signed out |

The field is consistent about this. Slack deactivates a member, Google Workspace suspends a user, Salesforce
and Okta deactivate; Gmail, Shopify, GitHub and Notion *archive* mail, products, repositories and pages. The
distinction is whether the thing has a login: for a person the operative fact is whether they can still get
in, and "archived" says nothing about that.

**And the words were only half the problem.** Five confirmations promised "They lose access immediately" and
none of them was true - a discarded student signed in, got a 303 to root, and the next request was
authenticated. `User#active_for_authentication?` now returns false for a discarded record, which Devise's
`activatable` hook checks on **every** `after_set_user`, so a session already open ends on the next request
rather than surviving until the cookie expires. That is the case the copy describes: an administrator
turning off somebody who is using the app right now.

The classroom confirmation had the mirror-image lie - "its teachers and students lose access immediately",
which archiving a classroom has never done and should not. It says what actually happens: the classroom
leaves the lists and cannot be opened, and nobody is signed out, because a classroom has no login.

**An "All" tab needs a status column, or it merges two populations a reader cannot tell apart.** Reported on
`admin/students`: with Active, Archived and All tabs, the All tab listed archived rows among live ones and
the only difference on screen was the *verb on the row action* -- "Archive" against "Restore". A control is
not information, and nobody scanning a list reads the buttons to work out what they are looking at.

That is the pattern's own bargain, and the field keeps both halves of it. Shopify's index pages pair
All / Active / Draft / Archived tabs with a status badge on every row; Stripe, GitHub's Open / Closed / All
and Linear all do the same. The tab is standard; a tab **without** the column is the defect.

So all three archivable indexes carry `Status` through one helper, `discard_status_badge`, and it is
**sortable** -- grouping them is the other half of what the tab is for. `discarded_at` is a real column, so
`sort_link` does it, and Postgres sorting NULLs last means ascending puts the archived rows together.

**And the column renders only on the All tab.** Shipped on all three at first, and reported: an "Active"
badge on every row of the Active tab is a column whose value never varies, which is the column-of-dashes
rule from the other direction, and it contradicts the reason `user_status_badge` renders nothing for a live
account. The tab already names the population. The column earns its place on the one tab where the two are
mixed -- and *there* both values are worth drawing, because a blank cell would read as missing data rather
than as "active".

**Three tabs, not two.** The alternative raised was All plus Archived, with All sorted by status. Sorting
groups; it does not exclude, and with two hundred students and thirty archived the default view would make
you scroll past thirty rows you did not ask for. Removing the Active tab also leaves the default state with
no tab to return to. Shopify ships All / Active / Draft / Archived and GitHub Open / Closed / All, both
keeping a tab for the default.

The label follows each page's own action, because that is what a reader connects it to: a student and a user
are **Archived** and restored, a teacher is **Deactivated** and reactivated. That split is in the verbs
already and is worth revisiting as one decision rather than by renaming a badge.

**Filters and tabs go above the card as well.** A filter is chrome above the data, so a
plain borderless filter bar or tab rail sits on the page background, `mb-4` (16px) above
the table — not on the card's surface. `admin/shared/_discard_filter_tabs` is the shared
rail for the active/archived/all filters on the students, teachers, users and classrooms indexes.

Which tab is selected is read in **one place** — `SoftDeletableFiltering#discard_filter`, exposed to views
with `helper_method`. `?discarded=true` / `?all=true` is a contract four indexes share, and it was being
read twice: once in the concern for the scope and once in `AdminHelper#current_discard_filter` for the
rail. The archive *mechanism* is not part of that contract — three of the four use `discard` and
`classrooms` an `archived` boolean, and both map onto the same three tabs.

This is worth stating plainly because the opposite argument is persuasive and wrong: *the
tabs filter the table directly below them, so they belong to it.* They do not. Putting
them on the card's surface puts chrome and data back on one surface, which is the thing
hoisting the header out was meant to stop.

Two details in that rail:

- Inactive tabs carry `border-b-2 border-transparent`. Without the width, selecting a tab
  shifts the row by 2px, and the `hover:border-slate-300` sets a colour on a border that
  has no width, so it renders nothing.
- The selected tab gets `aria-current="page"`. It was previously signalled by colour
  alone, which is unavailable to a screen reader (4.1.2) and to anyone who cannot
  separate the two colours (1.4.1).

### Dashboard pages: the standard shape

`portfolios#show` is the reference. Read top-down: **a KPI band, then the trend beside a
breakdown, then the detail table full width.** Robinhood, Fidelity, Wealthfront, Stripe and Shopify
analytics all order it this way, and it is the fix for a page reported as busy and hard to parse.

**One gutter: 24px, `gap-6`, everywhere.** The portfolio page had `gap-8` between its columns,
`gap-6` inside them and `gap-4` between its stats - three rhythms on one screen, which is most of
what "nothing lines up" means. Every row then starts and ends on the same two edges, which is what
makes a grid read as a grid.

**Cards sharing a row share a height.** A grid cell stretches; the card inside it does not, so it
needs `h-full`. Measured before: a 419px chart beside a 352px breakdown in the same row.

**The widest content gets the width.** A six-column holdings table was in a two-thirds column while
a narrow label/value list took the other third. A trend chart and a table want width; a list of
terms and values does not.

**KPI figures decompose the total, they do not repeat it.** `value = cash + invested` is worth
showing a student learning what a portfolio is. The old row showed cash in a stat *and* in the
earnings-to-invest card, and earnings in a stat *and* in the breakdown card - the duplication is
what made the page feel crowded, more than the layout did.

**One surface. There were five on that page**: `.tw-card`, `_stat`'s own `rounded-xl`/`shadow-xs`,
an `h-[150px]` panel, `.table-wrapper`'s `rounded-xl`/`shadow-xs`, and a hand-rolled amber alert.
`_stat` and `.table-wrapper` are `.tw-card`'s tokens now, and the alert is
`components/ui/_callout`. **A table card is a panel, so it is `rounded-2xl` like every other card** -
a 12px-cornered table directly under 16px-cornered cards is visible even when nothing else is wrong.
`test/system/portfolio_layout_test.rb` asserts one radius across the page.

### Delight on the student side

Six features on `portfolios#show`, all built on one rule: **every one is withheld when it has nothing
true to say.** A card reading "Best month yet: $0.00" or a comparison of "+$0.00" is worse than no
card, and a student in their first month should not be shown an achievement they have not had.
`PortfolioInsights` returns `nil` rather than zero for exactly this, and each partial returns early.

1. **A comparison line on the headline figure.** The baseline is the most recent snapshot dated
   *before this month*, so it means "since last month" rather than "since some point mid-month". No
   such snapshot means no line. A zero baseline means an amount but **no percentage** - a portfolio
   that was empty has not grown by a percentage.
2. **The first-share moment.** Inline, not a modal: on a shared Chromebook a modal is dismissed by
   whoever walks past, and it cannot cover the page it is explaining. Once per student, remembered
   in `portfolios.first_share_acknowledged_at` - a timestamp, so the record says *when* as well as
   whether. It explains **owning**, not buying.

   **It is `components/ui/_callout` with the `:info` tone, and a plain glyph.** It was a bespoke
   `bg-teal-50` / `border-teal-200` panel - Tailwind's teal, which is a **mint green and not this
   product's brand**: `sitf-primary` is `#00698c`, a blue-teal. An informational panel is blue in
   every system that ships one. The bespoke panel is also *how* the mint got in: the callout
   component was built two commits earlier and then not used here, so there was nowhere for the
   token to be checked. **A banner gets a plain tone-coloured glyph, never an icon tile** - the tile
   pattern is for contexts where the icon is the subject and it assumes a white surface.

   Note `teal-*` is not the brand anywhere. The badge component's `:brand` tone is
   `bg-teal-50 text-teal-700` for the same reason and has the same problem; it is used for
   categorical labels rather than brand emphasis, so nothing depends on it being the brand hue, but
   do not reach for `teal-*` expecting `sitf-primary`.

   **The icon is `chart-pie`, not `party-popper`, and the distinction is the whole point.** The copy
   says "you hold", never "you just bought", so the message is accurate for any holder - which
   matters, because nothing was backfilled and every existing student sees it once. A party popper
   implied a recency the words never claimed. A pie slice is what the sentence is about: a part of a
   whole. It also cannot be a `lightbulb`, which "Your money at work" already uses on the same page.

   **Nothing is backfilled, deliberately.** Not backfilling costs current holders one
   out-of-context, one-click-dismissible message. Backfilling would permanently deny the explanation
   to every student who has already bought - and in an app for teaching financial literacy the
   explanation is the product. A permanent cost to avoid a transient one.
3. **A plain-English summary.** It restates figures already on the page, which is the point: reading
   "$4.00 is still waiting to be invested" makes an idle balance a decision rather than a number.
   `pluralize`, so nobody reads "1 companies".
4. **The companies a student owns are the holdings table, and there is one of them.** A separate
   "Companies you own" card was built and then removed: it was a second list of the same companies
   with the same logos - exactly the duplication this page had just been rebuilt to remove - and a
   wall of **unlabelled logos**, which only works if you already recognise the brands. A logo with
   `alt=""` and an `sr-only` ticker is worse than it looks: the screen reader gets a name and the
   sighted student gets nothing. It was also the cause of the reported dead space, because grid
   children stretch to the tallest in the row and its wrapping logo strip padded out its neighbours.

   What the table lacked was the thing that actually made it unclear: **the company name.** A
   student read "KO" with no way to know that is Coca-Cola. The holdings cell is now the standard
   three-part identity - decorative logo, company name at body size and medium weight, ticker as a
   `text-xs slate-600` second line - which is what Robinhood, Fidelity and Schwab all ship, and what
   this document's primary-cell rule already said.
5. **A warmer empty state**, leading with the student's own balance. Someone else viewing their
   portfolio gets the plain version: it is not their balance to be invited to spend.
6. **A personal best, never a comparison with another student.** Earnings come from grades and
   attendance, so a classroom ranking would publish a student's school record to their classmates.

**Direction never rests on colour.** A gain or a loss carries its sign and its arrow as well as
`green-700`/`red-700`. **A loss is not a mistake** - prices come from a real API, and nothing here
implies a student did something wrong when the market moved.

**Deliberately not built**, so it is a decision rather than an omission: confetti or a streak on a
*purchase* (celebrating buying is the opposite lesson, and a streak makes not trading feel like
failure when doing nothing is usually right), and a classroom leaderboard.

### A card header is never a coloured band

A card's title is `text-base font-semibold` behind a hairline - the `_card` component. It is **never a
filled strip**, and the app had three of them, each in a different hue, each with its own radius and
its own off-scale type:

| Where | Was |
|---|---|
| The earnings breakdown | `bg-amber-300` at `tracking-wide`, `rounded-t-xl` inside a `rounded-2xl` card |
| `announcements#show` | `bg-teal-700` white-on-mint at `text-lg tracking-wide` |
| The grade books list | `bg-amber-300`, `rounded-t-xl`, sitting on a separate `rounded-md shadow` list |

The third is the clearest case of why this matters: the band's square bottom corners met a rounded
box below it, so the "card" was two boxes with three radii between them. **`rounded-t-*` on anything
is the tell** - a top-only radius exists to fuse a band to something, which the component already
does properly.

**Related, same root:** a tint is for a *message*, not a *figure*. `admin/students#show` had four
portfolio figures on `blue-50` / `green-50` / `purple-50` / `slate-50` panels - three arbitrary hues
and no icon to carry them - and the order modal had a mint panel beside an indigo one. All neutral
now. This document hue-codes a KPI's **icon tile**, never its panel fill, and a numeral is always
`slate-900`.

**Only the layout renders the flash.** `stocks#show` rendered `notice` a second time in its own green
panel, so a notice appeared twice on that page.

**Success auto-hides after 6s. Errors stay. Nothing else dismisses itself.**

`layouts/_flash`'s `#notice` carries `data-controller="auto-dismiss"`; `#alert` never does. The split
is a property of what a message *is*, not of how it looks - a notice reports that something you just
did worked and is worthless a minute later, while an alert is often the only record of what went
wrong, which is why it is `role="alert"` in the first place.

6s is the number because the field runs 3-10s and clusters at 4-6: Polaris, Bootstrap 5 and Chakra
default to 5s, Material to 4s (4-10s in its M3 guidance), Ant to 3s. The long end of the band suits
readers who are eleven. Hovering or focusing the message holds it and leaving restarts the full
delay, so it cannot vanish mid-read - that, plus a delay well above a couple of seconds, is what
keeps an auto-hiding status message clear of WCAG 2.2.1. Removal is silent by design: `role="status"`
announces the message when it appears, and taking it away later is not announced.

Two implementation traps, both real:

- **The fade is an inline style, not a utility class.** Tailwind only emits the classes it can see in
  the templates, so an `opacity-0` added from JS is not guaranteed to be in the build.
- **Removal runs on its own timer, not on `transitionend`.** A transition that never fires - a
  display change mid-fade, a browser skipping it under reduced motion - would leave the message on
  screen forever. Under `prefers-reduced-motion` the element is removed without fading at all.

**Sticking and dismissal, by banner type.** Whether a banner goes on its own, and whether the reader
can send it away, both follow from what the message *is*. All four rows are asserted by
`flash_dismiss_test.rb` rather than left to habit.

| Banner | Sticks | Auto | Close control |
|---|---|---|---|
| flash `#notice` (success) | no | 6s, held by hover/focus | yes - 44px, `dismiss#now` |
| flash `#alert` (error) | **yes** | never | yes - closing is the only way it goes |
| `components/ui/_callout` (page state) | **yes** | never | **yes, persisted** - a `button_to`, never JS |
| form error summary (`students#new`, `students#edit`, `profiles/_errors`) | **yes** | never | **no** |

The reasoning per row, since the table alone will not stop the next person guessing:

- **The alert is dismissible but never automatic.** It is often the only record of what went wrong, so
  a timer could take it before it was read - but sticking until the reader clears it is a different
  promise from sticking until they navigate, and every system that ships an error banner offers the
  close: Primer flash, Polaris `Banner` with `onDismiss`, Carbon inline notification.
- **A callout is dismissible only when the dismissal is remembered.** A client-side close on page state
  is worse than no close at all: "trading is turned off for your classroom" is still true on the next
  page load, so the banner returns and the button reads as broken. **A callout's close is a round trip,
  never a Stimulus controller.**

  **Dismissals live in one table.** `dismissals` is a row per user per key - `user_id`, `key`,
  `dismissed_at`, unique on the pair - and every dismissible banner posts to `POST /dismissals` with
  its key. `Dismissible` (included into `User`) provides `dismissed?(key, since:)` and `dismiss!(key)`;
  `Dismissal::KEYS` is the allowlist the controller checks a request against, so a client cannot write
  arbitrary rows. **Adding a dismissible banner is a key and a `button_to`** - no migration, no route,
  no controller action.

  This replaced a column per banner (`portfolios.first_share_acknowledged_at` and
  `portfolios.trading_off_dismissed_at`), which cost a migration, a predicate and a member action each.
  It hangs off `User` rather than `Portfolio` because a dismissal is a fact about a person - those two
  lived on portfolios only because both readers happened to be students, and a teacher-facing banner
  would have needed a third home.

  **`dismissed_at` is a timestamp compared against the condition's onset, and `since:` is how.** A
  boolean would be a mute button: a student who closed "trading is turned off" once would never see it
  again, including next term when their teacher switches trading off for a different reason - which is
  hiding something true and newly relevant, the exact harm the no-dismiss rule was protecting against.
  So `classrooms.trading_disabled_at` records *when* trading went off, `Classroom` clears it when
  trading comes back on, and `Portfolio#trading_off_notice?` passes it as `since:`.

  **Pass `since:` for anything that can recur, and leave it off only for something that genuinely
  cannot.** `celebrate_first_share?` omits it deliberately - a first share happens once and the
  celebration is over either way. A `nil` onset also covers "we do not know when this began", which is
  what a deliberately un-backfilled onset column leaves behind; the dismissal is honoured, and the
  first real onset makes the comparison exact, so it heals rather than needing a data migration.

  **The block is passed per call site, not built into the component**, because `button_to` renders a
  `<form>` and the callout in `admin/teachers/_form` sits *inside* the teacher form - where the parser
  drops the nested form and the button silently submits the outer one. That callout has no dismiss, and
  a test asserts it stays that way.
- **A form error summary has no close at all.** It is not an event, it is a description of the form as
  it currently stands, rebuilt on every submit. Hiding it hides the list of what still needs fixing
  while the fields it refers to are still wrong.

The close control lives in `layouts/_flash_dismiss`, one definition for both tints. It is **44px**,
matching the modal and drawer closes, because a bare icon control with no other affordance is the one
case where this app uses that figure rather than the 32px a labelled ghost button gets. It carries no
`text-*` colour, so the glyph inherits the banner's ink and keeps the copy's measured ratio, and it has
an `sr-only` name because `lucide_icon` renders `aria-hidden`. `-my-3` keeps the 44px target from
making the panel taller - measured 56px with the button and 56px without.

Note the flash section further down this document, under Accessibility, describes a `shared/_flashes`
partial with an `auto-dismiss` controller and a `notice_action` link. **That partial does not exist in
this app** - its neighbours name controllers that do not exist here, so that block came from another
codebase. Its ~6s figure is where this 6s comes from,
but this entry is the one describing code that is here.

**Notices go through `components/ui/_callout`**, which is why it exists. `admin/teachers/_form` had a
hand-rolled `yellow-50` panel with an inline SVG and a link buried mid-sentence; the link is the
callout's trailing action now - a message plus the thing to do about it. `layouts/_flash` deliberately
stays hand-rolled: it carries `id`s that tests target, `aria-live`, and `role="alert"` for errors,
which is an interrupting semantic a passive callout should not have. Its tokens already match.

### The brand is a blue-teal. Tailwind's `teal-*` is a mint, and is not it

`sitf-primary` is **`#00698c`**, a blue-teal. Tailwind's `teal-50` / `teal-700` are the **mint green**
family, and so is the brand's own unused secondary (`--sitf-secondary-chart2: #1db8a6`, a *chart*
colour by its own name). Reaching for `teal-*` to mean "the brand" gets you a different hue, and it
happened five times:

| Where | Was | Now |
|---|---|---|
| The first-share banner | a bespoke `bg-teal-50` panel | `_callout` `:info` |
| `announcements#show` | a saturated `bg-teal-700` title band | the page's `h1` on `_page_header` |
| The order modal | `bg-teal-700/10` beside an indigo panel | both neutral `bg-slate-50` |
| `_badge` `:brand` tone | `bg-teal-50 text-teal-700`, **used nowhere** | deleted |
| The delight preview | a teal mock of a shipped feature | deleted |

**Two of these were saturated bands on a card**, which is the same drift the earnings breakdown had
in amber: a coloured strip where the card component's header belongs. A card title is
`text-base font-semibold` behind a hairline, never a filled band.

**An unused off-brand tone is the worst case**, and the badge's `:brand` was exactly that: whoever
adopted it would have been reaching for the brand and would not have got it. Delete rather than
correct, when nothing uses it.

**What legitimately stays mint:** the avatar tone rotation in `AvatarHelper` includes
`bg-teal-100 text-teal-800`. An avatar tone does not represent the brand - it tells two people apart,
which is the categorical use this document already sanctions - and changing the palette would change
the colour of everyone who hashes to it, breaking the promise that a person looks the same on every
screen.

**The token file has two different mints for one role** (`--sitf-secondary-chart2` and the legacy
`--sitf-secondary-teal: #00b8b0`), neither used anywhere. Pick one deliberately and delete the other
rather than grepping for whichever appears first.

### Modals: one shell, two of them

Both modals - the trading modal shell (`shared/_modal`, streamed into `#modal_frame`) and the CSV
import dialog - now agree on every part of the shell. They agreed on almost none of it:

| | Trading modal | Import dialog |
|---|---|---|
| Scrim | `bg-black/70` | `bg-slate-500/75` |
| Panel | `rounded-2xl shadow-2xl` | `rounded-lg shadow-xl` |
| Title | `h2 text-2xl font-bold`, centred | `h3 text-lg font-medium` |
| Close | `rounded-full`, inline SVG | `rounded-full`, inline SVG |

The shell is now: **`bg-black/50` scrim, a `rounded-2xl shadow-2xl` white panel, an `h2` title at
`text-base font-semibold` with an optional `text-sm slate-600` subtitle beneath, and a `rounded-lg`
44px close control carrying `lucide_icon("x")` and an `sr-only` name.** The title is the same token as
a card's, because a dialog is a titled surface like any other, and the title-plus-subtitle shape is
the one `_card` already uses. The close control keeps 44px: it is icon-only, which is the case the
44px figure is reserved for.

**Inputs inside a modal use the named classes.** The order form's field was `border-2
border-slate-500` at `text-lg` - a 2px border in a darker slate than the `slate-300` token, two steps
up the type scale from every other field - and its label was `text-black`. Both are
`tw-input-primary` / `tw-label-primary` now. `.tw-input-primary` was itself `rounded-md`, against the
`controls rounded-lg` token; only one view used it, which is how it drifted unnoticed.

**An error panel inside a modal is a panel, not an opacity tint.** The order form's was
`bg-sitf-danger/10` with a `sitf-danger/20` border - red-500 tinted by transparency, landing somewhere
off the scale - and its heading was an `h4` with no `h3` above it. It is `bg-red-50` /
`border-red-200` / `text-red-700` with a `<p>`, matching every other alert in the app.

**Measure modal contrast by painting a pixel.** `getComputedStyle` returns `oklch()` in this browser,
and reading its three numbers as RGB reports slate-600 on slate-50 as **1.05:1** - an audit written
that way invented five failures that did not exist. Set the colour as a canvas `fillStyle`, fill one
pixel, read it back. Canvas `fillStyle` also returns `oklch()` unchanged, so reading the property is
not enough. `test/system/modal_standards_test.rb` does this across the buy modal, its review step -
a second screen inside the same modal, easy to miss - and the import dialog.

### Form fields: one shape, one class

Every field in the app is `tw-input-primary` with a `tw-label-primary` label, `tw-input-error` when
invalid, `tw-field-hint` for the hint above it, and `FormErrorsHelper#field_error_message` for the
message below - a component with an icon in it, not a class. (`.tw-field-error` was that class; it was a
second definition of the message, red text with no icon, and it is gone.) Measured across the auth
pages, four admin forms, the grade book and the teacher forms: **1px border, 8px radius, 14px text,
44px tall, slate-300** - the only variation being a textarea's height, which is rows.

There were **seven** treatments before, for one control:

| Where | What |
|---|---|
| `Admin::FormBuilder` (9 forms; `Ui::FormBuilder` now) | `rounded-md`, border faked with `ring-1 ring-inset ring-gray-300`, `focus:ring-blue-600`, an `sm:` tier, **`placeholder:text-gray-400` at 2.54:1** |
| `grade_books/_grade_entry` | `rounded-md shadow-sm focus:border-indigo-500` |
| `students/new`, `students/edit` | `mt-1 shadow-xs border-slate-300 rounded-md` |
| `admin/shared/_search_filter` | two variants of `rounded-md border-0 ring-1 ring-inset` |
| `devise/sessions/new`, `passwords/new` | a duplicated `field_class` local |
| `devise/passwords/edit`, `registrations/edit` | no classes at all - the browser's default input |
| `tw-input-primary` | the token, used by one view |

**A named class with one caller drifts as surely as no class at all.** That is how the placeholder
failure survived: the class that fixed it existed, and its own comment said so, and the builder that
rendered nine forms never adopted it.

**Passing a class to a builder that prepends its own does nothing, and looks like it worked.** The
shadcn form builder prepended its own base (`h-10 rounded-md border-input`, ring focus). Given
`tw-input-primary` too, the field carried both - and **utilities beat component classes**, so the
shadcn ones won. Sign in and sign up, the two pages every user meets first, kept a 40px `rounded-md`
field while every other form moved. That builder and its helper are deleted; the four Devise views are
on `Ui::FormBuilder` like everything else, and all of them measure 44px at an 8px radius.
**Check the rendered element, not the
argument you passed.**

### A balance is a numeral on a plain surface, not a tinted panel with an illustration

The home page's "Earnings to invest" hero was `bg-gradient-to-r from-sitf-hero-from to-sitf-hero-to`
- `#f4d18d` to `#f8dba8`, a tan-gold - with a `piggy_bank.png` beside it. The trading floor showed the
same figure in a white card with `investment-funds.png`, at `h-[150px]` with the image pushed out of
the box by `style="height: 170px; margin-bottom: -8px"`. One number, two surfaces, two illustrations,
three arbitrary values.

Both are `.tw-card` now, with the figure carrying the emphasis and **design.md's icon tile** where the
illustration was: `size-9 rounded-xl bg-emerald-50` with a `piggy-bank` glyph at `emerald-700`.

**Why a plain surface.** Contrast was never the problem - slate-800 on that gold measures 10:1. It was
that the gradient was the only one in the app and the only use of those two tokens, so it belonged to
no system, and a page background that changes under one card is exactly the drift the single
`bg-slate-50` rule exists to prevent. Robinhood, Monzo, Revolut, Fidelity, Vanguard and Cash App all
show a balance as a large numeral on a plain surface. The money is the hero; the panel is not.

**Why an icon tile rather than a different illustration.** Finance apps put illustration in **empty
states and onboarding**, not next to a live figure, where it competes with the number and reads as
marketing. The tile is already this app's sanctioned pattern, is resolution-independent, and fixes
something no raster here could: `piggy_bank.png` was `hidden lg:block`, so on the 375px phones most of
these students use, the decoration did not exist at all. If an illustration is wanted, the place for
it is the **zero-balance state**, which is a real empty state - not the card that shows a number.

**Eight PNGs ship in `app/assets/images` and none is now referenced** (`piggy_bank`,
`investment-funds`, `party_popper`, `boy_using_computer`, `girl_skateboarding_holding_laptop`, and
`1_Number` through `4_Number`). Removing them is a call for whoever owns the brand assets, not a
cleanup to do quietly - see design-todo.

### The profile page, and where account actions live

There was no profile page: `resources :users` routed seven actions to a controller that had never
existed, and the only reachable substitute was Devise's `registrations#edit`, which demands the
current password before it will save anything.

**Two forms, because the two changes cost different things.** Setting a display name must not
require proving your password; changing a password must. GitHub, Stripe and Linear all split them,
and the merged version is the specific reason `registrations#edit` was unusable here — a student
who wanted a display name had to prove a password they may have just been given.

**The page's primary is "Save details"; the password submit is secondary.** One filled primary per
page, and a second card's submit is the sub-form case this document already names.

**Username is shown, not edited.** It is what a student signs in with and a teacher assigns it, so
it renders `readonly` rather than `disabled` — a disabled field is skipped by keyboard navigation,
which puts the value a student needs to remember out of reach.

**"Edit profile" sits above "Sign out" in the account menu**, which is the order GitHub, Google,
Stripe and Linear use: the destructive-ish action last. It is the one exception to that panel
holding no navigation — an account action about the identity the panel exists to show, and nowhere
else in the chrome would carry it.

**There is one account page, not two.** Devise's `registrations#edit` was the other, and it lost:
it cannot set a display name, and it demands the current password before saving one. `GET /users/edit`
redirects here.

**No self-service account deletion.** The button that offered it had never worked - `User` refuses a
hard delete - and a working version would have taken the student's portfolio and orders with it.
Deactivation is an adult's action, and admin already has it. This is the general shape: a destructive
control in a product where the data is a child's financial record belongs to the adult administering
it.

**A display name changes the avatar.** Initials and tone both derive from `display_name`, which now
prefers the `name` column — a column that had existed all along with nothing ever reading it.

### `dark:` is not inert, and there is no dark mode here

`.dark` is declared in `shadcn.css` and **nothing applies it** — no class toggle, no `data-theme`,
no `@custom-variant`. That made a `dark:text-slate-400` on the sign-up page look unreachable, and an
earlier contrast audit scored it as justified at "6.99:1 on dark".

**Tailwind v4 compiles `dark:` to `@media (prefers-color-scheme: dark)`**, which the compiled
stylesheet confirms:

```css
@media (prefers-color-scheme:dark){.dark\:text-slate-400{color:var(--color-slate-400)}
```

So on any device whose OS is set to dark, that paragraph rendered slate-400 over a background that
stays light — **2.45:1**, a straight AA failure, for a group nobody had looked at. A variant is not
dead because the app has no theme switch; it is dead when no media query or class can trigger it.
Until dark mode is actually built, `dark:` does not belong in this app, and there are now none.

### Auth pages are one pair

Sign in and sign up drift because they are built separately. Sign up had no logo, no page title, a
`min-h-screen` wrapper inside a `<main>` that already sits below a 64px header, its own field
spacing, and a description reading "Enter your email below to create an account" — for a form that
asks for a **username**, on an app whose `authentication_keys` is `[:username]` and whose students
may have no email at all.

**A standalone link in an auth form is `.tw-link-tap`.** It carries the 44px height design.md
reserves for bare tap targets and is underlined at rest — `.tw-link` drops the rest-state underline
so a table dense with links is not a field of rules, and a lone link in a form is the opposite case.
Sign in had built that inline as a five-utility local while sign up used `tw-link text-sm`, so the
one link the two pages share looked different on each.

### One destination, one button — and the page header wins

Two buttons pointing at one path is the same fault as two labels for one path, from the other side.
`button_copy_test.rb` asserts it, and it found two cases:

- **`stocks#show` had "Back to trading floor" beside a primary "Trade"**, both going to
  `stocks_path`, because a stock's own page had no way to act on that stock. The page renders the
  trading floor's own `stocks/_trade_actions` now, behind the same `show_trading_link?` gate, so
  Buy and Sell open the order modal for *this* stock and the back link is the only navigation.
  One definition of the product's core transaction, rendered in three places.
- **`portfolios#show` offered `stocks_path` from the header *and* from the holdings empty state.**
  This document had already recorded that pair as a bug and the fix had only demoted the second one
  to secondary, leaving both.

**An empty state explains; the page header acts.** An empty state carries no filled primary, and where
one exists on the page the empty state carries no action at all. Reported, and the count made the case:
four admin indexes and the classroom roster rendered "New teacher" / "New student" / "New classroom"
*inside* the empty state while the page header carried the same label to the same path.

This reverses what this document said, so the reasoning is worth keeping. Polaris and Stripe do the
opposite -- the empty state owns the action and the header suppresses its own -- and that was the rule
here, applied on `portfolios#show` and nowhere else, which is how the five duplicates survived. Two things
decided it the other way:

- **The header is the one position that does not change.** A control that lives in the empty state moves
  to the header the moment the first record lands, on a state transition the reader did not choose and may
  not have caused. A button in the same place at every count is learnable; one that migrates is not.
- **Suppressing the header made the empty case the *only* case with no header action**, which on
  `portfolios#show` meant a student with no holdings -- the exact reader who needs the trading floor -- had
  their route removed the moment the empty state's own button went. The suppression was load-bearing for a
  pattern we no longer use.

So `portfolios#show` renders "Invest now" whatever the table holds, and the empty state under it says what
a first purchase is like and nothing else. `empty_state_preview_test` walks eight indexes and fails on any
`.tw-btn-primary` inside a `[data-testid='empty-state']`.

A **section**-level control is not covered by this: the grade book's "Add new students" sits on its
section's header line, which is where a section's action belongs, and it is a secondary. What went there
was the second, filled copy of it inside the empty state.

**A detail page's primary action acts on the thing it is showing.** A primary that navigates to the
list is not an action, and it is a strong signal that the page is missing one.

### Button copy: three words, verb first, one label per destination

**A button label is a verb-first phrase of at most three words.** `button_copy_test.rb` asserts it
on the rendered page, exempting `Back to …` -- a back link naming its destination is worth the fourth
word. It also exempted `Add the first …`, "an empty state's first-run CTA", and that exemption is gone
with the button it described.

**One destination gets one label.** `stocks_path` was reached by six:

| Label | Where | Now |
|---|---|---|
| "Go to the trading floor" | home header | **"Invest now"** |
| "Invest now" | portfolio header, trading-floor card | unchanged — this is the label |
| "See the companies" | portfolio empty state | **"Browse companies"** |
| "Trade" | holdings row action | unchanged |
| "Trade stock" | stock detail | **"Trade"** |
| "Back to stocks" | stock detail | **"Back to trading floor"** |

Two distinct intents survive on purpose, which is what Fidelity and Schwab also ship: **"Invest
now"** is *put money to work* (from a balance), **"Trade"** is *act on this holding* (from a row or
a stock). What is not allowed is a third phrasing for either.

**Name a place the way the place names itself.** The destination's own h1 and its nav item both say
"Trading floor"; a back link calling it "stocks" and a CTA calling it "the trading floor" made one
page three places.

**Verbs are fixed: View, Edit, Delete, Add, New.** `View` (not `Show`) — "Show this classroom"
became "View classroom", losing a demonstrative no other label has. **`New X` creates a record in
a collection; `Add X` attaches one to the parent you are looking at** ("Add student" on a
classroom, "Add transaction" on a portfolio). That distinction is Polaris's and it already held
here; it is written down now so it survives.

**A noun is not a label.** "Template" became "Download template", "All transactions" became "View
all" (its card is already titled "Recent transactions", so the noun was said twice).

**Devise ships its own dialect and it has to be translated.** "Log in" against ten "Sign in"s,
"Send me reset password instructions" (five words), and "my" in "Change my password" where every
other label is a bare imperative. Worst was **"Cancel my account"**, which permanently deletes it,
while "Cancel" on every other button in this app means *dismiss* — it is "Delete account".

### Buying power is a figure, not a card — and it belongs in the order ticket

The trading floor put the whole "My earnings to invest" card, a **217x114** bordered `.tw-card`, in
the header row beside the h1. Measured:

| | Header row | First table row | Rows visible |
|---|---|---|---|
| 1366x768 (625px usable) | 130px | 296px | 5 of 7 |
| 375x812 (669px usable) | 178px | 344px | **2 of 7** |

A page whose whole purpose is a list of things to buy opened with the list half off screen.

**No brokerage puts buying power in a card above the instrument list.** Fidelity, Schwab, E*Trade and
Vanguard all render "cash available to trade" as a compact labelled figure in a summary strip;
Robinhood keeps it off the list entirely, because it belongs where the decision is made — the order
ticket. This app already does that: the order modal shows the fee, the total and the balance
afterwards. So the figure stays, since a student choosing what to buy wants their budget in view
while scanning, but as **a two-line figure on the header's baseline**: `text-xs` label over a
`text-base font-semibold tabular-nums` value, in `_page_header`'s actions slot. Header 130px -> 40px,
first row 296px -> 206px.

**Whatever goes in a page header's action slot has to be action-sized.** That slot is
`flex items-center gap-2` and every other page puts 40px controls in it. A card there does not
misalign because of a class; it misaligns because it is three times the height of the thing the row
was built to hold.

### Retention here is a display rule, and it has to be

`stocks.archived_at` records when a company was archived; nothing did before, so the trading floor
could say a company had closed but never since when.

**Nothing deletes an archived stock and nothing should.** `orders.stock_id` and
`portfolio_stocks.stock_id` are both `NOT NULL` with foreign keys, and both associations are
`dependent: :restrict_with_error`. A stock a student has ever traded cannot be removed without
destroying that student's trade history — which in this product is a child's record of what they
learned. So there is no purge, and the rule is about the **list**:

- `Stock::LIST_RETENTION` is **12 months**, and `Stock.archived_recently` is what the trading floor
  lists. A school year is the unit this app already thinks in — a classroom belongs to one, grade
  books hang off its quarters — so "last year's companies" is a boundary a teacher recognises.
- **A stock you hold is exempt.** It stays listed however long ago it closed, because the only action
  the data supports on an archived stock is selling one you own, and a retention rule that hides a
  position would strand it.
- **A missing `archived_at` counts as in-window.** Rows from before the column existed were
  deliberately not backfilled: `updated_at` is not the archive date (the price job touches it), and
  inventing a date in a trading record is worse than admitting it is unknown. Treating NULL as old
  would silently hide rows the app shows today.

**The window is interpolated into the copy, not written out.** The sentence reads "they stay listed
for `#{Stock::LIST_RETENTION.inspect}`", so it cannot end up claiming one period while the scope
enforces another — the same two-places failure as a token defined twice.

**`archived` stays the flag and `archived_at` is derived from it**, maintained by one `before_save`.
Making the timestamp authoritative (Discard-style) is the tidier single source of truth and is noted
in `migration.md` as the shape to move to; it would touch both scopes, the policy, the admin form,
the seeds and every test that sets `archived:`. Two columns for one fact is a drift risk either way,
so the invariant lives in one method and is pinned by `stock_archiving_test.rb`: stamped on archive,
cleared on un-archive, and **not moved by a resave** — the price job writes these rows constantly and
must not drag the archive date forward.

### `<main>` owns the gutter — and one branch of it did not

**Correction to the rhythm section above.** It said pages were adding padding "on top of `main`'s
`p-4 lg:p-6`". That was true of the signed-out branch and of admin's inner wrapper, and **false of the
signed-in branch**, which was:

```erb
<main class="min-h-screen px-4 lg:px-6 ml-0 lg:ml-64 mt-16 pb-6">
```

Sides and bottom, and **no `padding-top`**. `mt-16` clears the fixed 64px nav; it is not padding, and
reading the class list quickly it looks like the top is handled. So when the sweep removed the
per-page `py-6` / `pt-4`, every signed-in page's title ended up flush against the nav bar. Measured:
home **0px**, portfolio **0px**, trading floor 8px (its own header's `items-end`), orders 24px because
it still had its own `pt-6`.

`main` is `p-4 lg:p-6` on all four sides now, in all three places, and two pages lost the `pt-6` that
would have doubled it. `spacing_test.rb` asserts the gutter above the content block on several pages
at both widths, so a layout that stops providing it fails there.

**Three copies of one element is the same fault as two copies of one class.** The signed-in `<main>`,
the signed-out `<main>` and admin's `<main> > div` all set the page gutter, and they disagreed. If
they ever need to differ, the difference should be a documented reason rather than a divergence.

### A partial rendered into `space-y-*` needs a single root

`space-y-6` compiles to `> :not([hidden]) ~ :not([hidden]) { margin-top: 1.5rem }`, which is more
specific than a plain `mt-1` or `mt-3`. So **every top-level element a partial emits becomes a spaced
sibling of the others.**

`_stocks_table` emitted three — the `<h2>`, the line explaining it, and the table — into the trading
floor's `space-y-6`. The markup said 4px and 12px; all three rendered **24px** apart, and the section
read as three unrelated things. Wrapping the partial in one `<section>` fixed it without touching a
single spacing class.

This is the class-names-lie rule in its purest form: nothing in `_stocks_table` was wrong, and nothing
in `stocks/index` was wrong. The bug only existed in the relationship, and only the rendered box shows
it. `spacing_test.rb` pins the two gaps.

**Where two roots are correct, keep them.** `_archived_stocks` deliberately emits the held-stock table
and the disclosure as siblings, because 24px between them *is* the section rhythm.

### A table says what it is for

Neither table on the trading floor explained itself. A reader had "Active stocks" and "Archived
stocks" and no way to know that one is buyable and the other is not, or why a company they remember
had moved. `_stocks_table` takes a `description:` and both use it:

| Table | Says |
|---|---|
| Active stocks | Companies you can buy shares in right now. Prices update every school day. |
| Archived stocks you hold | You still own shares in these. They cannot be bought any more, but you can sell whenever you like. |
| Archived stocks (N) | These companies have stopped trading here, so they cannot be bought. They stay listed for 12 months after they close, and a company you own shares in stays until you sell it. |

The empty states already worked this way — say what appears here and what to do about it — and a
*populated* table deserves the same courtesy. "Prices update every school day" is accurate rather
than reassuring: `config/recurring.yml` runs `StockPricesUpdateJob` Monday to Friday.

**Explanatory copy costs vertical space, and that is a trade to state rather than hide.** Taking the
earnings card out of the header moved the first table row from 296px to 206px on a 625px viewport;
these two description lines give 56px of that back, to 262px. Worth it — the previous 296px bought
nothing but a duplicated balance.

### An archived list earns its place only where it is actionable

The archived stocks table was every archived stock, in a table identical to the active one, with no
date, no explanation, and an **empty actions column** — because `StockPolicy#show_trading_link?`
withholds trading on an archived stock unless the viewer holds it. For almost every reader it was a
price list of things they cannot buy, under the list of things they can.

**The one thing the data supports is selling a position you already hold.** So:

- **Archived stocks you hold** render as a normal titled table, with Sell (and Buy withheld, which
  the policy already did).
- **Everything else** goes behind a native `<details>` — "Archived stocks (N)" — so it costs no
  vertical space until asked for. A teacher is not an admin and has no other view of archived
  stocks, so hiding it outright would remove their only access.
- **Every archived row says why it is there**: "No longer trading", plus "last priced <date>" when
  `last_trading_day` is set. There is no `archived_at` column — `archived` is a bare boolean — and
  `last_trading_day` is the more useful figure anyway, because it says when the price was last real.

**Nothing purges them and nothing can, yet.** No job deletes or ages archived stocks, and with no
`archived_at` there is no date to age them against, so the list only grows. That needs a column
before it can need a policy — recorded in `design-todo`.

### A figure card with an icon is `_stat`, not a second copy of it

`portfolios#show` put two cards side by side in one grid row with their tiles on **opposite sides** —
`money_at_work` on the left, `best_month` hung off the right in an `items-start justify-between` row.
That is the mirror-image version of the icon-gutter mistake, and it read as two unrelated components.

`best_month` was a `_stat` written out again: its label, figure and hint carried the *same tokens*
as the four KPI cards above it, plus a tile. `_stat` takes `icon:` / `icon_tone:` now and
`best_month` renders it, so the tile is on the label's line by construction and the card cannot
drift from its four neighbours.

**Measured, three seams for one gap.** The space under a label carrying a tile was 4px in `_stat`,
8px on the home page's balance card and 12px in `money_at_work`. The rule is what sits above it: a
32px tile row gets **8px**, a bare 20px label line gets **4px**. Class names would not have shown
this — all three read as "a margin under the label".

| | Before | After |
|---|---|---|
| tile side | left / **right** | left, both |
| tile size | 36px / 36px, vs 32px on home | 32px everywhere beside a label |
| label | `font-semibold text-slate-900` / `font-medium text-slate-600` | `font-medium text-slate-600` |
| gap under the label | 12px / 4px, vs 8px on home | 8px |

`icon_tile_test.rb` asserts every card tile sits at the left padding edge at 32px, so a tile on the
right fails rather than shipping.

### A card's leading icon goes on the title's line, and a numeral is a tile

This document had already ruled on both of these, and both were rediscovered on the home page.

**The icon belongs on the title's line, never in a column beside the whole card.** `_card` takes
`icon:` and `icon_tone:` and renders a 32px tile in the header row. An `items-start` icon column
indents *every* body line behind it, so the content hangs off the icon instead of the card edge:

| Card | Body indent before | After |
|---|---|---|
| Earnings to invest (home) | **77px** | flush |
| My earnings to invest (trading floor) | 61px | flush |
| a card with a leading icon | ~48px | 0 |

The home figure is the worst case, because the indented line was the cash balance — the one number
a student opens the app to read. `icon_tile_test.rb` asserts the balance sits at the card's padding
edge on both pages.

**A numeral is a tile, not a filled disc.** The getting-started steps were white numerals on
`bg-sitf-primary` at `rounded-full` — four saturated brand discs shouting over the copy they label,
against this document's own rule that the tile carries the hue and **a numeral is always
`slate-900`**. `_icon_tile` takes `label:` for this, so a step number is the tile pattern with a
digit in it, at `rounded-xl` and 16.28:1.

**A numbered sequence needs an unambiguous reading order.** The four steps were a 2x2 grid, where
1,2 reads across and 1,3 reads down and nothing in the layout says which. Four short columns at
`lg` read left to right the way the numerals claim, and stack to one column at 375px. This is the
shape Stripe and Shopify use for "how it works", and neither draws connectors between them —
which also avoids a decoration that only makes sense at one width.

**A card header may lead with a tile where the card is one of several sibling sections** and the
icon helps a reader find the one they want — the home page's three sections do. It is not for every
card; a card whose title is already unambiguous in context does not need one.

### Spacing rhythm: 24px, and the container owns it

**Sections and cards separate by 24px** — `space-y-6`, `gap-6`, `mb-6`. Nothing in the app was
literally off Tailwind's 4px scale; what was wrong is that twenty-two places used 32px or 64px
instead, which is not a second rhythm so much as no rhythm:

| Was | Where |
|---|---|
| `mb-8`, `my-8` ×20 | the component gallery — the one page that is supposed to *demonstrate* the system |
| `gap-8` | `classrooms#show`'s two panes, `stocks#show`'s detail grid |
| `space-y-8` | the trading floor's sections |
| `mt-8` | the roster and the grade book list, each carrying its own top margin |
| `p-8` | the announcement body, the only 32px card body in the app |
| `pb-16` | home and `announcements#show`, on top of `main`'s `pb-6` |
| `px-6 lg:px-8` | both auth pages, on top of `main`'s own padding (see the correction below) |

**The container owns spacing, not the child.** The roster and the grade book list each set `mt-8`,
so they agreed with each other and with nothing else — the flex row they sit in already spaces them.
`pb-16` and `px-6 lg:px-8` are the same mistake as the 48px content gutter: a page adding padding the
layout already provides. Measured after, sign-in sits **16px** from each edge at 375px rather than
40px, and the gap between top-level sections is **24px** on every page.

**Half-steps are fine where a token names them.** `px-2.5 py-1` is the badge, `gap-1.5` the ghost
and the badge, `mt-0.5` the checkbox nudge, `lg:py-1.5` the nav row. What is not fine is a half-step
nobody named: a `gap-0.5` on a two-line table stack that two other tables render with no gap.

**32px and up is a measurement of something else on screen, or it is nothing.** What survives:
`mt-16` / `pt-16` clearing the 64px fixed header, `lg:ml-64` / `lg:pl-64` clearing the 256px sidebar,
`py-12` on the page-level empty state and the vertically centred auth pages, `py-10` in
`.table-empty-cell`, and two `pr-10`s reserving room for a modal close button and a select's arrow.

**An icon inside an input sits on the input's own padding.** `.tw-input-primary` is `px-3`, so a
leading icon goes at `left-3` with the field at `pl-10` — 12px, a 16px glyph, 12px. The search field
had the icon at `pl-5` and the field at `pl-14`, so its glyph and its text both sat on a margin no
other input used. Stripe, Primer and Tailwind UI all draw it at 12/16/12.

### No gradients, and arbitrary values only where the scale has no answer

**There are no gradients.** The one that existed - the home hero's `from-sitf-hero-from
to-sitf-hero-to` - was the app's only one, and those two tokens had a single caller between them. A
gradient is a surface that belongs to no system while every other surface is white, `slate-50`, or a
named tint.

**Arbitrary values are these four and no others**, because the scale has no answer for them:

| Value | Why |
|---|---|
| `[&::-webkit-details-marker]:hidden` | No utility addresses a vendor pseudo-element |
| `after:content-['']` | An `::after` needs content to exist; this is the toggle knob |
| `border-l-[3px]` | Tailwind's border widths are 0/1/2/4/8; the nav indicator is 3px by design |
| `h-[calc(100vh-4rem)]` | The sidebar fills the viewport under the 64px header |

Everything else had a scale value waiting: **300px is `h-75`, 400px is `w-100`, 480px is `max-h-120`,
80px is `min-h-20`, 36px is `min-h-9`.** Tailwind v4 generates any multiple of the 4px spacing scale,
so a round pixel figure almost never needs brackets - verified each one appears in the compiled CSS.

**An inline `style` attribute is the same problem wearing a different hat**, and worse, because a
sweep for arbitrary *classes* will not find it. Four of the five conversions above were inline styles.
The one that was hardest to see was a partial local **named `style`** that actually held a button
class - it matched every grep for an inline style and was none of them. It is `button_class` now.

`test/design_system/no_arbitrary_values_test.rb` checks all three against the source, since none of
this is a rendering bug and no browser test would notice. It strips whole comment blocks, not
comment-leading lines: these comments quote the code they replaced, and a line-based filter reports
the documentation as the offence.

### Badges
**One component: `components/ui/_badge`**, matching the Status pill base above:
`inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-medium`, with a tone:
`:neutral :success :warning :danger :info :brand`. Every tone is a dark foreground on a light
tint, so all clear AA, and the label always states the status so meaning is never colour-alone.

**No ring and no border.** The component carried `ring-1 ring-inset` with a per-tone ring
colour, which this spec does not specify — and because fourteen hand-rolled badges were swept
onto it, that unspecified stroke landed on every badge in the app. **Aligning things onto a
component is only alignment if the component itself matches the spec.** Check the component
against the written rule before making it the baseline, or the sweep just standardises the drift.

**Tone names follow this document**, so emerald and rose rather than green and red. Measured on
their own tints: emerald 5.21:1, rose 5.72:1, slate 6.92:1, amber 4.84:1, blue 6.16:1, teal
5.25:1. Neutral is `slate-600`, not slate-500, for the reason recorded above.

**A badge is chrome, so it is `text-xs` and about 20px tall.** That is where Polaris badges,
Primer labels, Atlassian lozenges and Tailwind UI badges all sit. The order status pill in the
transactions table was `h-9 px-4 py-2` with `text-[14px]` and `rounded-[16px]` — 36px tall,
button-sized, and made of arbitrary values that bypass the tokens, including a `leading-[0]` that
means nothing. It was Figma-export markup that had been pasted in and never revisited.

The component existed and was used **once** in the whole app; fourteen other places hand-rolled a
badge in eight different treatments. It is now used everywhere, including `boolean_badge`.

**Do not assert exact hues in tests.** Three helper tests pinned `bg-green-100`, which meant the
helper could not move onto the component — whose success tone is the lighter `bg-green-50` with a
ring — without failing for no behavioural reason. Assert the tone family and the scale.

### Content gutter and width

**The layout owns the gutter. A page never adds its own horizontal padding.** `main` carries
`px-4 lg:px-6`, so the gap between the sidebar and the content is **24px** at `lg` and 16px below
it, on both sides of the product.

Measured before the fix: **admin 24px, app 48px**, because the app's `main` had `lg:px-6` *and*
five page wrappers added `px-4 lg:px-6` of their own on top. Home was **53px**, where a narrower
`max-w-5xl` let `mx-auto` centre the column and widen the gap further.

24px sits in the middle of the field - Material and Stripe 24, GitHub 24-32, Tailwind UI's
dashboard shell 32, Polaris 16-20. It was chosen because admin already rendered it, so the app
converges on admin rather than both moving, and because the report was that the gap was too large.

The page-rhythm entry above used to prescribe `px-4 py-6 sm:px-6 lg:px-8` -- 32px, via an `sm:`
tier this app does not use, applied *on the page* rather than the layout. That is inherited CASA
prose and it is the reason five app pages double-padded themselves to 48px. It now reads `py-6`,
vertical only. **A rule that contradicts the shipped layout will be followed by someone**, so the
fix is to correct the rule, not to annotate it as a deviation.

**The chrome shares the content's gutter, and an icon control aligns by its glyph.** The app bar
carries `px-4 lg:px-6`, the same as `main`, so the header's contents and the cards below sit on one
edge. As `px-6` at every width the header sat 24px in against content at 16px on a phone - and
because a 44px hit area centres a 24px icon, the hamburger *glyph* landed at 34px. Three numbers for
one edge.

### Icon controls on a gutter: the box that paints is the box that aligns

A 44px touch target centring a 24px glyph puts the glyph 10px inside its own box. So an icon button
sitting on a 16px gutter shows its glyph at 26px, and the chrome looks further in than the content
below it. **Leave it there.** The control's box is what the eye reads and what paints on hover, so the
box is what aligns to the gutter - flush with the cards, no negative margin. That is what GitHub
Primer and Shopify Polaris ship for a leading icon button, and it is the rule here.

The tempting alternative is an *optical* inset - pull the target out so the glyph lands on the gutter,
as Tailwind UI's shell does with `-m-2.5 p-2.5`. **It failed here three times, and each failure was
the same mistake:** a negative margin drags whatever paints along with it.

1. The trigger was a filled teal button, so pulling it out put a solid fill 6px from the viewport
   edge.
2. Making it borderless was not enough: it still had a `hover:` background, so at rest it looked
   right and on hover a 44px fill appeared 6px from the edge. **"Paints nothing" has to hold in every
   state.**
3. Splitting the target from a 40px `rounded-full` state layer put the paint at 8px instead of 6px -
   still short of the 16px the content uses. Closer is not aligned.

Tailwind UI's inset works because its trigger has **no hover surface at all**. Ours does. If a control
paints anything, in any state, align its box.

**The radius is `rounded-lg`.** The token at the top of this document is `controls rounded-lg`, and
the trigger was already on it. `rounded-full` was introduced with an aesthetic argument - that a
circle's mass sits at its centre so it reads as clearing the edge - which is an argument for
overriding an explicit token, made on a turn whose instruction was to follow the token. Where this
document names a value, that is the value; the field is the tiebreak only where it is silent.

Measured on both sides at 375px: the trigger's box at **16px** with a 44px target and an 8px radius,
its glyph at 26px, the account control's box **16px** from the right on the same radius, and cards at
16px left and right. At `lg` the sidebar owns the left and the account control shares the content's
24px trailing edge. No negative margins anywhere in the chrome.

**Do not assert any of this with a colour.** The first version of the test checked the trigger's
resting `backgroundColor`, which is transparent whether or not the bug is present - and Tailwind emits
`hover:` inside `@media (hover:hover)`, which the headless Chromium never matches, so a hover fill is
unobservable here. Assert the box's **position, radius and margin**.

**`<main>` is not its own scroll container.** It carried `overflow-auto`, which put its scrollbar
inside the padding box, so the right gutter measured ~15px wider than the left on any page tall
enough to scroll. Admin never had it. Measured after, below `lg`: hamburger glyph, page title, card
left and card right all 16px, and the account chevron 16px from the right.

`test/system/chrome_gutter_test.rb` asserts one gutter across both halves, and that both navigation
triggers have the same fill.

**Content width is `max-w-7xl`, and the layout owns it.** `max-w-[1180px]` was an arbitrary value the
token rules rule out, and home's `max-w-5xl` was narrow enough that `mx-auto` centred it and changed
the gutter on one page only.

Both layouts now put one `mx-auto max-w-7xl` around the flash **and** the yield, rather than leaving
each page to declare its own. A per-page column cannot include the flash, and a flash outside it is
the wrong width by definition: `layouts/_flash` was a bare child of `<main>`, so at 1920px the
"Signed in successfully" banner measured **1601px against cards of 1280px** - 321px wider, starting
161px to their left - and admin measured 1616px against 1280px. Nothing showed below about 1584px,
which is where main's content box stops exceeding `max-w-7xl`, so every test width the suite had
(1400, 1366, 375) measured a perfect match.

Constraining the flash alone would have inverted it: the trading floor, orders, classrooms and
classroom#show declared no column at all and spanned the full 1601px, so a 1280px banner would have
been the narrow thing on those four. Those pages are now in the column like the rest, which is what
this rule always said and what they were drifting from - they are **narrower above 1584px than they
were**, and that is the intended half of the change rather than a side effect.

The per-page `mx-auto max-w-7xl` wrappers still in the views are now redundant - a `max-w-7xl` inside
an equal-width parent is a no-op - and are left in place rather than swept across 39 call sites.

`test/system/flash_width_test.rb` measures the banner against the page below it at 1920px, on both
halves, because 1366px cannot see this class of bug.

`spacing_test` asserts the gutter matches on both sides.

### An entity detail page, and a setting on one

**Related collections stack full width. They are never side by side.** `classrooms#show` put the roster
and the grade books in a `lg:flex-row`, which at 1366px gave one 765px and the other 256px. That is the
shape Polaris calls a secondary column, and Polaris reserves it for **metadata** - status, tags,
organisation - not for a second collection. Stripe's customer page (payments, then subscriptions, then
invoices), GitHub's repository page and Linear's project page all stack an entity's collections at the
full column width and let the **order** say which is primary, rather than the widths. Stacked, the
roster went from 765px to 1045px and the grade books from a 256px rail to four cards that can show a
quarter's status - which the rail had no room for, so a teacher opened all four to find the one they
wanted.

Each collection is a `<section>` with an `<h2>` and `aria-labelledby`, in the page's `space-y-6`.

**A setting is not a page action, and its state must be readable as text.** The trading switch was a
bare 36x20 track labelled "Trading" in the header's action area, beside "Add student" and "Edit
classroom" - so the one control on the page that changes what students can do sat among the navigation,
its state was carried by the track's colour, and nothing said what it did. Three separate faults, and
the reported symptom was "the trading toggle makes no sense".

Polaris's `SettingToggle` is the reference for the *content* - state in words, then what it means - but
not for the wrapper, and getting that wrong took two attempts worth recording.

**A status pill never sits inline before body text**, and it was doing exactly that: a pill reading
"Trading off" to the left of the sentence "Students cannot buy or sell." Polaris, Primer and Carbon all
place a pill against a **title** or on its own line; none uses one as a sentence prefix. It was also the
third copy of one fact - pill, sentence, and the switch's own position all said on or off - so it went.
The sentence is the better of the three because it can carry the consequence in the same breath.

**A switch is labelled with the noun, never a verb.** The label was "Turn on" / "Turn off", on
`SettingToggle` reasoning - but Polaris puts that verb on a **button**, and a switch's position *is* its
state. "Turn on" beside a pill reading "Trading off" gave a reader two things to reconcile. iOS, Material
and Polaris all pair a noun with a switch. It is "Trading".

**And the setting does not get a card of its own.** It sits on the line under the Students heading, which
is where a section's control goes - Polaris's card header action, Primer's `Subhead`, Stripe's list
sections - with the sentence beside it. That is what makes the pill unnecessary and what took the page
from **six card surfaces to two**.

### A breadcrumb trail needs somewhere to go back to

Every admin index rendered **"Dashboard > Classrooms"** immediately above an `h1` reading "Classrooms" - the
page's own name twice, 30px apart - and the trail's only link duplicated the sidebar's own Dashboard item.
Reported as pushing the content down for no value, and measured at exactly that: 44px, taking the h1 from
y=128 to y=172 in a 768px viewport.

`admin/shared/_breadcrumbs` returns early below two crumbs, so the rule holds wherever the trail is rendered
rather than at nine call sites. A record page keeps its trail - "Dashboard > Students > Sam Student" has a
Students to click - and so does a create page.

The field is unanimous: Carbon states it outright ("do not use breadcrumbs when there is only one level"),
GOV.UK's breadcrumbs show the path *above* the current page so a top-level page has none, and Polaris has no
trail at all, only a single back action on pages with a parent.

### A record's page edits in place

**There is no separate edit page.** Stripe's customer page, Linear's project page, Shopify admin's product
page and Polaris's resource detail pages all hold a record's attributes *and* its related collections on one
screen, edited where they are shown. A separate `/edit` screen is a Rails scaffold convention; it earns its
place for a long form, not for a record with a handful of fields. Nine admin resources were three pages each
- a show page listing attributes, an edit page holding the form, a create page in a third width - and the
show page's cards were, in six cases out of nine, the form's own fields rendered again where they could not
be changed.

`/admin/<thing>/:id/edit` still resolves and renders the record page, so every existing link and redirect
keeps working.

**The shape, declared once in `admin/shared/_record_page` and `_record_section`:** `mx-auto max-w-3xl`,
breadcrumbs, the page header carrying the record's own name as its `h1`, then `space-y-6` sections. Each
section is a `<section aria-labelledby>` with an `h2`, an optional hint line, and its content 12px below -
one card per section, and **no card headers**, because the section heading has just named it. Before this the
same three pages measured 1047px, 768px and 1062px wide, with headings on four levels.

**What goes where is a three-way decision, and it is the whole simplification:**

- an attribute **the form edits** appears once, as a field. Not as a field *and* a read-only row.
- a collection **worth scanning or acting on** gets a section of its own.
- a lone **read-only fact** goes on the header's summary line - `classroom_summary`, `teacher_summary`,
  `student_summary`, `stock_price_summary`, one helper per resource. A student's cash balance and total
  value were two of four `text-2xl` tiles in a figure band; the third held the portfolio's **id**.

**An id, a timestamp and an invariant get nothing.** A "Record" card holding an id and two timestamps was
160px of a page for facts nobody acts on, and the id is in the URL. A school year always has exactly four
quarters, so listing them rendered an invariant as data; the count is in the summary line.

**Order follows what the page is for.** A collection leads where the collection is the point - the school
page's years, which are why anybody opens it - and Details leads where the editing is the point, as on a
student, a teacher or a stock. Read-only sections come last. State it per page in a comment; it is not a
fixed order, and the pages that get it wrong are the ones where nobody asked the question.

**The save row appears when there is something to save.** `.tw-form-actions` is hidden on an **update** form
until a field changes, then sticks to the bottom of the viewport - Polaris's ContextualSaveBar, and the
reason a page you are only reading has no button offering to save it. Three details are load-bearing:

- a **create** form's row is always visible: there is nothing saved to compare against, and its submit is
  the only way to do anything at all.
- a form that has just been **rejected** keeps its row, per form. It is not clean - its values were
  submitted and refused - and hiding it left an error summary on screen with no way to try again.
- no rule above it. A `border-t` there was one commit old and lost to the Dividers rule; the row sits on the
  page background below the card, primary first, aligned to the card's leading edge.

**A record page's length is bounded, and one section is where it stops being.** The student record measured
2958px - 3.9 viewports at 1366x768 - and half of it was two blocks: a 728px form held permanently open for an
occasional task, and every transaction the portfolio had. The second is the one that matters, because it has
no ceiling: 13 rows measured 739px, and a year of weekly trading is about 150 rows, which is 7,400px. Two
rules follow, and both are what the field does:

- **A collection on a record page shows the first few and links to the rest.** Five here, with "Showing 5 of
  13" and a link to the full list - which means the full list has to *exist* and be filterable, or truncation
  just hides rows. Stripe's customer page truncates its payments the same way; `admin/classrooms#show`
  already truncates its roster, and had nowhere to send you.
- **An occasional write is a control you open, not a form you scroll past.** The money form is a `<details>`
  inside the Transactions section, closed until asked for: Stripe's "Adjust balance" is a button for the same
  reason. Measured after both: 1914px, 2.5 viewports, and opening the form adds 720px only for the person
  who wanted it.

**A section heading is a noun and its control is a verb.** This is why there is no section called "Add a
transaction" containing a button of the same name: the collection is the subject, and the form is what you do
to it. The heading names what you are looking at, the control names what happens next.

**Use `<details>` for a disclosure, not a hidden div and a controller.** `dropdown_controller` already
records the reason - without JavaScript a native disclosure still opens and closes - and there is a second
one that matters more here: a rejected submit re-renders the page, and the panel has to come back **open**
with the values in it. With `<details>` that is one server-rendered attribute; with a JS panel it is state to
rebuild. Set it with `tag.details(open: record.errors.any?)`, never by interpolating the attribute, which
renders it unquoted and unmatched by any selector.

**A create page does not draw its section heading.** A record page has four sections and "Details" says
which one you are in; a create page has one, so the heading repeats the h1 a line above it and its hint
("Saved when you press Create student") repeats the button. Measured on `students#new`: the card sat at y=304
with the subhead and y=244 without, so it cost **60px of the first viewport to say nothing**. It stays in the
markup as `sr-only`, so the section keeps its accessible name, and the content loses its `mt-3` with it -
12px of gap under an invisible heading is the "delete the rule, leave its padding" mistake this document
records three times. Polaris's rule for a page with one card, applied a level up.

**An index page describes itself only where there is something to say.** Six of the nine admin indexes have
nothing a reader cannot see - a table of students needs no sentence explaining that it lists students - and
the correction to a create page that said too little is not a description on every page. Three do have a
fact: `users` overlaps the students and teachers pages in the same sidebar, `stocks` mixes archived rows with
active ones and its prices are refreshed by a job, and `portfolio_transactions` is what every balance is
derived from. `admin_page_structure_test` asserts **both** halves, so "add one everywhere" fails as loudly as
"add none".

**An empty state under a filter is a different sentence.** With nothing archived, three indexes said "No
students yet" / "No teachers yet" / "No users yet" and offered a New button - on a tab that lists archived
records, with plenty of unarchived ones one tab away. Both halves were false, and it is the state most
installations are permanently in. `archived_empty_state` owns that sentence once -- four indexes render it
now, `classrooms` included; the empty state offers no action there, because creating a record would put
nothing in the list you are looking at. The page header's New button stays, since that action is always
available.

**And an empty state that cannot render is dead markup.** `admin/users` carried both branches and the
unfiltered one could not fire: the viewer is a `User` and is not archived, so the Active and All tabs always
hold at least the admin reading the page, and that index has neither search nor pagination to empty them. It
said "No users yet" and offered a New button for a state the app cannot be in. That one index renders the
archived sentence alone; every other keeps both branches, because a school or a stock list genuinely can be
empty. Same question as the column of dashes -- can this ever show, for this viewer, in this state?

**And they are photographed, because they cannot be seen any other way.** An empty state renders only when a
list is empty and every development database has data, so the screen a first-time admin meets is the one
nobody looks at. `empty_state_preview_test` builds each condition, asserts a title, a body of at least 30
characters and no "No X found", and with `PREVIEW=1` writes `public/preview/empty-*.png`. It found the
archived-tab defect above on its first run.

**An empty state's icon is the glyph of the thing that is missing** -- the same one its nav item and its
section use, so `graduation-cap` for students, `presentation` for classrooms, `receipt` for transactions,
`book-user` for teachers. Audited after the icon sweep and it was the same shape: **"No students yet"
carried three glyphs** (`graduation-cap` on the classroom roster, `users` on the grade book, the partial's
default `inbox` on the admin list), three more titles carried two, and **twelve of twenty were on the
default** -- so the fallback was doing most of the work and doing it inconsistently.

The two state tabs take the *state's* glyph rather than the record's, because that is what the tab is about:
`user-x` for deactivated people, `archive` for archived things.

`inbox` survives as the partial's default and has exactly one caller: the gallery's generic "Nothing to
show", which demonstrates the component with no concept behind it. `icon_vocabulary_test` fails on any title
with two glyphs, and on any empty state falling through to the default.

**An empty state body is two sentences: what the thing is, then what will appear here.** Set by a reader on
the archived students list -- *"Archiving a student is reversible and keeps their history and records intact.
Archived students appear here."* -- and it is the second sentence that was missing. Half of them explained
the record type and stopped, so a reader learned what a classroom *is* and not that adding one would fill
this list; the other half said only "they appear here", with a pronoun for a noun that was not in the
sentence.

`archived_empty_state` takes **what archiving keeps** per noun, because "keeps everything attached to it" was
the generic that made the sentence say nothing. A student keeps their history and records, a teacher their
classrooms, a classroom its grade books -- naming them is the difference between a reassurance and a promise
a reader can check. It also fixes the article by **sound**: a first-letter test produced "an user".

One body keeps a different first sentence, deliberately: the student's own holdings empty state leads with
an invitation to buy rather than a definition, which this document already argues for. It gained the second
sentence rather than losing the first.

**An empty state is the only content on the page at the moment it shows**, so it says what the thing is or how
rows arrive: "A school year holds the quarters that earnings are calculated against", "Add students one at a
time, or import a whole classroom from a CSV". Two got this wrong in a way worth naming - one named a
transaction type the app never writes ("withdrawals when a student trades"; trading writes a **debit** or a
**credit**, and nothing in the app creates a withdrawal outside the admin form), and two spelled *finalized*
the British way against 42 American uses including the button's own label. Copy that names a value is subject
to the same rule as copy that quotes a figure: check it against the code.

**A field hint is a sentence and ends with a full stop. A caption under a figure does not.** Twelve of sixty
hints had no stop, which was reported as inconsistent - and nine of the twelve were not field hints at all.
`components/ui/_stat` takes a local also called `hint`, and a caption under a metric ("Ready to spend on
shares", "All deposits, all time") is a fragment, which is what Stripe and Polaris put there. Two components,
one local name, two correct answers. They are told apart by class: a field hint is `p.tw-field-hint`, a
caption is not, and `hint_copy_test` reads the class.

One field hint changed wording rather than gaining a stop: "Must start with http:// or https://" would have
ended on a full stop glued to a scheme, which reads as part of the address. It is "Must be a full web
address, starting with http or https." instead.

**A hint says something the label cannot.** Twenty-six of this app's field hints restated their own label:
"Full company name" under Company name, "Industry sector" under Industry, "Select the school for this school
year" under School, "Re-enter password to confirm" under Password confirmation, "Grant admin privileges to
this user" under Admin. GOV.UK, Polaris, Carbon and Material 3 each name this as the thing hint text must not
do, and the cost is not the wasted line - it is that a reader who finds three hints empty stops reading the
fourth, which is the one saying a nightly job overwrites the field.

A hint earns its place by carrying one of:

- **a format or constraint** the value is checked against -- "Must start with http:// or https://",
  "At least 6 characters", "In dollars, like 12.50"
- **a consequence** of the value -- "Students can no longer buy it. Anyone holding shares keeps them and can
  still sell", "Deposit and credit add to the balance. Withdrawal, debit and fee take from it"
- **who sees it, or what else writes it** -- "Shown wherever this teacher is listed", "Replaced each weekday
  by the price feed", "Notes for other administrators - a student never sees this"

Otherwise it is deleted, and no hint is the correct amount of hint. **Never open with the control's own
verb** - "Enter", "Select", "Choose", "Type" - because a text box already announces that you type in it;
GOV.UK's guidance is that a hint describes the *answer*, not the operation. **A choice group is the
exception**, and GOV.UK's own checkbox pattern is the reason: it ships "Select all that apply" as the hint,
because with a group the thing a reader cannot see is *how many* they may pick. So "Select all classrooms
this teacher teaches" is right on a `<fieldset>` and would be wrong on a text field.

**The register is impersonal and states the consequence.** Set by a reader on the teacher form and applied
across the product:

| | |
|---|---|
| purpose | `Used to sign in.` -- not "They sign in with this" |
| visibility | `Displayed wherever this teacher appears.` -- "Displayed", consistently, not "Shown" |
| fallback | `If left blank, the first part of their email is shown instead.` |
| consequence of saving | `A link to set a password will be sent by email once saved.` |
| a group | `Select all classrooms this teacher teaches.` |

Second person ("you sign in with this") and third ("they sign in with this") were both in use, sometimes on
one page. The subject of a hint is the *field*, so the sentence does not need a person in it at all - which
is also what removes the awkwardness of writing about a teacher and their student in the same line.

**Name the noun the sentence is about; do not lean on "it".** "Moving **it** to another school year gives
**it** that year's four grade books" was reported as needing help: the subject of the sentence is not in the
sentence, so a reader has to look up at the h1 and carry the answer back down. It reads "Moving **a class**
to another school year …" now, and the same fault was in four more places -- "Creating **it** adds a grade
book …", "Creating **one** adds its four quarters", "Open **one** to edit it", "so saving **this** moves the
money".

A pronoun is fine when its noun is *in the same sentence*: "Deposit adds to the cash balance. Debit takes
from **it**" names the balance first. The test is whether the line survives being read on its own, which is
how help text is read -- eyes go to the field, not to the title above it.

**And the sentence states the consequence, not the mechanism.** "gives it that year's four grade books" is
what happens to you; "updates the `school_year_id`" is what happens to the row. Every hint that earns its
place answers *what will this do to my data*: four grade books appear, a balance moves, a student can sign
in, a stock leaves the trading floor.

**A page description follows the same register, with the entity as a plural subject.** "Teachers are assigned
to classrooms, not schools, and can hold more than one" - not "A teacher is assigned to classrooms rather
than to a school, and they can hold classrooms in more than one". Plural because the page is about the type
rather than about one record; `not X` because a contrast is the shortest way to correct a wrong assumption;
and no pronoun, because on a **create** page "they" has no antecedent - the record does not exist yet.
`admin/students#new` opened "They can sign in straight away" about a student nobody had created.

The exception is the **student-facing** half, which addresses its reader about their own things: "You still
own shares in these", "Your cash plus your shares". That is not drift - a page about your portfolio uses the
second person, and a page about a type of record does not. And where a fact is true of a
whole card rather than one field, say it once in the page description: sixteen stock fields were each
gesturing at "students read this", which is one sentence about the page.

`hint_copy_test` fails on the shape rather than on a list of strings - the label's words appearing in a short
hint, or an opening imperative - so a new field cannot reintroduce it and the test does not go stale. It was
verified by putting "Enter the school name" back and watching it name the field.

**The product is American, and that extends to the verbs, not just the spellings.** "Tick every classroom
this teacher runs" is what a British writer says; it is **Select** here - and "check" only where the control
is unambiguously a checkbox and the sentence is about the box rather than the choice. Apple's HIG, Material
and Polaris all write "Select". Reported by a reader, on the one hint in the app that said it.

**A section hint that repeats the button is noise.** "Saved when you press Update school year" under a page
with one form says what the button says. It earns its place only where a page has **two** writes and they
behave differently - a student's record page, where the cash adjustment applies immediately and the account
form waits, or a school's, where the years do. Everywhere else the hint should carry a consequence or not
exist: "A balance is the sum of these rows, so changing this moves money" is worth a line; "Saved when you
press Update transaction" is not.

**And never the app's own history.** A stock's Details hint read "Grouped as they were on the old read-only
cards" - true, and meaningless to anybody who did not work on the branch that removed those cards. That
belongs in migration.md, which is what it is for.

**A fact about one field belongs on that field, not in the page description.** The new-teacher page opened
with "A temporary password is generated and a reset email goes to this address" - a footnote about the future,
met before there is an address to read it against. It is the **email field's** hint now: "They sign in with
this, and their temporary password and setup link are emailed here", which is an instruction about what to
type rather than a note about what will happen later. A description carries what is true of the *page*; a
hint carries what is true of the *field*.

**A control that filters another control is not a form field.** "School filter" sat between a teacher's name
and their classrooms, labelled like an attribute, and read as "which school does this teacher belong to?" -
which is not a question this app asks. It is now inside the group it filters, labelled "Show classrooms from",
and its hint says it changes nothing about the record. GOV.UK and Polaris both place a filter with the list it
narrows, never in the field order.

**A page description states what the reader cannot see, and what happens next.** `students#new` said "You can
add money and see attendance once the account exists", which described *other pages* to somebody filling in
this one. What is not on the page is the consequence of submitting: the account works immediately, and a blank
password field means one is generated and shown **once**. Both facts change what the reader does; neither is
guessable from the form.

**Two writes on one page need to say which saves when.** A student's record page has an account form that
waits for its button and a cash adjustment that applies immediately; the school page has a form and years
that add and remove as you click. The section hint carries it - "Saved when you press Update student",
"Applies as soon as you press Add transaction" - because a page that mixes the two and says nothing is the
one thing about this shape a reader cannot work out by looking.

### Price age, and why the daily change is not a column

**Decision: the trading floor states how old its prices are. It does not show a daily change.** That figure
had three homes in as many commits - a scrolling ticker in the header, a "Today's movers" card on the home
page, a Change column beside the price - and each move taught something. It is worth keeping all of it,
because the pull toward showing a market-style delta is strong and the reasons not to are not obvious.

**Why the ticker went.** `animation: scroll 20s linear infinite`, automatic and endless with **no pause
control and no `prefers-reduced-motion`** - WCAG 2.2.2 at **Level A**, on every signed-in page. Colours at
2.74:1 and 3.78:1. And it showed nothing true: every `yesterday_price_cents` was nil, so all 18 stocks read
`0.00%`, and because the test was `percentage_change >= 0` every one was green with an upward arrow. **A
ticker is a broadcast component** - television lower-thirds and public displays, where the viewer is captive
and cannot scroll. No finance application animates its chrome.

**Why the card went.** It listed three companies with price and change on the home page, pushing the balance,
the announcements and the getting-started steps down to do it. **A card that duplicates a page one click away
is not carrying its own weight**, and the home page's job is the balance, the news and the onboarding.

**Why the column went, which is the substantive one.** Four facts, each checked:

- **"Since yesterday" is wrong two days a week.** The job's cron is `0 2 * * 2-6`, Tuesday to Saturday, so
  nothing covers Sunday or Monday: on a Monday the figure spans Friday to Saturday. Holidays widen it.
- **Without an API key it is an em dash, always.** `fetch_quote` returns nil without one.
- **Rate limits make a partial update the normal case.** 18 stocks, one request each, a 1.1s sleep for the
  free tier - when the allowance runs out mid-run, some companies are fresh and some are days old.
- **It was `hidden lg:table-cell`**, so it was absent on the phones these students mostly use.

And the change that matters to a student already exists, on the portfolio: **current value minus what was
paid**, per holding, which needs no API for its baseline and is always true. Note the collision that had been
sitting in the product - "Change" meant *since purchase* there and *since yesterday* on the floor.

**What replaced it: the price's age.** A student places an order against that number, so its staleness bears
on the transaction rather than on the browsing.

- **Stale means "older than the freshest price on this page"**, not "older than today". That distinction is
  load-bearing: the job runs at 02:00 for the *previous* close, so a perfectly fresh price normally carries
  yesterday's date, and comparing against today would mark every row. `stocks.filter_map(&:last_trading_day).max`
  needs no calendar knowledge and cannot be wrong about weekends or holidays.
- **The page states the date once**; a row says something only when it is behind. When the whole page is
  behind, no row is marked and the description carries it - "prices as of 3 August" is the fact, not "every
  company is stale".
- **`slate-600`, not amber or rose.** A price that has not been refreshed is a fact about the data, not an
  error the student made or a warning about the company.
- **"Not priced yet"** where a fetch has never succeeded, rather than a date or a dash.
- One statement of the cadence, on the page. The Active stocks section used to say "Prices update every
  school day" as well - a second claim about the same thing, and a wrong one, since the cron knows nothing
  about school terms.

**The failure mode this all came from.** A failed fetch used to write `yesterday_price_cents = price_cents`,
so an API outage reported `0.00%` - identical to a flat market - and destroyed the real comparison point. The
job writes nothing on failure now, and leaves `last_trading_day` alone, which is what makes the staleness
visible at all. The test covering that path had asserted the bug, under the name "preserves yesterday price".

**One icon per card, and it lives in the header.** The announcements card had `megaphone` twice: 16px in
a 32x32 blue-50 tile in the header, and 20px bare slate-500 in the body's empty state. Bigger, a different
colour, no tile - reported as the two not matching. Matching them would have been the wrong fix: it would
still be the same glyph twice, 40px apart, giving a card with nothing in it two focal points.

**An icon in an empty state belongs to the page-level variant only**, where the emptiness *is* the screen
and the icon is what the eye lands on - Polaris's `EmptyState` illustration, Primer's `Blankslate` visual,
Material's full-screen states. Inside a titled card the header already carries one, so the compact variant
is **text**, which is what Stripe's card empty states and GOV.UK's are. `components/ui/_empty_state` takes
`icon` for the default variant and ignores it when `compact`.

**And an empty state occupies the same box as the content it replaces.** The glyph plus its gap indented
the copy **32px** past the card's content edge, so an announcement arriving shifted the text left: measured
333px empty against 301px filled, and 301px for both now. A state change must not move the layout.
`announcements_test.rb` asserts the icon count and that the two left edges are equal.

**A card per list item is card soup.** Four grade books were four `.tw-card` links; with the roster's
table card and the trading card that was six surfaces on one page, and it was reported as such. Four
quarters with a name and a status are **list rows in one card** - Polaris's `ResourceList`, Primer's Box
rows, Stripe's list sections - separated by `divide-y`, which is also the only divider the Dividers
section above permits here. A card earns its edges for a summary figure, a person, a preview; not for a
row with two fields. The original 256px rail had this right and was wrong only about its width.

**A summary band is standard and was still wrong here.** Stripe leads a customer with its figures and
the portfolio page uses the four-across `_stat` strip - but that strip is **134px** tall, and with the
setting card above the roster it put the first student at **567px of a 625px viewport**. Measured
through the change: 146px before, 567px with the band, 296px after removing it and dropping `_card`'s
redundant header from the setting block (179px -> 90px), and **206px** once the setting moved onto the
section's own header line and stopped being a card - which is the figure this document set for the
trading floor. The roster is why a teacher opens the
page. `ClassroomsController` still computes `@classroom_stats` and nothing renders it - four queries a
request thrown away - which is in `design-todo`, because the answer is a one-line meta summary beside
the title, not a band above the content.

`classroom_page_test.rb` asserts the stacking as geometry, both trading states, that the switch is not in
the page header, that no pill sits beside the sentence, that the page carries at most two surfaces, and
that the first row stays above 240px.

### The grade book page

Reported as "does not match the design system at all", and it did not. It had never been opened: four
links to it were added and its status badges asserted while the page itself went unread. Every figure
here is what it measured.

**A table always goes on `shared/_table_container`.** The grades table hand-rolled an `overflow-x-auto`
div to carry the three attributes a data-only scroll region needs - `tabindex="0"`, `role="region"`,
`aria-label` - and lost the card doing it: **0px border, transparent background, 0px radius** on a
slate-50 page. `classrooms#show`'s roster had exactly this defect and this document records it as fixed
there. The container takes an optional `region_label` now, so the affordance is an option rather than a
reason to bypass the container.

**`tw-input-primary` is the text input, and it was on a checkbox.** Perfect attendance rendered at
**187x44px** - a full-width bordered box with a tick in it. A checkbox takes the tokens from
`components/ui/_checkbox`: `size-4 rounded-sm border-slate-500 accent-sitf-primary`. `accent-*` is how a
native checkbox is tinted; `rounded-sm` because at 16px the control radius is nearly a circle and a
checkbox reads as a square.

**A page shows its own state.** The grade book's status - a real enum the classroom list displays on
every row - appeared nowhere on the grade book, so "Completed" in the list had no confirmation on the
page it linked to. It is a pill against the `h1`, and the `h1` is now the **quarter**: "Grade book"
identified nothing, since all four are grade books and all four had the same accessible name.

**Form actions anchor to the leading edge, never centred.** Two centred stacks - the submit and the
finalize - against a form whose own fields start at the left. Polaris, Primer and Tailwind UI all put
form actions on the leading edge or in a footer bar.

**Of those two, this product uses the leading edge, and the choice is now settled.** "Leading edge *or*
a footer bar" left room for three answers, and the app had all three: the students#new and #edit pages
put their actions in a `px-4 py-3 bg-slate-50 text-right` strip **inside** the card, the admin forms
right-aligned theirs on the page background, and the classroom form and grade book used the leading
edge. Reported as the grey background behind the buttons. So, everywhere:

- **On the page background, below the card** - never a tinted strip inside it. A footer bar is a real
  pattern (Polaris `Card` footer actions, Stripe's settings panels) but it is a *different* decision,
  not a free one: it needs the card to own its padding and it fills a strip with a colour that means
  nothing here. Measured after: the action row's background is `rgba(0, 0, 0, 0)`.
- **Aligned to the card's leading edge.** Measured on students#edit: card at 485px, primary at 485px.
- **Primary first, then cancel.** The order follows the alignment: at the leading edge the eye reads
  left to right and the primary is what the form is for, which is GOV.UK's and Material's order.
  Right-aligned rows reverse it - Polaris and Stripe put cancel first there - and that is precisely why
  the two cannot be mixed in one product.
- `flex flex-wrap items-center gap-3`, so a narrow viewport wraps instead of pushing cancel off the
  edge, and `gap-3` rather than `ml-3` on the second button.

`test/system/form_actions_test.rb` asserts all of it as pixels - inside-the-card, tint, leading edge,
40px height, and the card's own radius and border - on both sides of the product and at 375px. Verified
by putting the grey strip back and watching it fail.

**Whatever appears between the header and the card spaces itself.** Asked whether the gap above the card was
consistent: without an error summary it was, 24px on all three form pages - but the classroom card carried an
inert `mt-4`. **Adjacent vertical margins collapse to the larger**, and the header's own `mb-6` is bigger, so
that declaration did nothing at all until a summary appeared between the two, at which point it became live
and gave that state 16px. On the student forms the summary sat **flush against the card, 0px**. Three forms,
three different gaps in the error state, none of them the page's rhythm.

`shared/_form_errors` carries `mb-6` now, which is the only place that can be right for all three, and the
card carries no top margin. **An inert declaration is worse than none**: it reads as load-bearing, and this
one became load-bearing in exactly the state nobody checks.

**A page description says what the reader cannot already see.** "You can add students once it exists" was
reported as unhelpful and it was: adding students is the obvious next step and the classroom page offers it,
so the sentence spent itself on the one thing the reader would have found anyway. The non-obvious part is that
`after_create :create_gradebooks_for_quarters` produces **four grade books, one per quarter** - so the
description says that. Consequence-shaped, like its siblings: "They can sign in as soon as you save",
"Changes apply everywhere this student appears".

**A form's measure is a `max-w-*`, never a fraction of the viewport.** `classrooms#new` and `#edit` were
`mx-auto lg:w-2/3`, so on a 1920px monitor the form was 1280px wide with the name field stretched across
all of it. A form's readable measure does not scale with the window.

**The measure is `max-w-3xl` (768px), on every page that holds a form or a record, on both halves.** This
said `max-w-2xl` (672px) when the app-side forms were the only ones with a column at all; the nine admin
record pages then settled on 768px, and a create page cannot be a different width from the record it creates.
Reported as "cards for new students and new teachers are different widths" - measured at 1366px on the input
rather than the wrapper, there were **five** measures: 384px (auth), 630px (app-side forms), 726px (record
pages and three create pages), 854px (new announcement) and 1020px on four create pages that had no column at
all and inherited the layout's `max-w-7xl`. 768px is also where the field sits: GOV.UK's two-thirds column is
~630px, Polaris's narrow page is 662px, Stripe's forms run 600-700px.

**The auth pages keep their own 384px (`max-w-sm`), and that is not an inconsistency.** A signed-out centred
card holding two fields is a different page type, and every reference does the same - Stripe, GitHub and
Linear sign-in cards are all around 400px.

`page_width_test` asserts the 768px column on seventeen pages, so a page that forgets its column fails by
name rather than by looking slightly wrong.

**Every control in a form starts on one left edge, and a hover band must not move it.** Reported as the
teacher checkbox looking misaligned. Measuring **both** axes found where: vertically all six checkboxes were
already within 0.5px of their own label's first line, but the grades and teachers rows carried `px-2` for
their hover band, so those boxes sat at **518** while the inputs above and the trading checkbox below sat at
**510**. A checkbox 8px right of the field it follows reads as the checkbox being wrong.

GOV.UK's checkbox item has **no left padding** for exactly this reason; an indent is reserved for a nested or
dependent option, where it means something. Keep `py-*` for the row's height and its hover band and drop the
`px-*`. The other repair - keeping the padding and pulling the row back with a negative margin - takes the
hover fill with it, which this document records three times as the wrong fix.

Measured after: inputs, legends and all six checkboxes at 510.

**And the vertical rule is the outcome, not the mechanism.** A checkbox sits on its label's **first line**:
`items-center` does that for a single-line label whatever its line-height, and a two-line label needs
`items-start` plus a nudge sized to the line box. Both are correct and the classroom form uses both - so the
test measures the offset rather than asserting a class, which is what lets them differ. Asserting the
mechanism here would have failed a correct page.

**A group's hint goes under its subheader, before the options.** Reported on the classroom form, where both
groups had theirs below the checkboxes - which puts the instruction after the decision it governs, and leaves
it floating between one group and the next. This document already stated the rule for filters: hint text
"under the group's subheader ... not floating between two field groups", because a hint between groups is
ambiguous about which one it modifies. GOV.UK puts a fieldset's hint between the legend and the inputs for
the same reason. Measured after: on classrooms#new, Grades legend 457, hint 485, first option 527.

Note the distinction from a **single** field, where the hint goes *below* the input - that is Polaris and
Material, and it is what the student and grade-book forms do. A group has no single input to sit under, and
its legend is a subheader rather than a label.

**A boolean setting comes last: identity, then access, then behaviour.** "Enable trading" sat between the
grades and the teachers. It is optional with a default, it is the only field on that form with a runtime
effect on students, and it is the one setting that also has its own control on the classroom page - so in a
form it is "and one more thing", not part of what the classroom is. Required identity first, access next,
behaviour last is the order GOV.UK and Polaris both use when fields are grouped on one page.

**It is a checkbox, not a switch, and that is not a contradiction.** GOV.UK reserves a lone checkbox for
opting in, which is what this is; and a switch implies the change takes effect as you flip it, which is true
of the control on the classroom page and false here, where nothing happens until you save. The same setting
can legitimately be a switch in one place and a checkbox in another for exactly that reason.

**A state is a badge beside the name; the summary line is metadata, and it says what it is.** A classroom's
description read **"6th · 2026 - 2027 · trading on"** and was reported as unreadable. Two faults, and the
second is the one that generalises: "6th" does not say what it is a 6th of, and a *state* was joined to two
*attributes* by the same separator, so it read as a third attribute hanging off the end.

`_page_header` has had a `badge:` slot for this all along and `grade_books#show` uses it; three record pages
were putting their state in the description instead. Linear, Stripe, GitHub and Shopify all put an entity's
status on the title's line. So: classroom (Trading on / Trading off / Archived), teacher (Active /
Deactivated), user (Archived, and nothing when active - a badge on every ordinary record is a badge nobody
reads).

`teacher_summary` argued the other way and its comment is worth answering rather than deleting: "whether they
are active is stated in words, not only by a badge's colour." The worry is right and the badge meets it,
because **a badge carries a label**. "Active" in a pill is words.

**And the badge is derived once.** The classrooms index rendered Archived / Trading on / Trading off inline
while the record page derived the same thing again as prose, so one classroom could read "Trading off" in the
list and "trading on" on its own page. `classroom_status_badge` and `teacher_status_badge` are what both
render now.

**One thing a status badge is not: a second copy of a control's own label.** The app-side classroom page gets
no badge, because the trading setting below states its state in a sentence beside the switch - a pill would be
the third copy of one fact.

**A trail is plain text. No crumb carries an icon, including the first.** The root had a house glyph and
nothing else did, which was reported as inconsistent - and it is, because nothing distinguishes the first
crumb except that it is first, which its position already says.

The field is near-unanimous: GOV.UK, Carbon, Primer, Bootstrap and Atlassian all ship a breadcrumb with no
icons, and Polaris ships no trail at all, only a back action. The common exception is **Tailwind UI**, whose
example puts a house on the first item *instead of* the word - a compact home affordance, icon-only with an
`sr-only` name. This app had the icon **and** the word: that pattern's decoration without its economy. Two
roots also make the glyph wrong half the time, since it labelled "Dashboard" on the admin side.

The **chevron between crumbs stays**, on every boundary. That is the separator, not a decoration, and it is
what GOV.UK, Tailwind UI and Ant Design all use.

**A page reached from another page gets a breadcrumb trail, on both halves.** An admin clicking "View
portfolio" on `admin/students#show` - the only link out of that page - landed on `portfolios#show` with no
way back. Reported, and the trail was the fix asked for; a back link was tried first and replaced, because a
trail says the same thing and one level more.

Trails had been an admin convention only - the partial lived at `admin/shared/_breadcrumbs` - so **eight app
pages were reached from somewhere and named nowhere**: a stock, a classroom, its edit form, both student
forms, a grade book and a portfolio. `shared/_breadcrumbs` is one partial now with the root as a local, and
`page_breadcrumbs` / `admin_breadcrumbs` are its two callers.

**The root follows the reader, not the layout.** An admin opens a portfolio from the student's admin record,
so their trail is `Dashboard > Students > Robin Fields > Robin Fields's portfolio` and every crumb goes back
where they were - even though the page renders in the app layout. A teacher opens the same page from their
classroom roster and gets `Home > Classes > Period 3 > …`. Rooting both at Home would give the admin a first
crumb that was never on their path.

**And it costs 44px**, which is not free on a page whose job is a list. Measured on `classrooms#show`: the
trail is 20px tall with a 24px margin, and the roster's first row moved 206 -> 250 in a 625px viewport. That
page has twice paid for something added above its roster, so `classroom_page_test`'s threshold moved 240 ->
260 - ten pixels of headroom, deliberately, so the next block added above the roster still fails.

The general form: before linking from one half of the product into the other, open the destination as the
role that will click it and ask how they get back. A page that is top-level for one reader is a dead end for
another.

**A breadcrumb's last item is the page's own title, verbatim.** `admin/school_years#show` set its crumb to
`@school_year.to_s`; `SchoolYear` defines `#name` and no `#to_s`, so the trail read
`Dashboard / School years / #<SchoolYear:0x0000ffff68492f88>` under an h1 reading "Test School (2026 - 2027)".
Reported by a reader, because no test looked at a crumb's text.

Two more were the same fault without being broken: teachers put the **username** in the trail under an h1
showing the display name, and stocks the **ticker** under the company name. A trail whose last item disagrees
with the page it sits on cannot be used to work out where you are, which is the only thing a trail does -
GOV.UK, Primer and Polaris all specify the page title there. `breadcrumb_label_test` compares the two on
eight record pages and separately fails on `#<Model:0x…>` anywhere in a page's text.

**A figure that is the same on every record is not a summary.** A school year's description read
"2 classrooms · 4 quarters", and every school year has four: `create_quarters` makes them on create, nothing
else makes one, and there are no quarter routes. That is the invariant the Quarters *card* was removed for,
printed smaller - a description carries what differs between one record and the next.

**Say when a section is read-only, because the page around it usually is not.** A record page's Details is a
live form, so a list under it reads as another thing to change there. The school year's Classrooms section
was read-only and the only statement of that was a code comment; its hint now says where a classroom is
edited and where a new one comes from.

**A checkbox group's rows are contiguous - the row's padding is the whole of the gap.** It was `py-2` on
each row *and* `space-y-2` between them, so 24px of air between one option's text and the next and a 60px
pitch for a two-line row. Three spacings for one job, and reported as too much padding.

design.md was silent here, so the field decides, and the row's own `hover:bg-slate-50` settles it: a filled
row is Primer's ActionList and Material's list item, both of which run edge to edge, because a gap between
two fills reads as a hole rather than as separation. Polaris's bare ChoiceList takes the other consistent
option - a gap and no padding - and that is not this component. Measured after: **52px pitch for a two-line
row and 36px for one line**, against GOV.UK's 54px and Material's 56px two-line item. A multi-column group
gets `gap-x` only, for the same reason.

**A checkbox's own hint is indented to its label's text**, not to the box - `pl-7`, the 16px box plus the
12px gap, which GOV.UK also does. Measured: label text and hint text both at x=538, the checkbox at 510.

**Choosing a person is a checkbox list at this size, and an avatar is not part of it.** The teacher picker
put a 32px disc containing one letter beside each name, and it was reported as not making sense. It did not:
a single initial identifies nobody - two teachers whose names begin with T get the same disc - while taking
the widest column in the row. The name identifies and the **email disambiguates**, which is what GitHub's
collaborator lists and Google Workspace's member pickers show. An avatar earns its place where it carries a
real image or where a name alone is ambiguous in a dense list, not as a decorated bullet.

**The volume is what decides the control.** A checkbox list is right for a short, fully known set - GOV.UK,
Polaris and Primer all use one - and there is one teacher in this database. **Past roughly ten it should
become a searchable multi-select with chips**, which is GitHub's assignees picker, Linear's and Jira's,
because a list you have to scroll to find a name in is a list you should be able to type into. That threshold
is the trigger; not a redesign for its own sake.

**And a dropdown that hides options is not that control.** The admin teacher form had a single-select
"Show classrooms from" above the multi-select group it narrowed, which is two controls about one thing,
distinguished only by their labels, one of them naming a mechanism rather than a thing. It pre-selected the
school of the teacher's first classroom, so it hid options nobody chose to hide - and it was hiding a list
shorter than itself: 4 schools and 2 classrooms in the current year here. The whole apparatus went, and each
row names its school instead, so a classroom is unambiguous when two schools run a "Grade 5" and a teacher
spanning both can *see* it rather than read it in a caveat.

The general rule: **if a control narrows a list, it must earn its place against the length of the list it
narrows** - and it must not remove options from a submit. When a set is too long to scan, the answer is a
text filter the reader types, over a list they can still see all of. That is what GitHub, Linear and Jira do,
and the previous filter is what a checkbox group's own hint had to apologise for.

**A group of checkboxes is a `<fieldset>` with a `<legend>`.** It is the only thing that can name a group,
because there is no single control for a `<label for>` to point at - and the classroom form proved it by
trying: `form.label :grade_ids` emitted `for="classroom_grade_ids"`, no element had that id, and the
Grades group had **no accessible name at all**. Worse, `check_box_tag "classroom[grade_ids][]"` derives one
id from the name, so the hidden field and all four checkboxes shared `id="classroom_grade_ids_"` - five
elements, one id, invalid, and every `for=`/`aria-*` reference resolving to whichever came first. Give each
box an explicit id and the hidden companion `id: nil`. GOV.UK, Polaris and Primer all use a fieldset here.

**An option list only gets a scroll container when it can scroll.** Both of that form's groups were
`max-h-60 overflow-y-auto` panels with a `bg-slate-50` fill, around four grades and one teacher. A scroll
container that never scrolls, and a tinted panel inside a card - the same shape as the column of dashes and
the button that could only report it did nothing. Count the options before reaching for `max-h-*`; measured
after, the form has **0** scrolling sub-panels.

**A required hint states the requirement once.** That form's grades hint opened with a red
`* Required:` while the legend already carried the asterisk and the browser enforces it - three statements
of one fact, the third in the colour this app reserves for errors. Red type on a form with no error in it
reads as an error.

**Navigation is not a form action.** `classrooms#edit` ended with "View classroom" and "Back to
classrooms" as two `tw-btn-secondary` links *below* the form, under the submit - three actions in two
groups with the primary orphaned above them. Going back is one action, it is Cancel, and on an edit page it
goes to the record. `form_actions_test` asserts both nav buttons are gone.

**A view comment goes in an ERB comment tag.** An HTML comment is sent to the browser and can be read
there; 37 of them were, across nine views. And do not write the ERB terminator *inside* an ERB comment -
this document already records a case where that ended the comment early and leaked a sentence onto the page
as visible text.

**A form's card is `.tw-card`, and its fields are one column.** The student pages hand-rolled
`bg-white shadow-sm overflow-hidden lg:rounded-md`: no border at any width and no radius at all below
`lg`, so on a phone the form sat on a square-cornered white rectangle against a slate-50 page. And the
fields were a `grid grid-cols-6` with `col-span-6 lg:col-span-4` - a twelve-column grid for two fields,
which at `lg` made the inputs two thirds of a container already capped at 672px. One field per row in a
`space-y-5` stack is what GOV.UK, Polaris and Tailwind UI use for a short form.

**A validation message carries a red icon before it, or it reads as helper text.** Reported as the message
being "simply grey text", which is exactly what it was: slate under a field with no mark on it, which is the
shape of advice rather than of an error. `FormErrorsHelper#field_error_message` is the one definition, used by
the field-level proc, by a group's message and matched by the summary - the markup had even been carrying
`flex items-start gap-1.5`, which is the fingerprint of an icon the container was built for and that was never
added.

It matters past recognition: the input's border, the icon and the words are three channels, and a reader who
cannot see the border has only the last two. **red, not rose.** The inherited text in the Validation section
says rose, which is this app's *destructive-action* family - `.tw-btn-danger`, the confirm dialog's accept.
Validation here is red: `.tw-input-error` is `border-red-600` with a `focus:outline-red-700`, and the summary
is red-50 / red-200 / red-700. Using rose would put a second error hue in the product. Measured: the field
icon is red-600 on white at **4.77:1**, matching the invalid field's own border; the summary's is red-700 on
its red-50 at **5.87:1**, matching its own ink. Both clear 1.4.11's 3:1 for a non-text mark and the 4.5:1 text
threshold as well. `circle-alert`, `size-4` at a field and `size-5` in the summary, which is the callout's
shape.

**`ApplicationController.helpers`, never `ActionController::Base.helpers`, when an initializer reaches an app
helper.** The base proxy carries Rails' own helpers and none of the app's, so the call raised NoMethodError at
render time - a **500 on every invalid submit**, not a missing icon. And nothing showed it until the server was
restarted, because a new initializer is not picked up by code reloading: the running process was still
executing the previous, iconless proc and reporting success.

**Validation errors appear when the user clicks save, and this app now implements the pattern the
Validation section specifies.** It did not, and could not: every required input carried `required` and no
form set `noValidate`, so the browser's native bubble fired first and blocked the submit. The server never
saw an invalid form, so neither the summary nor any field-level message could ever render - and the proof
is in the suite, where the one test that needed the summary had to submit a **duplicate username** to get
past the browser rather than a blank field.

What is here now, against the four parts that section names:

- **Native validation off app-wide.** A handler in `application.js` sets `form.noValidate` on every form
  without `data-native-validation`, on `DOMContentLoaded`, `turbo:load`, `turbo:frame-load` and
  `turbo:render` - four events because Turbo Drive replaces the body on navigation and a frame can bring
  a form in on its own. The inputs keep `required`: it is what tells assistive tech the field is
  required, and it is harmless once the browser is not acting on it. If the JS never runs, native
  validation returns, which blocks the invalid submit - a safe way to fail.
- **Field level, automatic.** `config/initializers/field_error_proc.rb`. Every invalid text-like control
  gets `aria-invalid`, an `aria-describedby` pointing at a generated message, and `tw-input-error` **in
  place of** `tw-input-primary` - not alongside, because both set a border colour and the winner would be
  file order rather than intent. It skips labels, hidden, checkbox, radio and submit, and skips any
  control that already has `aria-describedby`, so a hand-placed message never doubles. It keeps Rails'
  `<div class="field_with_errors">` wrapper, which the suite selects on.
- **Groups, by hand.** A checkbox group's error belongs to its `<fieldset>`, not to whichever box Rails
  rendered first, so `FormErrorsHelper#field_error_attrs` splats the attributes onto the fieldset via
  `tag.fieldset(**...)` and `#field_error` renders the message under it. Both grades and teachers on the
  classroom form use them.
- **The border, twice over.** `tw-input-error` for the controls this app's classes reach, and
  `[aria-invalid="true"]` in `forms.css` for everything else. A field announced as invalid that does not
  look invalid is the failure that pair prevents. Note one difference from the section above: in **this**
  app `.field_with_errors` carries no border of its own - it is Rails' wrapper, kept as a hook - and the
  border comes from the class and the attribute.

**The message is the full message, at the field and in the summary both**, so the two say the same thing
rather than two versions of it: "Name can't be blank" under the field and in the list. Sentence case, no
trailing period.

**Which fields are required comes from the model, not the form.** The classroom form's grades group is
marked required and the model backs it - `validate :grade_level` adds "must have at least one grade" to
`:grades`, which is why the fieldset can be flagged at all. A form that marks a field required with no
validation behind it is a form that will silently accept a blank.

`validation_errors_test.rb` covers it: that `noValidate` is set, that the summary and every field message
appear on save, that nothing marked invalid is left without a message (1.4.1 - never colour alone), that a
valid save is unaffected, and that the student form gets it too.

**One error summary, in `shared/_form_errors`.** There were three: the student pages' bolded "Error:"
over a bare list, the classroom form's `bg-red-50 px-3 py-2 rounded-lg` with an `<h2>`, and Devise's
own. The shared one **counts** - "1 error stopped this student being saved" - because a reader needs to
know how many things to look for, which is GOV.UK's, Polaris's and Primer's error summary. It carries
`role="alert"`, an id and `tabindex="-1"` so focus can be moved to it, and **no dismiss**: it describes
the form as it stands and is rebuilt on submit, so hiding it hides the list of what is still wrong.
Note the test that broke on this - it found the summary by the word "Error", so a copy change read as a
dismissal regression. Assert the testid, not the wording.

**One filled primary.** "Finalize grades" was a second `tw-btn-primary`, greyed when completed, floating
at the foot of the page - and it is the action that pays every student and cannot be undone. It is
`:danger_outline` in an explained block now, the same shape as the trading setting: the consequence in
the copy, never in the control. For a completed grade book the block is not rendered at all, because a
dead greyed control is worse than none.

**The trailing column right-aligns whether or not it holds actions.** This document stated the rule for
an *actions* column and, separately, for numeric ones - and every table in the app happened to satisfy it
because every other table ends in actions. The grade book is the only one that does not, so its
"Perfect attendance" checkbox column was the only left-aligned trailing column in the product, and it
read as wrong beside the rest. Stated generally now: **the last column right-aligns**, header and cells,
and `table-body-cell-right` is the class either way.

**A `<select>` gets our chevron, not the browser's.** The native arrow's inset is not controllable: the
field is `px-3` and Chrome draws its glyph hard against the right edge of that padding, so it sat visibly
tighter to the border than any other control's contents - reported as the chevron not having enough
padding. `select.tw-input-primary` is `appearance-none` with lucide's chevron-down at
`right 0.75rem center` and `pr-9`, so the glyph matches the field's own `px-3` and a long option cannot
run under it. Styled by **element**, so all ten selects in the app are fixed without touching a call
site. Tailwind UI, Polaris and Primer all replace the native arrow for the same reason.

**A person's row shows the name over the username.** `font-medium slate-900` for the name,
`text-xs slate-600` for the username beneath - this document's primary-identifier shape, and what GitHub
does for a person. Both are needed and neither replaces the other: the name is who a teacher is looking
for, and the username is what they sign in with and what a password reset refers to. `display_name` falls
back to the username, so a student with no name shows **one** line rather than the same string twice.

Students had no name at all until now: `users.name` existed and `display_name` has always preferred it,
but nothing collected it, so every screen fell back to the lowercased identifier and it was reported as
the names being lowercase. They were not names, and capitalising them would have been wrong - usernames
are downcased because sign-in is case-insensitive, so `jsmith2` would have rendered as `Jsmith2`.

**The name is required on every path a person creates a student through** - both forms and the CSV import.
It is a `:student_form` validation context rather than `on: :create`, because a blanket presence check
would make the students who already exist without a name unsaveable: a password reset would start failing
on a field nobody touched. So the forms save with `context: :student_form`, and `ImportStudentService`
checks it itself.

`update` had to become assign-then-save: `update` writes before a context validation runs, so a blank name
would be saved and *then* reported, wiping the name it was complaining about.

**The import refuses a nameless row as a failure, not a skip**, and the distinction matters because the
buckets read differently: a skip means the row was fine and there was nothing to do, while a failure is
listed per row as "Row N: <message>" - what somebody fixing a spreadsheet needs. The blank-username and
blank-classroom guards were moved to failures for the same reason.

And the skip summary is **derived from the reasons** rather than assuming one. It read "Skipped N existing
usernames", which was true while a duplicate was the only thing that could produce a skip; it now reads
"Skipped N rows: <reasons>", capped at three before it summarises. That makes the mislabelling impossible
rather than corrected once.

**The import dialog states all three columns**, because helper text that lists a format is part of that
format. It said "classroom_id, username" and kept saying it after `name` became required, so it told an
admin to build a file the importer would then reject on every row. It now also links the template, which
existed and was only linked from the page behind it.

`User` normalizes the name (`strip.presence`), so an empty submission is nil rather than `""` - two
representations of "unset" in one column is how `name.nil?` ends up wrong half the time.

`admin/users`, `admin/teachers` and the transaction screens keep showing the username, deliberately:
there the account is the subject rather than the person.

**A column header names the column, not one of the things in it.** The roster's header is "Student" and
its cells hold a name over a username. "Student name" would be wrong for a student who has none and
"Student username" would be wrong for the line above it - GitHub, Linear and Stripe all label such a
column with the entity ("User", "Person") rather than with one of the fields in the cell.

**A `<th>` does not name a form control.** A column header names a data cell; an input in a table cell
takes nothing from it. The grade book had **eight unnamed controls** on a two-student roster - four per
row - so a screen reader could not tell a math grade from a reading grade, or whose row it was in. Each
carries an `aria-label` naming the field *and* the student, since a row is only identified visually. axe's
`label` rule catches this and had never been run against the page.

**A column that carries a payment says what it pays.** "Perfect attendance" as a bare checkbox under two
words gave a teacher nothing: not whether it was required, not what it was worth, not why it sits beside
a day count. It is a flat bonus on top of the per-day rate, and the section now says so - with every
figure interpolated from `GradeEntry`'s constants, so the copy cannot claim a rate the model does not pay.

**A short field is one column wide, and the fields still stack.** `width: :half` puts `.tw-field-half` on
the control - `max-width: calc(50% - 0.75rem)`, half the card's content box less half a 24px gutter, so
**351px** of 726px. That is the width a field would have *if* another sat beside it, which is what was asked
for: "half the size of the container and half the size of the padding **were there** another field beside it".

**Three shapes were tried, and the two wrong ones are worth knowing.** Four fixed `max-w-*` sizes were
GOV.UK's content-width rule applied without its layout, and a 128px field above a 384px one aligns with
nothing. A real two-column grid was the same instruction read as an indicative - it pairs the fields, which
costs a second scan line and a judgement per row about which two belong together. Pairing is Tailwind UI's
and Polaris's answer to a *long* form on a wide page; a stack with one scan line is GOV.UK's, and the width
does the work either way.

**Every single-line control takes it; only a textarea and a URL keep the full measure.** Reported after the
first sweep: the create and edit pages did not match the new classroom page, and some selects were one column
and some two. Measured, and the *same field* had two widths on two pages - School and Year were 351px on
`admin/classrooms` and 726px on `admin/school_years`, Classroom was 726 on students and users while
Transaction type beside it on transactions was 351. Nine fields were left behind, because `width: :half` is
opt-in and a field nobody has considered keeps the full measure.

The two exceptions are **readable from the element**: a `<textarea>` by its tag, and the one long single-line
field - a web address - by `type="url"`. That is deliberate. Every other exception in this codebase has been
a name written into a rule, and a named exception is how `portfolios#show` kept a column of dashes through
three sweeps. `form_field_test` walks eleven forms and asserts the width of every control against its own
tag and type, so a new field cannot quietly start full.

The class goes on the **control**, not the wrapper, so the label and hint keep the full measure and a two-line
hint does not wrap into four. GOV.UK puts its width modifiers there for the same reason. Default is `:full`,
so a field nobody has considered keeps the width it has, and an unknown name raises.

**An input in a table cell is sized to its content too**, and that is where this rule was first written: the grade book's days field rendered at **322px** for a value that
cannot exceed two digits, because the column took the table's slack. GOV.UK states the rule and ships
`width-2/3/4/5` modifiers for it. This is the one place overriding the component's width is wanted.

**Sized to content does not mean a different width per field.** All three grade-book fields are `w-24`
(96px): a grade needs two characters plus the chevron's 36px, and two digits plus Chrome's spinner lands
under the same figure. Days was `w-20` - enough for its content and **16px narrower than its
neighbours** - and below `lg`, where the row stacks and every control is right-aligned against one edge,
three controls at two widths read as a misalignment rather than as sizing. Reported that way. Measured
after: Math, Reading and Days attended all `left=246 right=342 w=96`.

**And the segmented control is sized to the field it sits with, not to its own text.** Measured, the
fields were 96x44 and `.tw-segmented` was **89x28** in the same stacked row. iOS and Material both give
a segmented control the height of the field beside it, so it is `min-h-11 min-w-24` with
`items-stretch`, and `min-*` rather than fixed so a longer pair of options grows instead of clipping.

**A yes/no answer is a segmented control, not a checkbox.** `.tw-segmented` in `forms.css`: two native
radios, `sr-only`, with their labels as the visible control - so arrow keys, single selection and the
click target all come from the browser and there is no JavaScript. GOV.UK reserves a single checkbox for
opting in and gives a yes/no question radios; the grade book's tick said nothing about what was being
answered, and a **badge is not an option here at all** because it has no editing affordance.

**The selected segment is a light raised surface, never a brand fill.** iOS raises the chosen segment in
white on a grey track and Material 3 uses a light container tint. A saturated `sitf-primary` chip
repeated down 25 rows is the same over-emphasis the row-action rule forbids for buttons, and it was
reported as looking heavy. Measured: slate-900 on white 16.9:1, slate-600 on slate-100 6.92:1.

**A confirmation has two parts: the question, then what the action actually does.** "Reset Ada's
password?" tells a teacher nothing they did not know when they clicked, and it was reported as exactly
that - *"what happens when the password is reset? Does the student get an email?"*. It does not send one:
`MemorablePasswordGenerator` makes a password, the student's is changed immediately, and the new one is
shown to the teacher **once**, in the flash on the next screen. That is a job the teacher has to finish,
so the dialog says so. macOS pairs message text with informative text, Polaris and GOV.UK both put the
consequence in the body, and `aria-describedby` points at it so a screen reader gets the consequence
with the question rather than after it.

**The body travels in the message string, after a blank line.** It is the only channel there is: Turbo
copies exactly five attributes onto the form it synthesises for a link - `data-turbo-method`, `-frame`,
`-action`, `-confirm`, `-stream` - and passes **no submitter** for one, so a second data attribute on the
link would reach nothing. Splitting on the first newline works the same for a link, a `button_to` and a
helper-generated row action, and degrades correctly: if the controller never connects, native
`confirm()` renders the newline perfectly well.

**Never claim an action cannot be undone unless it cannot.** "Delete Ada? This cannot be undone" was
false on every student delete in the product: `StudentsController#destroy` calls `discard`, and
`User#destroy` **raises** rather than hard-delete a person, so the portfolio, transactions and grade
entries all survive and an admin restores the account from the students list. The sentence a reader most
needs to trust is the one about irreversibility, and a false one there costs the next true one its
credibility. Two more found by checking rather than assuming: `admin/users` "Delete" also discarded (and
**raised in development**, because the guard only steps aside in production), and only
`Admin::TeachersController#destroy` is a genuine `really_destroy!`.

**A confirmation's destructive accept is `.tw-btn-danger` - solid rose.** It is the one place a filled
destructive button belongs, and the reasoning is in "No red at rest" in the Buttons section: that rule is
about a control sitting on a page, and a confirmation is not sitting in wait. A benign confirmation keeps
the brand primary, so the fill is carrying information rather than decorating every dialog.

`:danger_outline` keeps its own home, which is a destructive action **among bordered buttons on a page** -
the grade book's Finalize. The rule that a destructive action matches its neighbours still holds there;
the dialog is the exception, not a repeal.

Cancel is `.tw-btn-secondary`, first in the DOM, and holds `autofocus` - so a stray Return dismisses
rather than deletes, which is Apple HIG's rule and unaffected by the fill.

**A dialog's buttons are trailing-aligned, which is the exception the form-actions rule names.** Cancel
first in the DOM with `autofocus`, accept last: macOS, Polaris, Material and GitHub all put the answer
where the reading ends. Form actions go on the leading edge; a dialog is the other case.

**And a link-driven confirmation carries its verb now.** ~20 of them said "Confirm" because Turbo passes
no submitter for a link. The controller keeps the last element clicked that carries
`data-turbo-confirm`, from one capturing listener - a confirmation always follows the activation that
caused it, and a keyboard Enter on a link fires a click too - so the accept button reads "Delete" or
"Reset password" whatever Turbo hands the hook.

**Show what an irreversible action will do, before it does it.** A teacher finalized a grade book -
depositing real money into every student's portfolio, permanently - with no statement of what it would
pay. `GradeBookEarnings` runs `EarningsCalculator`, the class `DistributeEarnings` pays from, so the
figures are the payout by construction rather than by agreement. The total appears three times, each
doing a different job: the table's `<tfoot>` while working, the finalize block at the decision, and the
**confirmation at the commitment** - "Finalize and pay $5.60 to 2 students?" where it read "Are you sure
you want to finalize these grades?". Stripe's "Pay $X", Amazon's order summary and AWS's typed
confirmations all state the consequence there.

A `<tfoot>` is the element for a column summary and the first in this app. No rule above it: `divide-y`
already separates rows, and the Dividers section forbids adding one where something else separates. The
split by reason lives on the finalize block rather than in the footer, because it matters once rather
than on every keystroke.

**Everything derived from the entries refreshes together.** The autosave response replaced only the
buttons, so the Earns column would have shown what the grades used to earn. It now replaces the row
figures, the column total, the finalize block's split and **both halves of the warning** - that last pair was
missed on the first pass, so correcting the days fixed the data and the notification stayed on screen
still accusing. The cells are replaced by id, not the table, because the cursor is in an input and
swapping the table takes the focus and any half-typed value with it. A conditional block needs an
always-rendered container carrying the id, or there is nothing for the replacement to target and the
message outlives the problem.

**A status pill is words the reader can act on, never the enum's own value.** `status.capitalize` gave
"Draft", and it was reported as unreadable in the exact way that matters: *"I'm unclear whether this is
because the grades have not saved?"*. That is a collision, not a misreading - this page autosaves every
30s, has a "Save grades" button and a live "Saving..." region a few inches from the pill, and "draft" is
the word Docs, Gmail and WordPress all use for **unsaved** work. Stripe can label an invoice "Draft"
because nothing on that screen is autosaving. So the labels are the lifecycle in the page's **own verb** -
the action is "Finalize this quarter", so the states are **not finalized / finalizing / finalized** -
which cannot be confused with saving and tells a teacher what is outstanding rather than making them
learn an enum. `GradeBooksHelper.grade_book_status_badge` is the only definition; the page and the
classroom list each had their own `tones` hash before, which is the drift mechanism, twice.

**Naming a state is not explaining it.** A finalized grade book carried a pill and nothing else: every
input disabled, a dead "Save grades" primary, no finalize block, and no sentence anywhere saying what had
happened or why nothing could be typed - reported as the pill's "utility is unclear as a completed grades
page". The consequence now leads a callout above the table ("These grades have been paid and can no longer
be changed"), and the callout's **title carries the consequence rather than the state**, because the pill
already states the state and a third copy of one fact is what the Dividers-adjacent rule forbids. The dead
primary is not rendered at all - same rule as "Add new students", and note that `assert_no_button` passed
either way, because Capybara does not match a disabled button.

**Two summaries of one set of numbers must state their relationship, or they read as rivals.** The
split by reason and the Earns column are the **same money on different axes** - Earns adds up per
student, the split adds up per reason, and the only figure they share is the corner: $52.60 either way.
That is a cross-tabulation whose middle is never rendered, so nothing on the page makes the connection
visible, and it was reported as *"I still don't understand the distinction between the two or the
relationship between the two"*. **If the relationship between two summaries has to be explained, they
should not both be on the screen** - which is why the teacher's view carries one axis only, and why
the split does not go near the table at any width. Where it does appear, beside the finalize control, it
now opens with a sentence saying what it is: "Each student is paid in three deposits, which is how the
total divides and what their statement will show." That is also the only place the product says a
student receives three deposits rather than one, which is what `DistributeEarnings` writes.

**A label must not mean two things on one screen.** "Math" was a column of letter grades and a line of
money twelve inches apart. The split's labels name what earned the money - "Math grades", "Reading
grades" - for the same reason a figure never travels without its unit.

**The total is information; only finalizing is administrative.** Both were in one
`if current_user.admin?` block, so the teacher entering the grades could not see what they added up to
while the admin who only presses the button could. The total is in the table's footer now, which anyone
who can open the page can see, and each row carries its own figure in Earns. The split by reason is on
the finalize block, because it is what the payment is made of rather than what the grades add up to -
so a teacher sees every figure the grades produce and an admin additionally sees how the payment
divides.

**A section description sits in the heading's column.** It was a sibling of the heading row, so it
spanned the full width and ran under the "Add new students" button at every width. Title and subtitle are
one block with the actions beside it, `items-start` so the action stays level with the title - the shape
`_page_header` already uses.

**A warning gets a summary and a note in place**, which is this app's own form-error shape. An entry
claiming the perfect-attendance bonus with no days recorded is incoherent whatever the quarter's length,
so it can be flagged without the school-days figure the app does not store - and it is not hypothetical,
the seeds contain one. Amber, not the red of a validation message: this is something to check before
finalizing, not a failure.

`grade_book_page_test.rb` measures the surface, the keyboard region, the input widths, the segmented
control, the status, the action alignment and position, the primary count, the chevron inset, the
trailing-column alignment, every control's name, the row figures, the total against what
`DistributeEarnings` actually pays, both halves of the warning, and the confirmation's copy.

### The confirmation dialog

**One dialog, registered globally, for all 28 `data-turbo-confirm` call sites.** Turbo reads
`config.forms.confirm` in `FormSubmission#start`, and a link carrying `turbo_method` becomes a form
submission - so links, `button_to` forms and helper-generated row actions are all covered without
touching a single call site. `Turbo.setConfirmMethod` is deprecated in turbo-rails 2.0.23 and warns; the
config assignment is the current API, and it is called with `(message, formElement, submitter)`.

**A native `<dialog>`, unlike `shared/_modal` and `dialog_controller`**, which hand-roll an overlay and
therefore hand-roll a focus trap, an Escape handler and focus return. `showModal()` gives all of that
from the browser, plus the backdrop and the inertness of the page behind it. A new modal should start
here; the older two are not worth converting today.

**A confirmation's question is its title**, so `aria-labelledby` points at the message rather than at an
invented heading - "Are you sure?" above "Finalize and pay $5.60 to 2 students?" is a heading that says
less than its own body.

**Cancel takes focus and comes first**, so a stray Enter declines a destructive action. macOS, GitHub and
Polaris all focus the safe option. The accept button carries the **verb** from the control that was
pressed ("Finalize grades"), because "OK" makes the reader re-read the question to learn what it does;
Turbo supplies a submitter for a form and not for a link, so a link-driven confirm falls back to
"Confirm".

**If the controller never connects, Turbo falls back to native `confirm()`.** A destructive action must
not lose its confirmation because a script failed.

**Three sizing classes, all on the scale, and each earned:** `inset-x-4` for the 16px page gutter,
`m-auto` because Tailwind's preflight resets `dialog { margin: 0 }` and kills the UA's centring, and
`w-auto` because the UA sets `width: fit-content` and the panel would otherwise be sized by its message.
Measured: 448px centred at 1366px, and 328px with 16px either side at 375px. The first attempt used
`w-[calc(100vw-2rem)]`, which `no_arbitrary_values_test` rejected.

### Sidebar footer

**A footer row is an ordinary nav row, pinned.** Same `px-3` inset, same 4px rhythm, separated
from the list by a full-width hairline. That is what Stripe, Linear and GitHub do: a rule, then a
row that looks like every other row.

The Admin row was in a `py-2` list with **no horizontal padding at all**, so it sat flush to the
sidebar edge while every other row was inset 12px, with an 8px band above it - double the 4px
between nav rows. Neither is visible at rest; the hover highlight draws both, which is how it was
reported.

### Tables: alignment and the primary cell
**A row action sits on the row's first line, which means centre to centre and not top to top.** Reported as
the Edit button on the classrooms table not looking aligned; measured, it was **every table in the app, off
by 7px**. A 32px ghost and a 17px line of text both start at the cell's content edge, so the button's box
top-aligns exactly as this document asks while its vertically centred label lands 6.5px below the row's text.
Top-to-top is not the test - this document already says so for a lone checkbox, where the criterion is
"checkbox center == the name's first-line center", with `mt-0.5` as the mechanism. A control *taller* than a
line needs the same correction in the other direction.

**The correction is padding on the cell, never a negative margin on the control.** `td.table-actions-pinned`
takes `pt-1.5` where the shared cell takes `py-3`. A negative margin would drag the hover fill above the
content edge, which is recorded here three times as the wrong fix. Measured after, on five tables: off by
0.5px, and the row drops from **57px to 51px** - nearer this document's 48px row than it was, because the
32px control plus 24px of padding was what made those rows 57px in the first place.

This is deliberately a cell carrying its own `py-*`, which the note below calls a bug. The distinction is
that it is the shared token for one kind of cell, compensating for a control taller than a line of text - not
an ad-hoc padding at a call site, which is what that note is about and what put one classrooms cell 14px
below its neighbours. `td` only: the same class is on the header, where there is no control to align.

`row_action_alignment_test.rb` measures the centres across both sides of the product, and verifying it meant
putting the 12px back and watching all three tests fail by 6.5px.

**Cells are `align-top`.** As soon as one cell stacks two lines — a company name over a ticker,
a name over an email — middle alignment floats every single-line cell to the vertical centre of
a taller row and nothing shares a baseline. Polaris, Primer, Stripe and Tailwind UI all switch
to top alignment for exactly this. Middle is only safe when every cell is one line, which is not
a property that stays true as columns are added.

**A cell does not override the shared padding.** `table-body-cell` is `px-4 py-3`, and `tables.css`
lives in `@layer components` - so a `py-4` utility on the element **wins**, while the class list still
reads `table-body-cell` and looks like it is using the shared padding. classrooms#index did exactly
that: `table-body-cell py-4` on the Teacher(s) cell, plus `py-1` and `min-h-9` on the badge strip
inside it, all three carried over from an inline `style="max-width: 510px; min-height: 36px"`.
Measured: that cell's text at **28px** from the row top against **14px** for every other column, in a
row **69px** tall against the 48px above. Now 12px padding everywhere, one line, 49px.

A badge still sits ~4px below bare text, because a pill has `py-1` of its own; that is true of every
table in the app and is not worth chasing. Put a badge straight into `table-body-cell` the way the
admin tables do, with no wrapper padding.

**An unlabelled actions column is not rendered when the viewer can never use it.** A dash in an actions cell
means "no action on *this* row", which says something only when another row has one; a column of dashes
communicates only that there is a column. `ClassroomPolicy#edit?` **was**
admin-only, so a teacher's classrooms table was a trailing column of italic hyphens, on every row.
classrooms#index computes whether **any** row has a permitted action and drops the header, the cells and one
from the empty state's `colspan` when none does. (Teachers edit their own classrooms now, so that column
carries Edit for them and the guard fires only for a viewer with no rows at all - the rule outlived the case
that found it.) Asked per record rather than per class, so it stays correct if the policy ever starts
reading the record.

**The test is whether the permission varies by *row*, not whether the page has two kinds of reader** - and
this paragraph got that wrong for a year. It used to cite `portfolios#show` as the case where the dash is
*right*: "gives a non-student viewer the dash where a student gets Trade". That is a gate on the **viewer**,
so the column is all links or all dashes and never mixed - and a teacher or an admin opening a student's
portfolio saw five holdings and five hyphens. It was reported from the rendered page, and it had been
blessed here and in a `table_consistency_test` comment, which is why three later sweeps left it alone.

So ask it as a question about the collection you are about to draw: *would two rows of this table, for this
reader, differ?* If the gate reads the reader rather than the row, the answer is no whatever the gate says.
`dash_column_test` asserts the ratio - dashes strictly fewer than rows - on every table under every role,
which is a check a named exception cannot go stale against.

There is **no mixed column in the app, and no dash left to draw one with.** `classrooms#index` kept a branch
that could not fire - the scope gives a teacher only the classrooms they teach and `edit?` permits exactly
those - and it is gone, along with `.table-no-permission`, which then had no caller. The per-row
`policy(classroom).edit?` check stays, so a scope that widens renders an empty cell rather than a wrong link.

**If a genuinely mixed column ever appears**, the dash is still the right convention for its empty rows and
the declaration is preserved verbatim in migration.md: `.table-no-permission { @apply text-slate-500 italic; }`
- slate-500 because slate-400 measured 2.6:1 and fails AA. Restoring one class is cheaper than leaving a
class nothing renders, which is indistinguishable from a supported one.

`table_consistency_test.rb` measures all of it: one line across a classrooms row, the row height, Edit
present for a teacher and an admin, and the column plus the empty state's `colspan` both dropping for a
viewer with no rows.

**A row's height depends on whether it holds a control.** 48px is the padding-only row; a row carrying a
32px ghost action measures **57px** - 32 plus 24 of padding plus the hairline - which is what
admin/classrooms and admin/users have always measured. Do not "fix" one to match the other.

**One set of cell classes, `table-*`, on both sides.** Eight admin tables hand-wrote
`px-3 py-4` while their headers used the shared `table-header-cell` at `px-4 py-3` - transposed,
so **every column's header text sat 4px off its own data** (measured: `thLeft=281`,
`tdLeft=277`). Admin rows were also 56px against 48px for the student-facing tables. All of them
use `table-header-cell` / `table-body-cell` now: identical padding, columns aligned, 48px rows -
between Polaris's 44 and Material's 52. `spacing_test` asserts a header lines up with its column.

**The primary identifier is body size with medium weight**, not a larger face. The trading floor
rendered its ticker at `text-lg font-semibold` and the transactions table its company name at
`text-base text-black`, in cells whose neighbours are `text-sm` — which made each row read as a
heading and left the table with no single type scale. `font-medium text-slate-900` for the
primary value, `text-xs text-slate-600` for the secondary line beneath it.

### Page surface and chrome
**One page background across the whole product: `bg-slate-50`.** The app used
`bg-sitf-surface` (`#f7f9f3`, a warm off-white) while admin used `slate-50`, so moving between
them changed the paper as well as the furniture. Admin's is the one that stayed, because the
neutral reads as chrome rather than as a brand statement and the cards on it are white.

**The app bar is `bg-white` with `border-b border-slate-200`**, in both layouts. Fixed chrome
against a scrolling page is the one place a rule is structural — see Dividers. This replaced a
full-width 1px bar in `sitf-primary-dark` (8.5:1, body-text weight for furniture) and then,
briefly, a `shadow-xs`, which only existed because the header was the same colour as the page.
With the header white on a slate-50 page it is not.

**Sidebars are `bg-white border-r border-slate-200`** — see Sidebar navigation.

`--sitf-background` / `sitf-surface` is now unreferenced. It stays defined as part of the brand
palette but nothing should reach for it as a page background.

### Inline links
**`.tw-link`.** `sitf-primary-dark`, medium weight, underline on hover rather than always, and a
named focus outline. 9.01:1 on white, 8.61:1 on the slate-50 page.

Before this, 34 links hand-wrote a generic Tailwind blue — `text-blue-600 hover:text-blue-800`
plus blue-700, blue-800 and blue-900 variants — while newer code used the brand teal. Two link
colours in one product. **Contrast was never the problem** (blue-600 is 5.17:1 on white); brand
consistency was, and a literal repeated 34 times cannot be kept consistent by attention. Same
reasoning as `.tw-card` and the button classes.

Swept with it: the breadcrumb hover, the selected filter tab (which used generic blue while the
nav's selected row used the brand), and the checkbox accent colour. **Blue that stays** is
categorical rather than interactive — the `:info` badge tone, and the hue-coded KPI icon tiles,
which design.md sanctions.

One rule caught while sweeping: the student show page still coloured its stat **numerals**
(`text-blue-900`, `text-green-900`, `text-purple-900`). The KPI entry is explicit that a numeral
is always `slate-900` and never carries state; the tile carries it. Fixed.

### A column earns its width against 718px

**That is the number, and it is not 1366.** At 1024px - Tailwind's `lg` minimum, a docked Chromebook window,
and the width where every column hidden below `lg` reappears at once - the sidebar takes 256px and a table's
scroller is **718px**. Measured there, `admin/stocks` wanted 927px, `admin/teachers` 895px and `admin/users`
853px, so the trailing actions column sat off screen on all three. Nothing about it showed at 1366px, where
every one of them fits, or at 375px, where the row collapses into a single cell.

**The answer is fewer columns, not another breakpoint.** Two tiers is the policy, and a third would only have
hidden the problem at one more width. What came off, and the rule each removal follows:

- **`ID`, from all seven indexes that had one.** 62px, and it is in the URL of the link in the same row.
- **A column that duplicates another.** `Teacher#sync_username_from_email` sets `username = email`, so the
  teachers list printed the same string in two columns. The name leads that table now.
- **A creation date** on a staff list. Metadata belongs on the record page's summary line.
- **A yes/no beside the column that could answer it.** `Admin` was a badge next to `Type`, which said "User"
  for the one account that can do everything; `Type` reads the role through `account_role_label` now.
- **Two state columns become one.** Classrooms had `Archived` and `Trading enabled` as separate yes/no
  columns - 236px to answer two questions with "Yes". One `Status` column states the state in words, and
  archived outranks trading because an archived classroom's switch position is moot.

**What does not come off:** a column that is the only place a state is visible. `admin/stocks#index` lists
`Stock.all`, so its `Archived` column is the only thing telling an archived row from an active one - dropping
it would have hidden real data, and the two columns above it were enough.

**And `break-words` does not shrink a table column.** An email is one unbreakable token, so it sets the
cell's min-content width and the table sizes to it. `overflow-wrap: break-word` does not change a min-content
contribution - `overflow-wrap: anywhere` does, which is Tailwind's `wrap-anywhere`. That distinction is the
whole difference between a table that fits and one that scrolls, and it is invisible in the class list.

`table_actions_reachable_test` asserts no admin index overflows at 1024px, with a fixture whose emails and
names are long enough to matter, and its failure message names the columns and their widths - because "+58px"
does not tell you which column to argue with, and it is never the one you assume.

### A column whose meaning is fixed and whose scope is stated
**One column, one meaning; the viewer decides only the denominator.** The trading floor's `Held by`
answers *who owns this, among the people you can see* - and `ClassroomPolicy::Scope` decides who that
is, resolving to every classroom for an admin and to their own for a teacher. The alternative, a column
that exists for one role and not another, is two rules and a page that changes shape depending on who
opens it. Which is what it was: a teacher's trading floor was two columns, because
`StockPolicy#show_holdings?` requires a student with a persisted portfolio, so the holdings column and
the Buy/Sell cell were both removed. Nobody designed that page - it was the buy list with the buying
taken out, and a teacher cannot open `/admin/stocks` to find a better one.

**A relative figure needs its denominator named, in the section's description.** "4 of 25" is unreadable
without knowing which twenty-five, and the twenty-five differ by role. The sentence goes under the
section heading and above the table, where this document already puts a section's explanation - not in a
tooltip, not in a legend, and not repeated in every row. The word goes in the header (`Held by`), the
scope goes in the description, and the cell carries only the figure: "9 of 25 students" down twenty-five
rows is twenty-five copies of the denominator.

**That sentence carries no numbers.** The first attempt read *"Held by counts owners across 1 classroom -
3 students with a portfolio"*, and it is worth keeping as an example of three failures in one line:

- **Three ideas.** What the column is, how wide the scope is, and how the denominator was derived. Two is
  the limit for a line of helper text, and the cell already states the figure - so this only has to say
  *whose* figure it is.
- **A count that reads as a defect at one.** "across 1 classroom" is grammatical and looks like a bug.
  Any interpolated count has to be checked at 0, 1 and many; the cheapest fix is usually not to state it.
- **Vocabulary from the schema.** "students with a portfolio" is a phrase from `portfolios`, not from a
  staffroom - and it was describing a distinction the model does not really have, since `Student` has
  `after_create :ensure_portfolio`.

It reads "Held by shows how many of your students own each one" for a teacher and "...how many students
own each one, across every classroom" for an admin.

**A UI label inside prose is set off from it.** Unmarked, "Held by shows how many..." is read as a
preposition and then re-read as a label - a stumble on every visit. Microsoft's and Google's style guides
both say to bold the name of a UI element in running text; this is the first place in the app that names
one, so it is the convention here now:

- **`tag.b`, never `<strong>`.** The HTML spec reserves strong for *importance*, which a screen reader
  stresses; `b` is for "stylistically offset" text, and its own examples are product names and keywords.
  A UI label is exactly that, and assistive tech needs no help here anyway - the label is a real `<th>`
  on the column it names.
- **`font-medium text-slate-700`, not bold.** This is `text-sm text-slate-600` helper text and a full
  bold shouts in it. One step of weight and one of colour offsets the label and nothing more. Measured:
  weight 500 against the prose's 400, and 10.36:1 on the page.
- **No colon after it.** The weight already marks the label, and a colon turns the clause into a glossary
  entry - "Held by: how many of your students own each one" - which is right for a list of definitions
  and wrong as the tail of a sentence. Use one signal.

**A count on one page must be the count on another.** The denominator was students *with a portfolio*,
which disagreed with the roster a teacher would check it against: `Classroom#students` is scoped
`-> { kept }`, so a discarded student is off the roster and their portfolio was still in this figure -
the roster said 2 while the trading floor said "2 of 3". Count the thing the way the page that owns it
counts it, and keep the numerator inside the denominator, or "3 of 2" is reachable.

**A number and its noun have to agree.** `share_count` formats a figure and nothing pluralised the word
beside it, so a single share read "1 shares" in every cell that showed one. `shares_label` does both -
and only *exactly* one is singular, because a fractional holding is plural.

**And a description addresses whoever is reading it.** This one was "Companies you can buy shares in
right now" for everybody, including two roles that cannot buy anything. A description that addresses the
wrong person is worse than none: it tells them the page is for them and then does not behave that way.

**Zero is stated, and no-one-to-count removes the column.** A stock nobody owns reads `None`, because an
empty cell reads as missing data while "nobody owns this" is a fact. But a viewer whose scope contains
no portfolios at all loses the column and the sentence entirely - a column that can only ever report
`None` is not a column, which is the rule that removed a teacher's trailing column of dashes from
`classrooms#index`.

**Secondary facts about an entity go in its identity cell, not in new columns.** The exchange and the
industry are both in the primary cell - line one is the security (`KO . NYSE`), line two the company and
what it does (`The Coca-Cola Company . Beverages`), which is how Bloomberg, Yahoo Finance and Google
Finance render an identity block. Industry was previewed as a column and moved for two measured reasons:
it is populated on 10 of 10 active stocks and 0 of 8 archived ones, so a column would be empty on every
archived row; and a column present on one of two stacked tables and absent on the other gives them
different geometry, which moves every column at the boundary. In a cell an absent value costs nothing.

**A header that names a field its column does not contain is a bug.** This one said "Company (exchange)"
from the day it was written and never rendered an exchange, while `stock_exchange` sat populated on every
active stock and was shown only on `stocks#show`.

### A card's header, and when a page has one card
**A single-card form has no card heading.** Ten admin forms opened with an `h3` naming the record type -
"Teacher details" under a page header reading "Edit teacher", 24px apart, in two sizes. Polaris drops a
card's header when the page has one card, and the page title has already named the thing. **A heading
earns its place the moment there are two**, where it is what separates them - `admin/students` and the
school-year form both have two, and both keep theirs.

Those ten also hand-rolled the surface as `<div class="tw-card"><div class="p-5">`, so it was declared
eleven times. They render `components/ui/_card`. The value stays `p-5`: the document decided it, the app
is consistent with it, and the case for `p-6` would have to be that a form is measurably cramped - it is
not, `p-5` leaves a field 286px wide at 375px against `p-6`'s 278px.

### A figure inside a card, or as one
**`_stat` renders its own card by default and takes `surface: false` when it should not.** A strip of
separate cards is right where the figures *are* the summary and stand alone - the portfolio page. It is
wrong where they are one section among several: four `_stat` cards on `classrooms#show` took that page
from two surfaces to six, which is the card-soup shape its own test forbids. Four figures in one card
instead.

That test now asserts the rule rather than the number it happened to be: **one surface per section, never
one per item.** A bare `<= 2` fails when a legitimate third section arrives, which teaches you to raise
the number rather than to ask the question.

### Where a class summary goes
**At the foot of `classrooms#show`, under the grade books.** `ClassroomFacade#stats` computed four
figures on every teacher's and admin's visit and no template read them. They are not at the top, and that
is measured: the viewport is 625px on the target Chromebook, the roster's first row starts at 270px, and
a four-across band is 134px - one above the roster once put the first student at 567px of 625px. Below
the work is where "how is this class doing?" is actually asked.

The facade sums **cents** now. It summed `calculate_total_value`, which is already `cents / 100.0`, so it
added a float per student - and integer cents are authoritative here.

### A confirmation is a question and a consequence
**Every one of them.** Twenty-nine call sites passed a single string, so the dialog's body stayed hidden
and each was a one-line confirmation that could only restate the button - three of them said no more than
"Are you sure?". They are all two parts now, and `confirmation_copy_test` reads the rendered attribute on
every page that carries one, because most messages are built by a helper and a grep of the source cannot
see them.

Three rules came out of writing twenty of them:

- **Say what is kept, not only what is lost.** "They lose access immediately and leave this list.
  Everything attached to the account is kept, and an administrator can restore it" is a different decision
  from the same sentence without its second half. Most of these actions are reversible and read as though
  they were not.
- **Name the real consequence, not the record.** Deleting a portfolio transaction does not delete a
  record a student will never look at - a balance is **derived from** the transactions, so it says whose
  balance will move, by how much, and in which direction.
- **Distinguish the reversible from the irreversible in the words.** Deactivating a teacher discards;
  `really_destroy!` does not, and only one action calls it. Both used to end "this cannot be undone",
  which made the true one unremarkable.

And **a message shared by several call sites belongs in a helper.** The classroom archive/activate pair
was written twice and had already drifted into two wordings; the teacher actions were in three files with
three; the generic delete in three shared partials with three. `classroom_toggle_confirm`,
`teacher_*_confirm` and `delete_confirm` are one sentence each now.


`shared/_confirm_dialog` splits its message on the first blank line: the question becomes the title, what
follows becomes the body. **Passing one string means the body stays hidden**, and the dialog is then a
one-line confirmation that can only restate the button - which is the shape its own note was written to
prevent. Finalizing did exactly that: "Finalize and pay $12.00 to 2 students? This cannot be undone." all
in the title. It is "Finalize these grades?" with the consequence beneath it now.

**The consequence is one sentence, rendered in both places.** `finalize_consequence` is called by the
card and by the confirmation, so a preview and the thing it previews cannot come to describe one payment
two ways - the same rule this document already applies to the figures themselves.

**An irreversible action is not automatically a destructive one.** The accept button stays the brand
primary: finalizing pays students and locks entries, and nothing is lost. Stripe's "Pay $X" is a primary
button, and the rose `.tw-btn-danger` is reserved for a confirmation that destroys something. The
irreversibility is carried by the sentence, and by Cancel holding `autofocus`.

### Two actions on one page need an order, and the order has to be true
The grade book has **Save grades** and **Finalize grades**, and it expressed no relationship between
them. Reported as not knowing you had to do both, and as inconsistent that one sits inside a card and
the other does not.

**The placement was not the bug.** Each was following a rule that holds: a *form's* actions go on the
leading edge below the card, on the page background, and Save is the grades form's submit; the finalize
block is a decision panel and its button is that section's own action. Two correct rules can still
produce a page that reads as arbitrary - and moving either one to match the other would have broken a
rule to fix an appearance.

**What was actually missing was sequence, and it was not only cosmetic.** Finalizing pays whatever is in
the *database*. The page autosaved on a 30-second timer and nothing else, so a teacher could type a grade,
press Finalize inside that window, and pay the previous one, with nothing on the page saying so.

- **Close the window rather than warn about it.** Saving when a field loses focus means nothing typed is
  unsaved by the time the hand reaches Finalize. The interval stays as a backstop for a field left
  focused, which never blurs.
- **Say the state, next to the control that changes it - and then stop saying it.** "All changes saved"
  sits beside the Save button. It was in the page header 400px away and blank until the first save, which
  is precisely what an unsaved page looks like.

  **An autosave indicator that reports every save is noise.** Measured, this changed three times per
  edit - "Saving…", "All changes saved", then a new timestamp - which on a 25-student book is about three
  hundred redraws in one spot while a teacher works, each pulling the eye to a place where nothing
  happened. Docs, Notion and Figma all keep the steady state quiet and unchanging, and none of them counts
  saves at the user. So: **no timestamp ever** - "when" is not the question and it was the churn;
  **"Saving…" only after 800ms**, so an ordinary save changes nothing on screen; and **a failure that says
  so and stays**, which is the only state a teacher must act on and the one thing this never handled.
  Measured after: **zero** redraws per edit.

  The same rule applies to any `aria-live` region: assigning the same string still replaces the text node,
  so it re-announces. Compare before writing.
- **The section's heading is its button's words** - "Finalize grades". It read "Then finalize the quarter" while the button
  said "Finalize grades" - two names for one action, and "Then" opens a heading with a sentence fragment.
  A heading is a label, not a step in a sentence; the sequence lives in the line under the consequence,
  which is where it was already doing the work.
- **Do not swap the emphasis.** Making the irreversible payment the page's filled primary reads as the
  obvious fix and is backwards: on a page for entering grades the frequent action is saving, and a red
  or bright terminal action at rest is the always-on alarm this document rules out.

**And a timer must not be able to click a control that spends money.** Both buttons carried
`autosave_target: "button"`; the autosave clicks `buttonTarget`, the *first* matching target in the DOM.
That was Save only because the finalize card renders after the table - moving it above would have had a
thirty-second timer pay the students. A single target now, asserted by name.

### A second field is not always a duplicate
**Perfect attendance stays a checkbox the teacher ticks**, beside the day count they type. It looks like
one fact answered twice and it is not: the app does not know how many teaching days a quarter had, so
"did they attend every day" is **input**, from a teacher who may be taking the register in another system
entirely. A field the app cannot compute is not redundant with one it can.

This was built the other way first - a `quarters.school_days` column, derivation, and a freeze at
finalize - and reverted. Both halves of the reasoning were wrong, and both are the kind of wrong worth
recognising again:

- **The evidence was seed data.** An entry flagged perfect with nil days, another treating 3 days as
  perfect. Presented as the app contradicting itself; they were fixtures. *Check whether a contradiction
  exists in data a person actually entered before designing it away.*
- **The cost compounded, and each piece fixed the previous piece's problem.** Deriving needed a
  denominator, which needed an admin form, which created a dependency from outside the grade book, which
  needed freezing at finalize, which left unfinalized books exposed, which needed an impact preview on
  the school-year form. **When each new piece exists to contain the last one, the first piece is the
  problem.** And the default state of all of it was identical to the checkbox, because nothing changed
  until somebody entered four numbers per school year that nobody was being asked for.

What catches the one contradiction the app can actually see - a bonus claimed with no days recorded - is
`GradeBookEarnings#unattended_bonus_entries`, which predates all of it, needs no new data, and puts the
question in front of the person who can answer it at the moment they can answer it. **The app already had
the answer**, which is the thing to look for before adding a column.

### An environment ribbon, on staging only### An environment ribbon, on staging only
**A strip above the header, never in the content**, because it describes the application and not the page
- GitLab's environment ribbon and Shopify's development-store banner sit in the chrome for the same
reason. No dismiss: only an *outcome* removes itself, and the environment is still true in a minute.

**Not in development.** The URL already says localhost there, and a permanent stripe on every page of
every working day is noise that teaches you to stop seeing it - which is exactly what would make it
useless on staging, where it is seen rarely and has to register.

Its geometry lives in `EnvironmentHelper` and nowhere else: the ribbon is 32px, so the fixed header, the
admin drawer and `main` each read their offset from it. Two copies of that arithmetic is the drift this
document keeps recording.

### A list nobody can act on
**The trading floor shows an archived stock only to someone who holds it.** It used to list every
archived stock inside `Stock::LIST_RETENTION` behind a disclosure, for every reader - a price list of
companies nobody on that page can buy. Retention made it defensible; it never made it useful. A student
who holds one must be able to sell it, which is the only action the data supports, and a teacher who
wants the catalogue has `/admin/stocks`.

**And a reversible action needs its reverse.** `admin/users` archived and nothing un-archived: the
students and teachers lists have their own restore, so a user who is neither had no way back, and the
list had no archived filter to find them in. Both now, which is also what turns a row with no action into
a row with one.

### One builder, and the shape it enforces
**Every entity form on both halves is `Ui::FormBuilder`.** It was `Admin::FormBuilder`, and the name was
the problem: nine admin forms were built from it while the app half wrote its fields out by hand and the
four Devise pages used a third builder entirely. All three agreed on tokens and disagreed on
construction - which is the drift mechanism this document keeps recording, and it had already produced
its result: sign in and sign up kept a 40px `rounded-md` field while every other form moved to 44px
`rounded-lg`, because a builder that prepends its own base to whatever `class:` it is handed wins on
utility order. Measured after the conversion: 44px and an 8px radius on every form in the app.

**The shape is label, hint, input, error.** GOV.UK, Polaris, Carbon and Material all order it that way -
the hint tells you what to type *before* you type it. Two app-side forms had the hint below the control;
that is the hand-written shape and it is gone.

Four things the builder had to learn from the forms it replaced, all of which a conversion would
otherwise have quietly dropped:

- **A required indicator.** The hand-written forms marked required fields and the nine admin forms did
  not, so on that half nothing distinguished a field you must fill from one you may.
- **A `<fieldset>` with a `<legend>` for a group.** A `<label>` has to point at one control and a group
  has none, so the group had no accessible name at all. `errors_on:` goes with it: a group's errors are
  often on a different attribute than the one it posts - `grade_ids` posts, `grades` validates - and
  without naming both, the fieldset is never marked invalid and its message never renders.
- **The hidden empty value ahead of the boxes.** Without it, unchecking everything omits the parameter
  and the record keeps what it had: clearing a group silently does nothing and reports a save that
  worked.
- **A checkbox row is a `<label>` wrapping its box**, not a `for=` across two sibling divs. Both are
  valid HTML and GOV.UK does the latter; wrapping makes the row's whole width a hit target, which
  matters for students on phones.

**A custom label owns its own typography.** `collection_check_boxes` accepts a callable for the label
text - the teacher picker renders a name over an email - and the builder does not impose `font-medium`
on it. A weight on the wrapper made the email fight back with `font-normal`, a rule whose only job is to
undo another rule, and it made the wrapper rather than the first line read as "the label".

### One form per model, not one per namespace
**A model gets one form, rendered wherever it is needed.** `/classrooms/new` and
`/admin/classrooms/new` were two forms for one model and had drifted into two products: one asked for a
school and a year, the other for a single school year; one offered the teacher assignment, the other had
none; one led with an `h3` restating the page title. An admin got different fields depending which URL
they arrived through, and the admin half - the one whose job is administration - was the half that could
not assign a teacher, because its hand-written parameter filter had never permitted `teacher_ids`.

They render `classrooms/_form` now. **What varies is only what must vary**: the URL it posts to and where
Cancel goes, both passed as locals. Everything else - which fields exist, in what order, with what
validation - is one decision. The controllers share a concern for the data and the parameter handling,
because a shared partial only works if both sides agree about what it posts.

**The industry-standard field shape is label, hint, input, error** - GOV.UK, Polaris, Carbon and Material
all order it that way, and the admin builder already did. That is why the admin form read better: the
hint sat under its label, above the control it governs, and every field had one. It is the shape to keep.

### Validate the fields the form has
**An error must land on a control the reader can see.** `Classroom` belongs to a SchoolYear and no form
asks for one - both halves offer a **School** and a **Year**, and the pair is found-or-created - so
every failure reported "School year must exist" with neither select marked. The reader was told about
something that is not on the page.

`SchoolYearFields` accepts what the forms post: `school_id` and `year_id` are virtual attributes,
resolved into the association on validation, and the validation is on them. Three details are decisions:

- **The readers fall back to the association only when nothing was assigned.** Falling back always means
  an empty select silently keeps the old value and reports a save that worked.
- **The association satisfies the check when it was assigned directly** - a seed, a factory, a console.
  Those hand over a SchoolYear whole, and it may be unsaved, so checking its ids rather than its presence
  would fail a valid `build`.
- **`find_or_initialize_by` with `autosave`,** not find-or-create before the save. The controllers used
  to resolve it eagerly, which left an orphan SchoolYear behind every failed submit.

**A required field says so, and an optional one does not.** The mark is the red asterisk on the label -
`.required-indicator`, red-600 at 4.83:1 on white, where red-500 measured 3.76:1 and failed AA - plus
`required` on the control, which is what assistive technology announces. The asterisk is `aria-hidden`, so it
is not read twice. Pass `required: true` to the builder and both appear together.

**Both directions are the same defect.** A field marked required that the model would accept blank teaches a
reader to distrust the asterisk; a field the model rejects with no mark makes them find out by submitting.
Nine of eighteen forms were in the second state - a school's name, a stock's ticker, an announcement's title
and content, a school year's school and year, a teacher's email, a user's username and password, and every
field on both money forms. `test/integration/required_fields_test.rb` asserts the pairing per page, including
that an optional field carries no asterisk.

**Where the requirement is conditional, so is the mark.** `User#email_required?` is true for a teacher or an
admin and false for a student, so the profile page passes `required: current_user.email_required?` and the
asterisk appears exactly when a blank would be rejected. Guessing either way would be wrong for half the
users.

**`required` is not what stops the submit here** - native validation is off app-wide so the app's own error
summary can render - so a mark with no model validation behind it is decoration. When you add the mark, check
the validation exists; that is how `PortfolioTransaction`'s missing `transaction_type` and `amount_cents`
checks were found, both `null: false` columns whose blank submit produced a 500 rather than a message.

**Validate what the form claims.** The admin student form's classroom select carried the hint "Classroom
assignment (required)" and `belongs_to :classroom` is `optional: true`, so nothing required it. Saving the
blank was accepted and it broke the list the student was saved into - `admin/students#index` rendered
`student.classroom.name`, so one classroom-less student returned a 500 for the whole page. A field that says
required is required, on the label (the asterisk, `required: true`) and in the model; and a hint does not
repeat it, because a requirement is stated once.

**The requirement goes on the path a person types on, not on every create.** `Student` validates `name` and
`classroom_id` `on: :student_form`, which the two forms opt into with `save(context: :student_form)`. CSV
import and the seeds build students without a name and must keep working. Read the note in `Student` before
widening one of these to `on: :create`.

**Money is typed as text and stored as integer cents, and the parse has to be exact.** The admin's cash
adjustment did `(amount.to_f * 100).to_i`. Measured across every typed amount from $0.01 to $1000.00,
**4,586 of the 100,000** stored the wrong number of cents, always one low: $0.29 became 28, $1.15 became
114, $2.01 became 200. `BigDecimal(amount) * 100` is exact. This is the same float round trip the Money
section forbids in the other direction, in the one place a person types money into this app.

**A blank check cannot see a bad value.** The same form's validation asked only whether each param was
blank. `"abc".to_f * 100` is `0`, and `0` is not blank - so a typo deposited $0.00 and reported success;
`"-50"` was accepted as a negative deposit; and an amount past the integer column's 2,147,483,647 cents
raised `PG::NumericValueOutOfRange` from the insert, a 500 from a typo in a text box. Money has a shape:
digits, optionally two decimal places, bounded. `numericality` is not that shape - it accepts `1e3`,
`0x10` and `12.345`, and "is not a number" does not tell anybody what to type.

**Fields that are not a model's attributes get a form object.** Four loose params checked in the controller
and reported by `redirect_to ... alert:` put the message at the top of the page, threw away everything
typed, and could only ask whether a value was blank. `CashAdjustment` is an `ActiveModel::Model` with the
four fields, so each one carries its own error through `field_error_proc` like every other form in the app,
and a rejected submit re-renders the page with the values still in it. **A rejected form re-renders; it does
not redirect.**

**A picker offers what the validation accepts, from one list.** `CashAdjustment::REASONS` is the enum's keys
minus the one the model marks deprecated, and both the select and the `inclusion` validation read it. The
form had been offering `grade_earnings` - "Deprecated, will be removed in future" - which is how a
deprecated value stays alive: something still writes it.

**Native browser validation is off app-wide** (`app/javascript/application.js`), which is what lets the
app's own summary and field messages render at all. `required` stays on the input for assistive tech and for
the label's asterisk; it is not what stops the submit. Opt a form back in with `data-native-validation`.

### One field-level message, from one place
**A field shows one message.** Every invalid admin field showed **two**: "Name can't be blank" from
`config/initializers/field_error_proc.rb` and "can't be blank" from the form builder's own
`error_message`, in different colours, each with its own icon. The builder's is gone; the proc's is kept,
because it carries the attribute's name - so the field and the summary say the same thing - and because
it is the component the other half of the app uses.

The exception is a **checkbox group**, which the proc skips deliberately: a group's error belongs to the
group, and Rails would otherwise attach it to whichever box it rendered first. Those call
`FormErrorsHelper#field_error`, the same call the hand-written fieldsets make.

`.tw-field-error` went with it. It was the second definition of a field message - red text, no icon -
and once nothing referenced it, an unused class is indistinguishable from a supported one.

**One problem produces one error.** `Classroom` had a custom `school_year_presence` adding a `:blank`
error on `school_year_id` for the thing `belongs_to :school_year` already reports on `school_year`, so a
summary listed "School year must exist" and "School year can't be blank" for one empty field.

**Every form has an error summary.** Nine admin forms had none: a failed submit marked the fields and
said nothing at the top, so on a long form the reader had to hunt. `shared/_form_errors` is on all of
them now, which also retired the builder's `base_errors` - a second list of the same errors.

### Environment banner
**A destination that is not part of the product says so on the page, in a sentence - never by
recolouring its nav row.** The component demo was a purple row in a sidebar section headed
`Development`, explained as "deliberately off the shared treatment so it is obviously not a production
destination". Three things were wrong with that, and only the first is about colour:

- **The sidebar has one colour vocabulary and it means "you are here".** A second meaning competes with
  it. Measured, purple-700's chroma is 0.265 against slate-700's 0.044, so the idle demo row was about
  six times more saturated than the ten real rows and read louder than the *selected* row of the section
  you were actually in - the loudest thing in the admin nav was a link that does nothing in production.
  Contrast was never the failure: 7.07:1 idle, 5.54:1 on the icon, 6.58:1 on the active tint.
- **A hand-rolled row drifts.** It kept `min-h-11 py-2` with no `lg:` step after `NavHelper` moved a
  desktop row to 36px, so it rendered 44px against every neighbour's 36px.
- **A nav row has only colour to say it with.** A page can use words, which is where the field puts
  this: Stripe banners the page in test mode rather than recolouring the navigation, GitLab's
  environment ribbon sits on the page chrome, and GOV.UK's phase banner - the closest documented match,
  since it exists to say "this is not the finished product and here is what that means for you" - sits
  above the page's own heading.

The banner is `components/ui/_callout`, `tone: :warning`, first element in the page, `mb-6` above the
header block. Three rules in it:

- **It names the environment rather than hard-coding one**, so it reads "Test environment" in the suite
  and cannot go stale if the guard changes.
- **Amber, not blue.** Amber is the field's colour for "you are not in the real thing", and one line of
  it is a genuine caution: the examples are real records out of this database.
- **No dismiss and no auto-hide.** The environment is still true in a minute, and this document's rule
  is that only an *outcome* removes itself.

**And guard the route, not just the link.** The demo's routes were declared unconditionally while only
its nav row was wrapped in `Rails.env.development?`, so on production `/admin/component_demo` was a live
page for any admin, listing ten real users and their email addresses. `Rails.env.local?` on both - which
is development and test, excluding staging - makes the claim true *and* lets the suite render the page.
The old guard is why none of this was caught: the row and all three pages were invisible to every test
in the repo.

### Sidebar navigation
**One light sidebar, both sides of the app.** `bg-white` with a `border-r border-slate-200`,
`text-slate-700` idle, `hover:bg-slate-100`. The selected row is a brand tint plus a 3px
leading indicator: `bg-sitf-primary/10 text-sitf-primary-dark` with
`border-l-[3px] border-sitf-primary`. Measured **7.78:1**. **Ten rows is the ceiling, and it is exact.** Measured on a 1366x768 Chromebook, the ten product rows
fill 561px of 561px of available height - no slack at all, so any structural addition needs a structural
removal. Measured against that ceiling:

| | sidebar | overflow |
|---|---|---|
| ten product rows | 561 of 561 | 0 |
| a `Development` section with one row | 628 of 561 | 67px |
| a group of two under a subheader, with `View site` moved down beside it | 668 of 561 | 107px |
| that group, with Students / Teachers / Users collapsed to one row | 588 of 561 | 27px |
| and the one-item `Content` subheader dropped as well | 568 of 561 | 7px |

A footer row here was rejected earlier on the same measurement, at 68px. **A product section that does
not fit means the sections need rethinking, not loosening** - three of those rows are one table and two
STI subtypes of it, and one filtered list is what the field ships for that.

**A developer tool does not go in the navigation at all** - not the sidebar, and not the top bar either.
Storybook is a separate application; Polaris, Primer, Lightning, Material and Carbon are separate
documentation sites; Rails' own `/rails/info` and `/rails/mailers` are live routes that nothing links to.
The component gallery is reached by URL, documented in `README.md` and `design-instructions.md`. **A
destination out of the product is a different class of thing** and does belong in the top bar, which is
where WordPress, Django, Shopify and Craft all put `View site`. Grouping the two under one `Development`
subheader - the intuitive proposal - mislabels the most-used link in an admin as a development tool.

`spacing_test` asserts both the fit and that every row is the same height.

`NavHelper` holds the treatment -
`nav_row_class`, `nav_indicator_class`, `nav_icon_class` - so the app nav and the admin nav
cannot drift apart.

A light sidebar is what current practice means: Stripe, Shopify, GitHub, Notion, Vercel,
Linear, Material 3's navigation drawer. Dark sidebars survive in full dark themes, as
deliberate brand statements, and in dated admin templates. **Brand presence lives in the
logo, the primary buttons and the selected indicator, not in the panel.**

What this replaced: the app sidebar was a saturated `sitf-primary` panel whose selected state
was a full fill in `sitf-accent` — the lime `#D3DF44` that the token file labels *fill only,
never text or icons*, because it is 1.46:1 on white. It was readable as a background (8.80:1
with `#323232`), so this was a judgement about role: the loudest colour in the palette was
carrying the most repeated state in the app. Meanwhile admin was already white **with no
selected state at all**, so the two halves of one product looked like two products, and in
admin you could not tell which section you were in.

- **`aria-current="page"` on the selected row, always.** A tint and a bar are colour alone
  (1.4.1), and it is what a screen reader announces.
- **Nav rows are 44px** (`min-h-11`). A nav row is a bare tap target, which is where the 44px
  figure applies — unlike buttons, which are on the 40px token.
- **Icons are `lucide_icon`, inheriting `currentColor`.** They used to be external SVG assets
  tinted by two CSS `filter` chains in `navbar.css`, which existed only to force them white on
  the dark panel. Both are deleted.
- **Both sidebars are 256px** (`w-64`). The app one was 200px, so the switch to admin moved the
  content edge as well as changing the colour.
- **A section is current when the request is inside it**, so a show or edit page keeps its
  parent row lit. `nav_section_active?` takes `exact:` for the Dashboard, because `/admin` is a
  prefix of every admin path and "inside it" is true everywhere.

**Nav row density: 36px on a desktop sidebar, 44px in the drawer.** `min-h-11 lg:min-h-9`,
`py-2 lg:py-1.5`. A desktop sidebar row is 32-36px across the field - Notion about 27, Linear 28,
GitHub and Stripe 32, Tailwind UI and Polaris 36 - while 44px is the touch figure and Material's
56px drawer is mobile-first. WCAG 2.5.8 (AA) asks for 24x24, so 36px clears it with room, and the
44px AAA / Apple HIG figure is kept where the finger is.

Holding 44px at every width made the ten admin links **636px against 561px of available height on
a 1366x768 Chromebook, so the sidebar scrolled**. At 36px, with section groups at `space-y-4` and
headings at `mb-1`, it measures 561px and fits. Both figures measured, before and after.

`test/system/spacing_test.rb` asserts the admin sidebar does not overflow a Chromebook viewport,
because the default test window is 1400px tall and no real screen is - a sidebar that outgrows a
short viewport is invisible at the size tests normally run.

**Keep the nav one level deep.** Every row is a flat link. Do not expand one item into a
sublist while its siblings stay flat: the nav then has no consistent shape, and the expanding
row ends up holding several controls at once.

The Trading floor row was the reason for the rule. It was a `<details>` whose `<summary>` held
**both** a link and a chevron button, so one 44px row carried three overlapping affordances —
the summary toggled, the link navigated, the button toggled — and a Stimulus controller existed
purely to stop them fighting (`stopPropagation` on the link, `preventDefault` plus a manual
`open` flip on the button). Its sublist rendered one row per active stock, so the sidebar grew
with the catalogue. It is a flat link now; the controller and its chevron CSS are deleted.

**A catalogue does not belong in the nav.** Navigation is for destinations; records live on the
page that lists them. The standard ways to reach an individual record quickly, in rough order
of how common they are:

1. **Search and filter on the list page.** The list page owns discovery — this is what almost
   every product does for a catalogue of any size, and it is the one that scales.
2. **A command palette** (`⌘K`) once the catalogue is large enough that scanning is slow —
   Stripe, Linear, GitHub, Notion.
3. **Recently viewed**, bounded and per-user — Shopify, Salesforce.
4. **Pinned or favourited items**, where the user chooses what earns a nav row.

What none of them do is put every record in the sidebar. If a nav row genuinely needs children,
cap them at something bounded and user-specific — here that would be *stocks this student
holds*, not every stock that exists.

For this app the answer is (1): the trading floor page already lists stocks in labelled active
and archived tables, and the portfolio links to each holding. Recorded as done in
[`migration.md`](migration.md) — Map A.

**One drawer mechanism.** The mobile drawer is a Stimulus controller with a `<button>` trigger,
not a hidden checkbox driven by `<label>`s. A `<label>` is announced as a **checkbox**, not as a
control that opens navigation, and the CSS-only approach cannot carry `aria-expanded`, Escape,
a focus trap or focus return. An open drawer is a modal surface over the page and needs all
four; `dialog_controller` already implements them and is the model.

`drawer_controller` serves both layouts. It replaced two mechanisms for one interaction — a
hidden checkbox with `peer-checked:` and a `<label>` on every row in the app, a controller
toggling a class *and* an inline style in admin, which also rendered its nav twice. Neither
carried `aria-expanded`. The controller no-ops above `lg`, where the sidebar is permanent rather
than a drawer.

**Testing a drawer at 375px, since three things here are not obvious:**

- `ApplicationSystemTestCase#in_phone_viewport` resizes and **waits on the
  `(min-width: 64rem)` media query**. `resize_to` returns before the browser applies it, so a
  test can otherwise run at phone width against a desktop layout.
- **Capybara's `visible?` cannot see an off-canvas panel** — it reads display, visibility and
  opacity, not transforms. Assert on `getBoundingClientRect`, via `assert_offscreen` /
  `assert_onscreen`.
- **Those helpers wait, then assert.** The panel slides for 300ms, so reading its position
  straight after a click catches it mid-transition.

### Dividers
**A page title never gets a rule under it.** Spacing already separates a title from
its content. A horizontal line is a second, redundant signal, and it stacks visibly
against the border of whatever card or table sits directly beneath — two hairlines a
few pixels apart, which reads as a mistake rather than as structure.

**No extra dividers anywhere.** A rule earns its place only where nothing else is
already doing the separating. These stay:

- the tab rail an active tab's `border-b-2` sits on — the active tab needs a baseline
- the fixed admin app bar's bottom edge — fixed chrome against scrolling content
- row separators within a table (`divide-y`, `tables.css`)
- field-group separators inside a form card

**A card header does get a rule** — `border-b border-slate-200` on `components/ui/_card`'s
header. This is the app default, and it is the one place a rule is *added* rather than
removed. Stripe's Box, Primer's `Box.Header` and Tailwind UI's card-with-header all state
that boundary; Material and Polaris do not, and the split falls along card type. Most cards
here hold an attribute list or a table, which is the kind the first group is designed for.

This was got wrong once. The rule was removed on the strength of the Card / panel line about
`border-b` over-segmenting a card — but that line is about a **compact content card**, and it
names the substitute structure it depends on ("that detail divider and the footer
`border-t`"). A data card has neither, so removing the rule left it with no boundary at all,
and the header's `py-4` stacked on the body's `p-5` to float the title 36px above its
content. **Don't apply the compact-card line to a card holding data.**

A bare heading *inside* a card body is different and still takes no rule — that was the
`stocks/_stock` `h3` sitting directly on a `divide-y` list.

**The test:** delete a rule that duplicates a separation the page already makes some
other way — padding, a tint, a colour change, or a surface edge. Specifically: a rule
on the **page background** under a page title, a heading rule immediately above a
`divide-y` list, or a hairline on the edge of a coloured banner. **Keep** a rule that is
the only thing stating a real boundary, which is what a card header is.

### Iconography
- **Lucide**, through the `lucide-rails` gem's `lucide_icon` helper — inline SVG, no icon font and no
  CDN. It renders `aria-hidden` by default, which is right for a decorative glyph and wrong for an
  icon-only control: that needs its own visually hidden text, or it has **no accessible name at all**.
  A `bi-*` class name anywhere in this document is inherited prose; there are no Bootstrap Icons here.
- **Icon tile pattern** — icons representing a *stat or status* sit on a soft
  colored rounded background. It is a component: **`components/ui/_icon_tile`**, with
  `icon`, `tone` and `sm`. Do not write it longhand; it existed longhand in six places
  with the tone spelled inline, which is the shape this document warns about elsewhere —
  a style written in more than one place survives every sweep of one of them.

  Two sizes, and what decides is what the glyph sits next to:

  | | Box | Glyph | For |
  |---|---|---|---|
  | default | 36px | 20px | the tile is on a line of its own — above a figure, or in an empty state |
  | `compact` | 32px | 16px | the tile is **beside a line of text**, where 36px out-heights the 14–16px label it labels |

  **What decides is what the tile stands next to, not which page it is on.** The first wording here
  said "in a card header", which under-describes it — and that gap let the portfolio's two delight
  cards carry 36px tiles beside 14px labels while the home page's balance card carried 32px beside
  the same label, with a test pinning each. Beside text: 32px. On its own line: 36px.

  **The tones are the badge's tones** (`:neutral` `:success` `:warning` `:danger` `:info`),
  so a tile and a badge for the same state cannot drift apart. That fixes a discrepancy this
  document carried: the line here read `text-{semantic}-600` while the badge and all six
  hand-written tiles used `-700`. `-700` wins — it is what shipped, and it has more contrast
  headroom (measured 6.28:1 and 6.92:1 for the blue and slate tiles against their own tints,
  against a 3:1 bar). There is no `sky` tone; the admin dashboard had three tiles on
  `bg-sky-50 text-sky-700`, a second blue beside `:info`'s.

  Use for KPI cards, section headers, and list-item leading icons.
  **Do not** use bare floating icons or ringed white "avatar" circles for status
  contexts — reserve initial-avatars for representing *people* only.
- **A message bar or alert card gets a PLAIN glyph, never a tile.** The tile pattern above is for
  contexts where the icon is the *subject* — a KPI card, an empty state, a section header — and it
  assumes a white surface. A banner or alert is text with a marker beside it, and every system that
  ships one leads with a bare tone-coloured glyph, letting the tint and border carry the semantics:
  Polaris Banner, Material, Carbon inline notification, Primer flash, Atlassian SectionMessage.
  This was learned the hard way. A soft `-50` tile is invisible on a `-50` surface (measured against
  the amber-50 bar: amber-100 **1.07:1**, amber-200 1.20:1, amber-300 1.40:1), so "make it visible"
  turned into a filled `bg-amber-700` tile with a white glyph — which cleared contrast comfortably and
  was still wrong: it shouted, and a 32px block in a 20px line pushed the bar from **47px to 57px**.
  Reported as "draws too much visual attention, and increases the height of the banner". Reverted from
  the banner and from all four alert variants. **A measurement that answers "is it visible?" does not
  answer "does it belong?"** — if the only way to make an ornament visible is to make it loud, the
  ornament is wrong.
- **The bar is plain, and stays plain.** Both attempts to give it more presence were reverted for the
  same reason: nothing was wrong with it. A filled icon tile shouted and cost 10px of height; a 4px
  `amber-600` left accent band cost no height at all (measured 47px either way, 3.07:1 against the bar)
  and was still refused — *"neither of these changes add anything"*. If presence is ever actually
  needed, a left accent band is the standard device (Carbon, USWDS) because it cannot add height; an
  icon container is not. But the default answer for a message bar is a tint, a hairline border, a
  leading glyph and the message.
- **Align a leading glyph's INK to the text's x-height band, not its box to the line box.** Boxes are
  the wrong reference: with `text-base leading-5` the icon's box matched the 20px line exactly and the
  glyph still read as floating, because its ink centre sat at **85.5** against the text's dense-ink band
  centre of **88.0**. `mt-0.5` (2px) puts it at 87.5. That is what the original `mt-0.5` was for, and
  the bar measures the same 47px with it as without. Measure the ink: dump per-row ink counts across the
  text and take the dense band (x-height), since ascenders and descenders drag a naive ink centre around.
- **Leading-icon alignment** — an icon that precedes a label (menu items, list rows) is
  **top-aligned to the first line** (`items-start`), like a list marker, never centered
  against a wrapped block. Single-line labels look identical either way; `items-start` keeps
  it correct once a label wraps. (Material and Primer both top-align multi-line leading
  elements.)

### Accessibility (WCAG 2.1 AA)
Everything ships to **WCAG 2.1 AA** — it's part of "done", not a follow-up.
- **Contrast** ≥ 4.5:1 for text (3:1 for large ≥24px/bold text and for UI borders/icons).
  Muted text is `slate-500` on white — **not `slate-400`, which fails AA** — and
  `slate-600` on tinted surfaces. Never signal meaning by colour alone; pair a status
  colour with an icon or word.
- **Structure**: one `h1` per page, in-order headings, landmarks (`main`/`nav`/`aside`),
  real lists, and `<caption>` + `scope` on tables.
- **Forms**: every control has a real `<label>`; the error summary uses `role="alert"`
  and names the field; invalid/required state is never colour-only. A control with an
  **overridden id** or a **JS-enhanced widget** (the month/year
  `select_tag`s) needs an explicit accessible name — point the `<label for>` at the *actual*
  rendered id, or set `aria-label` — because the default `for` no longer matches and axe's
  `select-name` rule then fails. Guarded by `spec/system/accessibility/axe_spec.rb`.
- **Keyboard & focus**: fully keyboard-operable, visible `focus-visible` rings, a skip
  link, logical order; icon-only controls carry an `aria-label`, decorative icons are
  `aria-hidden`.
- **Motion**: respect `prefers-reduced-motion` (`motion-reduce:` variants).

**A page audit that only visits URLs misses whole components.** axe reads the DOM as it stands, so a
dialog, overflow menu, typeahead menu, multiselect menu, disclosure panel or drawer contributes nothing
until it is **opened** -- and the last whole-app sweep (137 states: every HTML route for every role, at
1400px and 390px, plus open component states) found *all* of its remaining violations either in an open
component or on a page a route-walk reaches but nobody looks at. **Prove the state is open before axe
runs**: three of the sweep's openers silently no-oped and reported a clean page. Fixtures must also
populate every table, since an empty collection audits clean and hides the defect. What axe cannot judge
at all: focus order, keyboard traps, whether alt text is *meaningful*, and icon contrast (there is no
non-text contrast rule). Regression examples live in `spec/system/accessibility/axe_spec.rb`, including
the open-component states.

**Measured token contrast on white** (computed from the built oklch tokens and cross-checked
against axe's own numbers — do not eyeball these, and do not assume a `-600` is safe):

| token | ratio | text (4.5:1) | icon/border (3:1) |
|---|---|---|---|
| `slate-400` | 2.63:1 | no | no |
| `slate-500` | 4.77:1 | yes | yes |
| `amber-600` | 3.19:1 | **no** | yes |
| `amber-700` | 5.05:1 | yes | yes |
| `emerald-600` | 3.67:1 | **no** | yes |
| `emerald-700` | 5.37:1 | yes | yes |
| `rose-600` | 4.51:1 | yes (barely) | yes |
| `rose-700` | 6.06:1 | yes | yes |

So `emerald-600`/`amber-600` are fine on a **decorative `aria-hidden` icon** but fail as
**text**: use `-700` for any status word ("Active", "+3 vs last month"). Watch the mixed
pattern `<span class="text-emerald-600"><i …></i> Active</span>` — the span colours the word
too, so it is text, not an icon. Keep a +/- pair on the same step so the two read at the
same weight.

**Heading order** (axe `heading-order`, and one `h1` per page above):
- A **subtitle/caption under the page `h1` is a `<p>`**, never a small heading. An `<h6>`
  used for a key-value fact or a sentence of instruction skips h2–h5
  and fails. Small-and-grey is a type decision (`text-sm text-slate-500`), not a level.
- A **`<dt>` is already the term** — never nest a heading inside it. `<dt><h6>Judge:</h6></dt>`
  both skipped levels and doubled the semantics.
- A **card partial shared by a grouped index and a flat list needs a caller-controlled
  level**. A card partial rendered at more than one depth takes a `heading_level` (default 3): an index nests
  cards under an `<h2>` case-number section, `#drafts` has no grouping level and passes 2.

**A `<label for>` does not name a custom element.** `label`/`for` only associates with
form-associated elements, so `<trix-editor role="textbox">` (and any custom element with an
ARIA input role) is left nameless — axe `aria-input-field-name` — even with a perfectly
correct visible `<label>` next to it. Set `aria: {label: …}` on the element itself. Same
remedy where a real `<label for>` would be actively wrong: a checklist's inputs
are driven by JS that sets checked state after an AJAX save, so associating a label would
toggle natively on top of it — they carry `aria-label` and keep the label unassociated.

**Links inside a text block need more than colour.** `brand-600` on `slate-900` body text is
2.83:1 (3:1 required), so a case-number link inside an `<h1>`/paragraph gets `underline
underline-offset-2` (axe `link-in-text-block`).

**Scrollable regions must be keyboard-reachable.** Trix ships
`.trix-button-row { flex-wrap: nowrap; overflow-x: auto }`, a scroll container that is not
focusable (axe `scrollable-region-focusable`). `tailwind.css` overrides it to wrap instead.

**Auditing caveat:** axe only sees the **rendered** DOM, so a page with an empty collection
audits clean and hides real defects — a first whole-app pass missed unlabelled
checkboxes and both org-settings status chips purely because no categories/contact topics
were seeded. Seed at least one row of every repeating region before believing a clean result.
Likewise, a page that 500s reports `document-title` + `html-has-lang` + `landmark-one-main` +
`region`: that combination means you are auditing a layout-less Rails error page, not a
finding. Capybara then re-raises the server error on the *next* `visit`, so the exception is
reported against the following page.

**Audit at more than one viewport.** axe skips hidden elements, so a desktop-only pass cannot
see `md:hidden` / `lg:hidden` markup *at all* — and this codebase renders a separate mobile
card list next to every desktop table. A whole-app sweep run at 1400px came back clean while
390px still had six violations, every one of them in below-the-breakpoint markup:
- the auth pages' only `<h1>` sat in an `<aside class="hidden … lg:flex">`, so below `lg` the
  page had **no `h1` at all**. Fixed by making each form heading ("Welcome back", "Reset your
  password") the `<h1>` and the marketing line a `<p>` — the page's subject is the form, not
  the brand statement. Sign-in/reset/invite/confirm all follow this.
- the `lg:hidden` org-settings group labels were `slate-400`.
- the metrics data tables and heatmap become **scroll containers** once they stop fitting, and
  they contain no links or controls, so nothing inside could take focus (axe
  `scrollable-region-focusable`). A scrollable region built from pure data needs
  **`tabindex: 0`** on the scroll container itself so it can be scrolled from the keyboard.

**Icon contrast is not automatable — check it by hand.** axe has **no rule** for non-text
contrast, so a decorative-looking icon can fail 1.4.11 (3:1) on a page that audits perfectly
clean. The org announcement banner shipped its megaphone as `text-amber-500`, which is
**2.07:1 on the `amber-50` banner background**. Icons in an alert/banner should **inherit the
container's text colour** (as `shared/_flashes` does) rather than setting their own, which keeps
them at the same ratio as the copy they sit with. Note contrast is against the *tinted* surface,
not white: measure against the actual background.

**Flash messages** (`shared/_flashes`): success auto-hides, errors stay.
- A success message carries the `auto-dismiss` controller and clears itself after ~6s. The timer
  **pauses on hover and on `focusin`**, so it cannot vanish mid-read — that plus a delay well
  above a couple of seconds is what keeps an auto-hiding status message clear of WCAG 2.2.1. The
  message keeps `role="status"`, so it is announced when it appears; removing it later is silent.
- Warnings and errors (`role="alert"`) are **never** auto-dismissed: they are often the only
  record of what went wrong.
- **Nor is a notice that carries a credential.** Four of them do - creating a student from either half, and
  the two password resets - and the message *is* the only copy: `MemorablePasswordGenerator` hands the
  password to the flash and nothing stores it, so six seconds later the only way back was another reset. The
  controller sets `flash[:sticky]` alongside such a notice and the partial omits `auto-dismiss`. The test for
  auto-dismiss is whether the sentence is still true in a minute; a password is.
- The fade is applied as an **inline style**, not a utility class, and the removal is on a timer
  rather than `transitionend`. A class added from JS only works while Tailwind still emits it, and
  a missed `transitionend` would leave the message on screen forever.
- Because the partial keys off the flash type (`notice` -> green success, anything else -> amber
  warning), **an error must not be sent as `flash[:notice]`**, or it renders green *and* now
  auto-dismisses. Authorization failures use `flash[:alert]`: `ApplicationController#not_authorized`
  plus any `RecordNotFound` rescues.

Sweep at **390 / 768 / 1400** before calling a page clean. Also note a route-walking audit
silently skips **feature-flagged** pages (it just follows the redirect)
was missed that way and had two failing status colours behind the flag.

## Components

### Buttons
Use the **`button_classes(:variant)`** helper (`DesignSystemHelper`) as the single source of
truth. Never hand-write button class strings in views; they drift (that is how the variants
ended up mismatched). Variants:
- `:primary` (filled brand): `bg-sitf-primary text-sitf-on-primary font-semibold hover:bg-sitf-primary-dark`,
  focus ring `sitf-primary-dark`
- `:secondary` (outlined): `border border-slate-500 bg-white text-slate-700 font-medium hover:bg-slate-50`
- `:danger` (filled rose): `bg-rose-700 text-white font-semibold hover:bg-rose-800`, focus ring
  `rose-800`. **For the accept button of a destructive confirmation, and nothing else** - see "No red at
  rest" below for why that is the one place it belongs. rose-700 rather than rose-600: measured with white
  text, 600 is **4.53:1** and clears AA by 0.03, which is no headroom, while 700 is **6.03:1** and sits
  level with the brand primary's 6.18:1, so a destructive accept does not read weaker than a benign one.
  The same one-step-darker correction this list already makes for `:success`.
- `:danger_outline` (a **quiet outlined destructive** button): identical to `:secondary` at rest -- `border border-slate-500 bg-white text-slate-700 font-medium` -- and turns rose only on hover (`hover:border-rose-300 hover:bg-rose-50 hover:text-rose-700`, rose focus ring). Use it for a destructive action that sits **among bordered buttons** (a toolbar/section/header of `:secondary`/`:primary`), so it matches them at rest with no always-on red; use `ghost_class(:danger)` when the neighbours are ghost (see below). No red-at-rest either way.
- `:success` (filled emerald, for a **prominent** positive action, e.g. reactivating a deactivated user): `bg-emerald-700 text-white font-semibold hover:bg-emerald-800` (emerald-700, not 600: white on 600 is 3.77:1, below AA). A **repeated per-row/card "resolve"** (e.g. resolving a followup reminder) recedes to `:secondary` -- a filled emerald over-emphasizes a low-frequency action next to its neutral row-mates.

Every variant shares a base of `inline-flex h-10 items-center justify-center gap-2 rounded-lg
px-4 text-sm shadow-sm` plus a `focus-visible` brand ring and `disabled:` states. The fixed
**`h-10` (40px) height token** is deliberate: with `box-sizing: border-box` it absorbs the
outlined variant's 1px border, so filled and outlined buttons are the same height by
construction (40px is the mainstream medium-button height: Material 3, Chakra, shadcn). **Do
not** re-equalize sizes with `border border-transparent` on the filled variants; that is a
fragile compensation pinned to the secondary's exact border width, and the height token
already handles it.

**One primary CTA per page.** A view gets exactly ONE filled `:primary` button -- the page's main
action (on a form page, its save: "Submit" / "Save changes"). Every *other* action is lower emphasis:
`:secondary` for a clear standalone action, ghost for repeated row/toolbar actions. In particular an
inline sub-form submit inside a section card is **`:secondary`, never `:primary`** -- it sits next to
a full-height select or textarea, so a 40px secondary aligns with the input, and it must not compete
with the page's save. Stacking a main-form submit primary with several section-form primaries is the
recurring bug; `grade_books#show` had two filled primaries at once, with Save grades outside the card
and Finalize grades inside it, and neither said which came first. A
**dialog keeps its own primary confirm** ("Yes, send reminder" / "Yes, copy"): that's the dialog's
local primary, visible only while the modal is open, so it doesn't count against the page.

**Left-aligning / splitting button content.** `button_classes` bakes in `justify-center`, and in
Tailwind v4 appending `justify-start` / `justify-between` does **not** reliably override it (utility
cascade order -- measured: label stayed centered). To left-align a label, or split it (label left,
trailing icon hard right) inside a `button_classes` button, wrap the label in a **`flex-1`** span: it
fills the free space, so `justify-center` has nothing left to center. The reports one-click exports use
this -- a leading report icon + label in a `flex-1` span, `bi-download` on the right (verified 17px
label/icon insets, not centered). Keep every child `pointer-events-none` if a click handler reads
`event.target` as the button (as `src/reports.js` does).

**Concise CTA labels.** A button label is the *action*, not a restatement of context the page already
supplies -- drop the page title and anything the h1 already said. "Add student" on a classroom page,
not "Add a new student to this classroom".

**And a label must be accurate about what the control does.** "Save and finalize" implied one action
where there are two, on a page that autosaves and where finalizing pays real money. It is "Finalize
grades", which is also what the confirmation's accept button reads, because that label is filled in
from the control that was pressed.

**A gated action: remove it and say why, rather than disabling it.** When a classroom's trading is
turned off, `StockPolicy` hides the Buy control outright and a dismissible callout states that trading
is off for this classroom. A `disabled` button sitting among live siblings reads as broken, gives no
feedback on click, and will not line up -- a `disabled <button>` next to `link_to` siblings landed ~4px
low. The two honest options are a live control that explains the refusal, or no control plus a
sentence; a greyed one is neither.

**A control that can only report that it did nothing is not a control.** "Add new students" was
offered on a fully populated grade book -- the normal state -- where it added nobody and flashed
"Every student already has a row", which then auto-dismissed after 6s so even the explanation
vanished. It renders only when somebody is actually missing an entry. Ask whether the affordance can
ever do anything for this viewer, in this state.

Disabling a button *during* submission is the correct, kept use of `disabled`.

**List rows** (the grade books on a classroom page): one row per entity = **identifying label plus
its status badge on the left, the action on the right** (`flex items-center justify-between`), never
the action stacked below the badge. This is the standard "list item with a trailing action" -- GitHub
collaborators, Slack members, Polaris's `ResourceList` -- and each entity reads as one scannable line.
One card with `divide-y` between the rows, **not a card per row**: four grade books as four cards,
plus the roster's table card and a setting card, put six surfaces on one page.

- Tertiary (ghost): the **`ghost_class(:neutral | :danger)`** helper (design_system_helper.rb) --
  `inline-flex items-center gap-1.5 rounded-lg px-2 py-1 text-sm font-medium text-slate-600`. **Both
  variants are slate at rest** (no jarring wall of colored text in a table); they differ ONLY on
  hover/focus: `:neutral` hovers gray (Edit / Detail view / View / Impersonate / Assign / filters),
  `:danger` hovers **rose** (every Delete / Remove / destructive action -- the destructive hover must
  be identical everywhere, never gray in one table and rose in another). Slate-at-rest + rose-on-hover
  is the **industry-standard destructive affordance** (GitHub, Gmail, Linear): it reveals danger at the
  point of action without an always-on red. Reinforced by the `bi-trash` icon + "Delete" label +
  confirm dialog. **A destructive action MATCHES the buttons beside it** (audit each context, never
  blanket one style): among ghost/compact actions (table rows, per-item lists) use `ghost_class(:danger)`;
  among **bordered** buttons (a toolbar/section/header of `:secondary`/`:primary`/`:success`) use
  `button_classes(:danger_outline)` (redefined above: slate at rest like `:secondary`, rose on hover) so
  it matches its neighbours at rest. Never mix a ghost destructive next to bordered buttons -- it reads
  as broken. Either way there is **no red-at-rest**. No border, fill, or shadow: the
  lowest-emphasis action, for repeated row / toolbar actions so they recede from brand links. It lives
**Irreversible is not destructive, and only one of them gets the rose hover.** The rose is the
affordance for an action that *takes something away* - delete, deactivate, archive - and its job is to
make that legible at the point of action. An action that is merely *irreversible* does not qualify:
finalizing a grade book pays money into every student's portfolio and cannot be undone, and it sat on
`:danger_outline` until that was reported as "lights up like a destructive button". Stripe's "Pay $X" is
not a red button either.

Note what colour was actually doing there, which is the general lesson: `:danger_outline` and
`:secondary` are **identical at rest**, so the only reader who ever saw the warning was one already
hovering the control they had decided to press. The weight belongs on the label, the figure stated
beside it, and the two-part confirmation. Ask what the hover is being asked to communicate, and to whom,
before spending the rose on it.

**No red-at-rest applies to the container too, not just the button.** A destructive section is a
plain `border-slate-200` card like every other section. A rose border belongs to an **alert message**
panel, paired with a rose fill and rose ink, saying that a thing *is* in a bad state. Outlining a
section in red to mean "the action in here is dangerous" is not a pattern; the danger lives in the
button variant, its icon, its label, and the confirmation dialog, whose single solid rose button is
the only red at rest anywhere.

  in a helper (not a `button_classes` variant -- it is a low-emphasis action at a shorter height, not a
  CTA) as the **single source of truth**, because copy-pasted inline strings drifted: case_groups sat
  drifted to their own paddings, and some tables used bare coloured text links instead of the ghost.
  **Call the helper; never hand-write the string.** Neutral ink stays
  at or above AA (slate-600 is about 7:1; never `slate-400` under visible text). Leading icon via
  `gap-1.5` plus a `bi-*` glyph (`bi-pencil` Edit, `bi-trash` Delete). Right-aligned in a table's
  trailing actions cell, give that cell extra end padding (`pr-6`) so the control clears the card edge
  rather than skewing the button's own padding. **Every table row action is this ghost** -- Edit
  (`ghost_class`) / Delete (`ghost_class(:danger)`, passed as the confirm dialog's `trigger_class` with
  a trash icon -- slate at rest, rose on hover) / View / Cancel, and a form-submit row control too --
  **never a
  `button_classes(:primary/:secondary)` CTA**: a filled CTA over-emphasizes a repeated per-row action
  and breaks table-to-table consistency. Right-align the whole trailing column (`text-right` cell +
  `flex items-center justify-end` when it holds more than one control, e.g. a `<select>` + Assign).

**Audit before shipping:** grep the views you touched for clickable elements (`link_to` /
`button_tag` / `button_to` / `<button` / `<a`) carrying a hand-rolled button shape
(`inline-flex` + `rounded-lg` + `px-`/`py-` + `bg-`/`border-`) and convert them to
`button_classes`. A bespoke string at `py-1.5` next to a 40px token is the recurring drift
bug; the only non-token clickable is the tertiary ghost, which has its own helper (call it -- do not
re-derive the string).

**This grep is necessary but not sufficient.** A button defined in **Ruby** compiles and ships exactly
like one in a template, because Tailwind scans `.rb` -- the admin form builder's submit backed eleven
forms at `bg-blue-600 rounded-md px-4 py-2`, so every admin form's primary was generic blue and a
different size from the primary in the page header above it, and no view grep could see it. Cover
`app/helpers`, `app/form_builders` and `app/assets/stylesheets` as well as `app/views`, and pixel-check
the rendered page.

**The 40px height is a minimum, not a fixed height.** `.tw-btn-*` was `h-10`; it is `min-h-10 py-2`, which
measures the same 40px at every size this app renders - `text-sm` is a 20px line box plus 16px of padding is
36px, so the minimum holds it - and survives the case a fixed height cannot. At **200% text** (WCAG 1.4.4) a
label long enough to wrap is cropped by its own button. Found on the first label in the product long enough
for it: "Add a transaction" measured 305px inside a 305px viewport at 320px, and every translated label after
it would have had the same problem. A button grows with its text.

An `inline-flex` control also needs `max-w-full` if its label can be long, because an inline-flex box is
sized by its content and nothing else bounds it.

### Button variants as implemented here

The variants above are CASA prose naming a `button_classes` helper and a `brand-600` token that do
not exist in this app. Here they are CSS classes, and `brand-600` maps to `sitf-primary` (`#00698c`,
white on it 6.18:1):

| design.md variant | here | notes |
|---|---|---|
| `:primary` | `.tw-btn-primary` | `bg-sitf-primary`, `font-semibold`, white label |
| `:secondary` | `.tw-btn-secondary` | `border border-slate-500`, `font-medium` |
| `:danger_outline` | `.tw-btn-danger-outline` | identical to secondary at rest, rose on hover |
| `:danger` (filled rose) | `.tw-btn-danger` | the accept button of a destructive confirmation, and nothing else. The note here used to read "not shipped - Turbo uses the native dialog, so there is no surface for it", which stopped being true when `shared/_confirm_dialog` landed. |
| `:success` (filled emerald) | **not shipped** | see below |
| tertiary / ghost | `ghost_class` in `ButtonHelper` | row actions |

**The base is one shared selector group**, not a string pasted per variant. It was pasted, and it
drifted in five ways at once, none of them visible in a class list:

- `.tw-btn-secondary` used `ring-1 ring-slate-300 ring-inset` where the spec says
  `border border-slate-200` - a ring, not a border, and a darker token. This is the one that was
  reported, as the outline looking too heavy.
- The filled variants were `font-medium`, not `font-semibold`. Weight carries part of the emphasis
  hierarchy, so filled and outlined are not interchangeable on it.
- `admin_primary_button_class` carried `border border-transparent`, which the section above rules
  out **by name**.
- `admin_secondary_button_class` and the admin danger button used `border-slate-300`.
- `ADMIN_BUTTON_BASE` omitted `justify-center` entirely.

The cause was structural: **two bases for one product**, one in `buttons.css` and one in Ruby, kept
in step by attention. The admin helpers are now three-line aliases returning the same class names,
so there is nothing left to keep in step. `test/system/button_variants_test.rb` asserts the rendered
box of every variant against the table above - measured, not read.

**Border contrast, stated plainly:** `slate-200` on white is **1.23:1** and `slate-300` is 1.48:1.
Neither is a 3:1 boundary under WCAG 1.4.11. The control is identified by its label (`slate-700`,
10.35:1) plus `shadow-sm`; the border is a refinement. Making it a real 3:1 boundary would be a
deliberate change to this spec, made once here rather than per call site - and it would be visibly
heavier than the report that prompted the move to `slate-200`.

**`.tw-btn-tertiary` is gone.** It was a filled `slate-100` button that is not one of the variants
above at all - the spec's tertiary is the ghost - and its six call sites were standalone
"Back to X" / "Edit class" actions, which the spec calls `:secondary`.

**`:success` is deliberately not shipped**, even though the section above names "reactivating a
deactivated user" as its example and this app has exactly that action on `admin/teachers#show`. A
filled emerald would be a third button colour in a product whose reviewed complaint was that the
buttons were garish, and the same page already carries a primary. Reactivate is `:secondary`; the
positive meaning is carried by its `circle-check` icon and its label. Revisit this as a design
decision, not as a drift fix.

**The component demo is a living style guide, so it must show the real components.** It rendered
seven hand-rolled buttons at `rounded-md px-4 py-2` with a red-at-rest Delete and a blue "Send
email" - a page teaching the drift that everything else had just been cleaned of. It uses the named
classes now.

**The shadcn button helper is deleted.** `Components::ButtonHelper#render_button` had no callers
left once the shadcn builder's `submit` stopped delegating to it, and it was a second button system
with its own tokens - its `--primary` being the near-black navy that made the sign-up button the one
off-brand primary in the product.

### One primary per page, audited

Counted the **rendered, visible** `.tw-btn-primary` on 41 pages across all four roles, excluding
anything inside a dialog or the modal turbo-frame. Two pages broke the rule, both in shapes the
Buttons section names explicitly:

- **`admin/students#edit`** stacked "Update student" with a second card's "Add transaction". That is
  the sub-form case: an inline submit inside a management card is `:secondary`, never `:primary`.
  `Ui::FormBuilder#submit_button` takes `variant: :secondary` for it.
- **`portfolios#show`** rendered a filled "Trade" in **every holdings row** - a per-row filled CTA,
  exactly what the row-action rule exists to prevent, in a table the earlier ghost sweep missed. It
  is `ghost_action_link` with an `arrow-up-down` icon now, and a non-student viewer gets the
  `table-no-permission` dash the rest of the app uses rather than a bespoke disabled pill. Its empty
  state also carried "Go to the trading floor" as a primary beside the earnings card's "Invest now",
  **two primaries pointing at the same path**; the empty state's is secondary.

**A primary whose destination is the current page is worse than a missing one.** The earnings card's
"Invest now" links to `stocks_path`, and the card renders on `stocks#index` - so the trading floor's
only filled primary did nothing. The card still shows the balance there; the CTA is suppressed with
`current_page?`.

`test/system/one_primary_test.rb` asserts at most one page-level primary, that the holdings row
action is a ghost with an icon, and that the trading floor has no self-linking CTA.

**Both of the pages that broke the rule had two forms or a table.** That is where to look: a page
with one form and one header CTA is hard to get wrong.

### Tables as implemented here

One set of classes, used by every table on both sides: `.table-base` on the `<table>`,
`.table-header-row` on the header `<tr>`, `.table-header-cell` / `.table-body-cell` on the cells,
`.table-body-row` on each body row. Nothing else styles a table.

**The header carries no fill.** A `border-b` on `.table-header-row` is the only separator. The grey
strip survived three previous sweeps because it was written **two ways at once** - this class on the
app side and an inline `<thead class="bg-slate-50">` on fourteen admin and teacher tables. Grep one
form and the other half stays. The border is `slate-200` against body rows at `slate-100`: the spec's
`slate-100` assumes CASA's `slate-50` row dividers, and what transfers is the relationship - the
header separator one step stronger than the row lines - not the literal token.

**One border at the seam.** `divide-y divide-slate-300` on the `<table>` (eleven of them) stacked on
the header row's own `border-b`. Row separators come from `.table-body-row`, never from a `divide-y`
on the table or tbody - three tokens were in use for that one job (`slate-300`, `slate-200`,
`slate-100`).

**Headers are `align-top` too**, not just body cells. Every `<th>` in the app computed to the
browser's `vertical-align: middle` default, so a wrapped header vertically centred its single-line
neighbours against itself.

**Hand-written cells are the recurring drift.** Four files still wrote `px-6 py-4` or `px-3 py-2`
under headers using the shared `px-4 py-3`, transposed exactly as the older admin tables were - so
each column's header text sat off its own data. **Match on the class list, not on an exact string:**
half of them were missed on the first pass because they read
`whitespace-nowrap px-3 py-2 text-sm ...`, with the padding in the middle. Sweep for any `<td>`/`<th>`
whose class contains a `px-`/`py-` and no `table-*-cell`.

**A `<tfoot>` holds a column summary: one row, and only figures that belong to the columns above them.**
The label goes in the **first** column, because that is where a row says which row it is, so "Total for
25 students" reads as a row identifier; the figure goes under the column it sums. Measured on the grade
book, the total's cell is 1245-1360px and the Earns column is 1245-1360px - the same box. That is
Polaris's `DataTable` `totals`, GOV.UK's table totals and the bottom row of every spreadsheet.

**A stack of components is not table rows.** The grade book's three-way split went into the footer as
three more `colspan="5"` rows and was reported as unreadable: *"difficult to read as it's part of the
columns, but not actually under the titles of the columns"*. Exactly right. A row in a grid claims the
headers above it describe it, and "Attendance, including bonuses" spanning
Student/Math/Reading/Days/Perfect is described by none of them - four prose-labelled rows read as a
second, differently-shaped table wearing the first one's columns. Components of a total go in an
**invoice totals block** (Stripe, QuickBooks, Xero: a narrow right-aligned stack outside the grid) or in
a **review summary beside the control that commits them** (Gusto, Square Payroll). This app uses the
second, and the invoice block was previewed for this page and rejected - not on placement, but because
a second summary of the same money next to the table cannot be read at all, whatever shape it takes.
See "Two summaries of one set of numbers" in the grade book section.

The same complaint had already rejected the other placement - a card holding those figures **below the
Save grades button**, which read as output of the save and said nothing about whether it counted what
had just been typed. So: the total belongs to the table, the split belongs to the action, and neither
belongs to a card of its own. `design.md` had recorded that division before I overrode it, which is the
recurring lesson - **where this document has already decided, that is the decision**.

**Anything derived from the rows is refreshed with them.** The footer is one element with an id,
replaced whole on save; the swap never touches an input, so it cannot take the cursor or a half-typed
value with it.

**A row partial rendered into someone else's `<tbody>` is invisible to a per-file sweep.**
`grade_books/_grade_entry` holds a bare `<tr>` whose `<tbody>` lives in `grade_books/_table`, so a
scan for rows inside a tbody never saw it and it kept its own padding and lost its separator.

**Two tables that sit above one another must share one column geometry.** The trading floor renders
Active stocks and Archived stocks as separate `<table>` elements from one partial, and under the
default auto layout each sized its columns from its own content: the Buy/Sell pair widened the
actions column in the active table and pulled every other column left, so the page stepped sideways
at the boundary (measured at 1366px: column two at 567px in one table, 699px in the other). Fixed by
**giving every column but the first an explicit width** (`w-32`, `w-32`, `w-52`), with `table-fixed`
to make those widths authoritative rather than advisory. Measured after: both tables report
`281:581 862:128 990:128 1118:208`.

**A row's contents hang off its first line, and an image must not set the row height.** The primary
cell was `items-center` around a logo that grew to `lg:size-16`, so the ticker sat 13px down while
the price and holdings text sat at 12px - and the taller the image, the wider the gap. The logo is
`size-10` at every width, which is exactly the height of the two-line ticker-over-company block, and
the cell is `items-start`. Measured after: ticker, price and holdings first lines all at 14px, with
the 40px logo and the 40px trade button sharing a top edge at 13px.

`test/system/table_consistency_test.rb` asserts all of this as computed style and geometry across
twelve tables on ten pages.

### Arrows mean value direction, so actions do not use them

Three different meanings were competing for the same glyph:

- **`↑` / `↓` mean the value moved.** The holdings table's Change and Total return columns use them
  with a sign and `green-700` / `red-700`. In any finance interface this is what a vertical arrow
  says, and it is the meaning users arrive with.
- **`⇅` means sort.** `sort_icon` renders it as an unsorted column's caret, and `↑` / `↓` once a
  column is sorted. Material calls the same glyph `swap_vert`.
- **Actions therefore get neither.** A vertical two-arrow glyph as a row action means "sort" in the
  one context where sorting is something you do to rows, and a `↑` on a Buy button means "the price
  went up" a few pixels from a column that says exactly that.

**Buy and Sell carry no icon.** They had `arrow-up` and `arrow-down`. Fidelity, Vanguard, Schwab,
Robinhood, E*Trade, Webull and Coinbase all label them as text and leave the arrows to the numbers.
The label is the affordance; the leading-icon rule is about **row actions** - the ghosts - not about
a CTA.

**An exchange action uses the horizontal glyph.** The portfolio's Trade row action was
`arrow-up-down` and is `arrow-right-left`: Material's `swap_horiz`, and what TD, Chase, Monzo and
Revolut use for a transfer. Worth knowing that the brokerages mostly do not icon this action at all -
"Trade" is a text control at Fidelity, Vanguard and Schwab - so the icon here exists to satisfy this
document's row-action rule rather than to follow theirs. If that rule ever relaxes, this is the first
icon to drop.

### Row actions as implemented here

`ButtonHelper#ghost_class(:neutral | :danger)` is this app's `ghost_class`, and
**`ghost_action_link` / `ghost_action_button` are what views call** -- they render the leading icon
themselves, so an action cannot ship without one. Both sides of the product use them.

**Every table row action is a ghost with a leading icon and a visible label**, and **one action has one
glyph**. The vocabulary is Lucide, not `bi-*`:

| Action | Icon | |
| --- | --- | --- |
| View | `eye` | |
| Edit | `pencil` | not `square-pen`, which three shared partials had |
| Delete | `trash-2` | and `Permanently delete`, which is the same act |
| **Deactivate** | `user-x` | a **person** |
| **Reactivate** | `user-check` | a **person** |
| **Archive** | `archive` | a **thing** |
| **Restore** | `rotate-ccw` | a **thing** |
| Cancel | `ban` | |

The person/thing pairs mirror the verbs: `user-x` / `user-check` for an account, `archive` / `rotate-ccw`
for a classroom. That is why `ban` is Cancel alone now and `circle-check` is gone - the old table gave
`ban` to Deactivate *and* Cancel, and `circle-check` to Activate *and* Reactivate, so two icons each carried
two meanings.

Reported, and worse than it sounded: **"Deactivate" carried four icons** - `user-x` in the shared helper,
`ban` on the teachers index, `archive` on the users index left from the rename, and `trash-2` on the teacher
record page, where it sat beside a real "Permanently delete" wearing the same glyph. One icon meant both
"reversible, they keep everything" and "gone".

**A navigation glyph identifies one item, and the two halves share their vocabulary.** The sidebar's icons
exist to tell its rows apart, so `presentation` labelling **both Classrooms and Teachers** was the whole
failure of the idea. Teachers is `book-user`; Classrooms keeps `presentation`, which the dashboard tile uses
too.

| Idea | Both navs |
| --- | --- |
| Home / Dashboard | `house` |
| Classes / Classrooms | `presentation` |
| Trading floor / Stocks | `chart-line` |
| Transactions | `receipt` |

Those four had drifted apart: Transactions was `receipt` on one half and `arrow-left-right` on the other,
the trading floor `chart-no-axes-combined` against `chart-line`, and **Classes hand-wrote a Heroicons
path** - which is why it appeared in no inventory, since nothing greps a path definition. Every icon in the
app comes from `lucide_icon` now, and a test counts them.

**And `arrow-left-right` is retired.** It is `arrow-right-left` - the Trade glyph this document names - with
the words swapped: two near-identical Lucide icons for one idea, one character apart in the name. Exchange
is `arrow-right-left`; the transactions *list* is `receipt`.

`icon_vocabulary_test` reads the call sites, because `lucide_icon` renders a bare `<svg>` with no name, no
class and no data attribute - a browser test could only compare path data. It fails on any label with two
icons, any nav with a glyph on two items, any drift between the halves, and any navbar item drawing its own
SVG.

**A row action never duplicates the row's own name link.** The name in the primary cell links to the
record's page, so `View` was two controls to one destination -- that argument removed it from all nine
admin indexes, and it applies unchanged to `Edit` now that the record page edits in place. What stays on an
admin row is what a link cannot do: `Delete`, and the `Archive` / `Restore` pair. The vocabulary above
keeps `eye` and `pencil` because the app side still uses both.

The test is the **destination, not the label.** `classrooms#index` on the app side keeps its `Edit`, and
that is not drift: the name links to the roster at `classroom_path` while `edit_classroom_path` is a
separate form page, so the two controls go to two places. Ask where the row's name goes before adding
anything beside it -- and note that removing the duplicate narrows the actions column, which is the column
that runs off screen first at 1024px.

**Height is `min-h-8` - 32px at every width.** 28-32px is where row actions sit in current practice
(Primer's small control 28 and medium 32, Linear and Stripe about 28, Polaris slim 28), and 44px
anywhere would make the ghost *taller* than the 40px primary button it recedes from.

It was `min-h-11 lg:min-h-8`, on a "44px where the finger is" argument that **contradicted this
document's own rule**: 44px is reserved for *bare* tap targets with no other affordance - an
icon-only control, a sidebar nav row - and a row action has a visible label and about 80px of width.
Fitts's law cares about both dimensions, and WCAG 2.5.8 (AA) asks for 24x24. It also read wrong: in a
cell whose neighbours are 17px lines, a 44px box top-aligned to the row's first line extends 27px
past it and looks like a slab floating mid-row, which is what was reported. Measured now: the
button's top is 12px and the adjacent text's is 13px, at every width.

**The trailing column is right-aligned and its header is unlabelled** (`sr-only` "Actions"). A
header naming one action stops being true the moment a second one is added, which is what
`classrooms#index` had ("Edit"), and an empty `<th />` gives the column no accessible name at all.

**Focus is an `outline`, never a `ring`, and only ever on `:focus-visible`.** Counted:
`focus-visible:outline-2` and `focus-visible:outline-offset-2` 28 times each,
`focus-visible:outline-sitf-primary` 25 - with `sitf-primary-dark` on the filled primary and `rose-700` on
the destructive outline, so the ring belongs to the control it surrounds. The colour is **always named**:
an unnamed `outline-color` falls back to `currentColor`, which is white on a filled button.

**A ring utility needs a width, and without one it paints nothing.** Three checkboxes on the classroom
form carried `focus-visible:ring-sitf-primary` - a ring *colour* with no `ring-2` - so they had **no focus
indicator of their own** and fell back to Chrome's default: measured, `1px auto rgb(16, 16, 16)` against
every other control's `2px solid rgb(0, 105, 140)`. They were the only controls in the app in that state,
and `components/ui/_checkbox` had the right string the whole time. Same string was wrong three more ways -
`text-sitf-primary` does nothing to a native checkbox (`accent-color` tints it), `rounded` is an 8px radius
on a 16px box, and there was no size.

**No control carries a ring at rest**, which is what makes a *preview* that paints one misleading:
`focus-visible` is a state, so a static mock cannot show it and must say it in words instead.
`focus_indicator_test.rb` asserts all three - the app's ring on every control the classroom form owns, the
checkbox specifically, and that nothing is ringed while unfocused.

**A text input is the deliberate exception, on `focus:` rather than `focus-visible:`**, with a *negative*
offset so the ring sits inside the field. Showing focus when a field is clicked into is correct and is
what every form library does; the distinction is that a button should not flash a ring at a mouse user.

**No red at rest for any control that sits on a page** - which is 15 of the app's 16 destructive
controls, and the rule as it was written. It reads "on a page" rather than "anywhere" because of one
named exception: **the accept button of a confirmation dialog is `.tw-btn-danger`, solid rose.**

The reason a red control is wrong at rest is that it alarms you while you are doing something else. A
confirmation exists only because you asked for the action a moment ago, and the dialog's whole job is to
describe it, so the argument does not reach it. The field splits the same way: a destructive control *on a
page* is low emphasis (Primer's danger variant is red text at rest with the fill on hover; Carbon ships
`danger--ghost` and `danger--tertiary`; Gmail and Linear are neutral), while a destructive control that is
*the subject of its surface* is solid red (Polaris's destructive modal `primaryAction`, GOV.UK's warning
button, Atlassian, Carbon, Ant Design). Before this, the app had the first tier twice over and the second
not at all, and the defect that showed was two identical white boxes as the two answers to "delete this
person?" - in the one dialog whose job is to make the choice deliberate.

**What does not change:** Cancel keeps `autofocus`, so the destructive answer is never the default. That
is Apple HIG's rule, it is orthogonal to the fill, and Polaris and Carbon ship both together. Apple is
the dissent on the fill itself - it uses red *text* - and this follows the majority.

**How the choice is made:** on the trigger, never on its words. `data-confirm-danger`, or the ghost's own
danger class. Keying on "delete" or "remove" would style a button for a noun in its label and would miss
"Deactivate".

**Do not read this as a general licence.** One class, one caller, and a page-level destructive button is
still slate at rest. `confirm_dialog_test.rb` asserts the fill on a destructive confirmation and its
absence on a benign one, and `focus_indicator_test.rb` asserts nothing carries a ring at rest.

**The history, because I got here badly.** I added a solid `.tw-btn-danger` on my own judgement while the
rule still read "anywhere", with rose-700 justified by a claim that rose-600 fails AA - it does not - and
with `border border-transparent`, which this document forbids by name. `buttons.css` recorded that the
class had already been deleted once for having no callers, eight lines above where I re-added it. Three
signals, none read. It was reverted, previewed at
`/admin/component_demo/destructive_buttons`, and adopted as a decision rather than a preference.

`admin_danger_button_class`
was `border-red-300 text-red-700` and is now slate at rest like `:secondary`, rose on hover -- it
sits in the `classrooms#show` toolbar between a bordered Edit and a bordered Delete, and a ghost
among bordered neighbours reads as broken. Restore was `green-600` on white, **3.30:1, a straight
AA failure**, which is what happens when a state colour is chosen for meaning and never measured.

**There is no filled-CTA exception on the trading floor. Buy and Sell are `.tw-btn-secondary`.**

I argued for one - that Buy/Sell are the core transaction and every brokerage table gives the trade
control real weight - and it was wrong in this context. A filled teal Buy beside a filled amber Sell
puts **two saturated fills, in two different hues, on every row** of the densest page in the app,
and the report from looking at it was that they were garish and did not work. The brokerage
comparison holds for a single trade button in a row, not for a permanently doubled one; and the
argument was made from reading the class names rather than the page.

The two actions are told apart by their **labels**, not by colour - which the colour rules require
regardless, since colour may not be the only carrier of meaning. Measured: white ground, `slate-700`
label at 10.35:1, 40px, identical at 375px and 1366px.

**And not by an arrow, which this entry used to prescribe** (`arrow-up` Buy, `arrow-down` Sell). In a
finance interface a vertical arrow means the *price* moved that way, and that is what the trading floor's
own **Change** column uses it for, a few pixels along the same row - so the same glyph would mean two
things on one screen. Fidelity, Vanguard, Schwab, Robinhood, E*Trade, Webull and Coinbase all label Buy and
Sell as text and leave the arrows to the numbers. The label is the affordance; the leading-icon rule is
about row-action ghosts, not about a CTA.

**Emphasis belongs to the confirm step, not the list.** The order modal's Review order and submit
are a single `.tw-btn-primary` in brand teal, with Cancel and Back as secondary beside them - one
primary button, alone, at the point the money actually moves. That also retired the amber, which
existed only to pair with the teal.

`.tw-btn-buy` and `.tw-btn-sell` are deleted; nothing references them.

**That exception is about the student view only, and it was written before anyone checked the
control was on screen.** Two things were wrong at the time:

- **Only a student with a persisted portfolio sees Buy/Sell at all.** `StockPolicy#show_holdings?`
  gates the holdings *and* actions columns, so a teacher or an admin gets a two-column read-only
  price list with no call to action anywhere. That is correct - they hold no portfolio and cannot
  trade - but it means "the trading floor's CTA" does not exist for the role most of the admin work
  is done under, which is how it came to be described as invisible.
- **On a phone the buttons were off screen.** As a trailing column they measured `left=370` inside
  a wrapper `326px` wide, with `scrollWidth 548 > clientWidth 326`: the only call to action in the
  student-facing product sat past the right edge of a horizontal scroll at 375px. Nothing failed,
  because the buttons were present and clickable and every assertion about them passed.

**So below `lg` the holdings figure and the trade buttons render inside the primary cell**, which is
the one cell always on screen, and the two trailing columns are `hidden lg:table-cell`. Measured
after: `left=33` inside a `16-344` wrapper and `scrollWidth == clientWidth`, so the table no longer
scrolls sideways at all. Collapsing secondary columns into the primary cell is the Polaris / Primer
treatment for a data table on a narrow viewport; the alternative, a sticky actions column, keeps the
horizontal scroll that caused this.

`stocks/_trade_actions` holds the pair so the two placements cannot drift.

### A component class must lose to a utility

`buttons.css`, `tables.css`, `cards.css`, `forms.css` and `navbar.css` are wrapped in
**`@layer components`**. They are imported after `@import "tailwindcss"`, and an **unlayered rule
beats every layered one regardless of specificity** - so `.tw-btn-buy { display: inline-flex }` was
winning against `.hidden { display: none }`. The order form's Back and submit buttons both carry
`hidden` and both rendered anyway: the buy/sell modal showed **Cancel, Back, Review order and Buy
shares all at once**, in the product's core flow. The flow still worked, so no test failed, and it
is invisible in a class list - the markup says `hidden` and means it.

Any `.tw-*` or `.table-*` class is a component and belongs in that layer. Utilities come last for a
reason; a component that outranks them makes every responsive and state utility unreliable on it.

### Page width: nothing may scroll `<main>` sideways at 375px

A page-level horizontal scroll is not the same as a table scrolling inside its own container. It
moves everything, it defeats a pinned cell (which pins to a container that is itself being pushed),
and it is invisible at 1366px. Measuring every page in the app at 375px found three causes, all
different:

- **A flex row that never stacks.** `classroom#show` put the roster beside the grade book list with
  a bare `flex gap-8`: 812px of content in a 328px viewport. A two-column row is
  `flex flex-col gap-8 lg:flex-row`, and the flexible pane takes **`min-w-0`** so a wide table
  cannot refuse to shrink. Measured, either one alone is enough; both are kept because stacking is
  the right treatment below `lg` and `min-w-0` guards the `lg` case.
- **An unwrappable breadcrumb trail.** `admin/shared/_breadcrumbs` was `inline-flex ... space-x-1`,
  and a school year's crumb reads "School name (2024-2025)" - 130px past the viewport, on six pages.
  Now `flex flex-wrap` with `gap-x`/`gap-y`, and the labels `break-words`.
- **An element that should have been hidden.** See the layer note above.

`test/system/page_width_test.rb` asserts `main.scrollWidth <= main.clientWidth` across signed-out,
student, teacher and admin pages, and names the offending element in the failure message. Show and
edit pages are covered as well as indexes, because the breadcrumb trail is longest there.

### Narrow-viewport tables: below `lg` a table is one column

**No table scrolls sideways at 375px.** Every one of them did, and it was reported: *"the table just
scrolls sideways and the actions go off screen"*. Measured, per table, at 375px: admin/teachers 685px of
overflow, admin/users 632, admin/stocks 595, admin/classrooms 579, orders 489, admin/transactions 404,
the grade book 398, the roster 364, admin/students 332, admin/school_years 299, teacher classrooms 227,
admin/schools 196, portfolio holdings 101, admin/student show 88 and 152. All zero now.

**The trading floor was the exception that showed the way.** It measured 0px because it was the one
table that collapsed its secondary columns into the primary cell instead of scrolling. That treatment is
now every table's: below `lg` the secondary cells are `hidden lg:table-cell`, and their values come back
as labelled lines inside the primary cell via `shared/_stacked_row_fields`, with the row's actions
underneath. Polaris's `IndexTable` condensed mode and Primer's guidance for the same problem.

**Two mechanisms, and the choice between them is not stylistic.**

- **Collapse** (`hidden lg:table-cell` + `shared/_stacked_row_fields`) where the row has an identifying
  primary column to collapse *into*, and where the cells hold text, badges and links. Table semantics
  survive: below `lg` it is a one-column table. The content is captured once per row and rendered at
  whichever width applies, so the two widths cannot drift apart.
- **Reflow** (`.table-stacked` in `tables.css`) where there is no primary column to collapse into - four
  peer columns of date/type/reason/amount - or where a cell holds a **form control**. The grade book is
  the second case and it is not a preference: restating an input in the primary cell would put two
  controls with the same `name` in one form and the second would win on submit. Reflow keeps one DOM and
  one input per field, and each control gains a real `<label for>`, which a `<th>` never gave it. The
  cost is that `display: block` removes table semantics below `lg`; for a form that is the better half
  of the trade.

**A duplicated link is fine; a duplicated input is a bug.** The collapse renders a row's actions twice,
one copy `display: none`. That is out of the accessibility tree and invisible to Capybara, which is why
it is safe - but **a request test has no CSS and counts both**, so `assert_select "tbody a[href*='/edit']"`
doubled. Scope such an assertion to `td.table-actions-pinned`.

**At `lg`, a table earns its width back by wrapping - it does not drop a column.** The question was what
to do about the residual overflow at 1366px, and the answer came from measuring rather than choosing:

- **The primary cell never gets `whitespace-nowrap`.** It holds the prose - a name, a company, an email -
  and it is what made these tables wider than a Chromebook. The portfolio holdings table has always
  worked this way; design.md already recorded that it "never scrolls at any width, because it adapts by
  wrapping the company name". Applied to the rest: admin/classrooms went from 286px of overflow to 213px
  at 1024px, and every table that overflowed a Chromebook stopped.
- **A URL shows its host.** `admin/stocks` still ran 38px past a Chromebook after that, from a single
  267px `https://www.verizon.com/...` in a `whitespace-nowrap` cell - the widest cell in the app.
  `AdminHelper#format_url` renders the host, linked, with the full URL in the title and the href, which
  is what Stripe, Linear and GitHub do with a URL in a table. 38px to 0.
- **No column is dropped.** `ID` is sortable and it is what an admin quotes in a support conversation,
  and dropping it recovers ~60px that wrapping recovers anyway. Dropping columns at `lg` would also need
  a breakpoint this system does not have - only `base` and `lg:` - so it would mean hiding them on a
  desktop too.
- **Dates, figures, badges and the actions cell keep `whitespace-nowrap`.** A date broken over two lines
  reads as a mistake, and a figure is short enough not to matter.

**What is left is 1024px, and horizontal scroll is the right answer there.** At Tailwind's `lg` minimum
admin/users still runs 202px past its container, admin/stocks 298px and admin/teachers 251px. That is
where the pinned cell does its work, and it is what AG Grid, Polaris `lastColumnSticky` and Stripe all
do at a width too narrow for a dense table and too wide to stack. `in_lg_minimum_viewport` exists for
exactly this width, because a test written at 1366px now passes without exercising anything.

**Pinning is still needed, at `lg`.** It is not dead code: measured at 1366px - the Chromebook width
this app is used at - admin/users still overflows by 64px and admin/classrooms by 90px with seven
columns, and at 1024px by 406px and 432px. Below `lg` there is no longer any scroll for a sticky cell to
hold its place against, so the test for it runs at a Chromebook width and **asserts the overflow exists
before asserting anything about it**.

**What the earlier rule got wrong.** It said column-hiding could not solve this, because three labelled
ghost actions are ~250px against a 343px viewport, so data and actions cannot share a row. True only
while the actions have a column of their own. Collapsed into the primary cell they need no width beside
the data, and the scroll goes away entirely.

**1. The trailing actions cell is `.table-actions-pinned`** - `sticky right-0`, with its separator
and opaque ground appearing **only once the table has actually been scrolled**, which the
`table-scroll` controller records as `data-table-scrolled` on the wrapper.

That condition matters, and getting it wrong was reported. The separator used to be unconditional
below `lg`, so on the student portfolio's holdings table - scrollable at 375px but not yet scrolled -
it drew a **stray vertical rule beside the Trade button**, and the opaque ground swallowed the row's
hover tint. **Scroll state, not a breakpoint, decides**: a table that fits needs no separator at any
width, and a table that has been scrolled needs one at every width. One capturing listener on `body`
covers all eleven scroll wrappers, because scroll does not bubble but does capture. Without
JavaScript the cell still pins and simply has no separator, which is the right way round. Every admin index table overflowed at 375px,
between 212px and 699px of it, with the actions last, so View / Edit / Delete sat past the right
edge: `admin/users` had Edit at `right=887` against a visible edge of `343`. Column-hiding cannot
solve it - three labelled ghosts are about 250px, roughly 73% of a 343px viewport, so data and
actions do not fit side by side at that width whatever you drop. The column has to stop scrolling.
Pinning the last column is AG Grid, Polaris `lastColumnSticky` and Material. Pinned only below
`lg`, so at the width admin is actually used at the cell is ordinary and the row hover tint is
unbroken. (Historical: those 375px figures are what the collapse above replaced. The mechanism now
earns its keep between `lg` and a table's natural width.) A pinned cell needs an **opaque** background or the scrolling columns show through it.

**Where the action is the point of the page, collapse instead of pinning** - that is the trading
floor, where Buy and Sell move into the primary cell below `lg`. Pinning keeps a horizontal scroll;
collapsing removes it. Use pinning for utility row actions in a dense admin table, collapsing where
the row's action is the reason the page exists.

**2. `<main>` must not scroll sideways at 375px.** `classroom#show` laid the roster beside the
grade book list with a bare `flex gap-8` at every width - 812px of content in a 328px viewport - so
the whole page scrolled horizontally and carried every row action off screen. **Pinning cannot fix
this**, because a cell pins to its own table's scroll container and that container was the element
being pushed right. A two-column row is `flex flex-col gap-8 lg:flex-row`, and the flexible pane
needs `min-w-0` or a wide table will refuse to shrink. Check `main.scrollWidth` against
`main.clientWidth` before pinning anything.

**A column's sort link is exempt.** It scrolls with the column it sorts, so scrolling brings the
column and its control into view together; that is inherent to a scrollable data table rather than
a hidden action. Only the trailing actions cell is asserted.

**A scroll container built from pure data needs `tabindex="0"` and `role="region"`** with a name -
axe `scrollable-region-focusable`. Every other scrolling table here holds row-action links, which
give a keyboard user a way to scroll it; `grade_books/_table` holds only grades and had neither, so
its off-screen columns were unreachable without a mouse.

**The accessibility result for this work, measured.** On the grade book, the classroom page and the
classrooms list, at 1400px and 375px: **no contrast failures**, **no unnamed controls**, **no duplicate
ids**, and **no 2.5.8 failures**. Worth keeping because two of those numbers were wrong the first time I
produced them, in both directions:

- **Compute the accessible name with the browser, not by hand.** My first pass checked `aria-label`,
  `label[for]`, text content and `title`, and reported the trading switch as an unnamed control. It is
  wrapped in a `<label>` containing "Trading" - an *implicit* association the name algorithm handles and
  a hand-rolled check does not. `Accessibility.getFullAXTree` over CDP gives Chrome's own computed names
  and cannot be fooled that way.
- **2.5.8 is a size rule with a spacing exception, and an `sr-only` input is not the target.** Measuring
  the input reported four 1x1 failures per grade-book row; those radios are visually hidden and the
  target is the `.tw-segmented-option` label that activates them. And the genuinely small targets - a
  16px sort link, a 17px row link - pass on **spacing**: nothing else comes within 24px of their
  centres, measured at 51-305px. A size-only check condemns every text link in a table.
- Duplicate ids matter here specifically because the collapse renders a row's actions twice. It
  introduces none: the row actions carry no ids.

**A table that stops being a table below `lg` loses 1.3.1 relationships, and has to pay for them.** With
`display: block` the grid semantics are gone from the accessibility tree in Chrome and Firefox. That is
only acceptable where the information comes back another way: in the grade book every control gains a
real `<label for>` - which a `<th>` never gave it - and in the read-only reflowed tables every cell
carries a visible `.table-stacked-label`. The collapse pattern keeps the semantics and does not need
this argument, which is a reason to prefer it wherever there is a primary column to collapse into.

**An audit that looks only at pinned cells cannot see a table without them.**
`table_actions_reachable_test` queries `td.table-actions-pinned`, so the grade book - a table of form
controls with no actions column - was invisible to it while four inputs per row sat off screen. And
`page_width_test` asserts `main` does not scroll, which is a different question: a table scrolling
inside its own container leaves `main` perfectly happy. `table_stacking_test` asserts the thing neither
of them did - that no table's scroller overflows at 375px, on every page, for every role.

**"Present" is not "reachable."** `assert_selector` and `click_on` both passed against a control
sitting outside its scroll container, so `test/system/trading_cta_test.rb` asserts the visible copy's
box is *within* the wrapper's box at 375px and 1366px, and that the wrapper does not scroll.

**A `hover:` state cannot be verified from a system test in this repo.** Tailwind v4 emits hover
utilities inside `@media (hover:hover)`, and the headless Chromium the system tests drive reports
`(hover: none)` -- measured: the Delete link stays slate with the pointer over it while
`el.matches(":hover")` is `true`. So hover is asserted as a class contract in
`test/helpers/button_helper_test.rb`, and the resting colour, icon count and height are asserted as
rendered pixels in `test/system/row_actions_test.rb`. Note also that the compiled stylesheet is
**minified**, so grepping it for `@media (hover: hover)` finds nothing while
`@media (hover:hover)` finds nine.

What this replaced: the same three actions written six ways across nine tables -- View as `tw-link`
in five and `text-sitf-primary-dark hover:underline` in a sixth, Edit as `text-slate-600` or
`text-slate-700`, Delete as `text-red-600` in four and `font-medium text-red-700` in another, plus
an icon-only `_action_icon_button` partial with no visible label.

**Buttons live outside `app/views` too.** `app/form_builders/admin/form_builder.rb` backs eleven
admin forms and its `submit_button` was `bg-blue-600` at `rounded-md px-4 py-2` -- so every admin
form's primary button was off-brand *and* a different size from the primary button in the page
header directly above it, for as long as the audit paths were `app/views`, `app/helpers`,
`app/assets/tailwind` and `app/components`. Tailwind scans `.rb`, so it compiled and shipped.
`app/components/shadcn/form_builder.rb` was worse: its `submit` delegated to the shadcn
`render_button`, whose `--primary` is a near-black navy, which is why the sign-up page had the only
off-brand primary button in the product. **Add `app/form_builders` and `app/components` to every
sweep.**

### Inputs
`tw-input-primary` (see `forms.css`). Do not hand-write the class list: this used to prescribe one, in
a `brand-500` this app does not define, and the token exists precisely because nine forms had drifted
apart writing their own

Placeholder ink is **`slate-500`**, like every other muted string -- `slate-400` is 2.63:1 and a
placeholder is text. All 50 placeholder sites in `app/` already use `slate-500`; this token was the
last `slate-400` placeholder left anywhere, and only in the doc.

**A date field prefilled with "today" has to get it from the browser.** The app sets no
`config.time_zone`, so `Date.current` is **UTC**: a server-rendered `value: Date.current` reads as
**tomorrow** for anyone west of UTC in the evening (after 8pm in New York) and as **yesterday** for
anyone east of it in the morning -- and yesterday silently drops today's records out of a range. Where
the field applies immediately, render `Date.current` as the no-JS fallback and have the controller
overwrite it on connect with today in the browser's zone (`new Date(now - now.getTimezoneOffset() *
60000).toISOString().slice(0, 10)`; a plain `toISOString()` is UTC and reintroduces the bug). Proven with
a CDP timezone override: in `Pacific/Kiritimati` the server said 2026-07-30 and the field correctly held
2026-07-31.

**Never pre-fill one end of a dependent range.** If the range belongs to a record chosen elsewhere on the
form, **both** ends stay empty until that record is picked, then fill together -- and empty again if the
selection is cleared. A "Starting from" that waits for the case while "Ending at" already shows today
reads as a half-broken form, and it cost three rounds of "the start date still isn't defaulting": the
complaint was the **asymmetry**, not the blank. So the picker modal renders neither date server-side,
while the case-page modal -- where the case is fixed -- fills both from the moment it opens.

**A JS-set "today" cannot be asserted against `Date.current`** -- `travel_to` freezes Ruby's clock, not
the browser's; specs compare against `browser_today` (`spec/support/browser_time_helpers.rb`).

**A prefilled default that depends on another field can't be server-rendered.** Carry the per-record
value on each `<option>` as a `data-` attribute and let the controller copy it across on `change`, reading
the native `<select>` rather than any widget's internal option data -- as
a date-range modal does for a "Starting from" default. Re-apply on every change, so
switching records does not leave the previous record's default behind.

### Select
A native `<select>`, but the browser's arrow is replaced with a lucide chevron so it
looks the same across browsers and matches the app's other dropdowns (the cases-index filter
is the reference). Wrap the select in a `relative` div and overlay the chevron:

```erb
<div class="relative">
  <%= form.select :field, options, { label: "Field" }, { class: "tw-input-primary" } %>
  <%# Or, in an entity form, `f.select` on `Ui::FormBuilder`, which supplies the class itself. %>
  <i class="bi bi-chevron-down pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 text-xs text-slate-500" aria-hidden="true"></i>
</div>
```

`appearance-none` hides the native arrow, and **`pr-9` is required** so the value never
crowds the chevron: a plain `<select>` with `px-3` collides the text with the native arrow.
Chevron ink is `slate-500` (AA). Month/year pickers reuse this through
a month/year select pair (keeping Rails' `_1i`/`_2i` date-part field names).
The cases-index filter is the reference for the **chevron**, not for the padding above: a
*filter* control is one step more compact than a *form* field (see "Filter bar").

### Search field in a filter bar
**Search as you type, debounced (~350ms) on `input`.** A text input fires `change` only on blur or
Enter, so a filter bar wired only to `change` looks broken: typing does nothing. Worse, the
unsubmitted text is still in the form, so it applies itself the moment the user touches any *other*
filter -- which reads as "the search box keeps letters I typed". Reported exactly that way on the
one roster; another index had it too.

`auto-submit` handles both: selects stay on `change->auto-submit#submit`, the search field gets
`input->auto-submit#search`.

**Turbo Drive is OFF app-wide** (`application.js`: `Turbo.session.drive = false`), so each submit is
a **real page load** -- do not assume otherwise from a partial's comments (two filter bars claimed
"Turbo Drive keeps it smooth"; verify with a `window` marker before the submit, which is how this was
caught). That means the search box is destroyed and rebuilt on every keystroke-pause, so without help
focus lands on `<body>` and the next letter goes nowhere. `auto-submit` parks
`{name, selectionStart, selectionEnd}` in **`sessionStorage`** (module/instance state does not survive
a page load) and restores it in `connect()` inside a `requestAnimationFrame` -- an immediate `focus()`
was measured being undone as the new page settled. Verify by reading
`document.activeElement === field` and `selectionStart`, not by eye.

**The clear "x" must cancel the pending debounce: `data: {action: "click->auto-submit#cancel"}`.**
The `x` is a plain link to the index without `search`, and the click starts a real page load that does
*not* tear the controller down right away -- so a debounce still in flight fires during the unload and
submits the query the user just cleared, and *that* navigation wins. The search comes back, which reads
as "clear is broken". In the docker container it reproduced on 4 of 4 runs with the handler removed and
on none of 7 with it, so it is a real bug and not a test artifact; it surfaces whenever the click lands
inside the ~350ms window, which is easy on a loaded machine and why CI caught it first. Any control that
navigates away from a debounced filter bar (not just this `x`) needs the same cancel. `disconnect()`
clearing the timer is not enough -- a full page unload does not reliably run it. In a spec, wait for the
*submit* to land (`have_current_path(/search=.../)` plus the result-count text) before clicking
anything; asserting on `find("#search").value` proves nothing, because the input reads the typed text
back instantly, submit or no submit.

### A stat's period must be stated, and must be true
The learning-hours roster column read **"Time completed this year"** while neither aggregate scope
filtered `occurred_at` -- so the number was an **all-time** total. Proven rather than read: 1h today +
2h from three years ago + 4h from Dec 31 returned 420 minutes, not 60. A header that names a period
the query does not apply is worse than an unlabelled one, because it is trusted.

Rules for any "total over a period" figure:
- **Name the period in the header**, with its start date -- "Time completed / since January 1, 2026"
  (or "X to Y" when the end is not today). "This year" is not a specification: nobody can tell whether
  it means calendar, fiscal, or rolling.
- **Let the user change it.** A `from`/`to` pair in the page's filter bar, same tokens as the other
  rosters, auto-submitting on `change`; `shared/_pagination` carries the params.
- **Clamp the parsed dates.** `Date.parse` accepts `"0730-02-02"`, which put "since February 2, 0730"
  in the header. Clamp to the domain's real window -- here 1989-01-01 (what `LearningHour` validates)
  to today.
- Keep the range **optional** in the model scope (`occurred_in(range)` no-ops on nil) so the Pundit
  scopes keep meaning "everything this user may see" rather than inheriting a UI default.
- **Widen a Date range to the end of its last day.** A `Date` range against a **datetime** column
  serialises to `BETWEEN '2026-01-01' AND '2026-07-31'`, and Postgres reads that upper bound as
  **midnight** — so anything logged *earlier today* fell outside "since January 1" and the total
  silently ignored it (measured: a 09:00 entry today was excluded). `occurred_in` now expands a Date
  range to `beginning_of_day..end_of_day`; note `DateTime` subclasses `Date` in Ruby, so the check is
  `instance_of?(Date)` and an explicit time range is left alone.
- **One definition of "this year" per app.** The roster defaults to calendar year to date
  (`beginning_of_year..today`), so a figure labelled "this year" had to stop being
  `occurred_at > 1.year.ago` — a rolling 12 months, which on 31 July counted the previous August. It is
  `learning_hours_spent_in_current_year` now, through the same scope, and the label **names the year**
  ("Learning hours in 2026") rather than saying "this year".

**Presets + custom, with the resolved dates shown.** Calendar **year-to-date** is what users expect
"this year" to mean, and the convention (Stripe, GA, Shopify, Polaris) is a short list of named windows
one of which is Custom. The learning-hours roster ships exactly that — *Year to date* (default) /
*Last 12 months* / *All time* / *Custom* — as a `period` param resolved in `set_period`, with the
column header naming the resolved window ("since January 1, 2026", "January 1 to March 31", or plainly
"all time"). Two details worth copying: the **From/To inputs render only for Custom**, so the bar stays
short for the cases a preset already covers; and a URL carrying `from`/`to` with **no** `period` is
treated as Custom, so a link saved before the presets existed does not snap back to year-to-date. "All
time" passes `nil`, which `occurred_in` no-ops on, rather than a sentinel floor date — a header reading
"since January 1, 1989" would be technically true and useless. What is *not* standard is a label that
names a period the query does not apply.
- `date.formats` has no `:standard` -- that lives under `time.formats`. For a Date use `:full`
  ("January 1, 2026").

### Filter bar

Two shapes here, and the difference between them is the point of the page-rhythm rule above.

**The search filter** (`admin/shared/_search_filter`) is a `tw-card mb-6 p-5` holding one search
field, any number of selects, a Filter submit and a Clear link -- a bordered card, so it is a
*section* and keeps the 24px gap. **The discard tabs** (`admin/shared/_discard_filter_tabs`) are a
plain `mb-4 flex gap-1 border-b` row of Active / Archived tabs -- borderless, so 16px.

**Layout: one toolbar row, not a titled panel.** The list-toolbar standard -- GitHub issues, Linear,
Jira, Notion, Polaris, Stripe -- is a single horizontal row directly above the list. There is **no
visible "Filters" heading**: the controls say what they are, and a heading costs a whole row. Each
control keeps an `sr-only` label so it is still named for assistive tech; a placeholder is not a
label.

**Clear renders exactly when a filter is applied**, never at the defaults, where it is dead chrome --
Polaris and Jira both gate it this way. Judging that is fiddlier than it looks: a checkbox always
posts a value even when unchecked, and array filters can arrive as `[""]`, so neither can be decided
by bare presence.

**A sort is not a filter.** A non-default sort must not put a control labelled *Clear filters* on
screen, and clearing must not silently reorder the list. Sorting here is `sort_link`, which carries
the current filter params through, and Clear returns to `request.path`, which keeps nothing -- so if a
sort ever needs to survive a clear, that is the thing to change.

**Label a sort control `Sort by`** (Jira, Polaris, Amazon; GitHub shortens it to `Sort`), not Rails'
auto-humanised "Sorted by", and never `Filter by`: it changes the order, not which rows show.

**A native `<select>` arrow cannot be inset.** Chrome draws it against the edge of the field's
padding, so it always reads tighter than the rest of the field's contents. `appearance-none` plus our
own chevron, styled on `select.tw-input-primary`, so every select in the app is fixed at once rather
than call site by call site.

**Never mix submit mechanisms on one filter bar**, or it behaves two ways at once. A native
`form.submit()` does a full-page submit; `requestSubmit()` fires a real submit event that Turbo
intercepts and, if the form carries `data-turbo-frame`, scopes to that frame only -- so anything in
the bar that lives outside the frame goes stale while everything inside it updates. The trap when
testing this: a frame update **preserves the document**, so tagging `window` and finding the tag still
there proves only that no *full* navigation happened, not that a submit fired. Assert on the chrome
that must change.


### Form layout
Forms use a **two-column responsive grid**: `grid grid-cols-1 gap-5 sm:grid-cols-2`, which
collapses to one column below `sm`. Wide fields (case number, a multiselect) get
`sm:col-span-2`; compact fields (dates, a status select, a single-value select) take one
column. Keep to just two widths, full and one-column, so it does not look loose. The submit
is a single primary button at the **bottom** (no top CTA on a fill-then-save form), verb-first
and sentence case ("Create case", "Save changes"). Month/year pickers use
a month/year select pair.

A **section heading** inside a form card (e.g. "Classroom details") lives **outside** the
grid, not as a grid child, so it does not inherit the uniform `gap-5` on every side. Give
the heading `mb-3` (12px) so it hugs the fields it introduces, and put the field above it
(e.g. case number) in its own block with `mb-6` (24px) for section separation. A heading
left as a grid child floats with equal 20px above and below and reads as detached.

**Simple CRUD forms** (the admin long-tail — schools, school years, stocks,
learning-hour types/topics, and other name(+active) resources) share one partial,
`shared/_settings_form` (locals: `model`, `title`, `show_active`, `description`). It renders the
app layout's page shell + a card with a required name field, an optional `Active?` checkbox, an
optional intro paragraph, and a Submit button; `form_with model:` infers the url + param key.
The resource's `_form` is a one-line `render`, and its controller sets `the app layout` +
`@active_nav = "settings"`. No breadcrumb (keeps it free of `current_organization`, so the
no-layout view specs render it standalone); save redirects back to the settings page.

### Rich text (Trix)
ActionText `rich_text_area` fields work on the app layout because `tailwind.css` `@import`s
`trix/dist/trix.css` alongside `tailwindcss` + tom-select. Trix's styles otherwise ship only in
the legacy `application` bundle, which the app layout does not load — without the import the toolbar is
unstyled and blows the page width to ~900px on every screen. Trix's default `.trix-button-row`
is `overflow-x: auto`, so once loaded the toolbar self-scrolls on narrow screens (the page fits;
the measure script surfaces the contained button row like a scrolling table). Give the editor
design-system chrome via `class: "trix-content rounded-lg border border-slate-300 shadow-sm"`.
The banner form is the reference.

### Type-ahead and multiselect: not in this app
Three sections lived here specifying TomSelect - a rich multiselect component, a searchable
single-select used by six person-assignment pickers, and an audit of twenty such controls. **This app
has none of them**: no TomSelect, no type-ahead, no multiselect, and its one long list of people (the
classroom form's teacher picker) is a checkbox group.

They were inherited with the rest of this document from Ruby for Good's CASA project, and they were
deleted rather than translated. A rule needs an example, but a *specification* for a control nobody has
built is not a rule - it is an instruction to build one, and the next person to need a searchable picker
would have implemented CASA's.

What survives, because it is a decision this app has actually taken: **a checkbox group is the right
control for a short, fully known set of options**, and beyond roughly ten it should become a searchable
multi-select with chips - GitHub's assignees picker, Linear's, Jira's. That threshold is the trigger, and
it is recorded on the classroom form, where it will be met first.

The four rules from those sections that would apply to **any** picker - clear the query on select, address
the native `<select>` rather than the widget, assert filtering by a decoy's absence, and never leave an
option's subtext nil - are kept in
[`docs/type-ahead-and-multiselect.md`](docs/type-ahead-and-multiselect.md), with the command that
retrieves the full original from git. They are not repeated here: a specification for a control this app
does not have belongs outside the document that describes the one it does.
### Repeatable rows: not in this app

There is no repeatable sub-form here. The one `fields_for` is `grade_books/_grade_entry`, which
renders a **fixed** row per student -- the set is the roster, not something the user adds to -- and
the only `accepts_nested_attributes_for` is a portfolio, created by a model callback.

Two rules from the sub-form spec are worth keeping, because they are about forms in general:

**A repeatable entry follows "Form layout" -- it is not exempt for being repeatable.** A wide field
takes the full width on its own line even inside a row that repeats; squeezing the main content field
into a fraction of the width to fit a select and a button beside it is the thing that section exists
to prevent, and a per-entry bordered box is a card inside a card. Separate entries with a **hairline**,
not a box each, and give the add row **no rule of its own** -- a second hairline of the same weight
reads as another entry rather than a section break, so space separates it, which is also what GOV.UK's
"add another" does.

**A note does not override a rule above it; if they disagree, the note is the drift.** That spec once
described the opposite arrangement, and the wording was then used to justify keeping it through two
rounds of fixes -- including one where three cramped controls were carefully measured into alignment
without anyone asking whether they belonged on one line at all.


### Autosave
The **grade book** (`grade_books#show`) is the app's one autosaving form, and it is the reference.
Everything else is explicit save.

**Save on blur, with a timer as the backstop -- not a timer alone.** Finalizing pays whatever is in
the database, so anything typed and not yet saved is money that will not be paid. With a 30-second
interval as the only trigger there was a window in which a teacher could enter a grade, press
Finalize, and pay the previous one, with nothing on the page saying so. Saving when a field loses
focus closes that window at the root; the interval stays for the field left focused, because somebody
typing in the last cell and walking away never blurs it.

`blur` does not bubble, so the listener is **capturing**, and a `change` flag stops a save firing for
a field somebody only tabbed through -- which is most of them.

**Bind on the form, never per field.** One listener on the `<form>` covers every control type and
cannot be forgotten when a field is added. Per-field triggers produce a genuinely confusing form:
only the fields that carry the trigger save themselves, so an edit elsewhere is *silently dropped*
when the user navigates away -- unless they also happen to touch one that does, because an autosave
posts the entire form and therefore commits everything. Whether your work persisted would depend on
which field you touched last.

**Keep the steady state quiet.** The status line used to change three times per edit -- "Saving…",
"All changes saved", then a new timestamp -- which on a 25-student book is about three hundred
redraws in one spot while a teacher works. Docs, Notion and Figma all leave the resting state
unchanging and none of them counts saves at the user. So: no timestamp ever, since "when" is not the
question being asked and it was the churn; "Saving…" only if a save is still running after 800ms, so
an ordinary edit changes nothing on screen at all; and a **failure says so and stays**, because it is
the one state a teacher has to act on. Assign the text only when the words actually change --
rewriting the same string still replaces the text node, which the eye catches and which an
`aria-live` region re-announces.

**Replace the derived cells by id, never the table.** A derived figure must refresh with whatever
derives it, so the response updates the Earns column -- but the cursor is in an input, and replacing
the table takes the focus and any half-typed value with it. An element also has to *exist* to be
replaced, so a conditional block needs an always-rendered container carrying the id.

**"Derived" includes the warnings, not just the figures.** Correcting the Earns column in one commit
while leaving both halves of a warning out of the same turbo\_stream fixed the numbers and left the
notification still accusing. When you find one stale derivation, list every derived thing on the page
before moving on: figures, totals, summaries, warnings, counts.

**The autosave clicks a button, so mind which one.** The finalize button briefly carried
`autosave_target: "button"`, which would have had the timer press an irreversible action on a schedule.
Only the save button is a target.

**Testing an autosave: prove the save, not the keystroke.** `click` and `send_keys` do not block, so
reading the database straight after asserts against a request still in flight. Wait on the status
line reaching its settled text, then assert the record. And when the correct outcome is that
*nothing* happened there is no positive state to wait on, so a short documented `sleep` is the honest
instrument -- verify such a test by making the thing happen and watching it fail.
`test/system/grade_book_autosave_test.rb` is the worked example.

Because the form autosaves in full it needs **no Cancel and no unsaved-changes warning**. The two
coherent models are "everything autosaves" (Google Docs, Notion, Linear: navigation is the exit) and
"explicit save" (GitHub, Jira: Cancel plus a `beforeunload` guard when dirty). This form is the first.
A partially-autosaving form is neither, and is the state to avoid.

**An input in a table cell is sized to its content**, not `w-full`, and **a `<th>` does not name a
form control** -- an input inside a cell takes no accessible name from its column header, so a table
of inputs is a table of unnamed controls. Give each an `aria-label` naming the field *and* the row,
because the row is identified visually only.


### There is no Bootstrap here

The spec this document came from was mid-migration, and several rules exist to keep Tailwind and
Bootstrap apart -- twin partials, JS hooks preserved across both, classes that render unstyled on the
other side. **None of that applies.** This app has one stylesheet system: Tailwind v4, plus the
`.tw-*` component classes in `app/assets/tailwind/`.

What transfers is the reason those twins existed: **a style written in two places survives every
sweep of one of them.** That has bitten here without any framework split at all -- the grey table
header lived in a shared class *and* in an inline `<thead>` on fourteen admin tables; the button base
existed in `buttons.css` *and* as a Ruby constant. Two definitions of one thing is the drift
mechanism.

### Card / panel
`rounded-2xl border border-slate-200 bg-white shadow-sm` (pad `p-5`).

**Padding either side of the header rule is 16px, not the card's full `p-5`.** A `py-4` header
above a `p-5` body stacks to 36px, measured at 37px from the header text to the first line of
content - which reads as a gap rather than a boundary. 16px either side (32px) is what Stripe's
Box and Primer's `Box.Header` use. A card with no header keeps the full `p-5`.

**Implemented as `.tw-card`** in `app/assets/tailwind/cards.css`. Use it for every card,
including the ones holding tables; `components/ui/_card` wraps it. Padding is deliberately
not part of the class, because a card holding a flush table needs none - callers add `p-5`,
or pass `padded:` to the partial.

**`p-5` means `p-5`, at every width, and it was written four ways.** Swept: the ten admin form
partials were `tw-card > div.px-6 py-6`, the component demo used `p-4` and `p-6`, the search filter
bar `p-4`, and three app-side form cards had picked up an undocumented `lg:p-6`. Twenty-two card
bodies, four values, one token. The visible cost was on a phone: 24px of padding either side leaves
a field 278px wide at 375px against `p-5`'s 286px, so the half of the product with the *denser*
forms was also the more cramped one. This is the two-definitions failure again - the value is stated
here, so a call site that restates it can only agree by luck.

The surface had drifted into four treatments across seven distinct class strings in 22
files: `rounded-xl`/`shadow-xs` in the component, `rounded-lg` with `ring-1 ring-slate-900/5`
instead of a border throughout admin, and two one-off variants in student-facing views. None
of them matched this spec. Naming it once is what stops that recurring - a class string
copied 27 times cannot be held consistent by attention.

A **content card with a leading icon** puts the icon **in the header
row** next to the title (`card-title flex flex-wrap items-center gap-2` + a 32px `h-8 w-8`
rounded-xl icon tile), **not** as a full-height gutter beside the whole body. An `items-start`
icon column indents *every* body line behind it — one card read as pushed ~48px
right, with the answers/notes hanging off the icon instead of the card edge. With the icon in
the header, the body (secondary text, answer list, actions) spans the card's full width,
left-aligned to the `p-5` edge (measured: body indent 48px -> 0). Decorative status glyphs are
never data: the transition-aged 🦋/🐛 emoji is dropped from the case-number heading (plain
number), per the Tables note.
**Type hierarchy inside a card:** the title is the only `text-base font-semibold` (slate-900)
element; every supporting / detail line is `text-sm`, and **no body line may out-weigh the
title** (a detail line once rendered `text-base font-bold` and made the body shout over the
title). Confirm the title (16px / 600) stays the sole anchor with computed style, not by eye.
**Progressive disclosure, not per-line truncation:** collapsible detail (a card's
topic answers + notes) goes in **one** native `<details>` "Show details" toggle that reveals the
whole block at full length — a `dl` of `text-xs font-semibold text-slate-500` `dt` +
`text-sm text-slate-700 whitespace-pre-line` `dd`, matching the new-design table's expandable
detail. **Never** give each line its own truncate + `read more`: reading a single note then cost
several clicks (the recurring "excessive truncation" bug). The `<summary>` swaps Show/Hide via
`group-open:` and is a `brand-600 font-medium` link with the marker hidden
(`[&::-webkit-details-marker]:hidden`).
**Dividers, not nested cards:** don't box a card's revealed detail in its own `rounded-xl border`
panel — a card inside a card isn't a pattern in this app. Separate the disclosure with a
`border-t border-slate-100 pt-3` rule on the `<details>` (as `metric_data_table`'s "View as
table" does) and render the `dl` unboxed. `border-b` *under the title* likewise over-segments a
compact card; structure comes from that detail divider and the footer `border-t`. WCAG: the
native `<details>`/`<summary>` carries its own expanded/collapsed semantics (keyboard + SR), the
chevron is `aria-hidden`, and the `brand-600` summary + `slate-500` labels clear AA on white.

**Scope note for this app.** The `border-b`-under-the-title sentence above is about a
*compact content* card, and it leans on the detail divider and footer rule it names. A card
holding an attribute list or a table has neither, so `components/ui/_card`'s header **does**
carry `border-b border-slate-200` — see Dividers. Applying that sentence to a data card
leaves it with no boundary at all, and its header padding stacking on the body's.

### Fact / detail list
Entity facts (the case-details card) are inline `dt` (muted `font-medium text-slate-500`) :
`dd` (dark `text-slate-800`) pairs. Put any **derived / secondary** value (a relative
duration, a submitted-at timestamp) on a **muted second line** (`mt-0.5 text-xs
text-slate-500`), never as a light suffix after the dark value on the same line as the light
label: light-dark-light on one line reads as broken. Keep the "Label:" wording (specs match
it) and reword derived text to be self-explanatory ("In care for over 8 years", not
"(over 8 years ago)").

**A label with nothing after it is a bug, not an empty state.** Omit the whole `dt`/`dd` pair when
the value **cannot exist yet** -- one card rendered "Unassigned:" with an empty
`dd` on every *active* assignment, leaving a hanging colon (and duplicating what the "Assigned" pill
already said). Use the muted **"Not set"** value only where the field genuinely applies but is unfilled
where one exists. Guard it by asserting no `dd` is blank, not by
eye.

**Keep a card to the type scale: two sizes, two weights, and let colour carry the role.** A person /
assignment row is a resource-list item -- identity, muted secondary identity, a status pill, label:value
metadata, then actions -- and each role gets exactly one treatment:

| role | token |
|---|---|
| identity (name) | `text-sm font-medium` + `name_link_class` |
| secondary identity (email) | `text-sm text-slate-500` |
| status | the pill (`text-xs font-medium` + tint) |
| fact label / value | `font-medium text-slate-500` : `text-slate-800`, **both at `text-sm`** |
| a **control's** label | the Label token, `text-sm font-medium text-slate-700` |

Only the pill is `text-xs`; everything else in the row is 14px, with weight and colour carrying the
role (measured on one row: 6 size/weight/colour combinations, each mapping to exactly one role).
**Inline vs stacked:** an inline `dt: dd` pair keeps ONE size for label and value -- 12px against 14px
on a shared baseline reads as ragged. The 12px label belongs to the **stacked** variant, where it sits
*above* its value (`dt text-xs text-slate-500` / `dd mt-0.5 text-sm text-slate-700`, as in the
a mobile card list); there the size step is the hierarchy cue. Either way the value stays at
`text-sm` (see Typography: 12px is chrome, not content).

What made this card unparseable was not the *number* of styles but that two different roles shared
one: a checkbox label sat at `text-xs font-medium text-slate-600` while the
fact values were `text-xs font-medium text-slate-700` -- visually the same thing, so an actionable
control read as another piece of metadata. Measured before/after on one row: 7 size/weight/colour
combinations -> 6, but every remaining one now maps to a single role. **Give a control the control
token; never the metadata token.**

### Table (in a card)
Full-bleed table inside an `overflow-hidden rounded-2xl` card: a header row
(`border-b border-slate-100 p-4`), then `thead`/`tbody` with cells `px-4 py-3` and
`divide-y divide-slate-50` between rows. Add `pb-2` to the card so the last row clears
the rounded bottom corner instead of butting against it (use `py-2` for a header-less
list card — e.g. notifications — so the first row clears the top corner too). Keep rows
a uniform height (a taller last row reads as a bug).

**State that decides whether something is visible must be a pill, and fixable in one click.** The
banners list reported "Active?" as plain body text ("Yes"/"No") in the same weight as every other
cell, `create` set no flash at all, and the only way to activate was to find the checkbox on the edit
form. A banner saved without ticking Active is invisible by design, so the whole feature read as
broken -- reported as "banners do not work, when I create one it does not load", with two inactive
banners sitting in the list. Status is now the documented pill (emerald check / slate minus), each
inactive row has an **Activate** action, and create/update flash the outcome: a `:notice` (green,
auto-dismisses) when it is live, an **`:alert`** (amber, stays put) when it is not, because that one
has to be read. When an object has a published/active flag, assume nobody will infer it from a table
cell.

**Every table converged (2026-07-30).** The three separator sources -- a card title block's
`border-b`, the `thead` `<tr>`'s `border-b`, and a `divide-y` on the `<table>` element itself -- must
sum to exactly **one**, and `tbody` is always `divide-y divide-slate-50`. Swept app-wide: 15 tables
carried `divide-y divide-slate-200` on the table (a darker rule than the token, and a second one
wherever a header row also had a border), 7 still had the forbidden `thead` fill, one
had **no** separator at all, and another was on `divide-slate-100` rows.
All 41 tables now satisfy the invariant -- re-check with a static audit over
`app/views/**/*.erb`, not by sampling pages, and note that a `thead` fill hides behind longer class
strings (`class="bg-slate-50 text-left text-xs ..."` survived a grep for the exact attribute).

**Exactly ONE rule above the column headers.** A card with a title block
(`border-b border-slate-100 p-4`) already has its separator, so the `thead`'s `<tr>` must **not** add
a second -- two hairlines ~40px apart read as a mistake. Absent a title block (the cases /
most index tables here), the `thead`'s `border-b` *is* the separator and stays. Audit this app-wide
rather than page by page: when it was last done the doubling was in six places at once. It got there
by copying a neighbouring table instead of checking this section, which propagates drift rather than
catching it: **match the pattern, not the nearest sibling.**

### Tables
Hand-built Tailwind, on the `.table-*` component classes in `app/assets/tailwind/tables.css`. Every
table renders through `shared/_table_container`, which supplies the surface: `.table-wrapper` is
`overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm` -- the same surface as
`.tw-card`, because a table card is a panel and the radius token for a panel is `rounded-2xl`. It was
briefly a near-duplicate that differed only in radius and shadow, which put a 12px-cornered table
directly under four 16px-cornered cards on the portfolio page.

`thead th` is `.table-header-cell`: `align-top px-4 py-3 text-xs font-semibold text-slate-600
whitespace-nowrap` -- **never an `uppercase` / `tracking-wide` transform**. Column headers are
sentence case like every other label, and hierarchy comes from size, weight and colour. The `thead`
itself is **unfilled**: `.table-header-row`'s `border-b` is the only separator, never a `bg-slate-50`
band. That fill was written in two places at once -- this class on the app side and an inline
`<thead class="bg-slate-50">` on fourteen admin and teacher tables -- so it survived three sweeps
that each fixed one of them. **When you find a token in a shared class, grep for the inline form
too.**

Header and body cells share `px-4 py-3` so columns line up, and every `<th>` is `align-top`: a column
whose header wraps to two lines otherwise anchors against neighbours the browser has vertically
centred, which reads as stray space. Every header computed to `middle` before this was fixed.

**A cell that carries its own `py-*` is a bug, not a tweak.** `tables.css` is layered, so a utility
on the cell outspecifies `.table-body-cell` -- a class list reading `table-body-cell py-4` looks like
the shared padding is in force and it is not. One classrooms cell sat 14px below every other column
and made the row 69px against the app's 48px. The same applies to any wrapper inside the cell.

**Body cells top-align to the row's first line**, never the `vertical-align: middle` default, which
floats content centred whenever any cell in the row wraps -- **including the trailing actions cell**,
where a hand-written `<td class="px-4 py-3 text-right">` that omits `align-top` leaves Edit and Delete
floating while the data top-aligns. Match cells on the class list rather than an exact string when
auditing this: half the hand-written cells here read `whitespace-nowrap px-3 py-2 text-sm ...`, with
the padding in the middle, and were missed by a search anchored at the front.

Money and counts are **right-aligned with `tabular-nums`** so digits line up down the column, and
**the last column right-aligns whatever it holds** -- actions, a number or a checkbox. Every table
satisfied that by accident because every other one ends in actions; the one that does not was the one
that looked wrong.

Sorting is **server-side** (`sort_link`, params). There is no bulk select, and nothing paginates --
the footer partial exists but no controller ever gives it a paginated collection, so see the note
under page rhythm before assuming a table has one. Keep the `thead` even when a table is empty and put an empty-state
row in the `tbody` (`admin/shared/_empty_row` wraps `_empty_state` for this), and remember its
`colspan` when a column is added or removed.

Verify a column's data source before carrying one forward, and **ask whether any row can act**: a
column of `table-no-permission` dashes is not a column. The dash means "no action on this row", which
only says something when other rows have one; when no row does, drop the header, the cells, and one
from the empty state's `colspan`.

**Two stacked tables need one column geometry.** Separate `<table>` elements size their columns
independently, so a wider actions column in one shifts every column relative to the other and the page
steps sideways at the boundary. Give every column but the first an explicit width.

**Responsive:** no card twin and no `md:` breakpoint -- this app has only `base` and `lg:`. Secondary
columns are `hidden lg:table-cell`, and their values come back inside the primary cell through
`shared/_stacked_row_fields`, which renders them as a `<dl>` of labelled lines below the row's name
and puts the row actions beneath. One `<tr>` serves both widths, so there is no second copy to drift.

Wide tables scroll horizontally inside `.table-wrapper`'s inner `overflow-x-auto` div, and the actions
cell **pins** (`table-actions-pinned`) so it stays reachable. Two traps live here. **Measure the
element that actually scrolls** -- `.table-wrapper` is `overflow-hidden` and can never report
scrolling, so measuring it concludes "this table never scrolls at any width"; `closest("[class*='overflow-x']")`
from the cell finds the real scroller. And **"present in the DOM" is not "on screen"**: the trading
floor's Buy and Sell buttons sat at `left=370` inside a 326px-wide scroller at 375px, past the right
edge, while `assert_selector` found them and `click_on` clicked them, because Capybara's visibility
check knows nothing about an ancestor having scrolled an element out of view. Compare the control's
box against the scroll container's box at 375px, and `scrollWidth` against `clientWidth`.

The pinned cell's left separator is **conditional on scroll state**, not on a breakpoint: it draws
only once `data-table-scrolled` is set, so a table that fits or has not been scrolled does not show a
rule with nothing behind it.


### Charts

There is **one** chart in this app: portfolio value over time on `portfolios#show`, a Chart.js line
chart on a `<canvas>` in a `relative h-75` box, driven by the `portfolio-chart` Stimulus controller
from `Portfolio#chart_data`. It shows an empty state until two months of value have been recorded,
rather than drawing a single point.

**This is a deliberate divergence from the spec it inherited**, which called for bespoke
server-rendered SVG and named Chart.js as the thing not to use. One line chart does not justify a
hand-built SVG toolchain; if a second and third chart appear, that trade-off is worth revisiting, and
the reason it was written that way was accessibility -- everything below is what a canvas does not
give you for free and has to be supplied.

- **Series identity is never colour alone.** With more than one series, each carries a distinct line
  style and marker shape on top of the palette, and the legend shows that key rather than a swatch.
- **A table twin per chart:** a `<details>` "View as table" holding a real `<table>` with scope
  headers. A canvas is opaque to assistive tech, so this is not optional -- it is the accessible
  version of the data.
- **A genuine zero shows a muted `0`; a missing value shows "No data"**, never a fake zero.
- **Totals live in stat tiles, never a row sum**, and never sum a non-additive column.
- Money on a chart follows the money rules like anywhere else: integer cents are authoritative, and
  the display value is derived once.

### KPI stat card
Semantic icon tile (`grid h-9 w-9 place-items-center rounded-xl bg-{hue}-50 text-{hue}-600`) ->
number (`text-3xl font-bold tracking-tight text-slate-900`) -> label (`text-sm text-slate-500`) ->
optional meta (`text-xs text-slate-500`, not slate-400 -- the contrast audit bumped readable
slate-400 to AA slate-500). `components/ui/_stat` and `components/ui/_icon_tile` are the
implementation, shared by the admin dashboard, the portfolio page and `classrooms#show`.
**The number is ALWAYS `text-slate-900`** — one numeral style on every card, in
every state. The state is carried by the icon tile, and for the danger cards by a `ring-1
ring-rose-100` on the card: **danger** = rose tile + rose ring; **attention** = amber tile
(`bg-amber-50 text-amber-600`) when positive, emerald when zero. This entry used to prescribe a **rose number** for the danger variant,
and it was wrong twice over: the coloured numeral read as an error rather than a count, and it made
one card in four change colour while the rest held still — reported as "the number is in Red font.
This does not match the design system". Same correction as the count columns above, where red
numerals were removed for the same reason: **never colour a numeral to signal state.** A **trend
delta** belongs on the meta line, coloured emerald/rose/slate for up/down/flat with a direction arrow
and a signed number, never colour-only.

**A stat band is 134px, and that is not free.** Four across the top of `classrooms#show` put the
roster's first row at 567px of a 625px viewport. Measure the primary content's first row before and
after adding one; on that page the figures moved to the foot for exactly this reason. And use one card
holding four figures rather than four cards -- `_stat` takes `surface: false` for that.

### Status pill
Base: `inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-medium`
- On track: `bg-emerald-50 text-emerald-700` + check icon
- Needs follow-up: `bg-rose-50 text-rose-700` + exclamation icon
- Neutral / deactivated: `bg-slate-100 text-slate-600` + minus icon (**slate-600**, not
  slate-500: on the slate-100 tint slate-500 is only 4.34:1, below AA; slate-600 is 6.92:1)
- In progress / partial: `bg-amber-50 text-amber-700` + clock icon

`components/ui/_badge` is the implementation and its tones are exactly these:
`:neutral` `:success` `:warning` `:danger` `:info`. It is a light tint with a dark foreground and
**no ring and no border** -- it carried `ring-1 ring-inset` for a while, which the spec does not
specify, and sweeping fourteen badges onto it standardised that drift instead of removing it.

Uses here: an order is pending (amber) / executed (emerald) / cancelled (slate), a grade book is
draft (slate) or finalized (emerald), a person or a stock is active (emerald) or archived (slate).
Presentation lives in a helper, never in the model, and **never OS emoji** -- literal ✅/❌ render
inconsistently across platforms and are invisible to any class-string audit.

Where a status belongs to the *page's* subject rather than a row, it goes **beside the title**, not
in the actions slot: `_page_header` takes a `badge` local for exactly this, because the block is the
actions slot and a status is not an action. The grade book's Draft pill floated in the top-right
corner among "Add student" and "Edit classroom" until it moved. Linear, Stripe and GitHub all put an
entity's state beside its name.

**A pill never prefixes a sentence, and a switch is never labelled with a verb.** Polaris, Primer and
Carbon all place a pill against a *title* or on its own line; a pill beside a sentence that already
says the state is a third copy of one fact. And a switch's position *is* its state, so iOS, Material
and Polaris all pair a switch with a **noun** -- Polaris's "Turn on" verb goes on a button.

**A badge is never the control.** It has no editing affordance, so a yes/no answer is a segmented
control on native radios, not a badge that happens to be clickable.

**A pill carries a status, never a quantity.** Counts belong in their own right-aligned numeric
column (`text-right` + **`tabular-nums`**), with the label in the column header and the cell
holding just the numeral. Every major system draws this line the same way -- Polaris badges,
Atlassian lozenges, Carbon tags are all for categorical state -- and GOV.UK and Material both
specify right alignment for numbers so digits line up and a column can be compared top to bottom.

The case that established this had three count pills stacked in one cell, the first two omitted at
zero. Two things went wrong, and they are what to watch for:
- **Ragged metrics.** Because the leading pills were conditional, the *same* metric landed at a
  different x-offset on every row -- measured 787 / 651 / 673px across three rows. Nothing could be
  scanned down the column. As columns, they right-align exactly.
- **Omitting a zero breaks comparison.** Show `0` (muted `text-slate-500`), don't drop the cell;
  a missing number is not the same as zero, and dropping it is what made the row shift.
Counts are also **dead ends unless they link**: point each one at the filtered list where such a
filter exists. Colour and weight stay as *reinforcement* only -- the header names the column, so
nothing is colour-only.

**Every figure in a numeric column gets the SAME style -- one colour, one weight, zeros included.**
Use the table body colour (`text-slate-700`) + `tabular-nums` + `text-right` and vary nothing per
cell. This took three tries to get right, and each intermediate version looked reasonable in
isolation:
1. rose on the non-zero "needs follow-up" count. rose *is* that semantic token, but the system spends
   it on **status pills and danger buttons**, not bare coloured digits, where it makes colour carry
   the meaning and reads as an error state rather than a figure.
2. weight instead (`font-semibold` on the interesting one, muted `text-slate-500` for zeros) plus a
   brand-coloured link on the two figures that had somewhere to point.
That last combination put **four different treatments in four adjacent cells** -- colour meaning "is
a link", weight meaning "is the actionable one", muting meaning "is zero" -- three unrelated signals
fighting in the one place whose whole purpose is comparing figures down and across. A reader cannot
tell whether blue-vs-grey encodes magnitude, status, or navigability.

So: **no per-cell emphasis, and never put the drill-through on the numeral.** Where the row needs to
link somewhere, make it **one row-level action** in the actions column, alongside Edit -- the
two-ghost-action shape every table here uses. That also stops the styling from advertising an
asymmetry in the data model, where some counts have a filtered destination and others have none.
If a count genuinely needs a status treatment, that is a pill in its own status column -- in the
numeric column it would break the digit alignment the column exists for.

**A count that links needs `record_link_class`, and the destination needs a way back.** These are
record links in a links-only cell, so the brand colour is the cue: use
`"font-medium #{record_link_class}"` and **not** a hand-rolled string with a persistent underline
(that treatment is reserved for a record link sitting inline in body text, and hand-rolling it also
loses the helper's focus ring). Drilling from one list into a filtered list is a **flow trap** unless
the destination offers a return, and it is easy to miss when the destination is itself a top-level nav
page, because then the back link must appear **only** when the page was actually reached from
somewhere:
- Mark the origin with `from:` on the drill-through link.
- Render the back affordance only when `params[:from]` says so.
- **Carry the origin through anything that re-renders the page**: a filter bar submits only its own
  fields, so without a hidden `from` the back link vanishes the moment the user filters.
- **Carry it one hop further**, onto the per-row links, or the next page returns to the *unfiltered*
  list and strands the user again. Verify the whole path, including that the link is absent when
  arriving from the nav.

**Trade-off to check when converting pills to columns:** wrapping pills fit a narrow viewport;
fixed columns do not. One roster measured 341px with no scroll as pills and 616px in a 341px viewport
as six columns -- the change *introduced* horizontal scrolling on mobile. A data table is the
documented WCAG 1.4.10 Reflow exception and axe stays clean either way, so this will not show up in an
audit; measure it. The fix here is `shared/_stacked_row_fields`: the extra columns are
`hidden lg:table-cell` and come back as a labelled `dl` inside the primary cell. Hoist any expensive
count into one array first rather than computing it per rendering. One `<tr>` serves both widths, so
there is no second copy whose ids could collide with the first.

### Person avatar (initials)
`grid place-items-center h-9 w-9 rounded-full text-xs font-semibold` with a soft color
pair (e.g. `bg-sky-100 text-sky-700`). **People only — never for status.**

**Built here as `AvatarHelper`.** `avatar_tag(user)` renders it; `avatar_initials` takes one
letter for a single-word name and two where the name separates on space, dot, underscore or
hyphen (usernames here are usually one word, so one initial is the common case).

- **Initials, never uploaded images.** The users are schoolchildren, so photographs are a
  data-protection question rather than a design one.
- **The tone is derived from the name**, not the id, so a person keeps the same colour in
  every environment and a seeded record matches production.
- **Six pairs, all 100/800**, measured at 6.37:1 to 7.57:1. `design.md`'s example used 700,
  which also clears the gate; 800 buys margin on `text-xs`, and an avatar is exactly the
  sort of near-decorative element where contrast gets skipped.
- The initials are `aria-hidden`: they repeat the name beside them, and announcing "F"
  adds nothing. **So an avatar-only control still needs its own visually hidden text.**
- Tone classes live in a Ruby helper. Tailwind v4's automatic source detection does scan
  `.rb` files — verified by putting a sentinel class in a helper and finding it in the
  built CSS — so this generates correctly without an `@source` directive.

### Header account menu
**Every layout's top bar carries one**, on the right: an initials avatar and a chevron, and
**nothing else in the trigger**. It is a native `<details>/<summary>` disclosure (see Dropdown /
popover) so it works without JS, and the `dropdown` controller adds outside-click and Escape with
focus returning to the summary.

The name used to sit beside the avatar at `lg` and up. It does not any more: GitHub, Google, Stripe
and Linear all show initials or an avatar alone, and a name of unpredictable length inside fixed
chrome is a thing that moves the controls around it. Because the avatar and chevron are both
`aria-hidden`, the trigger's `sr-only` text is its whole accessible name and it must **name the
user** - "Account menu for finn", not "Account menu", which would not say whose.

**The panel holds name, email and a role badge** on a `bg-slate-50` identity block, then the account
actions, then Sign out. The role is `components/ui/_badge` with the **`:info`** tone, not a line of
muted text: a role is **categorical**, which is what this document reserves blue for ("blue that
stays is categorical rather than interactive"), and the classrooms index already badges teacher names
the same way. Measured: blue-700 on blue-50 6.16:1, 24px tall, `rounded-full`, no border and no ring.
The label states the role, so nothing rests on the hue. **Assert it on the component's shape, not its
hue** - and exclude `[aria-hidden]`, because the initials avatar is also a `rounded-full text-xs`
span. **No rule separates them**: the tint groups the identity block, so the panel
does not need a divider. `w-64`, not `w-56` - an email is longer than a name and truncating it
defeats the point of showing it. The email is the line that tells you *which* account you are in,
which is why Google and Stripe both lead with it, and it matters here for the same reason the menu
does: shared machines. **Students may have no email, so that line is omitted rather than left
blank.**

**No navigation belongs in this menu.** It held "View site" in admin and "My portfolio" in the app.
Both are destinations, and a destination behind an avatar is not discoverable - "My portfolio" was
also a second copy of a row the sidebar already had. The rule is: the sidebar and the top bar carry
destinations, the account menu carries identity and account actions.

**The way from admin back to the site is a top-bar control**, `ghost_class` with a `house` icon,
beside the account menu - where WordPress ("Visit Site") and Django ("VIEW SITE") both keep it. The
label is `hidden lg:inline` with an `sr-only` twin below `lg`, because below `lg` that bar already
holds a menu trigger, a wordmark and an avatar; measured, the labelled version is 96px at `lg` and
the icon 32px below it, and the bar does not overflow at 375px. It is **not** in the sidebar: a
footer row there pushed the admin nav 68px past a 1366x768 Chromebook, which `spacing_test` caught.
That is the one asymmetry left with the app side, where Admin *is* a sidebar footer row - the app
sidebar has five rows and room to spare, admin has ten and none.

**There is no "Edit profile" link because there is no profile page.** `resources :users` routed
`edit` to a `UsersController` that does not exist, and Devise's `registrations#edit` is unstyled
generator output that also demands the current password. Adding the item would mean building the
page first - see design-todo.md.

Why it matters more here than convention would suggest: nothing in the chrome used to say
who was signed in, and these are shared school Chromebooks, so a student can land on a
session someone else left open. Signing out was the last item in a sidebar that collapses
behind a hamburger on a phone. **Sign out now lives only in this menu**, so there is one
place to do it.

**Signed out, the same bar shows the logo and a single Sign in action** — suppressed on the
sign-in page itself, which would otherwise link to the page you are already on. Before this
there was no header at all when signed out.

Test it by clicking. A request-level test cannot tell an open disclosure from a closed one,
because the links are in the DOM either way.

### Card meta line

A record's secondary facts -- date, amount, count, state -- go in **one plain-text meta line** beneath
the primary name, joined by a separator, with any fact omitted when it is unset. Build it in one place
(a helper or a decorator) and render that from every card, so two views of the same record cannot
drift apart.

**Plain text, not an icon.** An icon-only fact is a poor signifier: the glyphs are ambiguous, the
meaning is undiscoverable behind a hover, and a hover reveal is invisible on touch. Reviewers could not
tell what one meant. If a compact view really wants a glyph, pair the icon **with** its visible text
label -- never icon-alone -- and remember that Tailwind v4 gates `hover:` and `group-hover:` behind
`@media (hover: hover)`, so a hover-only reveal silently fails on touch and hybrid-pointer devices.
(That same media query is why you cannot verify a `hover:` style from a system test here: headless
Chromium reports `(hover: none)`, so assert hover as a class contract in a helper test and assert the
resting state as rendered pixels.)

Meta-line values are **sentence case** like every other label, and derived rather than written out --
`humanize` on an enum value, `number_to_currency` on money -- so they cannot drift back to Title Case
or to `$15.0`.

### Dashboard worklist ("Needs your attention")
A prioritised list of things to act on. The admin dashboard's two are "Orders awaiting execution"
and "Recent transactions". **One container: the section card**, holding a table built from the shared
`.table-*` tokens, with the secondary columns `hidden lg:table-cell` and `shared/_stacked_row_fields`
bringing them back inside the primary cell below `lg`.

**Pick table vs list by the row's width, not by taste.** A divided list is right in a narrow column
and wrong in a wide card: `justify-between` pins two small items to opposite edges, and at a ~918px
card that measured a **645px void** per row -- which reads as an empty table, the exact complaint the
tinted boxes had been hiding. Columns spend that width on data instead (largest inter-column gap after
the fix: 0px). So:
- **Wide card (a full-width dashboard section): a table.** Give it at least two data columns, or the
  same void reappears in table clothing. Give it a second column that is also what you triage on.
  Use the shared table tokens rather than hand-writing them.
- **Narrow column, or below `lg`: the divided list**, with the context on a second
  `text-xs text-slate-600` line.
If a new column needs data the query object does not have, **batch it**: one grouped lookup in
`AdminDashboard`, never a query per row.

Each row is primary text (a record link, or a person's name as identifying `font-medium
text-slate-800` + the initials avatar), and **one** action.

**Do not give each row its own box.** All three dashboards shipped every row as a rose-tinted,
rose-bordered `rounded-xl` panel with a filled 40px rose icon tile, nested inside the section card.
Two things go wrong and both get worse with length:
- **Card-in-card.** The section card is already the container; repeating it per row is the nested-card
  anti-pattern Material calls out for continuous lists. Measured at six rows: 6 boxes, 12 rose-tinted
  elements and 6 icon tiles, 528px tall vs 483px for the divided list.
- **A tint on every row signals nothing.** Alert fill is for a *single* message (one banner). Applied
  to a repeating collection it stops meaning "urgent" and just becomes the background, while fighting
  the card it sits in. State severity **once** -- the section heading plus its count.

**List or table?** A list when each row is "an entity + a little context + an action" (Polaris
ResourceList). A table only when rows carry several comparable attributes worth scanning or sorting
column-wise -- then use the numeric-column rules above. These worklists are the former.

**One action button per row.** A dashboard once had *two adjacent ghost buttons with the same href*
-- two controls styled alike, side by side, doing the same thing. Keep the verb, since deep-linking it
to the page where the action lives is fine, and drop the second.

A record link in the row text *plus* one action button is **not** the same defect, even when both
resolve to the same page: they are different affordances in different positions, and the row reads
"here is the case / here is what to do". So worklists differ on purpose: a record identifier is a
record link, while a person's name is identifying text (`font-medium text-slate-900`), because this
document prefers not to route users out of a flow via a name.

The empty state keeps its single tinted panel -- that is one message, which is exactly what alert
fill is for.

### Empty states (3 patterns)
1. **Cold start** (no data yet): centered icon tile + heading + one-line explainer +
   primary/secondary CTAs. Never show all-zero stat cards.
2. **Success / all caught up**: positive confirmation panel
   (`border-emerald-100 bg-emerald-50/40`, check icon) instead of a blank section.
3. **No results** (filters/search): centered search icon + message tied to the active
   filters + a "Clear filters" action.

### Alerts, flashes & form errors

There are four things here and they are not interchangeable. **Ask whether the sentence is still true
in a minute**, and the right one falls out.

- **Flash banners** (`layouts/_flash`, rendered by both layouts). A **notice** reports that something
  you just did worked: `role="status"`, `aria-live="polite"`, and it **auto-hides after 6s**, because
  it is worthless a minute later. An **alert** describes something that went wrong: `role="alert"`, and
  it **stays**. That split is the whole convention and it is a property of what the message *is*, not
  of how it looks. `test/system/flash_dismiss_test.rb` asserts it on the attribute, so a wrong one
  fails by name.

  **A banner is only as wide as the container it is in.** The flash was a bare child of `<main>`
  while the content column was declared per page, so at 1920px a sign-in notice measured 1601px over
  cards of 1280px. Anything the layout renders alongside `yield` has to share the page's column --
  which is why the column now lives in the layout, around both. Constraining the flash instead would
  have inverted the bug on the four pages that declare no column at all. Note that this is invisible
  below about 1584px, where `<main>`'s content box is already narrower than the cap.

  Two ways an auto-hiding element gets stuck on screen: fade with an **inline style**, because
  Tailwind only emits classes it can see in the templates and an `opacity-0` added from JS may not be
  in the build; and remove on **its own timer**, not `transitionend`, because a transition that never
  fires -- skipped under reduced motion, interrupted by a display change -- leaves the message up
  forever.

- **Callouts** describe a state of the page that is true until somebody changes it -- "trading is
  turned off for your classroom". They never auto-dismiss, and their dismiss is a **round trip, never
  a Stimulus controller**: a client-side close brings the banner straight back on the next load,
  because the condition still holds. Dismissals are one row per user per key in the `dismissals`
  table, via `POST /dismissals`; `Dismissible` on `User` gives `dismissed?(key, since:)` and
  `dismiss!(key)`. Adding one is a key in `Dismissal::KEYS` and a `button_to` -- no migration, no
  route, no controller action.

  **Pass `since:` or the dismissal is a mute button.** It defaults to nil, meaning permanent, and a
  caller who forgets it fails *silently*: the banner simply never comes back. Permanent is correct for
  something that happens once; it is wrong for any condition a teacher can turn off, on and off again,
  which is why `classrooms.trading_disabled_at` exists and why `Classroom` clears it when trading
  comes back on. Ask what the dismissal dismisses -- this message, or every future instance of it.

  **A `button_to` dismiss cannot live in the component.** `button_to` renders a whole `<form>`, and a
  callout inside another form would have the parser drop the nested form and the button silently
  submit the outer one. The dismiss is passed as a block per call site for that reason.

- **The staging band** is the one thing here that describes neither the page nor an outcome but the
  *deployment*, and it is the exception to "a message that removes itself must be an outcome". It is
  dismissible, and that reverses an earlier decision in this document. The reasoning that produced the
  earlier one was sound about the sentence -- "you are on staging" is still true in a minute -- and
  wrong about the strip, which was a 32px band across every page on every visit and was reported as
  "very distracting, and it pushes everything down".

  Two properties make the exception safe, and a dismissible chrome-level notice needs both:
  **it comes back**, on every login, through a session flag cleared by a Warden `after_authentication`
  hook rather than a `dismissals` row -- a permanent dismissal is the mute button warned about above,
  and its failure mode is somebody acting on staging months later believing it is real. And
  **something stays**: a compact badge in the header, at zero vertical cost, so the question the band
  answered is still answered. Exactly one of the two is on screen, never both. Stripe's persistent
  "Test mode" pill is the same trade.

- **The form error summary** (`shared/_form_errors`): `id="error_explanation"`, `role="alert"`, the
  red-200 / red-50 / red-700 card, a lone error inline and several as a `list-disc` list. It gets **no
  close at all** -- it describes the form as it stands and is rebuilt on submit, so hiding it hides the
  list of what is still wrong.

- **Field level.** Every invalid field shows a rose border **and** a visible message, so the error is
  never carried by colour alone (WCAG 1.4.1), and **this is automatic app-wide.** The global
  `field_error_proc` (`config/initializers/field_error_proc.rb`) marks the control `aria-invalid`,
  points `aria-describedby` at a message it renders beneath, and swaps `tw-input-primary` for
  `tw-input-error`. It skips labels, hidden / checkbox / radio / submit inputs, and anything that
  already carries `aria-describedby`, so nothing doubles and new forms get it for free. For the cases
  it skips -- a `collection_check_boxes` group, a composed fieldset -- `field_error(record, attr)` and
  `field_error_attrs(record, attr)` in `FormErrorsHelper` place the same message and attributes by
  hand.

  **Two errors for one field is the failure mode here**, and it shipped: the form builder rendered its
  own message *and* the proc rendered one, so every invalid field said everything twice. There is one
  producer per control now.

  Two traps live in that initializer. **`ActionController::Base.helpers` does not have the app's
  helpers** -- it carries Rails' own, so a call through it looks fine until it reaches an app helper
  and then raises `NoMethodError` at render time, which here meant a 500 on every invalid submit;
  `ApplicationController.helpers` has both. And **an initializer needs a boot**: code reloading covers
  `app/`, not `config/initializers/`, so a running server keeps executing the previous version and will
  report success on the very thing you just changed. If a change to an initializer appears to have done
  nothing -- or appears to have worked -- restart before believing either.

- **Native HTML5 validation is disabled app-wide** so the above can show. Otherwise the browser's own
  bubbles fire first, block the submit, and cannot be styled. `application.js` sets `form.noValidate`
  on every form. An invalid submit then reaches the server and re-renders the design-system errors.

- **Message copy.** Validation messages are app-shipped copy: sentence case, including the
  `activerecord.attributes` names in `config/locales/en.yml` that surface inside them, and no trailing
  period, so a message reads cleanly as a list item and never doubles its punctuation.


### Dropdown / popover
Menus (the header account menu, the cases-page "More" actions menu) are a native
`<details>/<summary>` disclosure: the `<summary>` is the trigger (styled as a button,
`[&::-webkit-details-marker]:hidden`), the panel an `absolute right-0 z-20 mt-2 w-56
rounded-xl border border-slate-200 bg-white py-1 shadow-lg` card of links. The `dropdown`
Stimulus controller enhances it — native toggle plus close on outside-click and Escape
(focus returns to the summary) — and degrades to the plain native toggle without JS. Keep
menus a disclosure-of-links (not a full ARIA `menu` widget) unless a screen needs arrow-key
roving. (Distinct from `disclosure`, which is for inline panels like the edit-profile forms
that should stay open.)

The `<summary>` wears `button_classes(:secondary)` so the trigger matches the primary CTA's
40px height. Menu items are `flex items-start gap-2 px-4 py-2 text-sm`: the leading icon is
**top-aligned to the first line** (`items-start`), never centered, so a label that wraps
still reads with its icon (see Iconography). A form-driven modal can be a menu item by
rendering `Dialog::GroupComponent(wrapper_class: "contents")` so its trigger and dialog sit
directly in the menu.

**Header action pattern.** A page header shows **one primary CTA plus a `More` overflow
disclosure**, not a flat row of equal buttons. Keep frequently-used, core actions visible and
overflow only the occasional ones. Do not bury a core action in `More`: it
is both a UX cost (an extra click on a common action) and a testability cost (rack_test
cannot open a native `<details>`, so non-JS specs that click it break).

On **mobile**, collapse the remaining visible secondaries into `More` too, so only the primary
CTA and `More` share the top line. Render such an action twice with responsive visibility: a
button wrapped in `hidden sm:contents` (shown `sm+`) and a `sm:hidden` menu item (shown on
mobile). This keeps it no-JS and unambiguous, and a non-JS click still finds the visible
button (rack_test ignores the `hidden` class but respects the closed `<details>`).

### Disclosure (collapsible panel)
Secondary actions (e.g. Change password / Change email) hide behind a full-width trigger
button; the `disclosure` Stimulus controller toggles a `hidden` panel and keeps
`aria-expanded` in sync. Keep the trigger a real `<button>` so it stays keyboard- and
test-reachable.

**The trigger label names the CONTENT, never the action.** This is the WAI-ARIA APG disclosure
rule (the button's accessible name describes the content it controls; `aria-expanded` carries the
state) and it is what Material, USWDS, Polaris and Primer all ship. `Expand / Hide` named the
action twice, described nothing, and duplicated `aria-expanded`. So:

| trigger | label |
|---|---|
| filter panel, some filters visible outside it | **`More filters`** (card heading `Filters`) |
| filter panel controlling every filter | `Filters` |
| form section | the section name -- `Change password`, `Change email`, `Filter columns` |
| icon-only row expander | content name as `aria-label` -- **`Contact details`**, not `Toggle contact details` ("Toggle" duplicates `aria-expanded`) |

Where some filters sit *outside* the panel, a bare `Filters` on the trigger would misdescribe what
it controls -- hence `More filters`, the label Jira, Linear and Polaris use for exactly this split.

**State is `aria-expanded` + a chevron that rotates -- never the label text.** Put `group` on the
trigger and `transition-transform group-aria-[expanded=true]:rotate-180` on the chevron
(`group-open:rotate-180` inside a native `<details>`). **Tailwind v4 emits `rotate-180` as the
standalone `rotate` property**, so verify with `getComputedStyle(el).rotate` (`none` ->
`180deg`): `.transform` reads `none` in *both* states and will tell you a working rotation is
broken.

The live instance of this in the app is the **mobile nav drawer**, whose trigger carries
`aria-expanded` from `drawer_controller` -- it previously carried none at all, in either layout, and
the two halves signalled their open state in different ways.

**A disclosure inside a form that re-renders must carry its open state across the render**, or the
server re-derives it and the panel snaps shut under the user. Two shapes:

- **A panel whose open state is derived from the data.** "Open if a hidden filter is active",
  re-evaluated on every submit, closes itself the moment a change leaves no hidden filter on -- even
  when the user did not touch a hidden filter at all. Carry the state explicitly in a hidden field and
  fall back to the derived value only on first load. Check **both directions**: a panel the user
  *closed* must stay closed even while a filter is active, which deriving-from-params also gets wrong.

- **A validation re-render.** A failed `update` that does `render :edit` will re-render a panel
  hardcoded shut, so the error appears at the top of the page while the form it refers to collapses out
  of sight, losing the user's input. No round trip is needed for this one: **`action_name` is still the
  failed action** inside `render :edit`, so open exactly that panel and leave its siblings closed.

**Deliberate exception:** an inline "more of this item" reveal may swap `Show details` / `Hide
details`, because it is not a section trigger, the text still names the content, and GOV.UK's
accordion does exactly this. Do not propagate it to section triggers.

### Modal and confirmation dialog

Two things, with different jobs. **A confirmation is a question about an action already chosen; a
modal is a place to do work.**

**The confirmation dialog** (`shared/_confirm_dialog`, `confirm_dialog_controller`) replaces the
browser's native `window.confirm` for the whole app by overriding `Turbo.config.forms.confirm` -- not
the deprecated `Turbo.setConfirmMethod`. It is a real `<dialog>` opened with `showModal()`, which
brings focus trapping, Escape to close, an inert page behind it and the backdrop from the browser, so
it is a fraction of the code of a hand-rolled overlay.

Two geometry rules are non-obvious and both are invisible until measured. **A native `<dialog>` needs
`m-auto` and `w-auto` under Tailwind:** Preflight resets `dialog { margin: 0 }`, killing the UA's
centring, and the UA sets `width: fit-content`, so a panel is sized by its own text. Mine sat against
the left edge at 301px wide.

The message is split on the **first blank line**: the part before it is the question, in
`text-base font-semibold`; the part after is the consequence, in `text-sm text-slate-600`. **Show what
an irreversible action will do, in the confirmation.** Finalizing a grade book deposits real money into
every student's portfolio and cannot be undone, and both the page and the dialog were once silent about
the amount. When a preview and a payment must agree, **run the same object** -- `EarningsCalculator`
here -- rather than reimplementing the rules beside it.

The question **never restates the button**: "Reset Ada's password?" tells a teacher nothing they did
not already know. Cancel comes first in the DOM, which is the reading order the buttons are in, and
the accept button's label is filled in from the control that was pressed, so it reads "Finalize
grades" rather than "OK".

**Replacing a global browser primitive breaks whatever was driving the old one.** Styling the confirm
took an afternoon; the 20 tests calling Capybara's `accept_confirm` -- which waits for a *native*
dialog -- took longer. `accept_confirmation` / `dismiss_confirmation` drive the app's dialog now.
**Before swapping a primitive, grep for what tests it**, not just what uses it.

Note also what `turbo_confirm` is where the override does not reach: a **native OS dialog** with no
styling available at all, so the string is the only thing that can be improved.

**The modal** (`shared/_modal`, `modal_controller`) is the trading floor's order form: a fixed
`bg-black/50` scrim, a `bg-white rounded-2xl shadow-2xl max-w-md w-full mx-4 p-6` panel with
`role="dialog"` and `aria-modal`, a close control at the top right, and a backdrop click to dismiss.
Its close button is icon-only, so it carries its own visually hidden text -- `lucide_icon` renders
`aria-hidden`, and an icon-only control otherwise has **no accessible name at all**.

**A `button_to` cannot go inside another form.** It renders a whole `<form>`, and nested forms are
invalid HTML: the browser drops the inner one during parsing, so the button silently submits the
**outer** form to the outer form's action. It looks fine, renders fine, and passes a controller test
that POSTs to the route directly -- only a system test that actually clicks it catches this. When an
empty state needs an action, branch around the form rather than putting the empty state inside it.

**An unlayered CSS rule beats every layered one, whatever the specificity.** The `.tw-*` component
files are imported after `@import "tailwindcss"`; until they were wrapped in `@layer components`,
`.tw-btn-buy`'s `display: inline-flex` beat `.hidden`, so the order modal showed Cancel, Back, Review
order and Buy shares simultaneously. `hidden` appeared in the markup and did nothing. Assert it: at
375px, any element carrying `.hidden` whose computed `display` is not `none` is a cascade failure.

**Proving that nothing happened needs a bounded wait.** `click` and `send_keys` do not block, so
reading the database straight after a Cancel asserts against a request still in flight, and a "the
action did *not* happen" test then passes whichever way it went. Mine passed with focus on the accept
button, which is the exact opposite of what it claimed. There is no positive state to wait on when the
correct outcome is nothing, so a short documented `sleep` is the honest instrument -- and verify the
test by making the thing happen and watching it fail.

**A destructive control with no test may never have worked.** "Delete account" posted to Devise's
`registrations#destroy`, which calls `resource.destroy`, and `User` raises *"Hard delete attempted …
Use #discard instead"*. It returned a 500 every time, for as long as it had existed. Before moving or
restyling a destructive control, run it.


## App shell
- **Sidebar** (256px, `border-r border-slate-200 bg-white`): org **name only** in the
  header (no logo/brand mark — not a value-add at this size, and avoids image/variant
  infrastructure), then nav links (active = `bg-sitf-primary/10 text-sitf-primary-dark`, idle =
  `text-slate-600 hover:bg-slate-100`). Nav visibility follows Pundit policies. On desktop the aside is
  **`lg:sticky lg:top-0 lg:h-screen`** (exactly viewport height, stays put as the page scrolls); below
  `lg` it collapses to an off-canvas drawer. That viewport height is what lets a **bottom-pinned item**
  (Settings, via `mt-auto`) sit at the bottom of the *screen* -- a plain `lg:static` column grows with
  the page, so `mt-auto` would strand Settings below the fold (only reachable after scrolling to the
  page end).
- **Sidebar nav order** (**not** alphabetical -- alphabetical is arbitrary vs. how people work):
  **Dashboard first (ungrouped), Settings pinned to the bottom** (`mt-auto` + its own divider), the
  middle **grouped by domain, ordered by frequency**. The admin sidebar's groups are Academic
  (Classrooms, Schools, School years) / Users (Students, Teachers, Users) / Portfolio (Stocks,
  Transactions) / Content (Announcements), with Dashboard ungrouped at the top. The app side is a
  short flat list -- Portfolio, Transactions, Trading floor -- and needs no groups at all.

  Each group wears a section label at `text-xs font-semibold text-slate-500`. **Not uppercase**, which
  is where this diverges from the spec it inherited: the copy rule here forbids the `uppercase`
  transform on labels and says to use size, weight and colour for hierarchy, and a nav heading is not
  exempt. The label does the separating, so there are **no between-group dividers**. A group whose
  every item is policy-gated out **renders nothing -- no orphan label**. It is built from an array in
  `admin/shared/_navigation` plus a shared row partial, which is what makes "apply it to both sides"
  mechanical rather than a sweep.

  **A nav is not a catalogue.** Trading floor was a `<details>` disclosure listing every active stock,
  which put the contents of a page into the navigation of it. It is one row now.
- **Top bar** (`border-b border-slate-200 bg-white/80 backdrop-blur`): mobile nav
  toggle, notifications, and the avatar **account menu** — the single place for identity
  + account actions (no duplicate identity block in the sidebar). Its header shows name,
  email, and the user's **role**, which is the single place it is surfaced.
- **Content**: `bg-slate-50`, cards, and **one content column declared by the layout** around both
  `yield` and the flash -- not per page. Announcements render at the top of the content area. The full
  logo is reserved for contexts with room, like sign-in, not the shell.

  Read the actual `<main>` before removing a page's padding: there are three of them here and they
  disagreed. The signed-in layout was `px-4 lg:px-6 ... mt-16 pb-6` -- sides and bottom only, with the
  `mt-16` clearing the fixed nav rather than padding anything -- while the signed-out branch and
  admin's inner wrapper both had `p-4 lg:p-6`. Removing per-page padding citing "main's `p-4 lg:p-6`"
  was right for two of the three and put every signed-in page's title flush against the nav.

  Wrapping `yield` also **moves every selector that reaches through `main`**. `main > div` used to be
  the page and is now the content column, so a spacing test reading `main > div > *` got a single
  element, never entered its comparison loop, and **passed while asserting nothing** -- the only signal
  was the assertion count dropping from 21 to 19.
- **Environment ribbon** (`layouts/_environment_ribbon`, above the top bar): on staging, a
  full-width bar naming the environment. Its geometry lives in one place, `EnvironmentHelper`, because
  a fixed header, the drawer and `<main>`'s offset all have to move by exactly the ribbon's height and
  three files disagreeing about that is a layout bug per page. There is no impersonation here.
- **Flash parity across the two layouts**: one partial, `layouts/_flash`, rendered by both, so the
  key-to-role mapping and the auto-dismiss rule cannot diverge between the app and admin. A flash
  carries its id (`#notice` / `#alert`) and its a11y `role`; styling is by role, not by class hook.
- **Stacking order (z-index).** The top bar is `relative z-[25]` so its account / notification
  dropdowns (absolute panels *inside* the header) always paint above page content. Relying on the
  header's `backdrop-blur` stacking context alone was fragile: any page element that makes its own
  stacking context (a positioned `z-*` toolbar, a `transform` / hover-lift card, a native control)
  ties the header and wins by DOM order — painting a page **button over the open dropdown**. The
  full order is **page content ≤ z-20 < top bar `z-[25]` < mobile nav scrim `z-30`** (so the open
  drawer still dims the header) **< sidebar drawer `z-40` < the staging ribbon `z-60` < native
  `<dialog>` modals** (top layer). The ribbon is above the drawers because it describes the whole
  deployment rather than the page - and it is explicit rather than left to DOM order, which is the
  same fragility as above: measured, it stays on top at `z-50` too, but only because it happens to be
  later in the layout.
  Keep page-content z-index ≤ 20; verify overlays with `elementFromPoint`, not by eye.

## Key patterns

- **Back navigation on sub-pages.** Every page reached *from* another page -- a form, a detail page,
  an action destination, anything that is not a top-level nav item -- has a way back. On the admin
  side that is the **breadcrumb trail** (`admin_breadcrumbs`, whose labels live in the controllers and
  also feed the layout's visually hidden `h1`); on the app side it is a `tw-btn-secondary` "Back to X"
  in the page header's action slot, as `stocks#show` and `announcements#show` do. Top-level
  destinations need neither.

  The trail **wraps** (`flex flex-wrap`, not `inline-flex`). As one unbreakable line it pushed
  `<main>` sideways on six admin pages -- a school year's crumb reads "School name (2024-2025)" and
  took the page 130px past a 375px viewport, which carried the row actions off screen with it.

  Never leave a back link as a **bare child of a `space-y-*` container**: the 24px rhythm then lands
  between the link and the title and shoves everything down. Back link and title are one header block.

- **A row action returns you to the list you took it from.** Archiving a classroom from the index
  redirected to that classroom's page, which is a destination nobody asked for: the click was on a row,
  and the answer to "did it work" is the list plus a message. Gmail, GitHub, Linear, Stripe and Polaris
  all keep you in place. `redirect_back_or_to(list_path)` rather than the list outright, because the same
  action is usually offered on the record's own page too, and from there the right destination is that
  page showing its new state. **Create and update are the opposite** - you have just made or edited a
  thing, so the record's page is where you see the result.

- **One way back per page, and on the admin side it is the breadcrumb.** Nine admin show pages carried a
  "Back to X" button at the foot as well, which is the same journey twice, and the footer copy is the one
  a reader has to scroll to find. Delete the wrapper with the button: each of those was the only control
  in an `mt-6` row, and leaving the row behind leaves 24px of dead space - the same rule as deleting a
  rule and leaving its padding.

- **Admin dashboard**: a KPI stat row, then the worklists -- orders awaiting execution, then recent
  transactions. Lead with what needs action. The figures come from `AdminDashboard`, and each card is
  `tw-card p-5` with an `icon_tile`, a `text-3xl tabular-nums` value and its label beneath.

- **Entity detail page** (`classrooms#show` is the reference): page header, then the entity's related
  collections as full-width stacked `<section>`s with `h2`s, then a summary at the foot. Two things
  were learned here and both are counter-intuitive.

  **Two collections side by side is a two-column layout used wrong.** A narrow secondary column is for
  metadata -- status, tags, counts -- which is what Polaris says and what Stripe, GitHub and Linear do.
  This page put a 765px roster beside a 256px grade-book rail, so one collection read as subordinate and
  the other had less room than it needed. Stack them and let the order say which is primary.

  **Adding to the top of a page costs the thing the page is for.** A four-across stat band is 134px;
  with a setting card above it, the roster's first row landed at 567px of a 625px viewport. So the
  figures sit at the **foot**, which is where "how is this class doing?" is actually asked. Measure the
  first row before and after anything added above the primary content.

  **A setting is not a page action.** The trading switch sat in the page header beside "Add student",
  carried its state only in the track's colour, and said nothing about what it did. A setting states
  its state **in words**, and it belongs on its **section's** header line -- Polaris's card header
  action, Primer's `Subhead`, Stripe's list sections.

  **A card per list item is card soup.** Four grade books as four card links, plus the roster's table
  card and a setting card, put six surfaces on one page. A row with a name and a status is a **list
  row**: one card, `divide-y` between rows, which is Polaris's `ResourceList`. A card earns its edges
  for a summary figure, a person or a preview.

- **Person edit page** (`profiles#edit`, and the record page for a student or a teacher): one
  `max-w-3xl` column, the shared page header, then the form in a single card. No top primary -- a
  fill-then-save page's primary lives at the form's bottom. Fields are editable per policy, and
  **the form hides what the policy filter drops**: a field whose value is silently discarded looks
  like a save that worked. `ClassroomPolicy#permitted_attributes` is the worked example, where a
  teacher may edit the name, grades and trading flag while `school_id`, `year_id` and `teacher_ids`
  stay admin-only.

- **Gate the action, not the information.** The grade book's earnings summary sat inside an
  `if current_user.admin?` block with the finalize button, so the teacher entering the grades could
  not see what they added up to while the admin who only presses the button could. A summary is for
  whoever can open the page; only the irreversible action is administrative.


## Design decisions (rationale)

The *why* behind the system, so choices aren't re-litigated or lost.

- **Two layouts, `application` and `admin`, and they are one product.** Every rule here applies to
  both. A fix applied to one half creates exactly the inconsistency the rule was meant to remove, so
  prefer changing a shared helper or partial -- `NavHelper`, `_page_header`, `_card`, `_badge`, the
  `.tw-btn-*` classes, `Ui::FormBuilder` -- over changing call sites.
- **Brand = `sitf-primary` (`#00698c`), neutrals = slate.** White on it is 6.18:1. The accent lime
  is **fill only** at 1.37:1 against white -- never a foreground.
- **Figtree** as the typeface — a warm humanist sans that reads friendly but credible, and is free via
  Google Fonts.
- **Icons come from `lucide_icon`**, vendored through the gem rather than a CDN. It renders
  `aria-hidden` by default, so an **icon-only control needs its own visually hidden text** or it has
  no accessible name at all.
- **Only `base` and `lg:`.** No `sm:`, `md:`, `xl:` or `2xl:`, and no custom breakpoint. Not because
  the audience has two devices, but because **this app's layouts change shape exactly once**: below
  1024px there is no room for a 256px sidebar beside the content, and above it there is. A third tier
  would be a breakpoint with no layout change behind it, which is a place for two versions of a
  component to drift. The field's rule is content-based breakpoints rather than device-based, and two
  is at the low end of what systems ship -- Tailwind's default is five, Bootstrap five, Material five,
  Primer four, Polaris four, GOV.UK three.

  **Two tiers is not two widths.** Everything must work continuously from 320px up, and at 200% text:
  WCAG 1.4.10 and 1.4.4, both AA. Checking 375 and 1366 alone shipped a fixed-height ribbon whose text
  rendered *above* the viewport at 200%, unreachable. Adapt fluidly -- `flex-wrap`, `minmax()`,
  `min-h-*` on anything containing text, `clamp()`, a measured value in a custom property -- before
  reaching for a tier. Verify at 320, 375, 768, 1024, 1366 and 1920, plus 375 and 1024 at 200%, plus
  one width above ~1584px, because a layout width cap is invisible at every width below it.

  **A component sizes against its container, not the window.** Tailwind v4 ships container queries, so
  anything that could render in a card, a column, a modal or a table cell uses `@container` and the
  container-relative `@lg:` (32rem), not the viewport `lg:` (1024px). That is where the field has moved
  - Polaris, Material and GitHub all keep viewport breakpoints for page layout and put component
  adaptation on container queries - and it is what stops "add `md:`" from turning two tiers into five.
  Every "this broke somewhere else" bug here has been a component sized against the viewport while
  living in a narrower box.

  Also standard now: **logical properties** (`ms-`, `pe-`, `text-end`) over physical ones, **`clamp()`**
  where a size step is arbitrary rather than a token, **`dvh`** over `vh`, and **`prefers-reduced-motion`**
  on anything that moves. The last of those is live - `motion.css` restricts which properties may
  transition, so a drawer stops sliding while a button still fades. The first two are conventions for new
  markup rather than a sweep, and container queries have no caller yet **on purpose**: measured, nothing
  in this app currently misbehaves in a narrow container, and every case that has come up was fixed by
  wrapping or `min-w-0` instead. The guidelines record the trigger for each, so a rule with no caller does
  not quietly become a rule nobody applies.

  [`docs/responsive-design-guidelines.md`](docs/responsive-design-guidelines.md) is the long form and
  wins on anything responsive.
- **No `dark:` variant.** There is no dark mode here, and Tailwind v4 compiles `dark:` to
  `@media (prefers-color-scheme: dark)`, so it goes live on any dark-OS device regardless. One
  `dark:text-slate-400` was audited as "justified, 6.99:1 on dark" while rendering **2.45:1** over a
  background that stays light.
- **Icon tiles for status, initial-avatars for people — never mixed.** A soft colored
  rounded tile behind an icon means "a stat/status"; a colored initials circle means
  "a person". Keeping these disjoint avoids visual ambiguity.
- **Sidebar shows the org name only (no logo mark); identity lives in one top-bar
  account menu.** Dropping the logo avoids image/variant infrastructure that adds little
  at 256px, and consolidating identity removes the duplicate sidebar identity block. The
  full org logo is reserved for roomy contexts (sign-in, reports).
- **Honorific-free names are presentation-only.** Show first + last (no Mr./Mrs./…) on
  every page via `display_person` (new UI), `formatted_name` (legacy `.display_name`
  sites) and `avatar_initials`, all backed by `NamePresentation`. The stored
  `display_name` is **never** mutated — it must round-trip raw input for security.
- **Landing pages use the triage pattern.** Greeting -> KPI row -> "needs your attention"
  -> roster/table. Lead with what needs action, not vanity metrics; push power tools into
  a "More" menu.
- **Every screen designs its empty state** using one of the three patterns (cold-start /
  all-caught-up / no-results). Never ship all-zero stat cards or a blank section.
- **Accessibility is part of "done".** Skip link, `aria-current` on the active nav,
  `aria-label` on icon-only controls, visible `focus-visible` rings, `sr-only` table
  captions/labels, `role="status"`/`"alert"` on flashes, and `motion-reduce` on the
  drawer. The shell already meets this bar — keep new pages there.
- **Build:** `npm run build:css` (minified) or `build:css:dev` (watch, the `tw`
  process in `Procfile.dev`). Class names are discovered via the `@source` globs in
  `tailwind.css`. The output `app/assets/builds/tailwind.css` is **gitignored** and built
  on deploy — don't commit it. Keep the script named `build:css`: `cssbundling-rails`
  runs `npm run build:css` during `assets:precompile`, so renaming it breaks the deploy.
- **Tables are bespoke, not jQuery DataTables (reversed).** Theming DataTables couldn't
  match the dashboard tables or meet WCAG — its generated chrome fights the design system.
  Build tables in Tailwind instead (matching the dashboard): server-side filtering +
  sortable header links via `sort_link`, with **Turbo** smoothing the
  GET navigations. Reuse each `*Datatable` class's query logic server-side; retire the
  DataTables JS as each page migrates. See the cases index for the reference pattern.

## Migrating a page (playbook)

Repeatable steps for bringing one screen onto the system:

1. **Read first** — this doc, plus the page's existing specs (know what behavior is
   pinned before you touch markup). Confirm each column / field you plan to keep still has a
   live data source; don't carry blank legacy columns forward (see Tables, above).
2. **Opt the action into a Tailwind layout** — `render ..., the app layout` (or
   `the signed-out layout`), and set `@active_nav` when it maps to a sidebar item.
3. **Rebuild the view with the components above.** Wrap page content in `py-6` and let the
   layout supply the horizontal gutter; use the h1/section-title scale; reuse the card, button,
   input, pill, KPI, and empty-state patterns instead of inventing new ones.
4. **Names:** `display_person` / `formatted_name` / `avatar_initials` — never raw
   `display_name`. **Icons:** `bi-*` only. **Status vs people:** icon tile vs avatar.
5. **Design the empty state** (pick the right one of the three).
6. **Keep behavior specs green.** When a spec is coupled to a presentational class, move
   it to a semantic hook (a `data-*` attribute) rather than weakening the assertion.
   Prefer system specs for new UI behavior (ADR 0006).
7. **Verify:** `npm run build:css`, run the page's specs, then `bin/lint`. Confirm the
   page fits at true 375 / 414 / 768 / 1024 / 1280 widths, measured with a CDP device-metrics
   override (`bin/measure-responsive.mjs`) rather than `--window-size` (headless Chrome clamps its minimum
   window to ~500px, so `--window-size=375` silently measures 500).
8. **Checkpoint:** commit and push to `stocksdesign`, tick the item off in
   `design-todo.md`, and update the status below.

## Migration status

This app was already Tailwind when the design work started, so there is no framework migration to
track. What this document records instead is the sweep that brought both halves of the product onto
one system.

**The history lives in [`migration.md`](migration.md)** -- every change with a long-term blast radius,
in the order it happened, never rewritten. **The backlog lives in
[`design-todo.md`](design-todo.md).** This section is only the shape of the work.

Both halves are covered: the student- and teacher-facing app and everything under `/admin`. They are
one product, and a fix applied to one half creates exactly the inconsistency the sweep was meant to
remove -- a teal sidebar against a white one, a page background that changed at the `/admin`
boundary, `slate-50` here and `sitf-surface` there. The mechanism is shared: `NavHelper`,
`components/ui/_page_header`, `_card`, `_badge`, the `.tw-btn-*` classes and one `Ui::FormBuilder`.
Prefer changing those over changing call sites.

Two things that keep re-appearing, both recorded at length below: **a style written in two places
survives every sweep of one of them** (the grey table header was a shared class *and* an inline
`<thead>` on fourteen admin tables; the button base was `buttons.css` *and* `ADMIN_BUTTON_BASE` in
Ruby), and **a named class with one caller drifts as surely as no class at all** (`tw-input-primary`
existed for months, with a comment describing the exact placeholder failure it fixed, while the admin
form builder rendered nine forms at 2.54:1).


## Workflow
- On the `stocksdesign` branch: **commit and push at every checkpoint.**

---

# Stocks in the Future specifics

Everything below is this project's own, not inherited. When it disagrees with
anything above, this wins.

## Brand tokens

Defined once in `app/assets/tailwind/shadcn.css`, exposed as Tailwind utilities in
the `@theme` block of `tailwind.config.css`. **Never write a hex value or a
`[var(--...)]` arbitrary value in markup** — both bypass the token layer, and both
hid contrast failures here.

| Token | Value | Contrast on white | Use |
|-------|-------|-------------------|-----|
| `sitf-surface` | `#f7f9f3` | — | page background |
| `sitf-primary` | `#00698c` | 5.82:1 | primary actions, links, focus rings |
| `sitf-primary-dark` | `#004f6b` | 8.50:1 | hover, headings, nav |
| `sitf-on-primary` | `#ffffff` | 6.18:1 on primary | labels on brand fills |
| `sitf-accent` | `#d3df44` | **1.37:1** | **fill only** — never text or icons |
| `sitf-on-accent` | `#323232` | 8.80:1 on accent | text on the lime fill |
| `sitf-accent-soft` | `#eceec8` | — | summary total rows |
| `sitf-hero-from` / `-to` | `#f4d18d` / `#f8dba8` | — | hero gradient |
| `sitf-ring` | `#a5b4fc` | **1.99:1** | **tint only** — never a focus indicator or a control border |
| `sitf-danger` | `#ef4444` | 3.76:1 | fills and borders, **not text** — use `red-700` for text |

## Component primitives

In `app/views/components/ui/`. Build on these rather than restyling inline.

- **`_card`** — hairline border plus a very low shadow, not a heavy drop shadow.
  Optional header with title and subtitle; `padded: false` for flush tables.
- **`_page_header`** — the single `h1` at page-title scale, optional description,
  actions aligned on the same optical line.
- **`_badge`** — six semantic tones, each a dark foreground on a light tint so all
  clear AA. The label always states the status, so meaning is never colour-alone.
- **`_empty_state`** — heading, explanation and a call to action. An empty state
  that names the next step without offering it is doing half a job.
- **`_data_table`** — visually hidden `<caption>` for the accessible name, plus a
  **focusable** scroll region. A plain `overflow-x-auto` div is not
  keyboard-scrollable, which fails WCAG 2.1.1.
- **`admin/shared/_empty_row`** — wraps `_empty_state` in the `tr`/`td`/colspan
  plumbing for use inside a table body.

Partials rendered with `render layout:` must test whether the **yielded content is
present**, not `block_given?` — the latter is unreliable inside a partial layout.

## Data tables

Reworked from a heavy black grid to industry standard. Classes live in
`app/assets/tailwind/tables.css`, so restyling them upgrades every table at once.

- Hairline horizontal dividers only. No vertical rules, no heavy outer border.
  Columns separate by alignment and whitespace.
- The header is chrome: `text-xs` semibold `slate-600` on `slate-50`, **with no
  uppercase transform** — this document says to use size, weight and colour for
  hierarchy instead, and that applies to column headers too.
- Rows tall enough to touch, with a hover anchor for scanning.
- **Money and counts right-aligned with `tabular-nums`**, so digits line up down
  the column. On a financial table this is the single biggest legibility win, and
  it was missing everywhere.

## Traps found the hard way

Each of these was a real defect in this codebase, not a hypothetical.

**Tailwind v4 resolves an unset `--tw-ring-color` to `currentColor`.** A
`focus-visible:ring-2` with no colour named gave a *white ring on a white
ring-offset on a white page* for the primary button — an invisible focus
indicator. Always name the ring colour.

**`bg-opacity-*` and `ring-opacity-*` were removed in v4** and compile to nothing.
Two modal scrims were rendering fully opaque and `ring-black ring-opacity-5` drew
a solid black rule. Use the slash syntax.

**An invalid utility fails silently.** `focus-visible:ring-2a` compiled to nothing
and went unnoticed. If a style has no effect, check the class actually exists in
the built CSS.

**`lucide_icon` renders `aria-hidden`.** An icon-only control therefore has *no*
accessible name unless you add visually hidden text. `title` alone is not
reliably announced.

**Dead classes accumulate.** 17 legacy top-nav rules had zero usages, and
`hero-banner`, `funds-pill` and `flex-cols-2` were referenced in markup but never
defined anywhere. A class that is never defined and a class that is never used
both look fine in review.

**Confirm dialogs need a subject.** "Are you sure?" gives no basis for a decision.
Name the record and say whether the action can be undone.

**`button_to` inside another form is dropped by the browser.** `button_to` renders a
whole `<form>`, and HTML parsing discards a nested `<form>` start tag — the button
then submits the *outer* form to the outer form's action. This is invisible in
review, in the rendered page, and in a controller test that POSTs to the route. It
bit the grade book empty state, where an "add students" button sat inside the grades
form and would have saved grades instead. When an empty state carries an action,
branch around the form instead of nesting the empty state within it, and cover the
button with a system test that clicks it.

## Accessibility gates

The per-page checklists live in
[`design-instructions.md`](design-instructions.md). Two habits matter more than
the lists:

1. ****Small supporting text is `slate-600`, not `slate-500`.** A caption, a section label, a breadcrumb's
current crumb and the em dash standing in for an absent value are all *text*, and slate-500 measures
**4.76:1** - which clears AA and not the 7:1 of 1.4.6. slate-600 is **7.58:1**.

Two things keep slate-500, and the distinction is the point: an **icon** is non-text content, governed by
1.4.11's 3:1, which slate-500 clears; and a **placeholder** darkened to slate-600 starts reading as a filled
value, which trades one problem for a worse one. A disabled control's text is exempt by 1.4.3's own
"inactive user interface component" carve-out.

This is an improvement rather than conformance, and it is worth saying which: after it, 1.4.6 still fails on
the **brand primary button** (white on `sitf-primary`, 6.18:1), the **gain green** (`green-700`, 4.95:1), and
two marginal cases at 6.84 and 6.92. Each of those is a colour decision rather than a token sweep.

**Fixed chrome needs `scroll-padding`, which is WCAG 2.2's 2.4.11.** A focused control must not be
*entirely* hidden by author-created content, and this app has three pieces of it: the staging ribbon, the
fixed header beneath it, and `.tw-form-actions`, which becomes `sticky bottom-0` the moment an update form is
dirty. When the browser scrolls a Tab target into view it stops at the scrollport's edge - which is behind
all three. Measured on `admin/stocks/new` with the form dirty: the `employees` input landed at 1213-1233
inside a save bar occupying 1161-1233.

`scroll-padding-top` and `scroll-padding-bottom` on `:root` tell the browser where the usable scrollport
starts and ends, so the fix is three lines against the chrome's own height variables rather than a scroll
handler. **Anything added to the fixed chrome has to move those numbers with it**, which is why they are
expressed as `calc(var(--sitf-header-h) + var(--sitf-ribbon-h) + …)` rather than written out.

**1.4.11 asks for 3:1 on the visual information *required to identify* a control -- so the question is
whether the boundary is the only thing doing that job.** It is not a blanket "every border is 3:1", and
applying it as one produced a visibly wrong button.

| Control | Other identifying signals | Border |
| --- | --- | --- |
| Input, select, textarea | none -- no fill, no shadow, no text of its own | **`slate-500`**, 4.76:1 |
| Checkbox, switch track | none -- a 16px box with nothing in it | **`slate-500`** |
| Outlined button | a label, 16px of padding, a rounded box, and `shadow-sm` | `slate-200`, and that is correct |
| Filled button | its own fill, well past 3:1 | none needed |
| Card, table divider | not a user interface component at all | `slate-200` |

The field agrees, and agrees for this reason. Tailwind UI ships `ring-gray-300` at about 1.5:1, GitHub a
0.15-alpha border over a tinted fill, Polaris a light border with a shadow -- and **Material 3's outlined
button is about 3.4:1**, which looks like a counter-example until you notice it has neither fill nor shadow.
Its outline *is* the only identifier. Same rule, different components.

This paragraph said `slate-500` everywhere for one day, and the secondary button was reported as too dark
and not matching this document -- which it was. `slate-400` was measured at **2.63:1** on the way, and still
fails where the bar does apply. `wcag_audit_test` encodes the test rather than a list: it skips a control
whose own fill already reaches 3:1, and one that carries a shadow.

Measure contrast, do not guess.** Every failure found here looked fine.
2. **Test the empty and error branches.** Every admin index page returned HTTP 200
   while its empty state was broken, because the tests all created records first.

