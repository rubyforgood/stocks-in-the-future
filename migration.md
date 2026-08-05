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

### `_action_icon_button`, `.table-action-*`, and two unreachable Devise views deleted

**What.** Removed `app/views/components/_action_icon_button.html.erb`, the
`.table-action-link` / `.table-action-button` classes from `tables.css`, and
`app/views/devise/unlocks/new.html.erb` plus
`app/views/devise/confirmations/new.html.erb`.

**Why.** The partial and the two CSS classes were the old row-action treatments and
have no callers left now that row actions go through `ButtonHelper` — an unused
class is indistinguishable from a supported one until someone adopts it. The two
Devise views had **no routes at all**: `User` enables
`:database_authenticatable, :registerable, :recoverable, :rememberable, :validatable`,
not `:confirmable` or `:lockable`, and `devise/shared/_links` guards on
`devise_mapping.confirmable?` / `lockable?` so their links never rendered either.

**If confirmable or lockable is ever enabled**, run `rails generate devise:views`
to get fresh templates rather than reviving these — they were unstyled scaffolding
with `<br>` tags and bare `f.submit`.

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

### `submit_button` takes a variant; the holdings row action is a ghost

**What.** `Admin::FormBuilder#submit_button` accepts `variant: :secondary`, used by
admin/students#edit's "Add transaction". `portfolios#show`'s per-row "Trade" is a
`ghost_action_link`, its empty-state CTA is `:secondary`, and the `trade_class` /
`trade_disabled_class` locals are deleted. The earnings card suppresses its "Invest now" CTA when
already on the trading floor.

**Why it has blast radius.**

1. **`portfolios#show`'s actions column changed shape** - filled 44px pill to a 32/44px ghost with a
   leading icon, and the non-student branch is now the `table-no-permission` dash rather than a
   disabled pill. Anything asserting on a "Trade" button's appearance there will need updating; the
   accessible name is unchanged.
2. **The trading floor no longer renders an "Invest now" link at all.** It pointed at the page it
   was on. A test looking for that link on `stocks#index` will fail, correctly.
3. `submit_button`'s signature gained an option rather than changing, so existing calls are
   unaffected.

### The navigation and account controls align by their own box

**What.** Both navigation triggers are a single 44px `<button>` with `rounded-lg` and a `hover:`
fill, flush with the content gutter - no negative margin, no nested state layer. The account menu's
trigger likewise lost its `-mr-2` and is `rounded-lg` rather than `rounded-full`.

**Why it has blast radius.**

1. **There are no negative margins in the chrome any more.** Three earlier attempts added one to put
   the glyph on the gutter; each put paint past the content edge. If one reappears, the fill goes
   with it.
2. **The glyph sits 10px inside its box, by design.** That is centring a 24px icon in a 44px target,
   and it is not a bug to be corrected.
3. **The trigger markup lost a level** - the state-layer `<span>` is gone, so the svg is a direct
   child of the button again.
4. **The account trigger is no longer a pill.** If a round avatar control is wanted there, that is a
   deliberate exception to the `rounded-lg` control token and belongs in design.md.

### The account menu carries identity only; navigation moved out

**What.** The account menu's trigger is an avatar and a chevron - the name beside it is gone - and
its `sr-only` text now names the user. The panel gained the email and is `w-64`. The `extra_links`
local is gone: "View site" is a top-bar control in admin, and "My portfolio" was dropped because the
app sidebar already has that row. `resources :users` is `only: []`.

**Why it has blast radius.**

1. **The user's name is no longer in the chrome**, only in the panel and in the trigger's accessible
   name. Anything asserting the name is visible in the header will fail - two integration tests did.
2. **`_account_menu` takes no locals at all now.** Passing `extra_links:` is silently ignored; if an
   account *action* is ever added it goes in the partial itself.
3. **Six routes stopped existing** (`users_path`, `user_path`, `edit_user_path`, `new_user_path` and
   the write pairs). They all raised before, and nothing referenced them, but a helper call anywhere
   would now fail at route-generation time instead of at the controller.
4. **The email line is conditional.** A user with no email renders no line rather than an empty one.

### One gutter for chrome and content; the app bar trigger is a ghost

**What.** Both app bars are `px-4 lg:px-6`, matching `main`. The navigation trigger takes `-ml-2.5`
and the account trigger `-mr-2` so their glyphs land on the content edge. The app's trigger lost its
`bg-sitf-primary` fill and now matches admin's borderless one. `<main>` lost `overflow-auto`, and the
signed-out `main` is `p-4 lg:p-6` rather than a flat `p-6`.

**Why it has blast radius.**

1. **The negative margins are load-bearing and look like mistakes.** Removing `-ml-2.5` puts the
   glyph 10px off the gutter again. They are only valid while the pulled-out element paints
   **nothing in any state** - the navigation trigger is a bare 44px target, and its hover fill lives
   on a nested 40px circle so the paint keeps 8px from the viewport edge. Moving that fill back onto
   the button, or giving the button a border, reintroduces the overhang.
2. **`<main>` is no longer a scroll container.** Anything that assumed it scrolls (a scroll-position
   script, a sticky offset measured against it) would change behaviour. `page_width_test` still reads
   `main.scrollWidth`, which reports content overflow regardless of the overflow property, so it is
   unaffected.
3. **The app bar trigger is no longer teal**, so a test looking for that fill would fail.

### The portfolio page is rebuilt, and two shared surfaces moved with it

**What.** `portfolios#show` is a KPI band, then chart + breakdown, then holdings full width, on a
single `gap-6`. `components/ui/_stat` and `.table-wrapper` now use `.tw-card`'s tokens
(`rounded-2xl`, `shadow-sm`). New `components/ui/_callout` replaces the hand-rolled amber banner on
`portfolios#show` and `stocks#index`. `_portfolio_chart` and `_earnings_summary_card` are rebuilt on
`components/ui/_card`.

**Why it has blast radius.**

1. **`.table-wrapper` changed on every table in the app** - 12px to 16px radius, `shadow-xs` to
   `shadow-sm`. Nothing asserted those, but it is a visible change everywhere, not just here.
2. **`_stat` changed everywhere it is used**, same reason.
3. **The page no longer renders `shared/_earnings_to_invest_card`.** Cash is a KPI now, and the card
   stays on the trading floor. A test looking for it on the portfolio page will fail.
4. **The stat testids changed**: `holdings-value` and `portfolio-value` are new, `cash-balance` and
   `total-stocks` kept their names but their labels changed ("Total cash value" to "Cash to invest",
   "Total stocks" to "Shares held"). "Total earnings" is gone from the stats and lives only in the
   breakdown card.
5. **`_earnings_summary_card` lost its amber band**, `divide-black/40` and `bg-sitf-accent-soft`.
   `sitf-accent-soft` may now be unreferenced - check before deleting the token.
6. The chart card's `h2` carried **two `class` attributes**; the browser silently kept the first.
   Worth knowing that ERB will not warn about that.

### One set of table classes; the header fill is gone

**What.** Every table converges on `.table-base` / `.table-header-row` / `.table-header-cell` /
`.table-body-row` / `.table-body-cell`. `.table-header-row` no longer carries `bg-slate-50`;
`.table-header-cell` gained `align-top`; `.table-base` is `min-w-full` rather than `w-full`. Removed:
`<thead class="bg-slate-50">` (14 occurrences), `divide-y divide-slate-{200,300}` on 16 `<table>`
elements and 15 `<tbody>` elements, and 38 hand-written cell class strings. The trading floor's two
tables share explicit column widths under `table-fixed`, and its logo is `size-10` at every width.

**Why it has blast radius.**

1. **Every table in the product changed** - no header fill, one border at the seam, `align-top`
   headers, and admin row dividers from `slate-200` to `.table-body-row`'s `slate-100`. Anything
   asserting on those classes breaks; `table_consistency_test.rb` asserts the computed result across
   twelve tables instead.
2. **`.table-base` is `min-w-full`.** `w-full` would have stopped wide tables from growing inside
   `overflow-x-auto`, which is what the pinned actions cell depends on.
3. **`shared/_table_container` takes an optional `table_class:`** local. Existing callers are
   unaffected.
4. **Row separators now come from the row, not the container.** A new `<tr>` in a `<tbody>` needs
   `table-body-row` or it will have no border - including a row partial defined in another file,
   which is how `grade_books/_grade_entry` was missed.

### One button base; admin button helpers are aliases

**What.** `buttons.css` defines the base once as a shared selector group and the variants extend it:
`.tw-btn-primary`, `.tw-btn-secondary`, `.tw-btn-danger-outline`, `.tw-btn-primary-disabled`.
`admin_primary_button_class` / `admin_secondary_button_class` / `admin_danger_button_class` return
those class names. `ADMIN_BUTTON_BASE`, `.tw-btn-tertiary` and
`app/helpers/components/button_helper.rb` are deleted.

**Why it has blast radius.**

1. **Every button in the product changed slightly.** Filled variants went `font-medium` ->
   `font-semibold`; outlined went `ring-1 ring-slate-300` / `border-slate-300` ->
   `border border-slate-200`; the admin primary lost a `border border-transparent`; the admin base
   gained the `justify-center` it never had. All of it is now asserted in
   `test/system/button_variants_test.rb` against the rendered box.
2. **`admin_*_button_class` no longer returns a full class string** - it returns one class name. Any
   caller that concatenated onto it still works, but anything parsing it will not.
3. **`.tw-btn-tertiary` no longer exists**; its seven call sites are `.tw-btn-secondary`.
4. **`render_button` is gone**, so `Shadcn::FormBuilder` must not start calling it again. The rest
   of the shadcn form builder (inputs, labels) is untouched and still in use.

**Deliberately not done:** design.md's `:danger` (filled rose) and `:success` (filled emerald) are
not shipped. `:danger` has no surface - Turbo uses the native confirm dialog. `:success` would add a
third button colour to a product whose reported problem was garish buttons; `admin/teachers#show`
Reactivate stays `:secondary` with a `circle-check` icon. Both are recorded in design.md as
decisions rather than omissions.

### Buy and Sell are secondary buttons; `.tw-btn-buy` / `.tw-btn-sell` deleted

**What.** The trading floor's Buy and Sell are `.tw-btn-secondary`. The order modal's Review order
and submit are a single `.tw-btn-primary`. Both filled variants are removed from `buttons.css`.

**Why it has blast radius.** Teal-for-buy / amber-for-sell was a documented convention in
`design.md` with a named exception arguing for it, and both are now reversed - so a future reader
finding the old prose in git history should know it was overturned deliberately, after looking at
the rendered page, not lost in a refactor. Two saturated fills in two hues on every row of the
densest page read as garish; the actions are distinguished by label and arrow instead, which the
colour rules require anyway. Emphasis moved to the confirm step, where one primary sits alone.

**Nothing depended on the colours.** No test asserted them, and the buy/sell system tests click by
label. If a chart or legend ever needs a buy/sell hue, take it from the chart tokens rather than
reviving these button classes.

### Component stylesheets moved into `@layer components`

**What.** `buttons.css`, `tables.css`, `cards.css`, `forms.css` and `navbar.css` are each wrapped in
`@layer components`.

**Why it has blast radius.** It inverts the cascade between these classes and every Tailwind
utility. Before, an unlayered `.tw-btn-buy` beat `.hidden`; now any utility wins, which is what the
markup already assumed. If something relied on a `.tw-*` class overriding a utility, that
expectation is now reversed - nothing in the suite did, but it is the thing to check first if a
component starts looking wrong.

The bug it fixed: the buy/sell modal rendered Cancel, Back, Review order and Buy shares at the same
time, because `hidden` on the Back and submit buttons did nothing. Introduced when those buttons
moved from bespoke class strings (which set no `display`) onto `.tw-btn-*`.

### `GET /orders/:id` removed

**What.** `resources :orders, except: %i[show destroy]`, and `orders/show.html.erb` plus
`orders/_order.html.erb` deleted.

**Why.** The route raised for every order: `OrdersController` has no `show` action, so the
scaffolding view's `render @order` was `render nil` -
`"'nil' is not an ActiveModel-compatible object"`. Nothing in the app linked to it, and `destroy`
had no action either. `orders/_order.json.jbuilder` is kept - `index.json.jbuilder` renders it.

**If an order detail page is ever wanted**, write the action and a real view; do not restore those
two files, which were generator output with an inline `style="color: green"`.

### Breadcrumbs wrap

**What.** `admin/shared/_breadcrumbs` is `flex flex-wrap` with `gap-x`/`gap-y` instead of
`inline-flex ... space-x-1`, and crumb labels `break-words`.

**Why it matters.** A long trail used to push `<main>` sideways on six admin show/edit pages, which
carried the row actions off screen with it. Any new crumb label is now free to be long.

### Row actions are pinned to the right edge below `lg`

**What.** `.table-actions-pinned` (`sticky right-0`, opaque, below `lg` only) is on the trailing
actions cell of all nine tables that have one, on both sides. `classroom#show`'s two-pane row is
`flex-col ... lg:flex-row`. `grade_books/_table` gained `tabindex="0"` / `role="region"`.

**Why it has blast radius.**

1. **A pinned cell needs an opaque background**, so anything that later sets a row background or a
   striping rule has to account for the actions cell painting over the scrolled columns. It is
   deliberately `lg:static lg:bg-transparent` so this only applies below `lg`.
2. **`<main>` must not scroll sideways at 375px.** `table_actions_reachable_test.rb` asserts it for
   two pages; a new two-column page that forgets `lg:flex-row` will fail there rather than in a
   visual review.
3. **The roster's actions header changed** from a visible "Actions" to `sr-only`, and its cells from
   `px-6 py-4` to the shared `table-body-cell`, so it matches every other table.
4. Column sort links are deliberately **not** asserted - they scroll with their own column.

### The trading floor's Buy/Sell moved into the primary cell below `lg`

**What.** `stocks/_index_row` renders the trade pair (now `stocks/_trade_actions`) inside the
company cell below `lg` and in a trailing column at `lg`, and the holdings + actions columns are
`hidden lg:table-cell`. The header, the row and the empty-row colspan all use
`policy(Stock).show_holdings?`.

**Why it has blast radius.**

1. **Both placements are in the DOM at once**, so `[data-testid='buy-stock-button']` matches twice
   per stock. Capybara only sees the visible one, so `click_on "Buy"` is unaffected, but any
   `count:` assertion or raw `page.html` count needs `visible: true`.
2. **A 500 was fixed, not just a layout.** `stocks#index` gated the earnings card on
   `show_holdings? || current_user.student?` while the card dereferences `@portfolio`, which the
   controller only assigns to a student who has one. A student with no persisted portfolio got an
   exception on the trading floor. Reachable in real data: the seeds create students with
   `User.find_or_initialize_by` and set `type` afterwards, which leaves a `User` instance, so
   `Student`'s `after_create :ensure_portfolio` never fires.
3. **The header and the row used different conditions** (`current_user.student?` against
   `policy(stock).show_holdings?`), so that same student got four header cells over two body cells.
4. The disabled "Invest now" pill was `bg-slate-400` with `slate-700` ink - **4.04:1**, under the
   4.5:1 gate - and is now `.tw-btn-primary-disabled`.

**Roles.** Teachers and admins see no trade controls, by design; they hold no portfolio.
`trading_cta_test.rb` asserts that absence so it is not rediscovered as a bug.

### Row actions are ghost buttons, and no destructive control is red at rest

**What.** `ButtonHelper` is new and owns `ghost_class(:neutral | :danger)` plus
`ghost_action_link` / `ghost_action_button`. Every table row action across both
sides — View, Edit, Delete, Archive, Restore, Activate, Reactivate, Deactivate,
Cancel order — is now that ghost with a leading Lucide icon. `admin_danger_button_class`
also changed from `border-red-300 text-red-700` to slate at rest with a rose hover.

**Why it has blast radius.** Three things a future reader could be surprised by:

1. **Confirm dialogs changed wording.** Several were a bare "Are you sure?" and now
   name the record ("Delete school-name (2024–2025)? This cannot be undone."). Any
   test or script matching the old string breaks. Three controller tests were already
   coupled to the *old badge classes* (`span.bg-green-50`) and were rewritten to assert
   the label instead.
2. **"Buy Shares" became "Buy shares".** Sentence case, and the label is interpolated
   (`"#{buying ? 'Buy' : 'Sell'} Shares"`), so no literal-based sweep could ever have
   found it. Nine system-test `click_button` calls were updated with it.
3. **Two icons were never visible.** `activate_button` / `archive_button` drew
   `content_tag(:i, class: "fas fa-*")` and the Font Awesome stylesheet is not linked
   in either layout, so they rendered an empty `<i>`. Same for two
   `fa-exclamation-circle` glyphs in `Admin::FormBuilder`'s error output. All four are
   Lucide now. **`font-awesome-rails` is still in the Gemfile and is now referenced by
   nothing** — a candidate removal, left alone here because dropping a gem touches
   `Gemfile.lock` and `bundler-audit`.

**Not changed:** Buy and Sell on the trading floor stay filled CTAs. See design.md,
"Row actions as implemented here", for why, so it does not get "corrected" later.

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
| Row actions | The ghost from `ButtonHelper`, with a leading Lucide icon and a visible label. Never a filled CTA per row. Trailing column right-aligned, header `sr-only` "Actions". |
| Destructive controls | No red at rest, ever — slate at rest, rose on hover, in both the ghost and the bordered variant. Danger is carried by icon, label and confirm dialog as well as colour. |
| Button definitions | Buttons are defined in Ruby as often as in templates. Sweeps must include `app/form_builders` and `app/components`, not just `app/views` / `app/helpers` / `app/assets/tailwind`. |
| Hover states | Unverifiable in system tests — Tailwind wraps `hover:` in `@media (hover:hover)` and headless Chromium reports `(hover: none)`. Assert hover as a class contract; assert rest state as pixels. |

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

### The content gutter was double on the app side

**Measured: admin 24px, app 48px, home 53px.** The app's `main` carried `px-4 lg:px-6` and then
five page wrappers added `px-4 lg:px-6` of their own on top of it - `stocks/index`,
`portfolios/show`, `students/new`, `students/edit`, and the two `px-6` wrappers I had added to
`orders/index` and `classrooms/index` myself. Home was worse again because `max-w-5xl` is narrower
than the space available, so `mx-auto` centred it and added ~29px more.

**The layout owns the gutter now; no page adds its own.** All of them measure 24px. Admin's inner
wrapper also moved from a flat `p-6` to `p-4 lg:p-6`, so the mobile padding matches the app's 16px
rather than being 24px on a phone.

**Content width unified on `max-w-7xl`** - already 35 call sites and what design.md references.
`max-w-[1180px]` was an arbitrary value the token rules exclude, and home's `max-w-5xl` was the
reason one page had a different gutter from every other.

**A recorded deviation from design.md.** Its page-rhythm entry says `lg:px-8` (32px). I used 24px:
admin already rendered it, so the app converges on admin rather than both moving; the report was
that the gap was too large; and 24px is mid-field (Material and Stripe 24, GitHub 24-32, Tailwind
UI 32, Polaris 16-20). The entry also uses the `sm:` tier this app does not, so it was already
partly superseded. Stating it so it is a decision rather than drift.

### Card, table and footer spacing, all measured

**Tables were two systems.** Four student-facing tables used the shared `table-*` classes
(`px-4 py-3`); eight admin tables hand-wrote `px-3 py-4`. Transposed, so an admin table's header
padding and its cell padding disagreed and **every column's header text sat 4px off its own
data** - measured `thLeft=281` against `tdLeft=277`. Admin rows were 56px, student-facing 48px.

All nine files now use `table-header-cell` / `table-body-cell`: padding identical
(`12px 16px` both), columns aligned (`281` and `281`), rows 48px - between Polaris's 44 and
Material's 52. `spacing_test` asserts a header lines up with its column, naming the cause.

**The sidebar footer** was a `py-2` list with **no horizontal padding**, so the Admin row sat
flush to the sidebar edge while every other row was inset 12px, with an 8px band above it against
the 4px used between nav rows. Both are invisible at rest and drawn by the hover highlight, which
is exactly how it was reported. It is now `px-3 pt-1`: measured `mainLeft=12 footerLeft=12
ruleToRow=4`. Industry standard for a pinned sidebar footer is a hairline and then an ordinary
row - Stripe, Linear, GitHub.

**Cards needed nothing**, which is worth recording so the next sweep does not fiddle with them:
24px between stacked cards (design.md's section rhythm), `p-5`-family padding, and the 32px header
seam fixed earlier. Measured rather than assumed.

### Sidebar density, and a standing instruction about both sides

**The admin sidebar scrolled on the machine it is built for.** Ten links at 44px rows with 24px
section gaps measured **636px against 561px of available height at 1366x768**. At `lg:min-h-9`
(36px), `space-y-4` groups and `mb-1` headings it measures **561px and fits**. Both figures were
measured directly, and the before figure by temporarily reverting the helper rather than by
arithmetic.

**36px is the desktop figure across the field** - Notion about 27, Linear 28, GitHub and Stripe
32, Tailwind UI and Polaris 36. 44px is the touch figure, and Material's 56px drawer is
mobile-first. So the row is `min-h-11 lg:min-h-9`: the phone drawer keeps its 44px target, the
desktop sidebar gets the density. WCAG 2.5.8 (AA) asks 24x24, which 36px clears comfortably.

Both navs moved together because they share `NavHelper` - which is the point of having it.

**`in_chromebook_viewport` is new**, and `spacing_test` now asserts the admin sidebar does not
overflow 1366x768. The default test window is 1400px *tall* and no real screen is, so a sidebar
that outgrows a short viewport is invisible at the size the suite normally runs. That is why this
reached a person before it reached a test.

**A flake I introduced, found and fixed here.** `assert_onscreen` returned as soon as the drawer
started entering, so a test that clicked immediately afterwards was clicking a moving target. It
failed about one run in three with "drawer should be off canvas once closed". It now waits for the
panel to be *fully* in (`left >= -1`). Four consecutive clean system runs after.

**Standing instruction recorded in CLAUDE.md**, since it generalises past this change: check
`design.md` *and* what the field does before choosing any value, and apply every instruction to
both the app and the admin side. Checking an existing component is not the same as checking the
spec - that is how an unspecified ring reached every badge in the app.

### Sentence case, pass eight: the residue, and what is correctly Title Case

A wider sweep after pass seven - text nodes in *any* tag, every quoted string in `app/**/*.rb`,
all locale values, and the attributes a text scan cannot see (`placeholder`, `alt`, `aria-label`,
`prompt`, `include_blank`) - surfaced 47 candidates and **four real ones**:

- `Nil Value:` on the component demo.
- `A School year with this school and year already exists.` in the school years controller.
- `User ID (Read-Only)` on the demo form.
- `alt: 'Investment Funds'` on the earnings card - fixed as `alt: ''` rather than lowercased,
  because the image is decorative and the card already states "Earnings to invest" beside it.
  The equivalent piggy bank on `home/index` was already `alt: ""`.

**The other 43 are correctly Title Case, and the list is worth keeping** so the next sweep does
not "fix" them:

- **Company and person names** throughout `db/seeds/partials/stocks.rb` - "Ford Motor Company",
  "Jim Farley (CEO)", "The Coca-Cola Company", and every competitor list.
- **Industry classifications** - "Consumer Electronics", "Telecommunications Services",
  "Exchange Traded Funds". These are sector names, conventionally Title Case.
- **`'Global Quote'` in `AlphaVantageApiClient`** - an API response key, not copy. Changing it
  would break the parse.
- **Class names in prose** - `Admin::FormBuilder`, `DateTime`.
- **Seed fixture values** - "Teacher Name", "Test School", "Smith's Sixth Grade", "Demo User".
- **Placeholders that are examples of the thing** - "John Doe", "Apple Inc.".

`John Doe` and `DateTime` were both caught and reverted during the original six passes; they were
caught again here, which is a reasonable sign the detector is calibrated rather than blunt.

### Sentence case, pass seven: three categories no view sweep could reach

The classrooms table still read "Student Count" and "Total Earnings" after six passes. Sweeping
again with a detector rather than by eye found **62 strings** across three categories, none of
which lives where the previous passes looked:

1. **Breadcrumb labels are in controllers**, not views — `label: "New Teacher"` in every admin
   controller. Six passes over `app/views` could not see them. They also feed the admin layout's
   `sr-only` h1, which is why the hidden heading read "New Teacher" while the visible one read
   "New teacher".
2. **Strings inside array and hash literals** in a view — `['Attendance Earnings', ...]` in the
   earnings card — which no `label:` / `link_to` / `<th>` pattern matches.
3. **Submit labels.** Explicit ones (`f.submit "Update Stock"`) were findable. One was not:
   `classrooms/_form` called a bare `form.submit`, and **Rails generates "Create Classroom" from
   the model name**. That string exists nowhere in the source, so no text search of any kind could
   have found it — the same class of problem as the `username.upcase` heading. Confirmed by
   asking Rails what it renders. Every submit now carries an explicit label.

Also swept: four `activerecord.attributes` reason strings in `en.yml` ("Earnings from Attendance"),
the trading floor's "Company (Exchange)", and the component demo's "Read-Only Fields".

**Tests were propagated from the views diff**, not by running the converter over `test/` — six
`click_on` labels in three system tests. The bare-submit case surfaced precisely because the test
then failed looking for a label the view never generated.

**Verified in the rendered page**, not the templates: the classrooms table now reads
`["Name", "Teacher(s)", "Student count", "Total earnings", "Edit"]` and transactions reads
`["Date", "Username", "Class", "Stock", "Price per share", "Shares", "Status", "Type", "Total cost"]`.

### The principle, named: measure the rendered box

Three spacing reports on this branch, three times reading the class names and concluding they
were correct, three times wrong. It is now a named principle in design.md and CLAUDE.md, with
the table of all three instances:

| Reported | Markup said | Measured | Cause |
|---|---|---|---|
| Under the page title | `mb-6` = 24px | 44px | a `pb-5` left behind when the rule under the title went |
| Inside the card | `py-4` + `p-5` | 37px | two paddings stacking at the seam |
| Under the page header | `mb-6` = 24px | 32px | a 40px action beside a 32px h1 in an `items-start` row |

**Two of the three came from removing something and leaving its spacing behind** - which is the
shape to watch for, and is why the rule now reads: when a rule, border or divider goes, the
padding that existed to hold content off it goes with it.

**Title and action alignment, measured rather than asserted.** With a title alone the action's
bottom is flush with the h1's bottom (`bottomDelta=0`); with a subtitle the action's top is flush
with the h1's top (`topDelta=0`). Tailwind UI's convention is to centre the row instead;
**centring measures 28px to the content below rather than 24px**, because a 32px h1 centred in a
40px row leaves 4px of dead space. That was measured by temporarily setting `items-center`, not
inferred.

### Header spacing, measured at last

The gap under a header was reported wrong three times on this branch. Each time I reasoned from
class names, and each time the classes looked right. Measuring the rendered geometry found two
causes, neither visible in the markup:

- **A 40px action beside a 32px h1.** `_page_header` used `lg:items-start` always, so the row
  was as tall as the button and the title left **8px of dead space beneath it**. A header that
  reads as `mb-6` rendered a **32px** gap. design.md specifies `items-end` for a title-only
  header and `items-start` only when there is a subtitle, and records it as a bug it had already
  measured once. The component now picks per header: 32px -> **24px**.
- **The card seam.** A `py-4` header above a `p-5` body stacks to 36px, measured at **37px** from
  the header text to the first line of content. Restoring the rule two changes ago marked the
  boundary but did not remove the space - I said the rule would absorb it, which it does not.
  16px either side of the rule, as Stripe's Box and Primer's `Box.Header` use: **33px**, and
  symmetric.

**`test/system/spacing_test.rb` asserts pixels, not classes**, because class inspection is what
failed three times. It measures the title-to-content gap and the card seam, with a 2px tolerance,
and its failure messages name the usual cause. Verified by putting `items-start` back and
watching it fail with "title to card measured 32px".

Everything else measured correctly at 24px: thirteen of the seventeen pages swept. The pages that
could not be measured cleanly are the three with custom inline headers, which is a separate piece
of work already noted.

### The badge component did not match its own spec, and the page-header sweep

**The ring was never in the spec.** `components/ui/_badge` carried `ring-1 ring-inset` with a
per-tone ring colour. design.md's Status pill specifies
`inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-medium` with a tint and a
dark foreground — **no ring, no border** — and `px-2.5 py-1`, not the `px-2 py-0.5` the component
used.

That matters more than one component, because the previous change swept fourteen hand-rolled
badges onto it. **Aligning things onto a component is only alignment if the component matches the
spec**; I took what existed as the baseline without checking it, so the sweep standardised the
drift instead of removing it. The component now matches, and tones follow design.md's names —
emerald and rose rather than green and red. Measured: emerald 5.21:1, rose 5.72:1, slate 6.92:1,
amber 4.84:1, blue 6.16:1, teal 5.25:1. The slate figure matches the one design.md quotes, which
is a useful check that the right spec is being read.

**The hue-pinning test problem, twice.** Tests had pinned `bg-green-100`; I loosened them to
`/green/`, which then blocked the move to emerald. They now assert the label, the badge scale, and
that true and false differ — no palette at all.

**Page headers.** The *scale* was already right: every visible h1 was
`text-2xl font-bold tracking-tight text-slate-900`. The header **block** was not — 31 pages
hand-rolled the h1 with spacing bolted on (`mb-6` on ten, `py-2` on two, `mb-2` on two). All but
the deliberate exceptions now render `components/ui/_page_header`.

**That sweep fixed an invisible defect.** The admin layout renders an `sr-only` h1 unless the page
declares `:own_heading`, and only `_page_header` declares it — so **nineteen hand-rolled admin
pages were shipping two h1s**, the visible one and a hidden breadcrumb-derived one that disagreed
on case ("New Teacher" against "New teacher"). Verified before and after by counting `h1`s in the
rendered pages.

**Left alone deliberately:** Devise's auth pages (a centred card, genuinely a different layout),
and `stocks/show`, `stocks/index` and `classrooms/show`, whose titles sit inline with controls
that would need restructuring rather than swapping — noted rather than forced.

**A scripted conversion mistake worth remembering.** My regex captured a subtitle *including* its
ERB delimiters and emitted `description: <%= @user.username %>` inside an ERB expression, which is
invalid. Four pages raised until it was fixed. The admin controller tests caught it immediately;
`bin/lint` did not.

### Badges, table alignment, and the oversized primary cell

**Cells are `align-top` now.** `.table-body-cell` was `align-middle`. The transactions table
stacks a company name over a ticker in one column while every other cell is a single line, so
the single-line cells floated to the vertical centre of a taller row. design.md's table tokens
already specified `align-top`; the class did not follow them.

**The order status badge was 36px tall.** `h-9 px-4 py-2` with `text-[14px]`, `rounded-[16px]`
and a meaningless `leading-[0]` — Figma-export markup, button-sized, and made of arbitrary
values that bypass the tokens. It is `components/ui/_badge` now: `px-2 py-0.5 text-xs`.

**The badge component existed and was used once.** Fourteen other places hand-rolled a badge in
eight distinct treatments — `px-2.5 py-0.5` and `px-2.5 py-1.5` and `rounded-md px-2 py-1`, with
`bg-*-100` here and `bg-*-50` with a ring there. All fourteen now render the component, including
`boolean_badge`. `order_status_tone` in `ApplicationHelper` maps a status to a tone so the two
views that render an order status agree.

**Three tests had pinned the badge to exact hues** (`bg-green-100`), which meant `boolean_badge`
could not move onto the component — whose success tone is `bg-green-50` with a ring — without
failing for no behavioural reason. They assert the tone family and the scale now. A test that
pins a Tailwind shade blocks the component it is meant to protect.

**Primary cells were oversized.** The trading floor rendered its ticker at `text-lg
font-semibold` and the transactions table its company name at `text-base text-black`, in tables
whose other cells are `text-sm`. Each row read as a heading. Both are `font-medium` at body size
now, with the secondary line `text-xs text-slate-600`.

### The flaky test, found

A single error had appeared twice across the branch, each time passing on rerun. The
fingerprint was consistent: same run count, **exactly 8 fewer assertions**, one error. That is
one test aborting before its first assertion.

**It is `ClassroomsControllerTest#test_update`, and the cause is the grade factory.**

```
ActiveRecord::RecordInvalid: Validation failed: Level has already been taken
    test/controllers/classrooms_controller_test.rb:96
```

`Grade#level` is validated unique. The factory used `sequence(:level) { |n| n }` — 1, 2, 3 — and
the classroom factory builds a grade for every classroom, so the sequence advances constantly.
Eleven test sites hard-code a level: 5, 6, 7, 9 and 10. When the sequence reached one of those
in the same worker before the test that hard-codes it, the test failed. Whether it did depended
on the seed and on how 744 tests were spread across ten workers.

**Proven, not inferred.** With `FactoryBot.rewind_sequences`, six `create(:grade)` calls produce
levels 1 to 6, and `create(:grade, level: 6)` then raises exactly the error above.

**Fix:** the sequence starts at 1000, outside the range real data or a test would name — real
grade levels are 1 to 12. One line, and it closes all eleven sites rather than the one that
happened to fail.

**Verified:** the flake hit at run 7 of a clean loop before the fix; 34 clean runs after it.

**A wrong turn worth recording.** My first attempt reproduced it by running the suite while
rewriting files, and produced `PG::TRDeadlockDetected` across many unrelated test classes. That
was self-inflicted: I had left a 60-run hunt going in the background, and **two `bin/rails test`
invocations share the same ten worker databases**, so they deadlock against each other. It looked
like a parallelism bug in the suite and was nothing of the kind. Two lessons: check what else is
running before believing a reproduction, and a stress reproduction that produces a *different*
signature from the original report is probably a different bug.

### One page surface, one link colour

**Page background.** The app was `bg-sitf-surface` (`#f7f9f3`) and admin was `slate-50`, so
moving between them changed the paper as well as the furniture. Both are `slate-50` now —
admin's, as asked. `sitf-surface` has no remaining references; the token stays defined as part
of the brand palette.

**App bar.** Both layouts are `bg-white border-b border-slate-200`. That also retires the
`shadow-xs` I put on the app header two changes ago: it existed only because the header was the
same colour as the page, which is no longer true. The note in this document about "two
treatments for the same piece of furniture" is settled.

**Links.** 34 links hand-wrote a generic Tailwind blue while newer code used the brand teal —
two link colours in one product. `.tw-link` names it once: `sitf-primary-dark`, 9.01:1 on white,
underline on hover. Contrast was never the issue (blue-600 is 5.17:1); consistency was.

**Found while sweeping, and fixed:**

- The **selected filter tab** used generic blue while the nav's selected row used the brand —
  two treatments for the same idea, on the same page.
- The **transaction type badge** was blue on the show page and green/slate on the index I had
  just written. Same data, two treatments; the index's is the one that distinguishes deposits.
- The **breadcrumb hover** and the **checkbox accent** were both generic blue.
- The **student show page coloured its stat numerals** (`text-blue-900`, `text-green-900`,
  `text-purple-900`). design.md's KPI entry is explicit that a numeral is always `slate-900` and
  never carries state — I had applied that on the new dashboard and missed it one page over.

**Left deliberately:** blue that is categorical rather than interactive — the `:info` badge tone
and the hue-coded KPI icon tiles, both of which design.md sanctions.

### Portfolio transactions gained an index, and the dashboard became a dashboard

**Why transactions were visible but not actionable.** `config/routes.rb` had
`resources :portfolio_transactions, except: [:index]`. Every other CRUD action existed, so a
transaction was reachable **only if you already had its id**. There was no list, the sidebar had
no entry, and the admin dashboard rendered "Portfolio transactions" as grey text with nothing to
link to — the money ledger of the whole app had no front door.

`index` is routed now, with a controller action, a sidebar entry, and a page listing date,
student, type, reason and amount, each row linking to the record with View, Edit and Delete.

**Written by hand rather than through `admin_table`.** That helper renders every cell through
`format_attribute`, which stringifies — `amount_cents` would print as raw cents. Money goes
through `number_to_currency`, right-aligned with `tabular-nums`. **A money column is a reason
not to use the generic table helper.**

**The dashboard was a second sidebar.** Four cards of links to Classrooms, Schools, Students and
so on, plus a yellow banner explaining that links marked `#` were unimplemented — by which point
no such links remained. It is now `AdminDashboard` plus KPI stat cards and two worklists, which
is design.md's dashboard pattern and what Stripe, Shopify, Salesforce and Django's admin do:
figures first, then the work waiting on you.

- **Work before scale.** The first two figures are orders awaiting execution and grade books
  verified but not yet paid out — the two things an admin can act on. Student, classroom and
  stock counts follow as context.
- **Deposits only** in the distributed figure. Summing every transaction would add withdrawals
  and fees to money paid out and report something meaningless.
- **Numerals are always `slate-900`.** design.md is explicit that a numeral never carries state,
  and records two occasions where a coloured one read as an error rather than a count. The icon
  tile carries the tone.
- **Every row links to its record**, and the transactions card ends in an "All transactions"
  link. A row you can see and cannot act on was the substance of the complaint.
- **No per-row queries**: `AdminDashboard` eager-loads `portfolio: :user` and `[:stock, :user]`,
  and every figure is one count or sum.

**Tested.** Four new dashboard tests: the two actionable figures, that the distributed sum
excludes fees, that each listed transaction links to its own page, and that the dashboard no
longer duplicates the sidebar. That last one had to be scoped to `main` — the sidebar links to
Schools legitimately, and my first version failed by catching it.

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

### Map B — One mobile drawer mechanism — **done**

**Outcome.** `drawer_controller.js` serves both layouts. One nav element per layout translates
into view; `admin_sidebar_controller.js`, the hidden checkbox, both `<label>` triggers, the four
`<label>` row wrappers and admin's duplicated mobile nav copy are all gone.

**What it gained.** `aria-expanded` on a real `<button>` trigger, Escape to close, focus moved
into the panel and returned to the trigger, a focus trap while open, and close-on-navigate
handled once in the controller rather than by a wrapper on every row. It also no-ops above `lg`,
because the sidebar is permanent there and trapping focus in ordinary page furniture would be a
bug.

**Step 0 was the valuable part.** `ApplicationSystemTestCase` gained `in_phone_viewport`, and
`mobile_navigation_test.rb` is the first test in the project's history to exercise the drawer at
375px. Three things only that step could have found:

- **Capybara's `visible?` cannot see an off-canvas panel.** It reads display, visibility and
  opacity, not transforms, so a closed drawer looks visible. The assertions read
  `getBoundingClientRect` instead.
- **A bare assertion races the 300ms slide.** Reading the position immediately after a click
  catches the panel mid-transition. `assert_offscreen` / `assert_onscreen` wait, then assert.
- **`resize_to` returns before the browser applies it.** A test could start at phone width with
  a desktop layout still in effect. That produced exactly one failure in one full-suite run and
  passed on five reruns; `in_phone_viewport` now waits on the same `(min-width: 64rem)` media
  query the CSS keys on, which makes it deterministic rather than usually fine.

**A deviation from the map, stated plainly.** The map called for characterisation tests of
current behaviour before the rewrite. I wrote target-state tests instead — red first, green
after — because the mechanism being characterised was the one being deleted, and the target
differs deliberately (nothing to characterise carries `aria-expanded` or Escape). The one
characterisation that mattered is there: the desktop assertion that the sidebar is *not*
off-canvas at 1400px, which passed before the change and still does.

**Also caught by the suite, not by me:** an early `assert_eventually` returned on success without
recording an assertion, and minitest reported "missing assertions" on three tests. A test that
asserts nothing can pass while verifying nothing. The wait and the assertion are separate now.

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

- ~~**Merge the CVE fix into `main`.**~~ **Closed — a maintainer merged it.** `main` is on
  `activestorage 8.1.3.1` as of PR #1190 (`6f48931`), so CVE-2026-66066 is fixed on the default
  branch and anything deployed from it. `stocksdesign` has since merged `main`, and
  `bundler-audit` reports no vulnerabilities against the merged lockfile. This sat open in these
  documents for the whole branch as "the most urgent item"; it is worth checking the claim before
  repeating it, because it was fixed upstream while the branch carried on saying otherwise.
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
