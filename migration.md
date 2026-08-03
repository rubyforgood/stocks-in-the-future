# Migration log

A running record of changes on the `stocksdesign` branch that **affect the app
long-term** — things a future contributor needs to know because they change a
convention, remove a capability, alter data behaviour, or add a dependency.

Not a changelog. Routine styling and copy edits live in the git history and in
[`design-todo.md`](design-todo.md). This file is for decisions with a blast radius.

**Add to this file as such items come up, not afterwards.** If a change would
surprise someone six months from now, it belongs here.

Related documents:

| File | Purpose |
|------|---------|
| [`design.md`](design.md) | The design system — what the UI should look like |
| [`design-instructions.md`](design-instructions.md) | Process, gates, precedence |
| [`design-todo.md`](design-todo.md) | Live backlog of remaining work |
| [`CLAUDE.md`](CLAUDE.md) | Working notes and traps for anyone picking this up |
| **this file** | Long-term-consequence changes |

---

## Removals

### `SchoolsController` and `app/views/schools/` deleted

**What.** Removed `app/controllers/schools_controller.rb`, nine templates under
`app/views/schools/` (including three `.jbuilder` views),
`test/controllers/schools_controller_test.rb`, and the orphaned top-level
`schools:` locale block.

**Why.** No route pointed at any of it — every path 404'd for every role. Schools
are managed at `/admin/schools`, which has its own controller, an admin
authorization gate, and 15 tests.

Three findings made deletion the clear choice over wiring it up:

1. **It had no test coverage despite appearances.** `schools_controller_test.rb`
   was named after it but referenced `admin_schools_url` in all 11 of its URL
   calls and non-admin routes zero times — it was testing
   `Admin::SchoolsController`, duplicating the admin test file. Its one unique
   test, an unauthenticated redirect, is already covered by
   `admin/base_controller_test.rb`.
2. **Wiring it up would have been a privilege escalation.** It had full CRUD
   including `destroy!`, guarded only by `authenticate_user!`, with **no Pundit
   policy**. Adding `resources :schools` would have let any signed-in user —
   including a student — create, rename and delete schools.
   `Admin::SchoolsController` inherits `authenticate_admin` from
   `Admin::BaseController`.
3. **It was untouched scaffold output.** Generator boilerplate comments and
   jbuilder views, superseded by the admin namespace.

**If a non-admin schools view is ever needed**, regenerate it and write the policy
and tests. The scaffold was not saving anyone meaningful work, and while it sat
there it twice attracted maintenance effort on unreachable code.

### `app/assets/tailwind/admin.css` deleted

**What.** Removed the file and its import. It held `.filter-tabs`, `.filter-tab`,
`.header-controls`, `.action-buttons` and `.form-select`.

**Why.** Zero references anywhere in views, helpers, components or JavaScript —
apparently scaffolding for an admin filter UI that was never built. `.filter-tab`
carried eight `!important` declarations and hard-coded hex predating the token
layer, and effort had already been spent "fixing" its focus indicator before
anyone noticed nothing rendered it. An unused class is indistinguishable from a
supported one until someone adopts it and finds out.

### Font Awesome removed entirely

**What.** All 76 icon usages converted to `lucide_icon`, and the CDN
`<link>` removed from both layouts.

**Why.** It was loaded from cdnjs on every page: a third-party runtime dependency,
a privacy leak, and icons that break offline. `lucide-rails` was already in the
Gemfile and already used in three views, so this follows existing convention.

**Consequence.** Icons now inherit `currentColor` and carry `aria-hidden` by
default. **An icon-only control therefore needs its own visually hidden text**, or
it has no accessible name at all.

### 17 dead legacy top-nav CSS rules removed

Superseded by the sidebar. Zero usages. This also removed the last off-tier
breakpoints from the stylesheets.

---

## Additions

### Figtree, self-hosted

**What.** Two woff2 files under `public/vendor/figtree/`, declared in
`app/assets/tailwind/figtree.css`, and `--font-sans` now leads with Figtree.

**Why.** `design.md` prescribes it, self-hosted, no CDN.

**Note for whoever touches this.** Figtree is a **variable** font, so one file
covers the whole 400–800 range. Shipping one file per weight would be the same
bytes five times — an earlier attempt downloaded ten files before an MD5 check
showed only two were distinct. Licence: SIL OFL 1.1.

### Component primitives in `app/views/components/ui/`

`_card`, `_page_header`, `_badge`, `_empty_state`, `_data_table`, `_stat`, plus
`admin/shared/_empty_row`. Build on these rather than restyling inline.

**Convention.** Partials rendered with `render layout:` must test whether the
**yielded content is present**, not `block_given?` — the latter is unreliable
inside a partial layout.

### `dialog` Stimulus controller

Added for show/hide dialogs whose content is already in the page, distinct from
`modal_controller` which streams content into a turbo-frame. Provides Escape,
focus-move-in, focus trap and focus restore — the CSV import modal previously had
four inline `onclick` handlers and none of those behaviours.

### Header account menu, initials avatars, and a signed-out header

**What.** `layouts/_account_menu` (a native `<details>/<summary>` disclosure),
`dropdown_controller.js`, `AvatarHelper`, and `ApplicationHelper#account_role_label`. Both
layouts render the menu top-right. The application layout also gained a signed-out header.

**Why.** `design.md` already specified both pieces — its Dropdown section names "the header
account menu" and there is a Person avatar spec — and neither existed. Beyond convention:
nothing in the chrome said who was signed in, and these are shared school Chromebooks, so a
student can land on a session someone else left open.

**Behaviour changes worth knowing:**

- **Sign out moved.** It is no longer in the sidebar; it lives only in the account menu.
  There is one place to do it rather than the last item of a sidebar that collapses behind a
  hamburger on a phone. The sidebar's bottom block now sits entirely behind the same policy
  check as its Admin link, so the separator cannot render above an empty list.
- **The admin bar lost its plain-text email and two bare links,** one of which was "Sign
  out" in `red-600` on white — 4.0:1, under the gate. It renders the same menu now, with
  "View site" as an extra link, so both layouts agree.
- **Signed out there is now a header at all.** Logo plus one Sign in action, suppressed on
  the sign-in page itself.

**Avatars are initials, never images.** The users are schoolchildren; photographs would be a
data-protection question rather than a design one. The tone comes from the name rather than
the id, so it is stable across environments.

**Two things verified rather than assumed:**

- **Tailwind v4 does scan `.rb` files.** The avatar tone classes only exist in a Ruby helper,
  which would render an avatar with no background if they were not generated. Confirmed by
  putting a sentinel class in a helper, building, and finding it in the output — which also
  retroactively confirms the `admin_*_button_class` helpers from the previous change.
- **All six tone pairs measured**, 6.37:1 to 7.57:1 against their backgrounds.

**Tested by clicking.** `test/system/account_menu_test.rb` opens the menu, signs out from
both layouts, follows the portfolio link, and checks that Escape closes it and returns focus
to the summary. A request test cannot tell an open disclosure from a closed one, since the
links are in the DOM either way — `test/integration/account_header_test.rb` covers what it
can: the name, role and initial render, the menu holds sign-out and the sidebar no longer
does, and the signed-out header offers a way in.

### `PopulateGradeBook`, and a way to fill a grade book from the UI

**What.** `app/services/populate_grade_book.rb`, plus a `populate` member route, a
controller action, a policy method, and two buttons on the grade book page: one in
the empty state, one in the header once entries exist.

**Why.** Grade entries only ever existed because seeds or a console session created
them. A grade book for a real classroom opened empty with no way to add anyone, which
made everything downstream of grading unobservable — including the earnings a student
is supposed to see.

**Contract.** Returns the number of entries created, or `false` when the grade book
is `completed`. Callers have to tell `false` apart from `0`; the controller does, and
the two cases have different flash messages.

**Idempotency.** It inserts only for students with no entry and never edits an
existing one, so re-running after a student joins mid-quarter adds just that student
and leaves entered grades alone. The unique index on `[grade_book_id, user_id]` backs
this at the database level.

**Students only.** It reads `classroom.students` — Student-typed and `kept`-scoped —
not `classroom.users`, which also holds the teachers and admins attached to the
classroom. Grading one of those would pay a teacher.

**Trap worth remembering.** The buttons must stay outside the grades form.
`button_to` renders a `<form>`, and a nested form is dropped by the browser, so a
button placed inside the grades form would silently submit the grades instead of
adding students. `show.html.erb` now branches around the form rather than holding the
empty state inside it, and both buttons are covered by system tests that click them
rather than posting to the route — a POST test would have passed either way.

**Verified.** 7 service tests, 5 controller tests, 2 system tests. Confirmed in
development that a mid-quarter joiner is added and an existing `A` grade survives.

### `EarningsCalculator`, extracted from `DistributeEarnings`

**What.** `app/services/earnings_calculator.rb`. Takes a grade entry plus the same
student's previous-quarter entry and returns an `Earnings` struct of `attendance`,
`math` and `reading` in cents, with `#total` and `#by_reason` (keyed by
`PortfolioTransaction` reason). `DistributeEarnings.execute` keeps its signature and
now only persists what the calculator returns.

**Why.** Steps 3 and 4 need to show a student what a grade earned, and a projection
for the open quarter, before the grade book is finalised. Without this there would be
a second implementation of the money rules, free to drift from the one that pays.

**Behaviour is unchanged, and that is tested rather than asserted.** 18
characterisation tests were written against the *old* code first, every amount a
literal, and pass unchanged after the extraction — same test file, same 40 assertions.
The pre-existing `distribute_earnings_test.rb` derives its expectations from
`GradeEntry`'s own constants, so it agrees with whatever the code does and could not
have caught a drift.

**What the pinning exposed.** All pre-existing, none of it changed:

- C and below pay nothing for the grade itself, but improvement still pays. F → D
  earns 200 cents for improving on a grade that earns nothing.
- Improving *within* a band counts: A- → A pays the improvement.
- Quarter 1 pays no improvement, but not because `Quarter#previous` returns nil — it
  falls back to quarter 4 of the previous school year at the same school. What
  actually stops it is one level down: a classroom belongs to a single school year and
  `create_gradebooks_for_quarters` only covers that year's quarters, so the lookup
  asks for a grade book that cannot exist. **Giving classrooms grade books that span
  years would silently switch improvement on in quarter 1.**

**Verified.** 18 characterisation tests through `DistributeEarnings`, plus 7 unit
tests against the calculator directly — those need no database rows at all, which is
the point of the split.

---

## Behaviour changes

### Money: integer cents are authoritative

**What.** Added `Portfolio#cash_balance_cents` (Integer, for all arithmetic and
comparison). `Portfolio#cash_balance` remains a Float **for display only**. Both
funds checks in `Order` now use the cents accessor.

**Why.** `cash_balance` divided cents by `100.0` and `sufficient_funds_for_buy`
multiplied the result back by 100. 131,252 of the first two million cent values
do not survive that round trip, so a student with exactly enough money was
refused with *"You have $16.06 but need $16.06"*.

**Rule going forward.** Never convert money to a Float and back. Render through
`number_to_currency` — interpolated raw, a whole-dollar price prints as `$15.0`.
Postgres types `price_cents / 100.0` as `numeric`, so existing SQL doing that is
exact and should be left alone.

### Trade confirmation step

**What.** The order form is now two steps: enter a quantity, review, confirm. The
review shows the action, quantity, price each, total, and **the balance the
student will be left with**.

**Why.** A mistyped quantity previously became a real order in one click.

**Consequence for tests.** Any test that places an order must click
`"Review order"` before the submit button.

### Seeds are now idempotent, and fail loudly

**What.** `db/seeds/partials/users.rb` gained the missing `username` for the
teacher and all four user saves became `save!`. The transaction and order
partials are guarded, and all randomness was removed.

**Why.** The teacher account could never be created — `username` is validated for
presence, `save` returned false, and the seed printed success anyway. Re-running
seeds duplicated transactions and inflated student cash balances; `orders.rb`
guarded its creates with `find_by` but randomised the values it matched on,
defeating its own guard.

**Verified.** Three consecutive `db:seed` runs leave record counts and balances
identical. Covered by `test/db/seeds_test.rb`.

### The seeded teacher is joined to a classroom, not just given a `classroom_id`

**What.** `db/seeds/partials/users.rb` now creates a `TeacherClassroom` row joining
the seeded teacher to `Classroom.first`, idempotently.

**Why.** `GradeBookPolicy` asks whether `classroom.teachers` includes the user, and
that association reads `teacher_classrooms`. A `classroom_id` on the user does not
feed it, so the seeded teacher was refused access to every grade book — the one
account most likely to be used to look at grading.

**Trap.** The row has to be built from a `Teacher`. The seed creates the teacher via
`User.find_or_initialize_by`, which yields a `User` instance and stays one even after
`type` is set to `"Teacher"`; `TeacherClassroom belongs_to :teacher, class_name:
"Teacher"` rejects it with `ActiveRecord::AssociationTypeMismatch`. The seed
re-fetches with `Teacher.find_by`. `test/db/seeds_test.rb` caught this — a console
check did not, because `find_by` there returned a correctly typed subclass.

### Page titles lost the rule underneath them

**What.** Removed `border-b` from the six page headers that had one — the shared
`components/ui/_page_header` primitive, plus the bespoke headers on portfolio, grade
book, trading floor, classrooms and transactions. Spacing classes were left exactly as
they were, so nothing shifted; only the line went. Two further redundant rules went
with them: a section `h3` sitting directly on top of a `divide-y` list, and a
slate hairline on the bottom edge of the teal announcement banner, where the colour
change is already the separation.

**Why.** Spacing separates a title from its content on its own. The rule was a second
signal saying the same thing, and where a card or table followed immediately it landed
a few pixels from that surface's own border — two hairlines together, which reads as a
bug rather than as structure.

**Also fixed on the way.** `classrooms/index` and `orders/index` used a bare
`border-b` with no colour named, so they were drawing Tailwind's default border colour
rather than a token. Deleting the rule removed the token violation too.

**What stays.** The tab rail an active tab's `border-b-2` sits on, the fixed admin app
bar's bottom edge, table row separators, and form field-group separators. The rule of
thumb is in `design.md`: delete a rule that duplicates a separation the page already
makes some other way — padding, a tint, a colour change, or a surface edge.

**Guarded.** `test/integration/page_title_divider_test.rb` renders six pages, parses
them with Nokogiri and walks up from the `h1`, so re-nesting a heading cannot quietly
turn the check into a no-op — the failure mode of the regex version I tried first. It
was verified by putting a border back and watching it fail, not just by watching it
pass. It also asserts exactly one visible `h1` per page.

**Follow-up: the admin index header strips went too.** All six — users, students,
teachers, classrooms, school years, and stocks through the shared
`admin/shared/_table` — no longer draw a rule beneath their header. They were the one
place I had argued to keep it, on the grounds that a rule inside a bounded surface is
structure. That argument does not survive contact with what is actually below the
strip: the table opens with a tinted `bg-slate-50` header row, so the separation is
already there, and on the students and teachers indexes the strip's rule was a second
line about 20px below the filter tab rail's own baseline. Verified against rendered
HTML for all six pages, including re-adding the border to the shared partial to confirm
the check could fail — which is also how I established that the shared partial backs the
stocks index and nothing else.

**Resolved: one card surface, `.tw-card`. The card header keeps its rule.**

The header half took two wrong turns before landing, and both are worth knowing.

**The surface was settled all along**, in `design.md`'s `### Card / panel` section, which I
had not read while calling it an open product decision:

> `rounded-2xl border border-slate-200 bg-white shadow-sm` (pad `p-5`)

The same passage says *"a card inside a card isn't a pattern in this app"*, which
independently confirms the nested-card fix on the show pages.

Its next sentence — `border-b` under the title over-segmenting a card — I then read as
settling the header too. It does not; see below.

**What changed.** `app/assets/tailwind/cards.css` defines `.tw-card` as the documented
surface. 31 replacements across 25 files now use it: `components/ui/_card`, the admin table
card, every admin form and filter panel, and the student-facing earnings, chart,
announcement and grade-book surfaces.

**The drift this removes.** Four treatments, seven distinct class strings, 22 files —
`rounded-xl`/`shadow-xs` in the component, `rounded-lg` with `ring-1 ring-slate-900/5`
instead of a border across admin, plus two one-offs. **None matched the spec**, including
the two I had presented as the choice.

Also unboxed three tables inside the student show page's cards. I had wrapped them in
`rounded-lg border` panels two changes earlier, which is the card-in-a-card the same passage
rules out; they now take a `border-t` above the table instead.

**Verified in the built CSS,** because an `@apply` class that fails compiles to nothing and
would have silently stripped the surface off every card in the app: `.tw-card` emits
`--radius-2xl`, a 1px slate-200 border, white background, `shadow-sm` and `overflow:hidden`.
(Checked twice — the first grep used `^\.tw-card` against minified CSS and found nothing,
which looked exactly like the failure it was not.)

**The guard needed updating too.** `admin_page_structure_test` located the card by its
`rounded-lg` class, which the new surface does not have. It matches `tw-card` now, so a
future change of surface cannot quietly turn the check into a no-op.

**Then the header rule came back**, because removing it was wrong. Two mistakes compounded:

1. **The sentence I relied on is scoped.** "`border-b` *under the title* likewise
   over-segments a **compact** card; structure comes from that detail divider and the footer
   `border-t`." It is about a compact *content* card, and it names the substitute structure
   it depends on. Most cards here hold an attribute list or a table and have no detail
   divider and no footer rule, so removing the header rule left them with **no boundary at
   all**. I applied a sentence about one kind of card to every card in the app.
2. **The padding was left stacked.** The header's `py-4` plus the body's `p-5` put 36px
   between a title and its content — the same fault as the `pb-5` left under the page title
   when that rule went, which had already been reported once. Padding that exists to hold
   content off a rule has to go when the rule does.

The rule is restored on `components/ui/_card`'s header: `border-b border-slate-200 px-5 py-4`
above a `p-5` body. That matches Stripe's Box, GitHub Primer's `Box.Header` and Tailwind UI's
card-with-header. Material and Polaris omit it, and the split falls along card type — ours
are mostly data cards, which is what the first group's pattern is for.

**Both `design.md` sections were corrected**, since they contradicted each other and the
code: the Dividers section now states that a card header is the one place a rule is added,
and the Card / panel section carries a scope note on the inherited sentence. A bare heading
*inside* a card body still takes no rule — that remains the `stocks/_stock` case.

### `grade_books.update.notice` was missing

Saving grades flashed `translation missing: en.grade_books.update.notice`. Added along
with the `populate` keys. `Save Grades` also became `Save grades` for the sentence
case convention, which meant updating five assertions in the system tests.

### How the trading fee works, and what changed

Worth writing down because it was misread once already, and the two halves live
in different files.

**The mechanism, unchanged.** There are two pieces:

1. **A hold.** `Portfolio#pending_transaction_fee` subtracts the fee from the
   *displayed* balance whenever the student has any pending order. Nothing is
   persisted — it reserves the money so it cannot be spent twice.
2. **A charge.** `OrderExecutionJob` runs on a schedule and calls `ExecuteOrder`
   for each pending order, then `TransactionFeeProcessor`, which writes a real
   `PortfolioTransaction` with `transaction_type: :fee` and
   `reason: :transaction_fees`. `Portfolio#total_fees` reads those rows.

The fee is **once per student per job run**, not once per order — both the hold
and the charge behave that way. Batching several trades into one charge is
deliberate: it is the "bundle your trades" lesson.

**Why this is easy to misread.** `ExecuteOrder` writes only `purchase_cost`, so
reading it alone suggests the fee is never charged. The charge is in a sibling
service invoked by the job. Anyone auditing this should run `OrderExecutionJob`
rather than calling `ExecuteOrder` directly, or they will see the hold released
and no charge appear.

**What changed.**

- The fee now records **which orders it covers**, in the existing `description`
  column: *"Daily trading fee, covering 2 orders: buy 1 AAPL, buy 3 GOOGL."*
  Previously a student seeing "−$1.00 Transaction fees" could not tell which trade
  caused it, and the charge could not be audited against the orders. Grouping is
  per student, so one student's fee never names another's trades.
- Renamed in the UI from "Trading fee" to **"Daily trading fee"**, because
  "trading fee" implies per-trade and it is not.
- The order form now says the amount is **held now and charged when the orders go
  through**, and the review step says placing the order holds the amount rather
  than charging it. At review time nothing has moved.

**Deliberately not changed.** The fee was not moved into `ExecuteOrder`. That
would make it per-order, changing the economics students experience and removing
the batching lesson. The amount stayed at $1.00.

### Rails 8.1.3 → 8.1.3.1 (security)

Merged upstream's `dependabot/bundler/rails-8.1.3.1` to clear **CVE-2026-66066**,
arbitrary file read and remote code execution in Active Storage variant
processing. This also made `bin/lint` pass end to end for the first time, since
it runs `bundler-audit`.

**`main` is still on 8.1.3.** See the open items below.

### Admin pages get a real heading and title from their breadcrumbs

**What.** The admin layout's `<h1>` was the branding link "Admin dashboard",
identical on every page, and its `<title>` was the static string
`Admin - StocksInTheFuture`. The branding is now a `<span>`, and both the heading
and the title are derived from the last breadcrumb — the one without a `path`,
which every admin controller already sets to the current page's label.

**Why.** Every admin page announced the same title regardless of what it showed:
a `<title>` failure under WCAG 2.4.2 and a heading failure under 2.4.6. `/admin`
had three `<h1>` elements. The title also still carried the old un-spaced brand
name.

**Convention worth knowing.** The layout heading is `sr-only`, because index and
show pages lead with a section title and a visible page title would say the same
word twice on screen. **A page that renders its own visible `<h1>` declares
`content_for :own_heading, true` and the layout steps aside.** Four pages do: the
dashboard, the component demo index, the component demo form, and the component
demo show.

Verified: all 16 admin pages now have exactly one `<h1>` and a distinct title.

---

## Conventions established

| Convention | Detail |
|-----------|--------|
| Responsive tiers | Only `base` and `lg:`. No `sm:`/`md:`/`xl:`/`2xl:`. Users are students on 1366×768 Chromebooks and 375px phones. |
| Neutral palette | `slate`, not `gray`. 918 utilities swept; contrast verified to hold. |
| Copy | Sentence case everywhere. Never all-caps, never the `uppercase` transform on labels. |
| Colour | Brand tokens only. No hex, no `[var(--...)]` in markup — both hid contrast failures. |
| Tables | Hairline dividers, `text-xs` chrome headers, money right-aligned with `tabular-nums`. |
| Page titles | One scale: `text-2xl font-bold tracking-tight text-slate-900`, and **never a rule beneath**. |
| Dividers | No extra dividers. A rule stays only where nothing else separates: tab rail baseline, app bar edge, table rows, form groups. Delete it under a page title and on a card header strip above a table. |
| Landmarks | Exactly one `<main>` per page — the layout provides it. |
| Flash | Only the layout renders it, via `layouts/_flash`. |

---

## Migration map: admin page headers out of the card — **done**

**The question that started it:** is a page title and its primary action, nested
inside the table card, industry standard? No. Tailwind UI's page-heading patterns,
Stripe's dashboard, Shopify Polaris (`Page` with `primaryAction`) and GitHub Primer all
put the page title and its action at **page level**, on the page background, with the
card below holding only the data. Nesting them inside the card makes the heading read
as a section label rather than as the page's title, and makes one surface do two jobs.

### Current structure

Every admin page, index and show alike:

```
breadcrumbs
card
  header strip - title + actions      <- should be at page level
  table (index) / attributes (show)
```

On show pages it is worse: the outer card wraps a padded div holding the title, the
actions, **and** `admin_show_attributes`, which renders `components/ui/_card` itself —
so a card inside a card. The trailing sections are `mt-6 pt-6 border-t` blocks with
`text-sm text-slate-500` headings, which is the divider pattern just removed elsewhere.

The visible heading is an `h2` or `h3`; the only `h1` is the layout's `sr-only` one
derived from breadcrumbs.

### Target structure

```
breadcrumbs
page header - h1 + actions, on the page background
card(s) - data only
```

### Order of moves, and what each breaks

1. **`components/ui/_page_header` declares `content_for :own_heading`.** Breaks
   nothing; the application layout does not read it. Without this every admin page
   would carry two `h1`s — the visible one and the layout's hidden one.
2. **`admin/shared/_table` loses its title/actions strip, and `admin_table` loses
   those options.** Breaks the three callers that pass them (stocks, announcements,
   schools) until step 3.
3. **Eight index pages gain a page header.** Breaks the seven controller tests that
   assert `h3`/`h2` for an index title — they become `h1`, which is the point.
4. **Ten show pages hoist title and actions out, and their trailing sections become
   cards.** Breaks the show-page title assertions the same way, and the section
   heading assertions, which move from `h3` to the `h2` a card renders.
5. **Extend `page_title_divider_test` to the admin pages.** They now have a real
   visible `h1`, so the existing "exactly one visible h1" assertion can cover them.

**Risk:** low. No controller, model, route or money behaviour changes — this is view
structure and heading level only. The heading changes are the observable part, and they
are covered by existing tests that must be updated deliberately rather than mechanically
(three of the `h3` assertions are section headings that stay put, not page titles).

### What actually shipped

All eight index pages and all ten show pages now render `components/ui/_page_header`
above the card. `admin/shared/_table` and `admin_table` no longer accept a title or
actions. `admin/shared/_show_actions` is new and carries the Edit/Delete pair, with
paths passed explicitly because `Student` and `Teacher` are STI subclasses of `User`, so
`[:admin, record]` does not reliably name their route. Show-page sections that were
`mt-6 pt-6 border-t` blocks are now cards, so those rules are gone too.

21 heading assertions moved: page titles to `h1`, section headings to the `h2` a card
renders, and two sub-headings inside a card body to `h3`. Each was changed by line
number rather than by pattern — `assert_select "h3", "Classrooms"` appears both as the
classrooms index title, which became `h1`, and as a section on the teacher show page,
which became `h2`.

### Found while doing it, and fixed

- **`admin/students/show` had unbalanced `</div>`s.** One stray closing tag meant the
  portfolio section's later content sat outside the block it appeared to be indented
  inside. The browser silently repaired it. Rebuilding the page on cards removed it.
- **The same page hand-rolled a `dl` that duplicated `admin_show_attributes`,** with
  `slate-500` labels rather than the `slate-700` the shared partial uses. Replaced with
  the partial.
- **No admin button had a focus indicator.** The class literals carried no `focus` or
  `focus-visible` style at all, so keyboard focus was invisible on every admin action —
  WCAG 2.4.7. They are now `admin_primary_button_class`, `admin_secondary_button_class`
  and `admin_danger_button_class`, which name the outline colour (Tailwind v4 resolves an
  unset one to `currentColor`) and add `min-h-11` for the 44px target the literals missed
  at about 36px.
- **`admin/shared/_actions` mixed `focus:ring-2` with `focus-visible:ring-*`,** so the
  ring rendered on plain focus with no colour named. Routed through the helpers.
- **Two contrast failures** on the student show page: `green-600` on `green-50` at 3.4:1
  and `red-600` on white at 4.0:1, both under the 4.5:1 gate for text that size. Now
  `green-700` (4.8:1) and `red-700` (5.9:1).
- **Delete confirmations named nothing.** "Are you sure you want to delete this stock?"
  became "Delete stock \"AAPL\"? This cannot be undone.", matching what
  `admin/shared/_table` already did.
- **`Portfolio Transaction #3`** was Title Case in a page title. Now sentence case.

### Follow-up: two things the first pass got wrong

Both were mine, and both came from reasoning about the layout instead of reading
`design.md`.

**Surplus padding under every page title.** Removing the rule from `_page_header` I kept
the `pb-5` deliberately, on the grounds that leaving spacing untouched meant nothing would
shift. But that padding only existed to hold content off the rule, so with the rule gone
it stacked 20px of padding on 24px of margin — 44px under every title. `design.md`'s page
rhythm is a 24px header block, so the header is now `mb-6` alone. Also removed from the
three bespoke headers that had the same pair: portfolio, grade book, trading floor.

**Filter tabs left inside the table card.** I decided they belonged to the table because
they filter it, and wrote a comment justifying it. `design.md` says the opposite in two
places: a filter is "chrome above the data", and a plain borderless filter bar sits `mb-4`
(16px) *above* the table. Leaving them on the card's surface kept chrome and data on one
surface, which is exactly what hoisting the header out was supposed to stop. They now sit
above the card, and the two rails — students and teachers — share
`admin/shared/_discard_filter_tabs` so they cannot drift apart again.

Extracting that rail fixed two defects in it. Inactive tabs had no border width, so
selecting a tab shifted the row by 2px and the `hover:border-slate-300` set a colour on
nothing; they now carry `border-b-2 border-transparent`. And the selected tab was
signalled by colour alone, so it now carries `aria-current="page"`.

`admin_page_structure_test.rb` asserts all of it: no heading and no create action inside
the table card on any of the eight index pages, and exactly one `aria-current` tab, above
the card rather than in it. Verified by moving the tabs back inside and watching it fail.

### One light sidebar across the app and admin

**What.** `NavHelper` holds a single row treatment used by `layouts/_navbar`,
`layouts/_nav_item` and `admin/shared/_navigation`. Both sidebars are now `bg-white` with a
`border-r`, `text-slate-700` idle, and a selected row of `bg-sitf-primary/10
text-sitf-primary-dark` plus a 3px `border-sitf-primary` leading indicator (7.78:1 measured).
Both are 256px wide; the app one was 200px, so `main` moved from `lg:ml-50` to `lg:ml-64`.

**Why.** The transition between the two halves of the product was jarring because they were
two different chromes: a saturated teal panel with a lime chart-accent fill on one side, white
with **no selected state at all** on the other. A light sidebar is also what current practice
means — Stripe, Shopify, GitHub, Notion, Vercel, Linear, Material 3 — with brand presence in
the logo, the buttons and the indicator rather than the panel.

**The lime was not a contrast bug.** `#323232` on `#D3DF44` is 8.80:1. The problem was role:
`sitf-accent` is labelled *fill only, never text or icons* in the token file because it is
1.46:1 on white, and it was the loudest colour in the palette carrying the most repeated state
in the app.

**Removals.** The two `nav-icon-active` / `nav-icon-inactive` `filter` chains in `navbar.css`
are gone. They existed only to force external SVG assets white on a dark panel; the nav uses
`lucide_icon` now, which inherits `currentColor`. Verified absent from the built CSS.

**Two bugs found on the way:**

- **Admin "Dashboard" linked to `root_path`**, the *app* root, so the first item of the admin
  nav left admin. It points at `admin_root_path` now.
- **Dashboard matched every admin page.** `/admin` is a prefix of every admin path, so
  "request is inside this section" was true everywhere and Dashboard lit up alongside the real
  section. `nav_section_active?` takes an `exact:` flag for it. **`admin_page_structure_test`
  caught this** by counting `aria-current` — it found 5 where it expected 1 — which also
  showed that the test's own selector was too broad once the nav gained `aria-current`. It is
  scoped to the tab rail by `data-testid` now.

**Tested.** `nav_selected_state_test.rb`: a section page marks only its own section, the
dashboard marks only Dashboard, a show page keeps its parent marked, the app nav marks its
destination, both navs carry the same selected class, and the sidebar is no longer a dark
panel.

### Buttons back on the 40px height token

**What.** `.tw-btn-*` and the admin button helpers are now `h-10` (40px), `px-4`, `text-sm`,
`gap-2`, `rounded-lg`, `shadow-sm` — design.md's documented button base. Per-icon
`-ml-1 mr-2` margins are gone in six files, since `gap-2` handles the spacing.

**Why.** Two separate drifts made buttons too big:

- `.tw-btn-primary` and `.tw-btn-tertiary` were `min-h-11 px-5 py-3` **with no text-size
  class**, so they inherited 16px body text — taller and wider than the token on both axes.
- I had set the admin helpers to `min-h-11` (44px) citing the "minimum 44px touch targets"
  note. That note is stricter than the spec: WCAG 2.5.8 (AA) asks for 24x24, and 44px is the
  AAA / Apple HIG figure. design.md fixes buttons at 40px, "the mainstream medium-button
  height: Material 3, Chakra, shadcn". `CLAUDE.md` and `design-instructions.md` are corrected
  so 44px is scoped to bare tap targets — icon-only controls, sidebar nav rows, row actions.

**Two contrast failures fixed with it.** The classrooms index "New classroom" button was
hand-written `bg-blue-500` with white bold text: off-brand, and **3.68:1**, under the 4.5:1
gate. The teacher-picker avatar in `classrooms/_form` was the same blue. Both are the brand
teal now, 6.18:1. Only two hand-written button strings existed app-wide; both are gone, so
every button goes through a named class.

**Removals.** `.tw-btn-danger` had no callers and is deleted — an unused class is
indistinguishable from a supported one until someone adopts it. `.tw-btn-tertiary` no longer
carries `ml-2`: a button holding its own margin puts layout inside the component, and one
caller was already fighting it with `ml-0`. Its five callers now get spacing from a `flex
gap-3` container.

**Verified in the built CSS:** `.tw-btn-primary` emits `height: calc(var(--spacing) * 10)`.

**Correction.** I first recorded the brand teal at 5.23:1, having measured `#00778b`, which
is not the token. `--color-sitf-primary` resolves to `--sitf-primary-chart1`, **`#00698c`**,
which is **6.18:1** on white. Better than claimed, but it was a guess presented as a
measurement. Resolve the variable chain before quoting a ratio.

### The dark bar under the top nav is gone

`layouts/application.html.erb` drew a fixed full-width 1px bar in `sitf-primary-dark`
under the header — an 8.5:1 dark rule straight across the page, which is body-text weight
for something that is chrome. Removed.

The header does still need *some* cue, because it is `fixed` and painted the same colour as
the page, so content scrolls invisibly beneath it. It now carries `shadow-xs`, which reads
as a layer rather than as a divider and keeps the "no extra dividers" rule intact.

Note the inconsistency this leaves: the **admin** app bar is `bg-white` with a neutral
`border-b border-slate-200`, while the main app bar is surface-coloured with a shadow. Two
treatments for the same piece of furniture. Worth settling on one.

### Guarded

`page_title_divider_test.rb` covers the twelve admin pages as well now — it could not
before, because the assertion is "exactly one *visible* h1" and admin pages had none.
Verified separately that `content_for :own_heading` really suppresses the layout's hidden
heading: each admin page renders exactly one `h1` in total, with no `sr-only` one left
over. Without that check the guard would have passed either way, since it filters
`sr-only` headings out.

---

## Migration map: navigation depth and the mobile drawer

Two restructures, mapped before any code moves. They are independent and can ship in either
order, but the drawer one has a prerequisite that the nav-depth one does not.

---

### Map A — Nav depth: the Trading floor disclosure — **done**

**Outcome.** The per-stock list was confirmed a leftover. Trading floor is a flat
`nav_item` render like its four siblings; `stock_navbar_toggle_controller.js` and the chevron
swap rules in `navbar.css` are deleted, and so are `set_navbar_stocks` and the `stocks:` local
— that was a `policy_scope(Stock).active` query on **every request** for a list only the sidebar
read.

**The coverage moved rather than disappearing**, which was the substance of this map. Four
tests in `navbar_policy_visibility_test` asserted which stocks a student could see *in the
navigation*. They now live in `stocks_controller_test` against the trading floor page, and they
test something truer there: the page separates **active** from **archived** in labelled tables,
where the nav simply hid archived stocks. That page had almost no coverage before — one
"responds 200" — so this is a net gain rather than a shuffle. What remains in the navbar test is
a single assertion that the row is flat: no `<details>`, no per-stock links.

**Industry standard, since it was asked:** navigation holds destinations, and a catalogue is
reached through search and filter on its list page, with a command palette, recently-viewed, or
pinned items as the escalations. None of them put every record in the sidebar. See design.md,
Sidebar navigation.

**Current structure.** Four of the five app nav items are flat links. Trading floor is a
`<details data-controller="stock-navbar-toggle">` whose `<summary>` contains **two further
interactive controls**:

```
<li>
  <details open-if-active>
    <summary>                        <- a control in its own right; click toggles
      <a href=/stocks>               <- navigates; needs stopPropagation to not toggle
      <button>chevron</button>       <- toggles; needs preventDefault + manual .open flip
    </summary>
    <ul> one <li> per active stock </ul>
  </details>
</li>
```

Three overlapping affordances in one 44px row. `stock_navbar_toggle_controller` exists only to
keep them from fighting: `navigateLink` stops propagation so the link does not toggle the
disclosure, and `toggleChevron` prevents the default and flips `open` by hand.

Two further problems, neither of them interaction:

- **The sublist is unbounded.** `ApplicationController#set_navbar_stocks` assigns
  `policy_scope(Stock).active`, so *every* active stock is a nav row. The sidebar grows with
  the catalogue and duplicates what the trading floor page already lists.
- **Depth is inconsistent.** One item expands and four do not, so the nav has no consistent
  shape to learn.

**Target structure.** Trading floor becomes a flat link like its four siblings. Stocks are
found on the trading floor page, which is what that page is for.

```
<li><a href=/stocks>Trading floor</a></li>
```

**Order of moves.**

1. **Confirm nobody depends on the sublist as a navigation path** — see the open question
   below. This is the only step that is not mechanical.
2. Replace the `<details>` block in `layouts/_navbar` with a `nav_item` render, matching the
   other four.
3. Delete `stock_navbar_toggle_controller.js`. Both methods exist only to referee the
   disclosure; nothing else calls them.
4. Delete the chevron swap rules from `navbar.css` (`details .icon-up`, `details[open]
   .icon-down`).
5. Drop `set_navbar_stocks` and the `stocks:` local, if nothing else uses `@navbar_stocks` —
   it is a `policy_scope` query on every request for a list only the sidebar reads.

**What breaks.** `test/integration/navbar_policy_visibility_test.rb` asserts
`details[data-controller='stock-navbar-toggle']` at lines 56 and 61, and those assertions are
the point of two tests — they check a student sees only permitted stocks in the nav. If the
sublist goes, **what those tests were protecting has to move to the trading floor page**, not
just be deleted. That is the real work in this map.

**Risk:** low mechanically, moderate in judgement. No money, no data, no routes. The risk is
removing a navigation path someone uses daily.

**Open question for a maintainer.** Is the per-stock sidebar list used, or is it a leftover?
It is the only place in the app that lists every stock outside the trading floor itself. If it
is wanted, the alternative target is a capped list — stocks the student holds, which is bounded
by the portfolio and is a genuinely different view from the full catalogue.

---

### Map B — One mobile drawer mechanism

**Current structure.** Two mechanisms for the same interaction.

| | App (`layouts/_navbar`) | Admin (`layouts/admin`) |
|---|---|---|
| Trigger | `<label for="mobile-menu-toggle">` | `<button data-action="click->admin-sidebar#toggle">` |
| State | hidden `<input type="checkbox">` + `peer-checked:` | `classList.toggle("-translate-x-full")` |
| Scrim | `<label>` with `peer-checked:block` | div toggling **both** `hidden` and inline `style.display` |
| Closing on navigate | 4 `<label for="mobile-menu-toggle">` wrappers | nothing |
| Nav markup | one nav, translated | rendered **twice**, desktop and mobile copies |

**It is also not really CSS-only.** `stock_navbar_toggle_controller#navigateLink` reaches into
the document and sets `menuCheckbox.checked = false`, so the checkbox mechanism already depends
on JavaScript to behave.

**Accessibility gaps in both**, which is the strongest reason to do this at all:

- **No `aria-expanded`** on either trigger, so neither announces open or closed.
- The app trigger is a `<label>` driving a hidden checkbox, so assistive tech announces a
  **checkbox**, not a button that opens navigation.
- **No Escape, no focus trap, no focus return.** An open drawer is a modal surface over the
  page; `dialog_controller` already does all three and is the model to copy.
- Admin's scrim fights itself: a `hidden` class *and* an inline `display` toggled together.

**Target structure.** One `drawer` Stimulus controller, used by both layouts, with a `<button>`
trigger carrying `aria-expanded`, one nav element that translates, one scrim, Escape to close,
focus moved in and returned, and close-on-navigate handled by the controller rather than by
wrapping every row in a `<label>`.

**Order of moves.**

0. **Make mobile width testable first.** *Every system test runs at 1400x1400*
   (`test/application_system_test_case.rb`), and the drawer only exists below `lg`. **Nothing
   in the suite has ever exercised either mechanism.** Step 0 is a way to drive a 375px
   viewport, plus characterisation tests of what both do today. Without it this is a rewrite
   with no safety net, on the interaction students on phones depend on.
1. Write `drawer_controller.js`, modelled on `dialog_controller` for Escape, focus trap and
   focus return.
2. Convert the **admin** layout first. It is the smaller surface, has no `<label>` wrappers to
   unpick, and lets the duplicated mobile nav copy collapse into one.
3. Convert the app layout: replace the checkbox, the scrim label, the close label and the four
   row wrappers with the controller.
4. Delete `admin_sidebar_controller.js`.
5. Drop the `navigateLink` half of `stock_navbar_toggle_controller` — or the whole controller,
   if Map A has already landed.

**What breaks.** Nothing at request level: `bin/rails test` never sees either mechanism. That
is precisely the problem — **a green suite will not tell you this worked.** The `<label>`
wrappers in `layouts/_nav_item` are load-bearing for the current behaviour and their comment
says so, so that partial changes too.

**Risk:** moderate, and higher than it looks because of the missing coverage. Confine it to
chrome: no routes, controllers or data. Do step 0 first, or the only verification available is
looking at it once.

---

## Open items owned by someone else

- **Merge the CVE fix into `main`.** `main` remains on `activestorage 8.1.3` with
  CVE-2026-66066. Upstream has the fix ready as a dependabot branch; a maintainer
  needs to merge it. **The most urgent item in any of these documents.**
- ~~**Decide what the trading fee is.**~~ **Resolved — and the original claim
  here was wrong.** This previously said the fee was never recorded as a
  transaction and that balances were therefore too high. That was incorrect. The
  fee *is* charged: `TransactionFeeProcessor`, called by `OrderExecutionJob` after
  the orders execute, writes a real `PortfolioTransaction` with
  `transaction_type: :fee`. The error came from a grep that looked for
  `transaction_type: :fee` and `.fee.create` and missed the plural scope,
  `.fees.create!`. See the fee entry under Behaviour changes for how it actually
  works.

---

## Architecture

No architectural work has been done. **When it begins, a migration map goes here**
— current structure, target structure, the order of moves, and what each step
breaks — before any code moves. Tier 3 items in `design-todo.md` (student
information architecture, teacher bulk grade entry, the earnings feedback loop)
would each need one.

---

# Migration map: Tier 3

Written before any code moves, per the convention above. This is an analysis and a
proposal, not a record of work done — nothing in this section has been built.

**Two of the three Tier 3 items I originally proposed rested on premises that turned
out to be false.** I have corrected them below rather than carrying them forward.
Read the "what I got wrong" note in each case.

## Current structure

Evidenced from the routes, the sidebar, and what each template renders.

### Student-facing destinations — four

| Destination | Route | Shows |
|---|---|---|
| Home | `/` | Welcome, "Earnings to invest" figure, announcements, a static four-step explainer |
| My portfolio | `/users/:id/portfolios/:id` | Value chart, three stats, holdings table, earnings summary by category |
| Transactions | `/orders` | Orders table with status |
| Trading floor | `/stocks` | Active and archived stock lists, buy/sell entry points |

### The cash figure appears in four places

`Portfolio#cash_balance` is rendered on Home ("Earnings to invest"), the portfolio
page ("Total cash value"), the trading floor (via `shared/_earnings_to_invest_card`)
and the order form ("Available cash"). Four labels, one number. That is not a bug,
but it means the student's most important figure has no single home.

### How earnings actually reach a student

```
Teacher enters grades in a grade book  (grade_books#update, autosaved)
        ↓
Admin finalizes the grade book         (grade_books#finalize — admin only)
        ↓
DistributeEarnings.execute             (attendance, math, reading, per entry)
        ↓
PortfolioTransaction deposits          (with a reason)
        ↓
Portfolio#cash_balance rises           (visible to the student)
```

Two properties of this chain matter for the architecture:

1. **`GradeBookPolicy#finalize?` is `user.admin?`.** A teacher can enter grades but
   cannot release the earnings they produce. The step that makes a student's work
   visible to them is held by someone outside the classroom.
2. **Quarters carry no dates** — the schema has `number` and `name` only. So the
   cadence is whatever a school decides, and the earnings latency is effectively one
   quarter.

### What a student cannot see

`grade_entry`, `math_grade`, `reading_grade` and `attendance_days` appear in exactly
three templates: the two teacher-facing grade book partials, and
`admin/students/show`. **No student-facing view renders them.**

So a student sees the *effect* — "Attendance earnings $5.00" in the earnings
summary — and never the *cause*: which grades, how many days, or what would change
it. The product's central feedback loop is one-directional.

## The three Tier 3 items, re-examined

### Item 10 — student information architecture. **Stands, but narrowed.**

I originally said a student's question *"am I doing well, and why?"* requires
assembling four screens. Half right. The *"am I doing well"* half is answerable
today: the portfolio page has the value chart, the stats and the holdings.

The *"why"* half is not answerable at all, on any screen, because the grades that
generated the earnings are invisible to students. That is the real finding, and it is
narrower and more actionable than "reshape the navigation".

**So the work is not a new dashboard. It is making cause visible.**

### Item 11 — teacher bulk grade entry. **Withdrawn: it already exists.**

**What I got wrong.** I wrote that "grade entry appears row-by-row" and proposed
bulk entry with keyboard navigation. I had not read `grade_books/_table.html.erb`.
It renders every student's entry in a single form via
`fields_for "grade_entries[]"`, with one submit for the whole grade book and a
30-second autosave. It is already bulk entry.

**What is genuinely missing, found while checking.** Nothing in application code
creates `GradeEntry` records — the only code path that does is `db/seeds`. Grade
*books* are created automatically per quarter by
`Classroom#create_gradebooks_for_quarters`, but their entries are not. A teacher
opening a real grade book therefore sees "No grade entries for this grade book yet"
and has no way to add their students.

That is a functional blocker, not an architecture question, and it blocks the entire
earnings mechanism: no entries means no grades, which means nothing to distribute.
**It should be fixed before any Tier 3 work and does not need a migration map.**

### Item 12 — feedback loop timing. **Stands.**

Earnings arrive only when an admin finalizes a grade book, so cause and effect are
separated by a quarter. A student cannot see what their current attendance is worth
until the quarter closes and someone else acts.

## Target structure

Deliberately conservative. It adds one destination and one concept, and leaves the
existing four destinations and every route in place.

### Add: an "Earnings" destination

A student-facing view of the grade entries that belong to them — attendance days,
math and reading grades, per quarter — alongside the earnings each produced. This is
the missing half of the loop.

It needs:

- A `GradeEntryPolicy` allowing a student to read **their own** entries. None exists
  today; grade entries are reachable only through `GradeBookPolicy`, which is scoped
  to teachers and admins.
- A read-only presentation. Students must never write to a grade entry.
- A distinction between **finalized** and **in progress**. A grade book that is not
  yet finalized holds provisional data, and showing it as fact would be misleading.

### Add: projected earnings, clearly labelled as projected

Once a student can see the current quarter's entry, the value it *would* produce is
computable from `DistributeEarnings`' existing rules. That closes the timing gap
without changing when money actually moves.

This requires extracting the earnings calculation from `DistributeEarnings`, which
currently computes and writes in the same pass. A pure calculator, used by both the
distributor and the projection, keeps one definition of the rules.

### Leave alone

- The four existing destinations and all routes. Navigation stays.
- When money moves. Projection is a display, not a change to the ledger.
- The trading fee mechanism.
- `GradeBookPolicy#finalize?` remaining admin-only. Whether teachers should finalize
  their own classroom's grades is a policy question for the maintainers, not a
  refactor.

## Order of moves, and what each one breaks

Each step is independently shippable and independently revertible. Nothing later
depends on anything earlier being perfect.

### Step 0 — Create grade entries from application code *(prerequisite, not Tier 3)* — **done**

Give teachers a way to populate a grade book from its classroom's enrolled students.

- **Breaks:** nothing. Purely additive.
- **Risk:** low, but it writes records that feed the money path, so entries must be
  idempotent — one per student per grade book. The unique index on
  `[grade_book_id, user_id]` already enforces this at the database level.
- **Tests first:** creating entries twice must not duplicate; a student enrolled
  later must be addable without disturbing existing grades.
- **Why first:** without it, nothing downstream is observable in a real environment.

Shipped as `PopulateGradeBook` — see the entry under Additions for the contract and
the two traps found on the way (nested forms, and STI typing in the seed). Two things
were pulled in because they blocked using the feature at all: the seeded teacher had
no `teacher_classrooms` row, so no seeded account could open a grade book, and
`grade_books.update.notice` did not exist, so saving grades flashed a missing
translation.

### Step 1 — Extract the earnings calculation — **done**

Split `DistributeEarnings` into a pure calculator (entry plus previous entry in,
amounts out) and a writer that persists what the calculator returns.

- **Breaks:** nothing visible. `DistributeEarnings.execute` keeps its signature.
- **Risk:** this is the money path. The calculator must be provably identical to the
  current behaviour before anything else uses it.
- **Tests first:** characterisation tests pinning the *current* outputs for
  attendance, math and reading, including the previous-quarter comparison, written
  and passing against the existing code before the extraction.
- **Watch for:** `find_previous_entries` returns `{}` when there is no previous
  quarter. First-quarter behaviour is a real branch and needs a test.

### Step 2 — Student-readable grade entries

Add `GradeEntryPolicy` (a student reads only their own), a scope, and a read-only
view of the current and past quarters' entries.

- **Breaks:** nothing. New policy, new route, new view.
- **Risk:** authorization. A student must never read another student's entry. This is
  the one step where a mistake is a privacy incident rather than a visual bug.
- **Tests first:** a student can read their own entry; a student cannot read another's;
  a teacher can read entries in their classroom; a student cannot write.
- **Watch for:** `policy_scope` is used elsewhere in this app — follow that pattern
  rather than filtering in the controller.

### Step 3 — Show earnings against their cause

On the new view, pair each quarter's entry with the earnings it produced, using the
existing `reason` values on the deposits.

- **Breaks:** nothing.
- **Risk:** low. Read-only presentation.
- **Watch for:** deposits carry a `reason` but no link to the grade book that caused
  them, so pairing is by reason and time rather than by association. If that proves
  ambiguous, associating the deposit with its grade book is a schema change and its
  own step — **not** something to slip into this one.

### Step 4 — Projected earnings for the open quarter

Use the Step 1 calculator to show what the current, unfinalized entry would be worth.

- **Breaks:** nothing in the ledger.
- **Risk:** the projection must be unmistakably a projection. If a student reads it as
  money they have, that is worse than not showing it. It must never be added to a
  balance, and the copy must distinguish it.
- **Tests first:** projected figures do not appear in `cash_balance`, and a finalized
  quarter shows actual rather than projected.

## Open product decisions

These are not mine to make, and Steps 2–4 are shaped by them.

1. **Should students see provisional grades at all?** A teacher part-way through
   entering a quarter's grades has incomplete data. Showing it is honest about
   progress but may cause anxiety or arguments; hiding it until finalized preserves the
   current latency. **Step 2 needs this answered.**
2. **Should teachers be able to finalize their own classroom's grade books?**
   Currently admin-only, so the step that releases earnings sits outside the
   classroom. This is a trust and workflow question, not a technical one.
3. **Is a projection desirable pedagogically?** It tightens the feedback loop, which
   is the product's mechanism. It also lets a student watch a number move without any
   money existing, which may read as a promise.

## What I am not proposing

- No new navigation structure. The four destinations work; the gap was a missing view,
  not a wrong hierarchy.
- No consolidated dashboard. My original framing suggested one; having read the
  screens, the portfolio page already is one.
- No change to when money moves.
- No schema changes in Steps 0–4. If pairing deposits to grade books in Step 3 proves
  ambiguous, that becomes a separate step with its own map entry.
