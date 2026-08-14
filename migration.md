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

### The signed-in `<main>` gets a top gutter, and `_stocks_table` gets a root

**What.** `application.html.erb`'s signed-in `<main>` goes from `px-4 lg:px-6 … mt-16 pb-6` to
`p-4 lg:p-6 … mt-16`. `classrooms/index` and `orders/index` lose their own `pt-6`.
`_stocks_table` is wrapped in a single `<section>`.

**Why it has blast radius.**

1. **Every signed-in page gains 16/24px above its title, and 16px instead of 24px below at base.**
   The top gutter was **0px** on most of them - `mt-16` clears the fixed nav but is not padding, and
   the sweep that removed the per-page `py-6` / `pt-4` cited a `p-4 lg:p-6` that only the signed-out
   branch had. Any test measuring absolute positions on a signed-in page shifts by 16-24px.
2. **Two pages lost `pt-6`**, which would otherwise have doubled to 40/48px.
3. **`_stocks_table` now emits one element instead of three.** A caller relying on its heading being a
   direct child of their own container - to space it, or to select it - is affected. This is what fixed
   the 24px gaps: the partial was being spaced *internally* by the page's `space-y-6`, because
   `space-y-6 > :not([hidden]) ~ :not([hidden])` outspecifies `mt-1` and `mt-3`.
4. `spacing_test.rb` gains three assertions - the title gutter at both widths, and the
   heading/helper/table gaps - and I checked each fails against the markup it was written for.

### Map: deriving perfect attendance (not started)

**Asked for:** drop the per-student "Perfect attendance" checkbox and let the data decide, surfacing the
result as a badge. It is the right instinct - the checkbox is a decision a teacher makes 25 times a
quarter, and it is *already* wrong in the seeds: one entry has `is_perfect_attendance: true` with
`attendance_days` **nil** and is paid the bonus, another counts 3 days as perfect. A flag that can
contradict the number beside it is worse than an extra step.

**Why it cannot be done yet.** There is no denominator. Nothing in the schema records how many school
days a quarter has - `quarters` is `name`, `number`, `school_year_id`; `school_years` is two foreign
keys; `years` is a name string. `grep` for `start_date|end_date|school_days|total_days` across the whole
schema returns nothing. Perfect attendance means "attended every day there was", and the app does not
know how many days there were.

**The one derivation available from today's data is wrong.** Taking the denominator as the highest
`attendance_days` in the grade book means that in a quarter where nobody attended every day, the best
attender is paid a bonus they did not earn - and it changes when a teacher edits somebody else's row.
Do not do this.

**Current structure.** `grade_entries.is_perfect_attendance` (boolean, `default: false, null: false`),
set by a checkbox per row, read only by `GradeEntry#attendance_perfect_earnings`, which pays
`EARNINGS_FOR_PERFECT_ATTENDANCE` (100 cents). Also read by `AttendanceEntryPresenter#perfect_attendance?`
for a Yes/No badge on `admin/students#show`.

**Target structure.** `quarters.school_days` (integer, nullable). `GradeEntry#perfect_attendance?`
returns `attendance_days.present? && school_days.present? && attendance_days >= school_days`. The column
`is_perfect_attendance` goes. The table column becomes a **badge**, not an input.

**Order of moves, and what each breaks.**

1. **Add `quarters.school_days`, nullable, not backfilled.** Nothing reads it yet. Breaks nothing. It
   must be nullable because no existing quarter has a value and inventing one would change what students
   are paid.
2. **Build somewhere to set it.** There is *no quarters UI at all* - `bin/rails routes | grep quarter` is
   empty, quarters come from seeds and `Classroom#create_gradebooks_for_quarters`. This is the real cost
   of the change, and it is a product question: an admin per school year, or the teacher at the start of a
   quarter? A teacher-entered figure is closer to the truth and closer to the person who knows it.
3. **Derive the predicate, keeping the column as the fallback** while `school_days` is nil. Two sources of
   truth for one fact, deliberately and temporarily.
4. **Replace the input with a badge** once a quarter has `school_days`. The column stops being a decision
   and becomes a readout: "Perfect" / nothing, or "17 of 18 days".
5. **Drop `is_perfect_attendance`.** Only after every quarter that matters has a `school_days`, because
   this is the step that changes money.

**The decision that blocks all of it.** Step 5 changes what a student is paid, and **finalized grade books
have already paid out** - `DistributeFunds` has run and the transactions exist. So either the derivation
applies only to grade books finalized after the change, or historical entries keep their stored boolean
forever. That is not a design call; it needs whoever is accountable for the money. Until it is answered,
the checkbox stays and the column at least explains what it pays.

### A name is required on the student form, and the populate button hides when it cannot act

**What.** `Student` validates `:name` presence on a `:student_form` context, which
`students#create/#update` and `admin/students` opt into. `ImportStudentService` accepts an optional
`name:` and the CSV template offers the column. `GradeBook#students_missing_entries` is extracted from
`PopulateGradeBook` and gates the "Add new students" button. The `:student` factory sets a name and gains
a `:nameless` trait.

**Why it has blast radius.**

1. **Every student created through a form now needs a name**, and `update` became assign-then-save
   because `update` writes before a context validation and would have persisted the blank it was about to
   reject. Anything creating a student through those controllers without a name gets 422.
2. **The CSV requires a `name` column, and this is a breaking change to an input format.** A spreadsheet
   generated against the old two-column template now fails every row, reported per row as
   "Row N: Name is required". That was a deliberate call: a bulk-imported class is where a roster of
   lowercased usernames is least navigable, and it is the path that creates twenty-five at once. The
   template ships the column on every example row.
3. **A nameless row is a *failure*, not a skip.** The skip bucket is described as "Skipped N existing
   usernames", so putting it there would call it a duplicate; failures are listed per row with their
   message. `ImportStudentService` gained a `failure_result(message)` for a row that is wrong before a
   record exists to read errors from.
4. **The seeds name their students** (`Sam Student`, `Mike Rivera`), so seeded data demonstrates the
   roster rather than showing two lowercased identifiers.
5. **The `:student` factory now sets a name**, so `display_name` returns it rather than the username
   across the whole suite. Seven tests asserted the username on screen or in initials; they use the new
   `:nameless` trait, which is also a real case - a student imported without a name, or created before
   this rule.
6. **"Add new students" is absent when nobody is missing an entry**, which is the normal state of a
   populated grade book. A test asserting that button unconditionally fails - and one of mine started
   *skipping* silently because it measured against it, which is worse.
7. `PopulateGradeBook`'s `missing_students` moved to `GradeBook#students_missing_entries`; the service
   reads it rather than owning it, so the view can ask the same question.

### Students get a name

**What.** `students#new` / `#edit` and `admin/students/_form` gain an optional full name; `:name` is
permitted on both controllers. `User` normalizes it. The roster shows name over username; the grade book,
its sort and the portfolio title use `display_name`.

**Why it has blast radius.**

1. **No migration - `users.name` already existed.** Nothing collected it, which is why every student's
   name was nil. So this is additive with no schema change and nothing to backfill.
2. **`normalizes :name` applies to every user, not just students.** A blank name becomes nil and a padded
   one is trimmed, on teachers and admins too. Anything comparing `name == " Foo "` changes; nothing does.
3. **The roster cell now has two lines** when a student has a name. A test asserting its exact text, or
   measuring the row height on a named student, moves - and the row grows by the second line.
4. **Sort order follows what is displayed.** The grade book sorted by username and now sorts by
   `display_name`, so a named student moves in the list relative to an unnamed one.
5. **Deliberately not changed**: `admin/users`, `admin/teachers`, `orders#index` and the transaction
   screens still show the username, because there the account is the subject rather than the person. If
   that is wrong it should be changed as one decision, not drifted into.

### The grade book shows what finalizing will pay

**What.** New `GradeBookEarnings` presenter and `GradeBook#previous_entries_by_user_id`, which
`DistributeEarnings` now uses instead of its private copy. New `.tw-segmented` in `forms.css`. The grade
row gains an Earns cell and sized inputs, and its checkbox becomes two radios. New `<tfoot>`. The
autosave response refreshes the figures. `finalize_button` names the amount.

**Why it has blast radius.**

1. **`DistributeEarnings` was refactored.** `find_previous_entries` moved to `GradeBook` and returns
   `index_by` rather than `group_by`, so the service no longer does `&.first`. Behaviour is identical -
   `grade_entries` is unique on `[grade_book_id, user_id]` - but it is a change to the code path that
   moves money, and `grade_books_controller_test` is what covers it.
2. **Perfect attendance is two radios, not a checkbox.** Anything finding
   `[data-testid='perfect-attendance-checkbox']`, or `input[type=checkbox]` in this table, breaks. The
   testid is `perfect-attendance-control` and the radios are `sr-only` with `<label>`s as the control -
   so a test must click the label, not the input. Two existing tests needed this.
3. **`form_field_test` had to exclude radios**, alongside the checkboxes it already excluded: an
   `sr-only` radio is not a rendered field and has no border to assert.
4. **The autosave turbo_stream replaces more elements.** Every `dom_id(entry, :earnings)` cell, every
   `dom_id(entry, :bonus_warning)` span, `#earnings-total`, `#earnings-summary` and
   `#unattended-bonus-callout`. **Anything derived from the entries has to be added there or it goes
   stale**, and it needs an always-rendered container with a stable id even when it has nothing to show -
   the warning had neither on the first pass, so it outlived the problem it described.
5. **The earnings summary is no longer admin-only.** It was inside the finalize block; it is its own
   `_earnings_summary` section rendered for anyone who can open the page. A test asserting a teacher sees
   no totals would now fail, and correctly.
6. **The confirmation text changed** and now interpolates a figure, so a test matching the old string
   fails. It is still a native browser dialog - see design-todo.
7. **The table has a `<tfoot>`**, the first in the app. Anything counting `tr` or `td` in this table, or
   assuming `tbody` is the last child, moves.

### The switch becomes a component, and the grade book page is brought onto the system

**What.** New `.tw-switch` / `.tw-switch-thumb` in `forms.css`, with the thumb as a real element.
`shared/_table_container` takes an optional `region_label`. `grade_books/show`, `_table`, `_grade_entry`
and `_finalize_button` are reworked. New `grade_book_page_test.rb`.

**Why it has blast radius.**

1. **The switch thumb is a real element, not `::after`.** Anything selecting `label div.peer` or reading
   the thumb through `getComputedStyle(el, "::after")` moves. The geometry changed too: 14px thumb,
   `translate-x-4`, 2px inset on all four sides in both states - it was flush against the bottom always
   and the right when checked. The track also gains a focus ring, which it had none of.
2. **`shared/_table_container` has a new optional local.** Existing callers are unchanged; passing
   `region_label` adds `tabindex="0"`, `role="region"` and a name to the scroll wrapper.
3. **`grade_books#show`'s `h1` is the quarter, not "Grade book".** Any test asserting that `h1`, or the
   page title, changes. The status pill is new on the page.
4. **"Finalize grades" is `:danger_outline`, not `tw-btn-primary`**, and is **not rendered at all** for a
   completed grade book rather than rendered disabled. A test asserting a disabled Finalize would fail;
   `assert_no_button` passes either way, which is why the existing suite did not notice.
5. **The perfect-attendance checkbox is 16px, not 187x44.** Anything clicking it by position moves.
6. **Every `<select>` in the app changes.** `select.tw-input-primary` is `appearance-none` with a
   background chevron and `pr-9`, styled by element, so all ten selects are affected rather than the two
   on this page. A test asserting the native arrow, or measuring a select's padding-right as 12px, moves.
7. **The grades table's trailing column right-aligns**, header and cells, and every control in it gained
   an `aria-label`. A test selecting a control by position, or asserting `text-left` on that column, moves.
8. **Row height stays 69px.** That is 44px of input plus 24px of padding plus the hairline, the same
   arithmetic as the 57px row with a 32px control. Shrinking the inputs to hit 48px would trade a real
   problem for a worse one - design.md's line about not shrinking content to dedupe sizes.

### The classroom page stops being two columns

**What.** `classrooms#show` stacks the roster and the grade books as full-width sections instead of a
`lg:flex-row`. The trading switch leaves the page header for a new `classrooms/_trading_setting`.
`_grade_books_list` goes from a 256px rail to four cards with status. New `classroom_page_test.rb`.

**Why it has blast radius.**

1. **The trading switch is no longer in the page header.** Anything locating it by walking down from
   the `<h1>`, or by "the checkbox in the header", moves. `trading_toggle_test.rb` finds it by role and
   was unaffected.
2. **The roster's first row moves down**, 146px to 206px at 1366x768. That is the cost of a section
   heading and a setting block that explains itself, and it is the number to argue with if the trade is
   wrong. The table gains 280px of width in exchange (765 -> 1045). A test pins the first row under
   240px so the next addition to the top of this page has to justify itself.
3. **The grade books partial emits one `<section>` with an `<h2>`**, not a `w-64` div. A caller placing
   it in a flex row would now get a full-width block; the only caller is this page.
4. **The setting has no card and no status pill.** It is a sentence and a switch on the line under the
   Students heading. Anything selecting it by `.tw-card`, by a badge, or by a "Turn on" / "Turn off"
   label finds nothing - the switch is labelled "Trading" and the state is in the sentence. Two earlier
   shapes were wrong here: a card with a pill inline before the sentence, and before that a bare switch
   in the page header.
5. **The page holds two card surfaces, and a test caps it there.** It was six - one per grade book, plus
   the table card and the setting card. Grade books are `divide-y` rows in one card now, so a caller
   adding a card to this page will fail `classroom_page_test`.
6. **Grade book `status` is on screen for the first time** (draft / verified / completed). The enum
   existed and the rail had no room for it. A copy change to those values now shows up in the UI.
7. **`@classroom_stats` is still dead.** I nearly rendered it and it cost too much vertical space to
   keep - see `design-todo`. Deleting the computation is a separate decision from where the figures go.

### Teachers can edit the classroom they teach

**What.** `ClassroomPolicy#update?` (and `edit?`, now delegating to it) allows a teacher who teaches
the record. New `ClassroomPolicy#permitted_attributes`, and `ClassroomsController#classroom_params`
takes its list from the policy. `classrooms/_form` hides the admin-only fields.

**Why it has blast radius.**

1. **A teacher can now change a classroom's name, grades and trading flag.** They could already open
   and close trading, which was the inconsistency, but the name and grades are new.
2. **The permitted list is per role, and that is the security boundary.** `school_id` / `year_id` move
   a classroom between school years, and `teacher_ids` is *who may see and edit it* - a teacher who
   could set it could grant another teacher access, or remove themselves and lose the classroom. Those
   three stay admin-only, filtered in `classroom_params`, so a crafted request drops them rather than
   relying on the form. `classrooms_update_permission_test.rb` sends exactly those requests; I widened
   the teacher list to the admin one and watched them fail.
3. **Pundit's `permitted_attributes` returns filtered params, not a list.** Handing its return value
   to `params.expect` raises `ParameterMissing` and every update 400s - which is how this was first
   written, and the "cannot change X" tests all passed while it did, because a 400 changes nothing
   either. **A negative test that passes on a broken request proves nothing**; check the positive path
   in the same file.
4. **The classrooms table's actions column reappears for teachers**, so the guard added a commit
   earlier now only fires for a teacher with no classrooms at all. That case is still asserted -
   header and `colspan` both - because it is the one that remains reachable.
5. **A classrooms row is 57px for a teacher now, not 49px**, because the row carries a 32px ghost
   action. That is what admin/classrooms and admin/users have always measured; `design.md`'s 48px is
   the padding-only row.
6. **An existing test asserted the old rule.** `"teachers cannot edit classrooms"` checked a redirect
   from the teacher's *own* classroom - the same one the test above it toggles trading on - and is now
   two tests, own and someone else's.

### Dismissals become one table

**What.** New `dismissals` (`user_id`, `key`, `dismissed_at`, unique on user+key), backfilled from the
two per-banner columns, which are then dropped. New `Dismissal`, `Dismissible` (into `User`) and
`DismissalsController`. `POST /dismissals` replaces two member actions on portfolios.

**Why it has blast radius.**

1. **Two columns are gone**: `portfolios.first_share_acknowledged_at` and
   `portfolios.trading_off_dismissed_at`. Anything reading them breaks loudly. `CreateDismissals`
   copies every non-NULL value across first, and its `down` copies them back before dropping the
   table, so the pair rolls both ways without losing a date - I ran the round trip and confirmed a
   dismissal survives forward, back and forward again.
2. **`remove_column` is `safety_assured`, with a caveat.** strong_migrations blocks it because
   ActiveRecord caches columns at boot: on a **rolling** deploy an old process would `SELECT` a column
   that no longer exists. This app deploys as a single unit and both readers are removed in the same
   commit, so there is no such window. **If this ever becomes a rolling deploy, that migration is the
   wrong shape** and the `ignored_columns`-then-drop sequence is the correct one.
3. **Two routes are gone**: `acknowledge_first_share` and `dismiss_trading_off`. Anything linking to
   them 404s.
4. **The key allowlist is now a security boundary.** `DismissalsController` writes whatever key it is
   given, for `current_user`, so `Dismissal::KEYS` is what stops it being an arbitrary-string write.
   A new banner **must** add its key there; `dismissals_controller_test.rb` covers the refusal path.
5. **`dismissed?` takes `since:` and defaults to nil**, which means a caller who forgets it gets a
   permanent dismissal. That is correct for a one-off and wrong for a recurring condition, and the
   failure is silent - the banner simply never returns. `dismissible_test.rb` pins both directions.

### The trading-off callout becomes dismissible, and records why it may come back

**What.** Two nullable columns: `classrooms.trading_disabled_at` and
`portfolios.trading_off_dismissed_at`. A `before_save` on `Classroom` keeps the first true to
`trading_enabled`. `Portfolio#trading_off_notice?` replaces a bare `!trading_enabled?` at both call
sites. New `patch :dismiss_trading_off` on portfolios, and `portfolios/_trading_off_dismiss`.

**Why it has blast radius.**

1. **A page can now be missing a callout that used to always render.** `stocks#index` and
   `portfolios#show` no longer show "trading is turned off" purely because trading is off - a student
   may have dismissed it. Any test asserting that text on a trading-disabled classroom needs an
   undismissed portfolio, which is the default, but the coupling is new.
2. **The onset column is what stops the dismissal being a mute button**, and it is load-bearing rather
   than decorative. `Classroom` **clears** `trading_disabled_at` when trading is switched on, so the
   next switch-off stamps its own date and is newer than any earlier dismissal. Remove the clear and a
   dismissal made once suppresses the notice for good - which is the behaviour the no-dismiss rule
   existed to prevent. `portfolio_trading_off_notice_test.rb` pins both directions, and a
   boolean-style implementation fails it.
3. **Deliberately not backfilled**, like `stocks.archived_at`: `updated_at` is not the date trading
   changed. NULL onset plus a dismissal hides the callout, and the first real toggle makes the
   comparison exact - so it heals instead of needing a data migration.
4. **`trading_enabled` is still the flag.** The timestamp is derived, exactly as `archived_at` is
   derived from `archived`, so nothing that reads or writes `trading_enabled` changes.
5. **The dismiss block is per call site, not in the component.** `button_to` renders a `<form>`, and
   the callout in `admin/teachers/_form` is inside the teacher form - a nested form is dropped by the
   parser and the button would submit the outer one. Putting the dismiss into `_callout` itself would
   break that page silently; a test asserts that callout has no dismiss.

### The success flash auto-dismisses after 6s

**What.** New `auto_dismiss_controller.js`. `layouts/_flash`'s `#notice` gains
`data-controller="auto-dismiss"` and hold/restart actions; `#alert` does not. New
`test/system/flash_dismiss_test.rb`.

**Why it has blast radius.**

1. **A message on screen now disappears on its own**, which any test that signs in and then asserts
   on the notice can lose. Nothing in the suite hit this - the assertions all run well inside 6s -
   but a test that signs in, does slow setup and *then* looks for the notice will fail, and it will
   look intermittent rather than causal. `#alert` is unaffected by design.
2. **It establishes a convention**: transient outcomes dismiss, page state and errors do not.
   `components/ui/_callout` and the `students#new` / `students#edit` / `profiles` error summaries are
   explicitly excluded, and `flash_dismiss_test.rb` asserts on the attribute so a new banner that
   copies the wrong half fails with the banner named. A future dismissible callout should get a
   *button*, not this controller - a control the reader operates is a different thing from a timer.
3. **The timing is real in the tests**, so `flash_dismiss_test.rb` costs about 30s of wall time on
   its own. That is deliberate: the number is the decision, and a shortened delay would assert only
   that some timer exists. If the suite ever needs to be fast, shorten the delay via
   `data-auto-dismiss-after-value` rather than deleting the coverage.
4. **`prefers-reduced-motion` is honoured here and nowhere else.** The controller removes the element
   without fading under that query; `drawer_controller`'s 300ms slide still animates regardless. That
   inconsistency is pre-existing and was not touched.
5. **Both flash banners gained a close button**, so `layouts/_flash` now renders an interactive
   control. A test that counts buttons on a page, or clicks "the only button", can be affected on any
   page reached by a redirect that sets a flash. `dismiss_controller` is deliberately separate from
   `auto-dismiss`: the alert takes the button without the timer.
6. **The dismissal model is now a documented four-row rule, not a habit.** design.md carries the table
   (sticks / auto / close, per banner type) and `flash_dismiss_test.rb` asserts every row. The one
   that will surprise someone: **a callout may only have a close if the dismissal is persisted**, as
   `portfolios/_first_share` does via `acknowledge_first_share`. Adding `data-controller="dismiss"` to
   a callout instead fails the suite, by design - a client-side close on page state comes back on the
   next load.

### The content column moves into both layouts

**What.** `application.html.erb` (signed-in) and `admin.html.erb` each gain one
`<div class="mx-auto max-w-7xl">` wrapping the flash **and** the yield. `spacing_test`'s
`section_gaps` helper is retargeted. New `test/system/flash_width_test.rb`.

**Why it has blast radius.**

1. **Four pages get narrower above ~1584px.** The trading floor, orders, classrooms and
   classroom#show declared no content column and spanned main's full box; they are now capped at
   1280px like every other page. This is `design.md`'s existing rule ("Content width is
   `max-w-7xl`") applied to the pages that had drifted from it, not a new decision - but it is a
   visible change on a wide monitor, and it is the half of this change a reviewer should look at.
   Below 1584px nothing moves anywhere, which is why no existing test width saw any of this.
2. **`main > div` now means the content column, not the page.** Any selector or script reaching
   into the page through `main`'s first child is off by one level. This already bit
   `spacing_test`'s `section_gaps`, which read `main > div > *`: it returned a single element, the
   comparison loop never ran, and `test_sections_on_a_page_are_24px_apart` **passed while asserting
   nothing** - 21 assertions to 19, with minitest's "missing assertions" warning as the only
   signal. The helper now descends to the column's last child. Anything else measuring positions
   through `main > div` needs the same treatment.
3. **The per-page `mx-auto max-w-7xl` wrappers are now redundant** on the ~39 call sites that have
   them. They are harmless - a `max-w-7xl` inside an equal-width parent is a no-op - and were left
   alone deliberately rather than swept. A later sweep removing them is safe; removing the
   *layout's* column is not, because the flash would leave the column with it.
4. **A flash is now inside the column**, so anything selecting it as a child of `<main>` moves.

### `stocks.archived_at`, and a retention rule for the archived list

**What.** New nullable `stocks.archived_at`, a `before_save` keeping it true to the `archived` flag,
`Stock::LIST_RETENTION` (12 months) with a `Stock.archived_recently` scope, and a `description:` on
`_stocks_table` used by all three tables.

**Migration map, and why the smaller shape was chosen.** The tidier model is Discard's: drop the
boolean and let `archived_at`'s presence be the fact. That would touch, in order:

1. `Stock.active` / `Stock.archived` scopes -> `where(archived_at: nil)` / `where.not(...)`
2. `Stock#archived?` -> `archived_at.present?` (currently ActiveRecord's boolean reader)
3. `StockPolicy#show_trading_link?`, which calls `record.archived?`
4. `admin/stocks/_form`'s `boolean_field :archived` -> a control that writes a timestamp
5. `admin/stocks` index and show, which display the flag
6. seeds and roughly 30 test references that set `archived: true`
7. finally, `remove_column :stocks, :archived`

Each step is safe alone, but 4 and 6 are where it breaks: an admin checkbox has to translate to a
timestamp, and every `create(:stock, archived: true)` has to change. **Not done**, because the
user-visible need was a date and a retention rule, and both work with the flag intact. The invariant
is enforced in one `before_save` so the two columns cannot disagree.

**Why it has blast radius.**

1. **Every save of an archived stock now writes `archived_at`.** The price job saves these rows on a
   weekday schedule; `||=` means it will not drag the date forward, and a test pins that.
2. **Un-archiving clears the date.** A stock archived, restored, then archived again reports the
   second date. That is deliberate - the alternative reports a date that was true of a different
   listing.
3. **Existing archived stocks have `archived_at = NULL` and were not backfilled.** They stay listed
   indefinitely, because `archived_recently` treats NULL as in-window. If a backfill is ever wanted
   it needs a real source for the date, not `updated_at`.
4. **The archived list is now filtered.** A stock archived more than 12 months ago disappears from
   the trading floor unless the viewer holds it. Nothing is deleted, and `admin/stocks` still shows
   everything, but a test asserting a specific archived stock appears on `stocks#index` will fail once
   that stock ages out.
5. **No index on `archived_at`.** `strong_migrations` wants `algorithm: :concurrently`, which is the
   right rule for a table big enough to lock; this one holds the companies a classroom can trade,
   where a sequential scan wins. Add one if the catalogue reaches the thousands.

### The trading floor header, and the archived list

**What.** `stocks/index` renders `components/ui/_page_header` with a compact cash figure;
`shared/_earnings_to_invest_card` is **deleted**. New `stocks/_archived_stocks` splits held from
unheld and puts the unheld behind a `<details>`. `_index_row` gains an "archived" line.
`_stocks_table`'s title is optional. New `share_count` helper.

**Why it has blast radius.**

1. **`shared/_earnings_to_invest_card.html.erb` is gone**, and it was the only place a non-student
   saw a `tw-btn-primary-disabled` "Invest now". That branch was already dead on this page -
   `show_holdings?` is false for a non-student, so the card never rendered for them - but the partial
   is no longer available to anything.
2. **The archived list is no longer a titled `<h2>` table.** It is a `<details>` whose `<summary>`
   reads "Archived stocks (N)", except for rows the viewer holds, which get their own titled table.
   `stocks_controller_test` asserted the old `<h2>`.
3. **`icon_tile_test` asserted the trading floor's balance card was flush.** There is no card there
   now, so the assertion is inverted: no card carries a balance, and the figure is in the header.
4. **Shares render through `share_count` in four places.** `portfolio_stocks.shares` is
   `decimal(15,2)`, so `sum(:shares)` returns a BigDecimal and every trading-floor row, the portfolio
   holdings table and the order modal read "3.0". Now "3", while a genuine fraction still shows as
   "1.5" - truncating would have been wrong, because the column really can hold one.
5. **`_stocks_table` accepts a nil title.** Its empty-state copy used `title.downcase`.

### `_stat` takes an icon, and the portfolio's two delight cards align

**What.** `components/ui/_stat` gains `icon:` / `icon_tone:`, rendered as a 32px tile on the label's
line. `portfolios/_best_month` now renders `_stat` instead of hand-writing the same card.
`portfolios/_money_at_work` moves to a 32px tile, `gap-2`, and the `_stat` label token.
`portfolios/show` loses a `py-6` that stacked on `main`'s padding.

**Why it has blast radius.**

1. **A test asserted the opposite size.** `portfolio_layout_test` pinned *36px* for every tile on
   that page ("32x32 means one was eyeballed"). The rule that holds across the app is about what the
   tile stands beside, not which page it is on — beside a 14px label it is 32px, on its own line
   above a figure it is 36px — so the test now asserts 32px. design.md's own table said
   "in a card header", which under-described it and is what allowed the divergence.
2. **`_best_month`'s markup changed shape.** It was a `div.tw-card` with three `<p>`s; it is now
   whatever `_stat` renders. Its `data-testid="best-month"` is preserved. Anything matching its
   internal structure rather than the testid breaks.
3. **`_money_at_work`'s label is quieter** — `font-medium text-slate-600` where it was
   `font-semibold text-slate-900`.
4. **Any `_stat` caller passing `icon:`** gets an 8px gap under the label instead of 4px; callers
   without an icon are unchanged.

### One account page: registrations#edit removed, and self-service deletion with it

**What.** `devise/registrations/edit.html.erb` is deleted. `devise_for :users, skip: %i[registrations]`
with `new`, `create` and a redirect re-added by hand, so `GET /users/edit` now 301s to
`/profile/edit`. `PATCH/PUT /users`, `DELETE /users` and `/users/cancel` are no longer routed.

**Why it has blast radius.**

1. **Self-service account deletion is gone, and it never worked.** The "Delete account" button posted
   `DELETE /users` to `registrations#destroy`, which calls `resource.destroy` - and `User` raises
   *"Hard delete attempted … Use #discard instead"*. So it returned a **500**, every time, with no
   test covering it. Had it worked it would have been worse: `portfolio` and `orders` are
   `dependent: :destroy`, so a student could have deleted their own money history. Account removal
   here is an adult's action and already exists as admin **Deactivate / Reactivate**, which discards.
   **If self-service closure is ever wanted it has to be built as a discard**, and someone has to
   decide whether a student may lock themselves out of their coursework.
2. **`PATCH /users` is unrouted**, so anything posting to Devise's account-update action now 404s.
   Nothing in the app did once its only form went; the route had to go with the view, because a
   validation failure there renders `registrations/edit`, which no longer exists.
3. **`GET /users/edit` is a 301**, not a page. Any bookmark or external link lands on `/profile/edit`.
4. **A dead route was removed.** `devise_scope :user { get "users/sign_up", to: redirect("/") }` was
   declared *after* `devise_for`, and the first matching route wins - so it never fired and sign-up
   rendered anyway. Behaviour is unchanged by deleting it; whether public sign-up should be open at
   all is a product question, now in `design-todo`.
5. `cancel_user_registration_path` and `destroy_user_registration_path` no longer exist as helpers.

### A real profile page, and thirteen image files deleted

**What.** New `ProfilesController` (`edit` / `update` / `password`), `resource :profile`,
`profiles/edit` with two forms, an "Edit profile" item in the account menu, `User#display_name`
preferring the `name` column, and thirteen unused files removed from `app/assets/images`.

**Why it has blast radius.**

1. **`User#display_name` now prefers `name` over `username`.** The column existed and nothing read
   it. Avatar initials *and* avatar tone derive from `display_name`, so the first user to set a name
   changes their initials and their colour everywhere. That is the intent, but any test pinning an
   avatar letter for a user with a `name` will break.
2. **Thirteen image files are gone**: nine illustrations (`piggy_bank`, `investment-funds`,
   `party_popper`, `boy_using_computer`, `girl_skateboarding_holding_laptop`, `1_Number`–`4_Number`)
   and four SVGs (`house`, `id-card`, `receipt`, `chart-no-axes-combined`). The SVGs are the
   dangerous ones to reason about: their names match Lucide icon names, so a grep for `house` finds
   `lucide_icon("house")` and reports the *file* as used. It is not — `lucide_icon` renders from the
   gem. **`SITF-Horz-logo.svg` is kept**: it is the only version with the tagline, and deleting the
   sole tagline logo is a brand call rather than a sweep. The backlog called this "eight unused
   images" and listed nine.
3. **The account menu has a second item**, so a test counting `a[href*='edit']` unscoped now finds
   one more link. `admin/students_controller_test` did exactly that.
4. **`profiles/edit` scopes both forms with `scope: :user`.** Without it, STI makes a Student post
   `student[name]` and the controller 400s. `scope:` is the keyword; `as:` is silently ignored by
   `form_with`.
5. Devise's `registrations#edit` is still routed and still reachable. This does not replace it, and
   the two now overlap - deciding whether to route `/users/edit` at the profile page is a follow-up.

### The backlog closed out: form builder, tokens, Devise, classrooms#show

**What.** `Admin::FormBuilder`'s remaining pre-token styling; the order modal's four 44px buttons;
four dead brand tokens; `devise/shared/_links` rebuilt; `classrooms/show` and
`devise/registrations/new` onto the primitives; the classroom roster onto `shared/_table_container`;
a new `submit_on_change` Stimulus controller and a new `.tw-link-tap` class.

**Why it has blast radius.**

1. **`--color-sitf-secondary`, `--color-sitf-hero-from`, `--color-sitf-hero-to` and
   `--color-sitf-ring` no longer exist**, so `bg-sitf-secondary` and friends now compile to nothing
   rather than to a colour. Nothing used them; anything added against them will silently render
   unstyled.
2. **The classroom h1 changed shape.** It joined name, grade and year with commas; the name is the
   title and the rest is the description. Two system tests asserted the year inside the h1.
3. **The trading switch submits through Stimulus, not an inline `onchange`.** It was the last inline
   handler in the app - and the thing a CSP without `unsafe-inline` blocks. Nothing covered it, so
   `trading_toggle_test.rb` is new. Its `disabled:` branch turns out to be unreachable
   (`check_classroom_eligibility` admits only admins and the classroom's own teachers, and both may
   toggle); it stays as an authorization guard.
4. **`devise/shared/_links` lost four of its six branches** - the two "Didn't receive … instructions?"
   links and the omniauth buttons. The model does not enable `:confirmable`, `:lockable` or
   `:omniauthable`, so none could render. If those modules are ever switched on, Devise's generator
   has to put the markup back.
5. **The sign-up page's description changed** from "Enter your email below…" to naming the username,
   and its h1 from "Sign up" to "Create your account".
6. **Every `dark:` variant is gone**, and with it a live 2.45:1 failure for dark-OS users. `.dark` in
   `shadcn.css` is still declared and still unused.

### stocks#show rebuilt on the shared header, and given a real trade action

**What.** The page now renders `components/ui/_page_header` (ticker as title, company name as
description, `_badge` for archived) and `stocks/_trade_actions` in place of a "Trade" link. Dropped:
a `📈📊` emoji, a hand-rolled `bg-red-100 … rounded-full` pill, `py-6` stacked on `main`'s padding,
an `h-8` spacer div, `flex-shrink-0`, HTML comments, and one unbalanced `</div>`.

**Why it has blast radius.**

1. **The stock page can now place an order.** It renders the same Buy/Sell partial as the trading
   floor rows, behind the same `StockPolicy#show_trading_link?` gate, targeting `modal_frame` in the
   application layout. Behaviour that did not exist before: a student can trade from a stock's own
   page. Buy is withheld on an archived stock and the whole pair is withheld unless the student
   holds it, which is the policy's existing rule, not a new one.
2. **`stocks_controller_test` asserted the old "Trade" link.** Replaced with assertions on the Buy
   and Sell hrefs plus a teacher case.
3. **The h1 changed shape.** It was one heading reading `AAPL | Apple Inc.` with the company name in
   a nested span; it is now `AAPL` with the company name in the header's description. Anything
   matching the h1's full text breaks. The page also declares `:own_heading` for the first time,
   via the shared header.
4. **`portfolios#show`'s header CTA is now conditional on having holdings**, and the empty state's
   CTA is the primary while the table is empty. A test asserting "Invest now" on a fresh portfolio
   will not find it.

### Button copy normalised, and a dead branch of stocks/_stock removed

**What.** Fourteen labels changed (see design.md's table). Four tests updated that pinned the old
strings. `stocks/_stock.html.erb` lost its unreachable second branch.

**Why it has blast radius.**

1. **`stocks/_stock.html.erb` had two branches behind `if action_name == "show"`, and the else was
   dead.** It held a compact "index card" with its own hand-rolled surface
   (`rounded-xl border … shadow-xs` rather than `.tw-card`) and a "View details" button pointing at
   `stocks#show`. Nothing rendered it — the partial is reached only from `stocks#show`, and the
   trading floor's tables use `stocks/_index_row`. Removed with the conditional. **If anything ever
   wants a compact stock card, it has to be written again** — deliberately, on the card primitive.
2. **The reset-password email's link text changed** from "Change my password" to "Reset password".
   `teachers_controller_test` asserted the old string against the mail body.
3. **"Cancel my account" is now "Delete account".** Same action, but the label no longer collides
   with the dismiss meaning "Cancel" carries on eleven form buttons and a modal.
4. **Four tests asserted removed copy** — "See the companies", "Trade stock", "All transactions",
   and the mail body above.
5. `button_copy_test.rb` asserts the three-word limit and that no button links to the page it is
   on, so both classes of drift fail there rather than in review.

### The icon tile is a component, and card headers can lead with one

**What.** New `components/ui/_icon_tile` (icon or numeral, five tones, two sizes). All six
longhand tiles converted. `_card` gains optional `icon:` / `icon_tone:`. Both earnings cards
restructured so the figure is flush rather than indented behind the tile. The home page's steps
are four columns with tile numerals, and its CTA is `.tw-btn-primary`.

**Why it has blast radius.**

1. **The admin dashboard's three `sky` tiles are now `:info` blue.** `bg-sky-50 text-sky-700` was
   not in the tone vocabulary — a second blue beside `:info`'s — so those three stat tiles change
   hue. Arguably they should be `:neutral`, since this document hue-codes *state* and a count of
   classrooms has none; that is a bigger aesthetic call than putting them on the vocabulary, so it
   is `:info` for now and noted in `design-todo.md`.
2. **`design.md`'s tile spec said `text-{semantic}-600` while every tile shipped `-700`.** The
   component uses the badge's tones, so tiles and badges for one state cannot diverge; the document
   now names `-700`. Anything written against the `-600` line will read as changed.
3. **The home page's primary CTA was 44px** — the third instance of the longhand
   `min-h-11 … px-4 py-2 … shadow-xs` primary, after `_empty_row` and the roster. It is 40px now.
   The remaining `min-h-11`s are legitimate bare tap targets, except **`orders/_form`'s four modal
   buttons**, which override the token's `h-10` and render 44px. Left alone here because the modal
   was not in scope; recorded in `design-todo.md`.
4. **`_card`'s header markup changed shape** — the title now sits inside a flex row. A test
   matching the header's direct children rather than the `h2` itself would break.
5. `icon_tile_test.rb` asserts the flush balance, the numeral geometry and 3:1 on every tile, so
   an icon gutter reintroduced anywhere on those two pages fails there.

### Spacing brought onto the 24px rhythm, and the in-table empty state fixed

**What.** Twenty-two off-rhythm values to 24px (`mb-8`/`my-8` across the component gallery, `gap-8`
×2, `space-y-8`, `p-8`, `mt-8` ×3), `pb-16` off two pages, `px-6 lg:px-8` off both auth pages, a
`gap-0.5` off a table stack, and the search field's icon geometry onto `.tw-input-primary`'s `px-3`.

**Why it has blast radius.**

1. **`admin/shared/_empty_row` was shipping an off-token button.** Its CTA was written longhand at
   `min-h-11 … px-4 py-2 … shadow-xs` — 44px tall against the 40px `h-10` token, with the wrong
   shadow — and that partial backs the empty state on five admin index pages. It is `.tw-btn-primary`
   now, so those five CTAs changed height. This is the same 44px mistake `CLAUDE.md` already records
   for the admin buttons; it survived in a partial nobody re-read.
2. **The classroom roster's empty state moved into the table body.** It was a hand-rolled
   `text-center py-8` block *below* the table, so an empty roster rendered bare column headers with a
   sentence stranded underneath, and its CTA was an eighth button shape (`rounded-md px-4 py-2`,
   `border-transparent`). It now renders through `_empty_row` with an icon, a title and a body, so
   the copy changed: "No students in this classroom yet." became "No students yet" plus a sentence.
   Anything asserting the old string breaks.
3. **Both auth pages lost 24px of horizontal padding at base and 32px at `lg`**, and two pages lost
   64px of bottom padding. They were adding it on top of `main`'s.
4. `spacing_test.rb` now asserts the 24px section rhythm and the 16px auth edge as **pixels**, so
   reintroducing a page's own padding fails there rather than in review.

### Arbitrary values converted, and the shadcn checkbox rebuilt

**What.** `style="height: 300px"` to `h-75`, `style="width: 400px"` to `w-100`,
`style="max-width: 510px; min-height: 36px"` to `max-w-128 min-h-9`, `max-h-[480px]` to `max-h-120`.
`components/ui/_checkbox` renders a native input on the app's tokens. `_input`, `_textarea` and their
helpers are deleted. A partial local named `style` is now `button_class`.

**Why it has blast radius.**

1. **The badge scroller is 512px, not 510px.** The scale has no 510; the 2px is not visible.
2. **The checkbox lost `role="checkbox"`, `aria-checked="false"` and `data-state`.** The role was
   redundant on a native checkbox and the static `aria-checked` actively lied once ticked, because
   nothing updated it. Anything asserting those attributes will fail, correctly. It is on
   `accent-sitf-primary` now rather than the shadcn navy `border-primary`, and the dead hidden tick
   SVG is gone.
3. **`render_input` and `render_textarea` no longer exist.** Nothing called them once
   `Shadcn::FormBuilder` stopped delegating. `render_label` and `render_form_for` remain - the
   checkbox and the two devise auth pages use them.
4. **A source-level test now guards this.** Adding a gradient, an inline `style`, or an arbitrary
   value outside the four-item allowlist fails
   `test/design_system/no_arbitrary_values_test.rb`. Extend the allowlist deliberately, with the
   reason, rather than to make it pass.

### The earnings surfaces lost their gradient and their illustrations

**What.** The home page's "Earnings to invest" hero and `shared/_earnings_to_invest_card` are both
`.tw-card` with a `size-9 rounded-xl bg-emerald-50` icon tile and a `piggy-bank` glyph.

**Why it has blast radius.**

1. **`--sitf-hero-from` and `--sitf-hero-to` are now unreferenced.** They were the app's only
   gradient and had exactly one caller.
2. **`piggy_bank.png` and `investment-funds.png` are unreferenced**, which leaves all eight images in
   `app/assets/images` unused. Listed in design-todo rather than deleted.
3. **The trading floor card lost its fixed `h-[150px]`**, so it now sizes to its content. It sits in
   the page header row on `stocks#index`, which is where to look if that row's alignment shifts.
4. The home hero's label went from `slate-800` (chosen for the gold) to `slate-600`, the muted token
   on white.

### Every form field is on one named class

**What.** `Admin::FormBuilder`'s five class constants now point at `tw-input-primary`,
`tw-input-error`, `tw-label-primary`, `tw-field-error` and `tw-field-hint`. `Shadcn::FormBuilder`'s
`label` / `text_field` / `password_field` / `email_field` render plain Rails fields on the same
classes rather than delegating to `render_input`. Ten hand-rolled field strings across the grade
book, the two student forms, the admin search filter and the devise pages are gone.
`devise/passwords/edit` and `devise/registrations/edit` were rebuilt from raw generator output.
`forms.css` gained `tw-input-error`, `tw-field-error` and `tw-field-hint`.

**Why it has blast radius.**

1. **Every field in the app changed size**, from 40px or an unset height to 44px, and from
   `rounded-md` to `rounded-lg`. Nine admin forms also lose a `placeholder:text-gray-400` that
   measured 2.54:1.
2. **`Shadcn::FormBuilder` no longer calls `render_input`.** That helper is now unused;
   `render_label` is still used by `components/ui/_checkbox`. Do not reintroduce the delegation - it
   silently overrode the class it was passed.
3. **The two devise auth views no longer pass `class:`** to their fields; the builder supplies it.
   Passing one again would append, not replace.
4. **`devise/registrations/edit` is a real page now** - two cards, a proper heading, and its
   "Cancel my account" on the bordered danger button rather than an unstyled `button_to`. It is still
   not a profile page; see design-todo.

### Both modals share one shell

**What.** `bg-black/50` scrim, `rounded-2xl shadow-2xl` panel, `h2` title at `text-base
font-semibold`, `rounded-lg` 44px close control with `lucide_icon("x")` - applied to `shared/_modal`
and the CSV import dialog. The order form's field uses `tw-input-primary` / `tw-label-primary`, its
error panel uses the red tokens, and `.tw-input-primary` itself moved from `rounded-md` to
`rounded-lg`.

**Why it has blast radius.**

1. **The buy modal's title shrank** from `text-2xl font-bold` centred to `text-base font-semibold`
   left-aligned. That is the biggest visible change and the one to look at first if it reads too
   quiet; it is one token in two files.
2. **The import dialog's title changed level**, `h3` to `h2`. Its `id="modal-title"` and the
   `aria-labelledby` pointing at it are unchanged.
3. **`.tw-input-primary` changed radius app-wide**, though only `classrooms/_form` used it before.
   Every form other than these two still hand-rolls its inputs - a sweep for later, noted in
   design-todo.
4. **The order form's number field lost `text-lg`**, so it renders at the same size as every other
   input rather than two steps up.

### Buy and Sell lost their arrows; Trade's went horizontal

**What.** `stocks/_trade_actions` renders "Buy" and "Sell" with no icon. The portfolio's Trade row
action is `arrow-right-left` rather than `arrow-up-down`.

**Why it has blast radius.** A vertical arrow already had two meanings in the product - value
direction in the Change and Total return columns, and sort in `sort_icon`'s `⇅` caret - so the
actions were the third claimant on one glyph. Anything that adds an arrow to an action reintroduces
the ambiguity. Nothing asserted these glyphs, but `one_primary_test` does assert the Trade action
carries exactly one icon, so it cannot simply be dropped without changing that rule too.

### The pinned separator is scroll-conditional, and row actions are 32px

**What.** `.table-actions-pinned` is `sticky right-0 z-10` only; its border and opaque background
come from `[data-table-scrolled="true"]`, set by a new `table-scroll` controller on `body`.
`ghost_class` is `min-h-8` at every width rather than `min-h-11 lg:min-h-8`. The portfolio holdings
table's figure columns are `whitespace-nowrap`.

**Why it has blast radius.**

1. **Every row action in the app is 4px shorter below `lg`** (44px to 32px). That is a deliberate
   reversal: 44px contradicted the rule that reserves it for bare tap targets, and it read as a slab
   beside 17px text. Three tests asserted the old height.
2. **The separator now depends on JavaScript.** Without it the cell still pins and simply has no
   separator - degradation in the right direction, but worth knowing it is not pure CSS.
3. **`data-table-scrolled` is written to any element with `overflow-x: auto|scroll`** that the user
   scrolls, anywhere in the document. Nothing else reads it today.
4. **The controller listens in the capture phase** because scroll does not bubble. Moving it off
   `body` to a per-table attribute would need eleven call sites.

### Coloured bands and hue-coded panels removed

**What.** The grade books list's `bg-amber-300` band is a card title. `admin/students#show`'s four
figure panels are neutral. `stocks#show` no longer renders the flash a second time.
`admin/teachers/_form`'s notice is `components/ui/_callout`. The `rounded-smrelative` class in both
student forms is fixed.

**Why it has blast radius.**

1. **`rounded-smrelative` was two fused tokens** - `rounded-sm` and `relative` - so the browser
   applied neither. Anything that looked correct because of "relative" on those error panels was
   never actually positioned.
2. **`stocks#show` showed a duplicate notice.** Removing it means one flash, from the layout. A test
   asserting two would now fail, correctly.
3. **The teachers-form notice changed shape**: its title is a `<p>` inside `[role=status]` rather
   than an `<h3>`, its copy changed, and the link is a trailing action labelled "Update classrooms"
   rather than "update classrooms" mid-sentence. One controller test asserted all three.
4. **`admin/students#show`'s figure labels are `slate-600`** rather than blue/green/purple-700. The
   `data-testid` hooks are unchanged.
5. **The grade books list is a card**, so its markup gained a wrapper and its empty case is the
   shared empty state rather than centred `slate-500` text.

### Off-brand mint swept out of the app

**What.** `sitf-primary` is `#00698c`, a blue-teal; Tailwind's `teal-*` is a mint. Five places
treated the mint as the brand and are corrected: the first-share banner, `announcements#show`'s
title band, the order modal's two hue-coded panels, the `_badge` `:brand` tone (deleted, unused),
and the delight preview page (deleted).

**Why it has blast radius.**

1. **`_badge` no longer has a `:brand` tone.** Passing `tone: :brand` now silently falls back to
   `:neutral` rather than raising. Nothing used it.
2. **`announcements#show` gained an `h1`** and lost its coloured band. The page had no heading at
   all before, so anything asserting the title's position or its old classes will need updating.
3. **`/admin/component_demo/delight` is gone** - route, action, view and its guard test.
4. **The order modal's panels are neutral**, which also removed the only use of `--sitf-ring` as a
   surface. That token (`#a5b4fc`) is now unreferenced outside its definition.
5. **`AvatarHelper` keeps its teal deliberately** - a categorical tone for a person, not a brand
   colour, and swapping it would change the colour of everyone who hashes to it.

### The delight cards moved onto the design system

**What.** `_first_share` is `components/ui/_callout` with `:info` rather than a bespoke `teal-50`
panel; `_callout` gained an optional trailing-action block and a `testid`. `_money_at_work`'s bare
icon is an icon tile, and `_best_month`'s tile went from `size-10` to the `size-9` token.
`_companies_owned` is **deleted**, and the holdings cell shows company name + ticker.

**Why it has blast radius.**

1. **`teal-*` is not the brand.** `sitf-primary` is `#00698c`, a blue-teal; Tailwind's `teal-50` is
   mint. Anything reaching for `teal-*` to mean "brand" is wrong, including the badge component's
   `:brand` tone - left alone because it is used categorically, but noted.
2. **`_callout` renders through `tag.div` now**, so an absent `testid` is omitted rather than
   emitted unquoted. It also takes a block; existing callers pass none and are unaffected.
3. **`_companies_owned` is gone.** Anything referencing "Companies you own" will fail - one test did.
4. **The holdings cell markup changed shape** from one span to a two-line stack, so a selector
   matching the ticker as the cell's only text will not match.

### Six delight features, one new column and one new route

**What.** `PortfolioInsights` (new, pure) holds the derived figures. `portfolios.first_share_acknowledged_at`
is a new nullable datetime. `PATCH /portfolios/:id/acknowledge_first_share` dismisses the
first-share message. `components/ui/_stat` takes optional `change` / `change_up`. Four new partials
under `portfolios/`.

**Why it has blast radius.**

1. **A migration, deliberately not backfilled.** `first_share_acknowledged_at` is null for every
   existing portfolio, so every student who already holds shares sees the first-share message once.
   That was a product call and it was made: **do not backfill.** The copy says "you hold", never
   "you just bought", so the message is accurate for any holder; not backfilling costs a transient,
   one-click-dismissible oddity, while backfilling would permanently deny the explanation to the
   students who already bought. The icon was softened from `party-popper` to `chart-pie` instead,
   because it was the celebratory framing rather than the message that implied recency.
2. **`_stat` gained two locals.** Existing calls are unaffected; the line only renders when `change`
   is present.
3. **Every figure is integer cents.** `PortfolioInsights` returns cents and `nil`, never a Float and
   never zero-as-absent. `change_percent` is the one Float, guarded against a zero baseline, and it
   is display-only.
4. **The comparison depends on snapshots existing.** No snapshot before the current month means no
   comparison line at all - which is why the seeded `Student` shows none while `mike` shows one.

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

## Tables at 375px: from sideways scroll to stacked rows (2026-08)

**Blast radius: every table in the app, both sides.** Reported as *"the table just scrolls sideways and
the actions go off screen, does not match design system and industry std"*, with the ask being *"the
table to stack or scroll cleanly at 375px"*.

### What was there, measured

Audited every table at 375px, per table, as the role that sees it. Overflow of the scroll container:

| Page | cols | overflow | actions pinned |
|---|---|---|---|
| admin/teachers | 7 | **685px** | yes |
| admin/users | 7 | 632px | yes |
| admin/stocks | 7 | 595px | yes |
| admin/classrooms | 7 | 579px | yes |
| orders | 8 | 489px | yes |
| admin/transactions | 6 | 404px | yes |
| grade book | 6 | **398px** | **no - it has no actions column** |
| classroom show (roster) | 4 | 364px | yes |
| admin/students | 5 | 332px | yes |
| admin/school_years | 5 | 299px | yes |
| classrooms (teacher) | 5 | 227px | yes |
| admin/schools | 4 | 196px | yes |
| admin/student show | 4 | 88px, 152px | no |
| portfolio holdings | 6 | 101px | no |
| stocks (trading floor) | 4 | **0px** | collapses instead |
| admin/dashboard | 3 | 0px | n/a |

Two things that table shows. **The trading floor already fits**, because it is the one table that
collapses its secondary columns into the primary cell below `lg` instead of scrolling. And the grade
book is the worst case in kind rather than in pixels: it is a table of **form controls** with no
actions column, so pinning never applied to it and four inputs per row sat off screen.

### What this overturns

`design.md`'s "Narrow-viewport tables: pin the actions, never let the page scroll" said pinning was the
answer for dense tables and that column-hiding could not work, because three labelled ghost actions are
~250px against a 343px viewport. **That reasoning holds only while the actions stay in their own
column.** Once the actions collapse into the primary cell - which the trading floor already does - there
is nothing left to need 250px of width beside the data, and the scroll goes away entirely.

So the rule changes from *pin the actions inside a horizontal scroll* to **below `lg` a table is one
column per row**: identifier, then its secondary fields as labelled lines, then its actions. That is
Polaris's `IndexTable` condensed mode and Primer's guidance for the same problem. Pinning stays in the
stylesheet for the `lg` case, where a wide table can still overflow.

### Order of moves

1. `admin/shared/_table.html.erb` - nine index tables come from this one partial, so the generic
   treatment lands there first: secondary columns `hidden lg:table-cell`, their values restated as a
   `<dl>` inside the primary cell under `lg:hidden`, actions moved into the primary cell below `lg`.
   Breaks nothing that selects on `[data-testid]`, because the testids stay on the real cells.
2. `grade_books/_table.html.erb` - the form case, and the only one where the trading floor's trick is
   **not** available: restating a control in a second cell would render **two inputs with the same
   name**, and the last one submitted wins. So this one reflows in CSS (`.table-stacked`), keeping one
   DOM and one input per field, and gains a real `<label>` per control below `lg`.
3. The hand-written tables: `orders/index`, `classrooms/index`, `classrooms/_classroom_students_table`,
   the portfolio holdings table, `admin/students/show`.
4. A test that asserts **no table scroller overflows at 375px** anywhere, which is the assertion the
   suite never had - `table_actions_reachable_test` only ever looked at `td.table-actions-pinned`, so a
   table with no actions column (the grade book) was invisible to it.

### What each step breaks

- Any test asserting a cell is visible at 375px: below `lg` the secondary cells are `display: none`, so
  `assert_text` inside them fails while the same text passes in the primary cell's `<dl>`. Assert on the
  row, not the cell.
- `.table-stacked` changes `display` on table elements below `lg`, which removes table semantics from
  the accessibility tree in Chrome and Firefox. The grade book gains real `<label>`s in exchange, which
  is a better trade for a form than a `<th>` that never named a control anyway.
- Column counts in `colspan` on empty rows are unchanged, because the empty row spans the full table at
  every width.

## `Admin::UsersController#destroy` now discards explicitly (2026-08)

**Data behaviour, and a control that never worked outside production.** It called `@user.destroy`.
`User#destroy` runs `soft_delete_guard` first, which **raises** in every environment except production
and only then falls through to `discard` - so this action returned a 500 for every admin who tried it in
development or test, and nothing covered it. In production it soft-deleted, while its confirmation said
"This cannot be undone".

It calls `discard` directly now, which is what the guard exists to force. **Production behaviour is
unchanged** - it discarded there already. What changes is that the control works in development and test,
and that the confirmation tells the truth: the action is labelled "Archive", and says the account loses
access immediately and that nothing is deleted.

**Still open, and a product decision rather than a design one:** a discarded plain user has no way back
through the admin screens. `admin/students` has `restore`, teachers have reactivation, and a user who is
neither has neither. Recorded in `design-todo.md`.

## The nav's scrolling stock ticker is removed (2026-08)

**Capability removed, plus a file and two colour tokens deleted.** Reported as "a continuously scrolling
green ticker... it does not look WCAG compliant nor is there any real data here", previewed at
`/admin/component_demo/stock_ticker`, and approved.

### What went

| Deleted | Was |
|---|---|
| `app/views/layouts/_stock_ticker.html.erb` | the 400px `hidden lg:block` window in the app-side header |
| `app/views/layouts/_stock_item.html.erb` | one symbol + percentage, rendered twice per stock for the loop |
| `ApplicationHelper#ticker_stocks` | `Stock.active.order(:ticker)` |
| `app/assets/tailwind/navbar.css` | the whole file - four rules and the `scroll` keyframes, nothing else |
| `.text-green-up` / `.text-destructive` | in `app/assets/stylesheets/application.css`, at 2.74:1 and 3.78:1 |

### Why

1. **WCAG 2.2.2 Pause, Stop, Hide - Level A.** `20s linear infinite`, automatic, endless, no pause control,
   no `prefers-reduced-motion`. On every signed-in page.
2. **WCAG 1.4.3.** 2.74:1 up and 3.78:1 down on white against AA's 4.5:1.
3. **It was not showing data.** Every `yesterday_price_cents` was nil, so all 18 stocks read `0.00%`, and
   the colour test was `percentage_change >= 0`, so every one was green with an upward arrow.
4. **A ticker is a broadcast component.** It belongs to television lower-thirds and public displays, where
   the viewer is captive and cannot scroll. No finance application animates its chrome. See design.md.

### What replaced it

**A Change column on the trading floor**, beside Last price, plus `ApplicationHelper#movement_class`.

It spent one commit as `home/_todays_movers`, a card below the balance listing three companies with price
and change. That was reported as making no sense there, correctly: it pushed the balance, the announcements
and the getting-started steps down in order to show three of the companies the trading floor lists anyway.
The card, its partial and the `Stock.movers` scope that fed it are all deleted - an unused scope is
indistinguishable from a supported one - and the caution it carried is the trading floor's page description
now, where it is read at the point of choosing.

### What this breaks

- **Anything selecting `.ticker-content`, `.ticker-item`, `.animate-scroll`, `.text-green-up` or
  `.text-destructive`** finds nothing. Nothing in the app did; `todays_movers_test` asserts the absence.
- **The header is one element narrower at `lg`.** Nothing measured against its 400px, and the account menu
  was already the flex row's other child, so it simply sits where it did with more room beside it.
- **`app/assets/stylesheets/application.css` now holds only a font import.** It is kept for that import and
  for the comment recording why the two tokens went. It is also **now in CLAUDE.md's audit scope**, which it
  never was - the reason a 2.74:1 colour survived the entire design migration.
- **The Change column shows an em dash until the daily price job has run twice**, and for every archived
  company. That is the honest state: a stock with no yesterday price has no change, and an archived one has
  a frozen price. Any environment where the job has never run sees em dashes down the column, which is what
  development saw before three rows were given yesterday prices by hand.

## The trading floor's Change column is removed (2026-08)

**Third and final move for one figure.** The scrolling ticker became a home-page card, the card became a
Change column, and the column is now gone in favour of stating how old each price is. Reasons in design.md;
the short version is that the daily change is wrong two days a week by its own schedule, empty without an API
key, partial under the free tier's rate limit, and hidden on phones - while the change a student cares about
(gain or loss on what they own) is on the portfolio and needs no API.

### What went

- The `Change` `<th>` in `stocks/_stocks_table`, its `<td>` in `stocks/_index_row`, and the below-`lg` line
  that restated it in the primary cell.
- The empty row's `colspan` goes back to `show_holdings? ? 4 : 2`.
- The trading floor's page description no longer cautions about a big move not making a company a better buy:
  the figure it cautioned about is not on the screen.
- `Stock.movers` and `home/_todays_movers` were already deleted with the card.

### What arrived

- `Last price` widens to `w-40` and carries a second line: `as of 4 Aug` when a row is behind the freshest
  price on the page, `Not priced yet` when `last_trading_day` is nil, nothing when it is current.
- The page description states the cadence and the date once, from
  `@stocks.filter_map(&:last_trading_day).max`.
- `ApplicationHelper#movement_class` **stays** - the portfolio's Change and Total return columns use it.

### What this breaks

- **Anything asserting a `Change` header or a percentage on the trading floor.** Two tests did; both are
  rewritten in `price_change_test`.
- **The staleness note depends on `last_trading_day` being maintained.** It is set only on a successful
  fetch, which is exactly what makes it usable as an age - but it means a stock whose price is edited by hand
  in the admin screens keeps whatever date it had. That is arguably right (the date describes the market
  price, not the edit) and is worth knowing before anyone reads it as "last modified".


## One card-body padding value, and every page on `_page_header`

Both halves of a sweep of the page's vertical rhythm. The measurement is
`test/system/page_rhythm_test.rb`, which walks 38 pages across the three roles and asserts the rendered
gap between the page header block and the first element that follows it. It found 24px everywhere it
could measure, and two pages it could not.

### What changed

- **`admin/portfolio_transactions#new` and `#edit` now render `components/ui/_page_header`.** They were
  the only two pages in the app that never adopted it: the title was a `text-2xl font-bold` `h2` inside
  a card wrapping a form that renders its own card. Each page loses an outer `.tw-card`, gains a real
  `h1`, and stops nesting two surfaces around one form.
- **`Edit Portfolio Transaction #<id>` became `Edit portfolio transaction`.** Sentence case, and the id
  is in the breadcrumb, where every other admin edit page puts the record's identifier.
- **Twenty-two card bodies moved to `p-5`**, from four different values: `px-6 py-6` on the ten admin
  form partials, `p-4` and `p-6` on the component demo, `p-4` on the shared search-filter bar, and
  `p-5 lg:p-6` on three app-side form cards. design.md's Card / panel section states `p-5`.
- **`flex flex-col h-full w-full` is gone from `orders#index` and `classrooms#index`**, along with the
  bare `<div>` it wrapped the page header in and the `flex-1 pb-6` on the content.
- **`classrooms#show` lost `mt-6`** from its section wrapper and `classrooms/_form` lost `mt-4` from its
  card; both collapsed against the header's own `mb-6` and measured nothing.
- **Two admin breadcrumbs pointing at `"#"`** now point at `admin_portfolio_transactions_path`.

### What this breaks

- **Anything selecting `main > div > div` on the two index pages.** The header is one level shallower
  than it was, which is the same class of change as wrapping `yield` in the layout - and that one made a
  spacing test pass while asserting nothing. Check the assertion *count*, not just the pass.
- **Any test or audit asserting `px-6 py-6`, or a 24px card body.** None did; the sweep looked.
- **A new page that omits `_page_header` now fails a test rather than looking slightly wrong.**
  `page_rhythm_test` fails by name when a page's only `h1` is the admin layout's visually hidden
  fallback, because a page with no header has no header rhythm to measure. That is deliberate: the
  previous version of this audit measured from the clipped 1px `h1` and reported a meaningless 0px.
- **The form pages are measurable only because the instrument descends through `display: contents`.**
  `form_with class: "contents"` generates no box, so `nextElementSibling` finds an element with no
  geometry; the walk recurses into its children. A future audit of any seam next to a form needs the
  same treatment or it will report the content as absent.

## The component demo stops existing outside development and test

### What changed

- **`config/routes.rb` wraps the `component_demo` routes in `if Rails.env.local?`.** They were declared
  unconditionally while only the *nav row* was guarded by `Rails.env.development?`, so on production
  `/admin/component_demo`, `/admin/component_demo/form` and `/admin/component_demo/:id` were live pages
  for any admin - the index listing ten real users and their email addresses under a heading reading
  "Component demo", the show page rendering `User.find(params[:id])`. Nothing beyond an admin's existing
  rights, but the page claimed to be development-only and was not.
- **The nav row is gone, from the sidebar and from the top bar.** It first moved to the top bar beside
  `View site`, because the sidebar has no room - ten product rows are 561px in 561px on a Chromebook and
  the `Development` section cost 67px. It then came out of the chrome entirely: a component gallery is a
  developer tool, and the field keeps those outside the product (Storybook, Polaris, Primer, Lightning,
  and Rails' own `/rails/info`). The gallery is reached by URL. `View site` stays in the top bar, being a
  different class of thing.
- **`README.md` gained a `## Component gallery` section** under Local Development, and
  `design-instructions.md` now states the URL, the admin login and the `Rails.env.local?` guard beside
  both of its existing references - which named the *view directory* and never the URL, so a developer
  following the instruction to "register new components there" had no stated way to look at the result.
- **All three demo pages carry an environment banner** (`admin/component_demo/_environment_banner`),
  which is what says "not part of the product" now. It replaced two hand-rolled `bg-blue-50` panels.
- The demo controller's breadcrumbs read `Component demo` rather than `Components / Demo`, which also
  fixes a document title of "Demo | Admin | Stocks in the Future".

### What this breaks

- **`admin_component_demo_index_path` raises `NameError` outside development and test.** Every caller is
  behind the same `Rails.env.local?` guard: the top-bar link and the controller's own breadcrumbs. Any
  new reference needs the guard, or production boots and then 500s on the admin layout.
- **The suite now renders the demo pages and the top-bar link**, which is the point - but it means the
  test environment's admin chrome is not identical to production's. `spacing_test`'s "the sidebar fits a
  Chromebook" assertion is now measuring the same sidebar a developer sees; it failed by 67px the moment
  the guard changed, which is how the overflow was found.
- **`Rails.env.local?` excludes staging**, which has its own `config/environments/staging.rb` here. If
  the demo is ever wanted on staging that is a deliberate change, and the banner will name it correctly
  without being touched, because it interpolates `Rails.env`.

## The trading floor answers a teacher

### What changed

- **`StockPolicy#show_class_holdings?`** is new: true for a teacher or an admin. It is the staff half of
  `show_holdings?` - that one answers "do you own this", this one "who owns this, among the people you
  can see" - and it deliberately does not decide *which* classrooms. `ClassroomPolicy::Scope` already
  does, and duplicating that rule is how two definitions of one thing start.
- **`StocksController#index` loads two grouped aggregates** for staff: holders per stock and the number
  of students with a portfolio, both scoped by `policy_scope(Classroom)`. Nothing in the app aggregated
  holdings by stock before - there was no `group(:stock_id)` anywhere.
- **The `Held by` column** renders on every stocks table for staff, with the figure moving into the
  primary cell below `lg`, exactly as a student's holdings line does.
- **The active table's description is role-aware** and states what `Held by` counts. It was "Companies
  you can buy shares in right now" for every role, including two that cannot buy.
- **The identity cell carries the exchange and the industry.** `stock_exchange` had never rendered here
  despite the header naming it.
- **`/admin/component_demo/trading_floor_columns` is deleted** - route, action, view and its two query
  helpers. It existed to decide this and it did.

### What this breaks

- **Any test asserting a teacher or admin sees exactly two columns on `/stocks`.** None did.
- **`Portfolio.joins(:user).count` is no longer a count of students** anywhere this matters - use
  `.distinct.count(:user_id)`. `portfolios` has no uniqueness constraint on `user_id` and `has_one` does
  not add one; it only decides which row the association returns.
- **The `:with_portfolio` factory trait is now idempotent**, and was creating a *second* portfolio row on
  top of the one `Student#ensure_portfolio` makes. Any test that counted portfolios was reading double,
  and any test that deposited into `student.portfolio` was writing to whichever row the association
  happened to return. This is what made the new column report "1 of 2" for a single student.
- **The empty-row `colspan` is computed** rather than a two-way branch, because there are now three
  column counts: 4 for a student, 3 for staff with the column, 2 for anyone else.

### Follow-up: the denominator, and the sentence

- **`Held by` counts kept students, not portfolios.** `Student.kept.where(classroom_id:)`, with the
  holders query filtered the same way. The first version counted portfolio rows, which disagreed with
  the roster - `Classroom#students` is scoped `-> { kept }` - so a discarded student was off the roster
  and still in the figure.
- **The scope sentence carries no counts.** It was "Held by counts owners across 1 classroom - 3 students
  with a portfolio"; it is "Held by shows how many of your students own each one" for a teacher and
  "...how many students own each one, across every classroom" for an admin. `held_by_scope_note` takes
  only the user now, and `active_stocks_description` takes `students:` solely to decide whether the
  sentence appears at all.
- **The scope sentence returns a `SafeBuffer`, not a `String`.** It sets the column's name off from the
  prose with `tag.b`, so `active_stocks_description` is composed with `safe_join`. Any caller that
  escapes it by hand, or matches it with a plain-string regex, needs `strip_tags` - the helper test does.
- **`ApplicationHelper#shares_label`** is new: `share_count` plus an agreeing noun. Anything rendering
  "#{share_count(n)} shares" was printing "1 shares" for a single share.

## One classroom form, and one field-level message

### What changed

- **`app/views/admin/classrooms/_form.html.erb` is deleted.** Both halves render `classrooms/_form`,
  which now takes `url:` and `cancel_path:` locals.
- **`ClassroomFormFields`** (a controller concern) holds `classroom_form_data`,
  `assign_school_year_to_classroom` and `classroom_attributes`. Both classroom controllers include it.
- **`Admin::ClassroomsController#classroom_params` uses Pundit's `permitted_attributes`.** Its own list
  permitted `school_year_id` and never `teacher_ids`.
- **`Admin::FormBuilder` no longer renders field-level errors.** `field_wrapper` and
  `render_select_with_wrapper` dropped `error_message`; the method and `ERROR_CLASSES` are gone, as is
  `.tw-field-error` in `forms.css`. `collection_check_boxes` calls `FormErrorsHelper#field_error`.
- **`Admin::FormBuilder#base_errors` is gone**, with its one caller, replaced by the summary.
- **All nine admin form partials render `shared/_form_errors`.**
- **`Classroom#school_year_presence` is gone** - `belongs_to :school_year` already reports it.

### What this breaks

- **Anything posting `classroom[school_year_id]` to the admin controller.** It is not permitted; the
  form posts `school_id` and `year_id`, which are found-or-created into a SchoolYear. A controller test
  hand-wrote the old params and passed against a controller that agreed with it and not with the form -
  which is why `classroom_form_consistency_test` clicks the real form instead.
- **Anything asserting `p.text-red-600`, `.tw-field-error`, or two messages under an admin field.** One
  test did, on the school-year duplicate error; it asserts the summary now.
- **Anything asserting `Classroom` reports an error on `school_year_id`.** It reports on `school_year`.
- **`Admin::FormBuilder` is now unusable for a form with no error summary**, in the sense that an
  invalid field will show its message and nothing will tell the reader at the top. Every current form
  has one; a new admin form needs the render call.

## Migration map: one form builder for both halves

**Written before any code moves**, per the standing instruction. Current structure, target, order, and
what each step breaks.

### Current structure

| built with | forms |
|---|---|
| `Admin::FormBuilder` | the nine `admin/*/_form` partials, plus the component demo |
| hand-written fields | `classrooms/_form`, `students/new`, `students/edit`, `profiles/edit` (2) |
| Devise's `form_for`, hand-written fields | `sessions/new`, `registrations/new`, `passwords/new`, `passwords/edit` |
| not entity forms, out of scope | `orders/_form` (a modal), `grade_books/show` (a table of inputs), `classrooms/_trading_setting` (a switch), the two filter bars |

The two sets agree on tokens - `tw-input-primary`, `tw-label-primary`, 44px, `p-5` - and disagree on
construction. That is the drift mechanism this repo keeps rediscovering: `px-6 py-6` against four card
paddings, two button bases, two field-message definitions.

### Target

One builder, `Ui::FormBuilder` in `app/form_builders/ui/form_builder.rb`, named for
`app/views/components/ui/` rather than for a namespace it is no longer confined to. Every entity form on
both halves is built from it. The hand-written forms convert *to* the builder, not the reverse: its
shape - label, hint, input, error - is what GOV.UK, Polaris, Carbon and Material specify, and it is why
the admin forms read better.

### Order, and what each step breaks

1. **Bring the builder up to what the hand-written forms reached.** It has no required indicator and its
   `collection_check_boxes` renders a `<label>` over a group rather than a `<fieldset>` with a
   `<legend>` - which `classrooms/_form` fixed by hand, because a label pointing at nothing was the
   accessibility bug that form was rebuilt to remove. Converting first would lose that.
   *Breaks:* nothing; both are additions.
2. **Rename to `Ui::FormBuilder`,** converting all ten call sites in the same change - a shared class
   with one caller drifts as surely as no class at all.
   *Breaks:* anything referencing `Admin::FormBuilder` by name. Ten call sites and no tests do.
3. **Convert `classrooms/_form`,** the form both halves already share, so one change covers two pages.
   *Breaks:* selectors for hand-written markup. `classroom_form_consistency_test` clicks labels, so it
   survives; anything matching `div > label + input` would not.
4. **Convert `students/new` and `students/edit`.** These put their hint *below* the input; the builder
   puts it above, which is the standard. That is a visible change to two pages.
   *Breaks:* `teacher_creates_student_test`, which drives these by label.
5. **Convert `profiles/edit`.** Two forms, both `scope: :user` - load-bearing, because `User` is an STI
   base and `form_with model:` would derive `student[...]` from the record's class.
   *Breaks:* the profile controller tests, if the scope is lost. Assert rendered field names.
6. **Devise last, or not at all.** These four are `form_for` on a different layout, and Devise ships its
   own error partial. They are the least shared and the most likely to fight the framework.

### What changed

- **`app/form_builders/admin/form_builder.rb` is `app/form_builders/ui/form_builder.rb`**, and
  `Admin::FormBuilder` is `Ui::FormBuilder`. All ten call sites moved in the same change.
- **`Shadcn::FormBuilder` and `Components::FormsHelper` are deleted.** They backed a *third* shape,
  reached through `render_form_for`, on the four Devise pages - which is why sign in and sign up kept a
  40px `rounded-md` field while every other form moved to 44px `rounded-lg`. Measured after: 44px and
  8px radius on sign in, both classroom pages, the profile forms and the admin forms.
- **The builder grew four things the hand-written forms had and it did not**: a required indicator, a
  `<fieldset>` with a `<legend>` for a checkbox group, the hidden empty value that makes unchecking
  everything submit an empty list, and `errors_on:` for a group whose errors are on a different
  attribute than the one it posts (`grade_ids` posts, `grades` validates).
- **A checkbox row is a `<label>` wrapping its box**, not a `for=` across two sibling divs. Both are
  valid; wrapping makes the whole row a hit target and it is the shape the app's geometry tests measure.
- **`classrooms/_form`, `students/new`, `students/edit`, `profiles/edit` and all four Devise views** are
  built from the builder. The hint moved above the input on the ones that had it below.

### What this breaks

- **Anything naming `Admin::FormBuilder`, `Shadcn::FormBuilder`, `render_form_for` or
  `render_form_with`.** Nothing does; the constants are gone, so a stale reference is a NameError at
  render time rather than a silent fallback.
- **Selectors written against hand-written field markup.** Three tests in `form_actions_test` measured
  `input.closest("label")` and `span.font-medium`; the first two now pass because the row wraps, and the
  third needed the weight moved off the wrapper onto the name - a `font-medium` wrapper made the email
  fight back with `font-normal`, a rule whose only job was undoing another rule.
- **A checkbox group that does not pass `errors_on:`** silently renders no message when its errors are
  on a different attribute. `validation_errors_test` catches the classroom case by name.
- **The hint's position changed on `students/new`, `students/edit` and `profiles/edit`** - it is above
  the input now, which is where GOV.UK, Polaris, Carbon and Material put it.

## The eight open questions, decided and built

### What changed

- **`quarters.school_days`** (nullable integer). `GradeEntry#perfect_attendance?` derives the answer from
  it where it is set and falls back to the stored `is_perfect_attendance` where it is nil. The grade book
  shows a figure instead of a control in the derived case; the school-year form has the four fields.
- **`classrooms#show` renders `@classroom_stats`**, at the foot, in one card of four `_stat`s with
  `surface: false`. `ClassroomFacade#stats` returns **`total_portfolio_value_cents`** now, not
  `total_portfolio_value` - it summed a float per student.
- **`components/ui/_stat` takes `surface:`**, default true.
- **Seven admin form partials render `components/ui/_card`** and lost their `h3`.
  `admin/students` and `admin/school_years` keep theirs: they have two cards.
- **`admin/users` has `restore`, a discarded filter and a Restore row action**, and includes
  `SoftDeletableFiltering`.
- **The trading floor's archived disclosure is gone.** `stocks/_archived_stocks` takes only `stocks:`.
- **`EnvironmentHelper` and `layouts/_environment_ribbon`** - a staging-only strip, with the offsets for
  the header, the admin drawer and `main` derived from one constant.
- **`.rubocop.yml` teaches `Rails/UnknownEnv` about staging.**
- The trading floor's actions cell is `align-top`.

### What this breaks

- **Anything reading `is_perfect_attendance` directly.** The column is still written by the control where
  a quarter has no `school_days`, but the *answer* is `perfect_attendance?`. Four call sites moved; a
  fifth would silently disagree with the money.
- **Money changes for any entry whose flag and day count disagree, once its quarter has a figure** - but
  only on a grade book that has **not** been finalized. A completed book reads the stored flag, and
  `DistributeEarnings` freezes the derived answer into that column in the same transaction as the
  deposits, so what a finalized page shows is what was paid whatever `school_days` becomes later. Without
  that, editing a school year would have moved the earnings displayed on books paid months ago while the
  ledger stayed put. Both paths are pinned as literals.
- **`ClassroomFacade#stats[:total_portfolio_value]` no longer exists.**
- **Anything asserting the archived disclosure**, or two tables on the trading floor for a reader who
  holds nothing. Four tests moved.
- **`spacing_test`'s h1-to-card measurement had to leave `admin/users`**, which now has filter tabs
  between the header and the card - which is what design.md says filters do.
- **A quarter factory's attributes are discarded**: its `to_create` swaps in the row `SchoolYear` already
  made, so `school_days` has to be set on the record afterwards. This cost two failing tests to find.

## Reverted: deriving perfect attendance

`quarters.school_days`, the derivation, the school-year fields and the freeze-at-finalize are all gone.
The checkbox is the input again, unchanged from before any of it.

### Why

- **The evidence was seed data.** The contradictions cited - a flag with nil days, 3 days treated as
  perfect - were fixtures, not a teacher's mistake.
- **The checkbox is not redundant.** The app cannot know a quarter's length, so "did they attend every
  day" is information only the teacher has, quite possibly from the system they take the register in.
- **The cost compounded.** Deriving needed a denominator, which needed an admin form, which created a
  dependency from outside the grade book, which needed a freeze at finalize, which left unfinalized books
  exposed, which needed an impact preview. Each piece existed to contain the previous one.
- **The app already caught the real case.** `GradeBookEarnings#unattended_bonus_entries` flags a bonus
  claimed with no days recorded, per row and in the finalize warning, and predates all of this.

### What this breaks

- **Nothing.** `GradeEntry#perfect_attendance?`, `#perfect_attendance_derived?` and `#school_days` are
  gone; every caller reads `is_perfect_attendance`, which is what they read before. The grade book always
  shows the control. `SchoolYear` no longer accepts nested quarter attributes.
- **The drop migration is `safety_assured`.** strong_migrations blocks a column drop because Active
  Record caches attributes and a process from before the deploy would still select it. That does not
  apply to a column added and removed on the same unreleased branch, and the justification is written
  into the migration rather than left as a bare override.

## The grade book saves on blur, and only Save is an autosave target

### What changed

- **`autosave_controller` saves on `blur`** (a capturing listener, since blur does not bubble), guarded
  by a `change` flag so tabbing through an untouched field does not post. The 30-second interval stays as
  a backstop for a field left focused.
- **The status target moved** from the page header to beside the Save button, and reads "All changes
  saved" on load rather than being empty until the first save.
- **`_finalize_button` is no longer `autosave_target: "button"`.** The turbo_stream still replaces it by
  id, which is all it needed.
- **Copy**: "Then finalize the quarter", plus "Uses your saved grades, above."

### What this breaks

- **Anything asserting an empty autosave status, or finding it in the page header.** It has a
  `data-testid` now.
- **Anything relying on the finalize button being an autosave target** - nothing did; it was the hazard.
- **A test that types into a field and asserts nothing was saved** would now fail, because leaving the
  field saves it. That is the point, and `grade_book_autosave_test` verifies the handler by removing it
  and watching the assertion fail.

### Follow-up: the save indicator, and the finalize heading

- **No timestamp**, `Saving…` only after 800ms, and a failure state (`Not saved — check your connection`,
  red, persistent). `setStatus` compares before assigning, so an unchanged message never replaces the
  text node - which matters on an `aria-live` region, where it would re-announce.
- **The finalize card is headed "Finalize grades"**, matching its button.
- **A save is now silent**, so a test that edits a field has nothing in the status to wait on. Wait on
  `[data-testid='row-earnings']`, which the turbo_stream replaces - asserting the database straight after
  a blur races the request.

## Every confirmation is two parts

### What changed

- **Twenty-nine `turbo_confirm` messages** are a question and a consequence, split on a blank line.
- **Five new helpers** hold the messages that had several call sites: `classroom_toggle_confirm`,
  `teacher_deactivate_confirm`, `teacher_reactivate_confirm`, `teacher_delete_confirm`, `delete_confirm`,
  plus `transaction_delete_confirm` and `school_year_delete_confirm` for the two with real cascades.
- **`orders.cancel.confirm`** is a YAML block scalar, so the blank line survives.
- **`admin/classrooms#show` lost its Delete button.** It posted `DELETE` to `admin_classroom_path`, and
  `resources :classrooms, except: [:destroy]` means that route does not exist - it 404'd every time it
  was pressed, for as long as it had existed.
- **`confirmation_copy_test`** reads every rendered `data-turbo-confirm` on the pages that carry one and
  fails when a message has no body, has a body under 40 characters, or asks "are you sure".

### What this breaks

- **Anything asserting a confirmation's exact string.** The system tests drive the dialog rather than the
  attribute, so none did.
- **A new confirmation must carry a body**, or the guard fails by page and question.
- **`i18n-tasks normalize` strips comments from `en.yml`**, so a note about a message has to live beside
  its call site rather than in the locale file.

## The admin authorization question, answered with a test

### What changed

- **`Admin::PortfolioTransactionsController` lost six commented-out `authorize` calls** and the TODOs
  asking whether they were needed. They are not: authorization in that namespace is
  `Admin::BaseController#authenticate_admin`, every one of the ten admin controllers relies on it, and
  the single `authorize` elsewhere under `admin/` (`classrooms#toggle_archive`) is meaningful only
  because `ClassroomPolicy` exists and teachers reach classroom actions on the app side.
- **`test/controllers/admin/admin_access_test.rb`** derives every id-less admin GET route from the route
  table and asserts a teacher, a student and a signed-out visitor are each turned away, and that an admin
  reaches them all. 244 assertions across about sixty routes; before it, `base_controller_test` covered
  `/admin` and two controller tests covered one action each.

### What this breaks

- **A new admin controller that does not inherit from `Admin::BaseController` fails immediately**, which
  is the point. Verified by removing the `before_action` and watching four routes let a student in.
- **A new admin GET route with no id is covered automatically** - including one that is not ready to be
  opened by an admin, which will fail the last test until it is.

## The seeded logins keep their promise

`db/seeds/partials/users.rb` ends by restoring any of the four demo accounts that has been archived, and
resetting its password to the documented one.

Every block above it assigns attributes **only when the record is new**, and `find_or_initialize_by`
finds a discarded record perfectly well - Discard adds no default scope, only the explicit `.kept` calls
filter. So once `student` had been archived and had its password reset while somebody exercised those
actions against a development database, every later `db:seed` printed "Student user already exists" and
left an account nobody could sign in as. The README hands these four out as logins.

Only `db/seeds/development.rb` includes this partial - production and staging do not - so resetting a
demo password here cannot touch a real one.

## The six skipped tests

Zero skips in either suite now. None of the six was flaky, and none needed the fix its message named.

| skip | what it said | what it was |
|---|---|---|
| `admin_helper_test` x2 | "Broken due to routing issues" | `sort_link` calls `url_for(..., only_path: true)`, which builds a URL for the **current page** - a view test has no current page. The helper was fine; the test was in the wrong file. Moved to `admin/sort_link_test`, where a request exists, and grown from two commented-out stubs to five assertions including the toggle in both directions. |
| `user_manages_orders_test` | "Number of shares field not visible - needs modal JavaScript fix" | The skip sat **after** `fill_in "Number of shares"` and a successful order, so the field was demonstrably visible. It stranded the three assertions that check the order is for the right stock and share count. |
| `teacher_creates_student_test` x2 | "Flaky modal test - to be fixed in future PR" | Not flaky. The delete test passed as written. The reset test had three stale selectors: `p#notice` (the flash is a `div` now), `fill_in "Full name"` on the **sign-in** page, which asks only for a username and password, and an h1 of "WELCOME TO YOUR FINANCIAL JOURNEY!" that the sentence-case sweep retitled. |
| `flash_dismiss_test` | "first-share callout did not render for this fixture" | A conditional skip, so the test passed whether or not the thing it described was on the page. It did not render because the `:with_portfolio` factory trait created a second portfolio row - fixed earlier this session - so the share was on a different record than the page loaded. It asserts the callout outright now. |

### What this breaks

- **Nothing was disabled to make them pass.** The suites are 879 and 322 with zero skips.
- **`AdminHelperTest` no longer covers `sort_link`.** `Admin::SortLinkTest` does, on real routes.

## `sign_out` cannot switch users in a system test

`teacher_creates_student_test`'s password-reset test signs out the teacher, signs back in as the
student with the password the teacher was shown, and asserts the student is signed in. It failed
about **4 runs in 10** of the full system suite, and passed 6/6 on its own.

Devise's `sign_out` is `Warden::Test::Helpers#logout`, which *queues* the logout for the next request
the Warden middleware handles. In a request test that is the next request you make. In a system test
it is whichever request arrives first, and a queued block can also fire later and sign the previous
user back in — the measured end state was the **teacher** in the account menu after the student had
signed in successfully.

Two attempted fixes did not work and are recorded so they are not retried: a 10-second
`assert_field` wait (nothing was ever going to arrive), and clearing the browser cookies plus
`Warden.test_reset!` inside a `sign_out` override (still 6 pass / 4 fail over ten runs). Going
through the account menu fixed it: **10 runs out of 10**, then 5 more.

`ApplicationSystemTestCase#sign_out_through_the_ui` is the helper. Use it whenever a test signs back
in as somebody else. Plain `sign_out` is fine where a test only signs out, because nothing after it
depends on the session having ended by a particular moment.

### What this breaks

- **Nothing.** One test switched helpers; the other ten `sign_out` call sites are unchanged, and the
  suite is 322 runs with zero failures across fifteen consecutive full runs.
- **The test now asserts a different thing**, and this is the point. It used to assert the home
  page's `h1` — and the teacher's home page has the *same* `h1`, so it passed while signed in as the
  wrong user. It asserts the account menu names the student, which is the claim the test makes.

## The staging ribbon's sidebar offset, found by previewing it

`EnvironmentHelper` exists so the ribbon's 32px is written once and every fixed element below it moves
by exactly that. The admin layout read it. **The app layout did not** — `layouts/_navbar` hardcoded
`lg:top-16` — so with the ribbon on, admin's navigation dropped to 96px and the student's stayed at
64px, with its top third behind the 32–96px header.

`environment_ribbon_test` could not see it. The student-side case asserted `main`'s top, and `main`
was correct: it reads `main_offset_class`, which the layout does use. The sidebar was the one element
in that layout not going through the helper.

`sidebar_top_class` is the `lg:` twin of `drawer_top_class` — separate because the app side's phone
drawer is a full-height `top-0` overlay, where admin's hangs below the header. Two assertions now
pin it: the sidebar's top equals the header's bottom, and neither overlaps.

The ribbon also moved to `z-60`, above the `z-50` drawers. **Not because it was broken** — measured by
reverting the class, it stays on top at `z-50` too, purely because it is later in the layout. That is
the DOM-order tie design.md's stacking section already calls fragile, and an explicit rank is the
remedy it gives. The test asserts the *compiled* `z-index`, because `z-60` is a real Tailwind v4
utility and a class the build dropped would leave the tie in place while the markup read as fixed.

### What this breaks

- **Nothing outside staging.** Every one of these methods returns the previous value when
  `Rails.env.staging?` is false, which is every environment the app currently runs in.
- The ribbon is now the top of the stacking order below native `<dialog>`; design.md records it.

## The ribbon's offsets move from six hardcoded classes to one measured custom property

Previewing the ribbon at eight widths, and at 200% text, found a WCAG **1.4.4 (AA)** failure at every
width below 1024px. The sentence wraps on a phone; at 200% it needs 128px. In a rigid `h-8` box with
centred content the overflow went **both** ways — measured at 320px the text began at **y = -48**,
above the top of the viewport, where a fixed element cannot be scrolled to, and the rest covered the
header. Two lines of it were simply unreachable.

The cause was the design, not the number. `EnvironmentHelper` handed out five Tailwind classes
(`header_top_class`, `main_offset_class`, `drawer_top_class`, `drawer_height_class`,
`sidebar_top_class`) so the ribbon's 32px was written down in six places, and **a hardcoded height
cannot be right when the text rewraps.**

The ribbon is now `min-h-8` growing downward, it publishes its rendered height as `--sitf-ribbon-h`
through the `ribbon-offset` controller and a `ResizeObserver`, and every offset below it is CSS
against that variable (`chrome.css`). The header's own 4rem is a genuine constant and stays a literal.
**With no ribbon the variable is `0px` and every value collapses to exactly what it was**: header at
0, main at 4rem, drawer at 4rem — which is why nothing outside staging moved.

A `ResizeObserver` rather than a resize listener, because the height also changes on zoom and on the
webfont swap, and only the element knows about all three.

Two other gaps closed in the same pass:

- **The signed-out layout had no ribbon at all** — the half of staging a person sees first. Its header
  is in normal flow, so the ribbon is static there (`fixed: false`) and skips the controller, because
  nothing is offset against it.
- **`PREVIEW_STAGING_CHROME=1` shows it outside production.** Chrome that exists in one environment is
  chrome nobody looks at until it is deployed, which is how it reached staging with the sidebar behind
  the header and its text unreachable at 200%.

### What this breaks

- **Nothing outside staging**, by construction: the variable defaults to `0px`.
- **`EnvironmentHelper` is down to one method.** Anything calling the five class helpers must move to
  the `chrome-*` classes.
- The offsets are no longer greppable as Tailwind classes in the layouts; they are in `chrome.css`.

## The two-breakpoint policy is explicit now, and grounded in the content rather than the devices

`docs/responsive-design-guidelines.md` already said "use only `base` and `lg:`". Its stated reason was
device-based — "1366×768 is the most common Chromebook resolution" — which is the reasoning the field
explicitly warns against, because a list of device widths goes stale while a layout's own breaking
point does not.

The rule is unchanged. **The justification is now the layout**: this app changes shape exactly once,
at 1024px, where there is or is not room for a 256px sidebar beside the content. A third tier would be
a breakpoint with no layout change behind it, and every one of those is a place for two versions of a
component to drift apart. The doc now shows what other systems ship — Tailwind five, Bootstrap five,
Material five, Primer four, Polaris four, GOV.UK three — so that two is a visible, argued choice
rather than an unexamined one.

**The substantive addition is "two tiers is not two widths."** The doc used to say *Test at Two
Sizes*, and that is what let the ribbon ship: it passed at 375 and 1366 and failed at every width
below 1024 as soon as text was at 200%. Two tiers is a claim about layout; the product still has to
work continuously from 320px, and at 200% text, which are WCAG 1.4.10 and 1.4.4, both AA. The doc now
asks for 320 / 375 / 768 / 1024 / 1366 / 1920 plus two zoom cases, and says to adapt fluidly —
`flex-wrap`, `minmax()`, `min-h-*`, `clamp()`, a measured custom property — before adding a tier.

Three contradictions with design.md were fixed in the same pass, since a doc that disagrees with the
spec is the drift this repo keeps recording:

- It required **44px** touch targets. design.md's button height is 40px, and 44px is reserved for bare
  tap targets. Setting the admin buttons to 44px once made them visibly taller than every other button.
- It said **"Tailwind-only: no custom CSS"**, which has never been true — the `.tw-*` component classes
  are the app's shared patterns. What is actually banned is an inline style or an arbitrary value with
  a scale equivalent, and there is a test for that.
- Its example markup was **pre-token**: `border-2 border-black rounded-[20px]`, `bg-blue-600`,
  `min-h-[48px]`. Now `.tw-btn-*` and `components/ui/_card`.

## The ribbon's copy

`Staging — this is not the real site, and nothing here affects real students` became
**`Staging site. These are not real students.`**

- **No em dash.** A dash asks the reader to work out how the halves relate; a full stop states them.
- **"These are not real students", not "nothing here affects real students."** The second is a
  stronger promise than the deployment can keep: staging is configured with real SMTP, so an action
  here can still send mail. What is reliably true is that the records are fake.
- **Length is a constraint.** At 375px there are 304px for text. The first rewrite measured 307px and
  wrapped by three pixels; this one is 219px and fits on one line from 320px up. The ribbon grows to
  fit either way, but a phone should not need two lines to say this.

## Container queries become the rule for components

The two-tier viewport policy was made explicit in the previous entry. This adds the thing that makes
two tiers *viable* rather than merely defensible.

A viewport breakpoint answers "how wide is the window". A component nearly always needs "how wide am
I", and the two diverge the moment anything sits in a column, a card, a modal or a table cell. Every
"this component broke somewhere else" bug recorded in this document is that divergence: the roster at
765px beside a 256px rail, a `flex-1` pane that needed `min-w-0`, a four-across stat band that is fine
full width and wrong in a column, row actions off screen because the *page* scrolled.

The usual response to those is to add `md:`, then `xl:` — which is how a two-tier system becomes a
five-tier one without anyone deciding to. **The rule is now: page layout uses the viewport tiers, and
anything that could render in a narrower box than the page uses a container query.** Verified in this
codebase, not assumed: Tailwind 4.3.1 compiles `@container` and its variants, with `@lg:` resolving to
`@container (min-width:32rem)` — container-relative, not the 1024px viewport `lg:`.

Adoption is by touch, not by sweep: a component that only ever renders full width loses nothing by
using `lg:`. The test is "could this render in a narrower box than the page?"

Four smaller items were added at the same time, all of them current field defaults and none of them
expensive today: **logical properties** (`ms-`, `pe-`, `text-end`) over physical, **`clamp()`** where a
size step is arbitrary rather than a token, **`dvh`** over `vh`, and **`prefers-reduced-motion`** on
anything that moves.

The doc also now says what is *missing*: a test that walks the main pages at 320px and at 200% text
asserting no overflow, nothing above `y = 0`, and no control outside its scroll container. Every
failure found by hand in this session would have been caught by it.

### What this breaks

- **Nothing yet.** No existing component was converted; this is a rule for new and rebuilt ones.
- A future PR adding `md:` or `xl:` should be answered with "should that be a container query?"

## The ribbon's copy, second pass

`Staging site. These are not real students.` became **`Staging site. Test data only.`**

The absolute claim was a promise the deployment cannot keep *through use*. Staging is seeded from
`db/seeds/development.rb`, so it ships with fabricated students — but an admin doing UAT can import a
real roster through the CSV path, and a banner that then reassures them the data is fake is worse than
one that says nothing. "Test data only" states what the environment is *for*, which stays true and
reads as an instruction rather than a guarantee.

It is also the field's idiom (Stripe's "test data", Shopify's "Development store") and the shortest
candidate measured: 148px against a 249px budget at 320px, where "Does not contain any real data" needs
236px and "Nothing here affects the live site" 250px — the latter wraps at 320px.

## `reflow_test`, and the five failures it found on its first run

The previous entry said the highest-value gap was a test that walks the main pages at 320px and at
200% text. It exists now: `test/system/reflow_test.rb`, four tests — signed out, student, teacher,
admin — covering seventeen pages, each measured twice.

Two helpers make it possible, and both are worth knowing about:

- **`in_reflow_viewport`** uses CDP `Emulation.setDeviceMetricsOverride`, not `resize_to`. A Chrome
  *window* will not go below about 500px, so `resize_to(320, ...)` silently gives you ~500 and a test
  that believes it checked 320px. The override yields a 305px client width, the rest being scrollbar.
- **`apply_200_percent_text`** doubles the root font size. Tailwind sizes type *and* spacing in rem, so
  this scales what browser zoom scales. It has to be re-applied after every `visit`.

It asserts three things per page: the document does not scroll sideways, nothing visible renders above
`y = 0`, and no `.hidden` element has a computed display other than `none`.

**It failed on five pages the first time it ran, and every failure was real.** All five were the same
shape — a row that could not wrap, or a box that could not shrink — and all five fixes are fluid, not
new breakpoints:

| Page | Cause | Fix |
|---|---|---|
| every admin page | the header bar was `h-16` with two unshrinkable groups; at 200% the wordmark alone is 166px and the account group 216px, against 305px | `min-h-16 flex-wrap`, `min-w-0` on the left group, `truncate` on the wordmark |
| every page | the account menu panel is `w-64` — 16rem, so **512px** at 200% — and an absolutely positioned box adds to its container's scrollable overflow **whether or not the menu is open** | `.account-menu-panel { width: min(16rem, calc(100vw - 2rem)) }` |
| admin students, teachers | the Active / Deactivated / All tabs, `flex gap-1` with no wrap, 507px | `flex-wrap` |
| admin announcements | the `h1` "Announcements" at 346px | `min-w-0 break-words` |
| student portfolio | the callout's Dismiss is `shrink-0`, so the row ran to 447px | `flex-wrap` on the callout, `min-w-0` on its body |

**The `h1` is the one to remember.** `break-words` alone changed nothing, because the title is a *flex
item* — the row also holds the status badge — so its `min-width: auto` floors it at min-content, and
the min-content of a single unbreakable word is the whole word. `min-w-0` removes the floor; only then
does `overflow-wrap` get to break it. Any "why won't this wrap" inside a flex row is this.

### What this breaks

- **Nothing.** 882 unit and 330 system runs pass, and the system suite was run three times to be sure.
- Four shared partials changed — `_page_header`, `_callout`, `_account_menu`, `_discard_filter_tabs` —
  plus the admin layout's header. All of them widen what already worked; none narrows it.

## The staging band becomes dismissible, per login, and leaves a badge

This **reverses a decision recorded earlier in this document**, so the reversal is recorded rather than
the earlier entry rewritten.

The original reasoning was that only an *outcome* removes itself, and "you are on staging" is still
true in a minute. That is sound about the sentence and wrong about the strip: a 32px band across every
page on every visit was reported in use as "very distracting, and it pushes everything down". Both
halves of that are accurate — it *is* on every page, and before the chrome refactor it pushed the
header, the drawer and the content down by a hardcoded 32px.

Two properties make the reversal safe, and a dismissible chrome-level notice needs both:

- **It comes back on every login.** The dismissal is a flag in the **session**, not a `dismissals` row.
  That table holds one persistent row per user per key, which is right for "I have seen the first-share
  celebration" and wrong here. A Warden `after_authentication` hook clears the flag, which is the only
  moment that reliably means "a new login" — signing out and back in during the same browser session
  brings the band back too, and Devise's logout does not reliably clear unrelated session keys.
- **A badge takes its place.** `layouts/_environment_badge`, in the header both halves already have, at
  zero vertical cost. The question the band answers is still answered; only the strip goes. Exactly one
  of the two is on screen, never both and never neither. Stripe's persistent "Test mode" pill is the
  same trade, and a collapsed Salesforce sandbox banner leaves a marker rather than nothing.

The dismiss is a `button_to`, for the reason already recorded for callouts: a client-side hide of page
state that is still true comes straight back on the next load. Here the round trip does more than
persist — because the band is then **absent from the render** rather than hidden inside it,
`--sitf-ribbon-h` falls back to its 0px default and the 32px is genuinely reclaimed. The test asserts
that number rather than the band's visibility, because "hidden but still occupying space" is exactly the
outcome that would look correct.

There is no `authenticate_user!` on the controller: the sign-in page shows the band too, the flag is in
the reader's own session, and signing in clears it. Nothing is authorised because nothing is shared.

### What this breaks

- **A test asserting the ribbon had no dismiss is gone**, replaced by four: that the space is reclaimed
  and not merely hidden, that it returns on the next login, that band and badge are alternatives, and
  that neither appears outside staging.
- **`design.md`'s "a message that removes itself must be an outcome" now has a stated exception.** The
  rule stands for flashes, callouts and error summaries; the deployment band is the one thing that
  describes neither the page nor an outcome.
- Adds `StagingRibbonDismissal` (a session-key holder, not a record), one controller, one route, and one
  initializer. `Dismissal::KEYS` is unchanged — briefly adding a key there was the wrong store and was
  reverted before it shipped.

## The fixed header's height stops being a hardcoded 4rem

Reported: "an odd line that goes past the top nav, in the admin setting page, and the horizontal line
does not continue." It was a regression from the previous entry but one worth having found, because the
cause was older than the change.

`chrome.css` positioned everything below the header against a literal `4rem`. The admin bar was
`min-h-16` around a 44px trigger inside `py-3`, so it measured **69px**. Its `border-b` therefore painted
at y=100 while the sidebar and the content both started at 96 — a hairline lying across the top of the
nav, and the nav's own rule beginning 5px late. Switching that bar from `h-16` to `min-h-16` in the
previous entry is what let the intrinsic height win; `h-16` had been clipping it.

Two fixes, and the second is the one that matters:

- The redundant `py-3` is gone, so the bar is the 64px its token says.
- **The header's height is measured and published as `--sitf-header-h`**, the same way the staging band
  publishes its own. Every offset is now `calc(var(--sitf-header-h) + var(--sitf-ribbon-h))`. A hardcoded
  height cannot survive a header that wraps at narrow widths or grows at 200% text, and both are things
  this header now does.

`ribbon_offset_controller` became `chrome_offset_controller`, taking the variable name as a value, so
one measurer serves both.

**It publishes `clientHeight`, not the bounding rect**, and that detail took two attempts. The two
layouts carried `border-b` on different boxes, so measuring the border box published 65 in one and 64 in
the other and the sidebars aligned with different numbers. The app header is now structured like
admin's — border on the outer element, `min-h-16` on an inner row — because Preflight sets
`box-sizing: border-box`, so `min-h-16` *on the bordered element* leaves 63px of content. That was a
1px seam difference between the two halves, invisible until something depended on it.

**`flex-wrap` came off the app header.** It belongs on admin's, whose left side is a text wordmark that
grows with the font; this side's is a fixed-size SVG, and wrapping put the account menu on a second line
at the left edge — 272px off the gutter it shares with every card, which `chrome_gutter_test` caught.
`reflow_test` passes at 320px and 200% without it.

### What this breaks

- **`test/system/fixed_chrome_test.rb` is new** and asserts the seam *relatively* — the header's painted
  bottom, the sidebar's top and the content's top all equal the offset the chrome publishes — on both
  halves, with and without the band, at normal and 200% text. Every previous assertion about this seam
  was the number 96, which both sides agreed on until one grew. Verified by reinstating the hardcoded
  `4rem`, which fails it.
- Two assertions in `environment_ribbon_test` were hardcoding a 64px header and are now relative. One
  was off by the 1px border, which paints *on* the seam and always has.

## Finalize grades stops being a destructive button

Reported: "on the grade book page finalize grades lights up like a destructive button on hover. This
should not be the case." Correct, and the file's own comment already contained the argument against
itself.

It was `:danger_outline` — slate at rest, rose on hover — while the note beside it explained that the
*dialog's* accept button stays the brand primary because "finalizing is irreversible and it is not
destructive: it pays students and locks entries, and nothing is lost". The same action was therefore
non-destructive in the confirmation and dangerous on the page.

**Irreversible is not destructive.** The rose hover is the affordance for an action that takes something
away, and every other `:danger_outline` in this app is one: Permanently delete, Deactivate, Archive,
Delete. Audited all of them, plus every `variant: :danger` ghost — finalize was the only misuse, and the
Restore and Reactivate counterparts were already correctly neutral. Finalizing adds money to portfolios;
Stripe's "Pay $X" is not a red button.

It is `:secondary`, not the primary, because "Save grades" is the primary on that page — the hierarchy
the page was rebuilt around.

**What colour was actually doing there is the general lesson.** `:danger_outline` and `:secondary` are
identical at rest, so the only reader who ever saw the warning was one already hovering the control they
had decided to press. The weight belongs on the label, the figure stated beside it, and the two-part
confirmation. That is now a rule in design.md.

### What this breaks

- One assertion in `grade_book_page_test` said `.tw-btn-danger-outline`; it says `.tw-btn-secondary`.
- A new test pins it as a **class contract**, not a rendered colour, and the reason is recorded in it:
  Tailwind emits `hover:` inside `@media (hover: hover)` and the headless Chromium reports
  `(hover: none)`, so the rose never applies in the suite even with the pointer on the control — and the
  resting colours are identical, so a pixel assertion could not tell the two variants apart either.

## Admin index rows: a real link on the name, and the pinned cell stops floating over the columns

Two reported defects on `admin/classrooms`, both of which turned out to be app-wide.

### The name had no signifier because the class attribute was silently dropped

The row navigates on click - `data-controller="clickable-row"` - and the only affordance was
`cursor-pointer`. It never applied: the `<tr>` carried **two `class` attributes**, and a browser keeps
the first and drops the second without complaint. This is the same trap already recorded against the
portfolio chart's `h2`, and it was in **five** files: admin classrooms, teachers, portfolio
transactions, the shared admin table, and orders. `.table-body-row` already supplies the hover tint and
the transition, which is exactly why nothing else looked wrong and nobody noticed.

The fix is not the cursor. **The primary cell is a real `<a>`** on `.tw-link`, because a `<tr>` with a
click handler is not keyboard reachable and is not announced as anything - the row click stays as an
enhancement on top. Applied to classrooms, students and users, and `admin/shared/_table` now links its
**primary column always** rather than only when a caller passes `link: true`. That option existed and
was used by exactly one caller: the component demo. Announcements, schools and stocks had the same
plain-text primary cell.

### The pinned actions cell was transparent at scroll position zero

Reported as the buttons overlapping the columns to their left as the viewport narrows, and the condition
was simply the wrong one. A `sticky right-0` cell is pulled into view the moment its table is wider than
its container - **at scroll position 0, before any scroll event exists** - but the opaque ground and the
separator were gated on `data-table-scrolled`, which only a scroll listener ever set. So the buttons
floated over the columns with nothing behind them until the user happened to scroll.

The flag is `data-table-pinned` now and it means *can* scroll, not *has* scrolled:
`scrollWidth > clientWidth`, set on connect, on scroll, and from a `ResizeObserver` on each container
and its table, so a viewport change or a content change re-evaluates it. Turbo's load and stream events
re-scan, since Turbo replaces content without reconnecting a body-level controller.

The original concern is preserved: a table that fits gets neither, which is what stops the student
portfolio's holdings table - which never scrolls at any width, because it wraps the company name
instead - from drawing a stray rule beside its Trade button.

### What this breaks

- One assertion moved from `[data-table-scrolled='true']` to `[data-table-pinned='true']`.
- A new test covers the case nothing did: the cell **unscrolled**, asserting `scrollLeft` is 0, that the
  table does overflow, that the background is opaque, that the separator is there, and - with
  `elementFromPoint` at the cell's own centre - that the cell is what paints there. Verified by
  reinstating the old condition, which fails both pinned-cell tests.
- The shared table's `link:` option now only affects non-primary columns.

## The actions column stops being pinned

Reported, after the previous entry made the pinned cell opaque: "there is a point where half a column is
displayed, and the rest is covered by the column on the right with the action buttons."

That is inherent to a frozen trailing column. `position: sticky; right: 0` pulls the cell into view
whenever its table overflows, so at every scroll position except the last it sits over whatever column is
underneath. Making it opaque with a separator is the correct treatment *for a frozen column* - AG Grid and
Airtable both do exactly that - and it made the dead zone legible rather than removing it.

Two measurements decided to remove it instead:

| table | overflow @1024 | @1366 | @1920 | actions column @1024 |
|---|---|---|---|---|
| classrooms | 215px | 0 | 0 | 260px |
| users | 340px | 0 | 0 | 260px |
| teachers | 306px | 0 | 0 | 280px |
| stocks | 175px | 0 | 0 | 253px |
| students | 11px | 0 | 0 | 260px |

**The pin served one narrow band**, roughly 1024-1200px: at 1366 and 1920 nothing overflows at all. And
below `lg` the row collapses into its primary cell, where `shared/_stacked_row_fields` already repeats the
actions - verified on all six admin indexes - so a phone never needed it either.

**The convention it was reaching for freezes the leading column, not the trailing one.** Excel's frozen
panes, Airtable, AG Grid and Material's data tables pin the *identifier*, so you know which row you are on
while scrolling across. Pinning actions is rare and, where it exists, an explicit user choice.

`.table-actions-pinned` is `.table-actions-cell` now, keeping only the `pt-1.5` that puts a 32px control on
the row's first line. `table_scroll_controller` is deleted along with the `data-table-pinned` attribute it
existed to set - nothing else read it.

**The width is the real problem and it is still open.** That cell is 253-280px, the widest column in every
one of these tables and 36% of the 703px visible at 1024px, against 175-340px of overflow. Take ~180px out
of it and four of the five stop overflowing entirely. It also absorbs all the slack at wide widths, reaching
**455px** on admin/students at 1920 to hold two buttons. Three labelled ghosts per row - View, Edit,
Archive - is what every major system puts behind one overflow trigger.

### What this breaks

- **Three tests describing the pin are gone**, replaced by two describing what is true now: the actions
  cell is `position: static` and moves with the scroll, and the collapsed row carries its actions.
- Any future need to keep a column in view should pin the **first** one, and should note that a menu
  inside `overflow-x-auto` will be clipped unless it renders in the top layer.

## The row actions menu is reverted

Built as a preview on `admin/classrooms` and in the gallery, reviewed, and rejected: "it just adds
clicks and friction, not value."

That is the trade the numbers could not settle. The menu did what it claimed - the trailing cell went
260px to 76px and the table's overflow at 1024px went 215px to 31px - but every one of those pixels was
bought with a click on Edit, which is the action people go to that page for. design.md already says not
to bury a core action in an overflow menu, and this is the case it was warning about.

Reverted in full, including `.tw-menu-item`. Extracting that from `layouts/_account_menu` was justified
by a *second* menu needing it; with no second menu it is a named class with one caller, which this
codebase treats as no better than the local string it came from.

**What is worth keeping from the exercise, since none of it depends on the menu:**

- **The trailing actions cell is the widest column in every admin table** - 253-280px against 175-340px
  of overflow at 1024px, and 455px at 1920 where it absorbs all the slack for two buttons. Whatever
  narrows it, that is where the width is.
- **`View` is redundant now.** The record's name became a link in the previous change, so the row carries
  two controls to the same page - the defect this document already records for a dashboard with two
  ghosts sharing an href. Dropping it saves ~85px and costs nothing, and is the obvious next move, but it
  was part of the reverted change rather than asked for, so it is left alone here.
- **A dropdown cannot be an absolute panel in a table cell.** Measured: 508px against a 288px wrapper,
  and `.table-wrapper` computes `overflow: auto` on both axes. It needs the top layer - `popover` - and
  JS positioning, because CSS anchor positioning is Chrome-only.
- **A row emitted twice needs two ids.** These rows render in the trailing cell at `lg` and inside the
  primary cell below it, so any id-addressed control - a popover, an `aria-controls` - is duplicated, and
  the *visible* trigger then drives the *hidden* copy. The panel measured 0x0 and reported itself open.
- **44px does not fit a table row here.** The shared alignment rule puts a control's centre on the row's
  first text line, 22px from the cell top; 32px needs 6px of padding above it and 40px needs 2px, and
  44px cannot reach it without a negative margin, which drags the hover fill past the content edge.

## `View` is gone from every admin index

The record's name became a link in the primary cell two changes ago, so every row was carrying **two
controls to one destination** - the defect this document already records for a dashboard that had two
adjacent ghosts sharing an href. Approved on the condition that the name is genuinely clickable, which is
why three tables were linked first: `teachers`, `school_years` and `portfolio_transactions` still had
plain-text primary cells and would otherwise have lost their only route to the record. Every admin index
links its name now, and none of them offers `View`.

Measured, before → after, at 1024px:

| table | actions cell | overflow |
|---|---|---|
| classrooms | 260 → 185px | 215 → 136px |
| users | 260 → 185px | 340 → 249px |
| teachers | 280 → 206px | 306 → 244px |
| school_years | — → 228px | 0 |
| students | 260 → 208px | 11 → 0px |

About 75px per table, and the two tables that fitted already still fit. It does not close the 1024-1200
overflow on `users` and `teachers` - their username and email columns are ~190px each - and that is
accepted: nothing is obscured now that the actions cell is not pinned, and a data table is WCAG 1.4.10's
documented reflow exception.

### What this breaks

- **`tbody tr a` no longer means "a row action."** `row_actions_test` measured every link in the row, so
  it read the 17px name link as a 32px ghost with a missing icon and reported two spacing failures. It is
  scoped to the actions cell and to `[data-testid='stacked-row-actions']` now - a testid added for this,
  because the collapsed row had no hook of its own. The lesson generalises: a test that selects by tag
  inside a row is asserting about whatever else lands there later.
- Any test or bookmark that clicked `View` in a row: the name is the link now.

## A row action returns you to the list, and the admin back buttons are gone

Two reported on `admin/classrooms`: archiving a classroom took the user to that classroom's page, and the
"Back to classrooms" button at the foot duplicated the breadcrumb.

**Archive redirected to the record.** It was the odd one out - every other row action in the admin half
already returned to its list - and it is not the convention: Gmail, GitHub, Linear, Stripe and Polaris all
keep you where you were and report what happened in a message. The click was on a row; the answer to "did
it work" is the list. It is `redirect_back_or_to(admin_classrooms_path)` rather than the index outright,
because the same action is offered on the classroom's own page through `archive_button`, and from there
the right destination is that page showing its new state.

Auditing the rest turned up **one more**: `portfolio_transactions#destroy` redirected to the
**dashboard**. Now the transactions list. Create and update are deliberately unchanged - after editing a
thing, its page is where you see the result.

**The back buttons.** Nine admin show pages carried a footer "Back to X" while every admin page already
has a breadcrumb - the same journey twice, and the footer copy is the one you have to scroll to find. The
component demo's page-header "Back to list" went with them. The wrapper went too: each button was the only
control in an `mt-6 flex gap-3` row, and leaving an empty row behind leaves 24px of dead space, which is
the rule about deleting a rule and keeping its padding.

### What this breaks

- **Five assertions pinned the old archive destination** and now expect the list. A sixth test is new: with
  a `Referer` the action returns to the page it was called from, which the fallback would otherwise hide -
  the same shape as a negative test that passes because the endpoint is broken.
- One assertion expected the dashboard after deleting a transaction.
- **A caution from doing it:** my first edit replaced the redirect assertion in `update` as well, which
  correctly goes to the record. A mechanical replace across a test file catches the tests you did not mean.

## Reduced motion is honoured, and three unused rules get their triggers written down

**`prefers-reduced-motion` was live in one place.** `auto_dismiss_controller` checked it for the flash
fade; meanwhile both nav drawers slid 256px on a 300ms transform and every button and row transitioned
its colours. That is a real accessibility gap on a setting every major OS ships.

`app/assets/tailwind/motion.css` **restricts which properties may transition** rather than zeroing every
duration. The common snippet sets `transition-duration: 0.01ms` on everything, and it is blunter than the
setting asks for: the query is about *motion*, and a colour or opacity fade is not motion in the sense
that causes trouble. So transforms stop moving and animations collapse, while a button still fades on
hover. `!important` is deliberate and confined to this file, because a utility is what declares the
transition on every one of these elements.

One thing made this safe: **nothing here waits on `transitionend`**. That was already a rule - "remove on
its own timer, because a transition that never fires leaves the message up forever" - and a
reduced-motion override is exactly the trap it was written for.

`reduced_motion_test` drives it through CDP `Emulation.setEmulatedMedia`, which is the only way to put
this browser in that state; without it the media query is dead code no test can see. Verified by
un-importing the stylesheet - both examples fail.

**And the three rules with no callers.** Container queries, logical properties and `clamp()` were added to
the responsive guidelines two changes ago and nothing used any of them. A caller was looked for rather
than invented: `components/ui/_stat` was the candidate, since it renders both in a four-across band and
inside a card, and measured on `classrooms#show` it is 151px at 1024px with no overflow and no label wrap.
`reflow_test` passes at 320px and 200%. Every case that has actually come up was fixed by `flex-wrap`,
`min-w-0` or `min-h-*`.

So the guidelines now record the **trigger** for each instead of implying adoption: a container query is
for a component that must change *layout* by its own width, logical properties are a convention for new
markup rather than a sweep, and `clamp()` is wrong for a value that is a token - which nearly every size
here is. Both failure modes are named in the doc: a rule with no caller drifts as surely as no rule, and a
caller invented to satisfy a rule is an abstraction nobody asked for.

**Closed while there:** the backlog still claimed the `design.md` reconciliation had "roughly 200 lines"
of CASA examples left. That finished earlier the same day at 236 → 6 lines, the 6 deliberate. The file
itself records "re-check a standing claim before repeating it", from carrying a fixed CVE as the branch's
most urgent item.

## Map: re-opening a finalized grade book, and paying the difference

**Asked for:** an admin-only re-open of a finalized grade book, with the app computing the difference and
offering it for confirmation rather than an admin entering it by hand.

**Why it needs a map.** This changes what students are paid, and the current code will pay twice if
anything reopens a book. Three problems, all measured or read off the schema:

1. **`finalize` pays in full, every time.** It sets `verified!`, and `DistributeEarnings` deposits the
   whole computed amount and sets `completed!`. Return the status to `draft` and finalize again and every
   student is paid the entire amount a second time. The service has no notion of having run before.
2. **Nothing links a deposit to the grade book that caused it.** `portfolio_transactions` is
   `amount_cents`, `reason`, `transaction_type`, `description`, `portfolio_id`. So "how much has this book
   already paid this student?" is unanswerable, and a difference cannot be computed at all.
3. **A finalized book's entries are writable today.** `GradeBooksController#update` has no `completed?`
   guard - only `finalize` does - and `GradeBookPolicy#update?` asks who you are, not what state the book
   is in. Measured: a teacher PATCHed a completed book and moved a grade from C to A, days 3 to 40 and the
   perfect-attendance flag to true. The ledger did not move, so the record and the money now disagree, and
   the page's derived figures are computed from the record.

**Target structure.**

- `portfolio_transactions.grade_book_id` (nullable, indexed). Nullable because every existing row and
  every purchase, sale and fee has no grade book. This is also Tier 3 Step 3 - pairing an earnings
  transaction with the grade that caused it - which is why that item comes forward with this one.
- `GradeBook#paid?` derives from the existence of linked transactions rather than a second column, so
  there is one source for "has this paid". `#paid_on` and `#amount_paid_cents` come from the same rows.
- `DistributeEarnings` pays the **difference per user per reason**: owed now, minus what this book has
  already paid for that reason. On a fresh book the second term is zero, so behaviour is unchanged, and
  the characterisation test's literals still hold.
- **A negative difference is never taken back.** A grade corrected downward leaves the overpayment paid.
  Taking money out of a portfolio is not neutral - the student may have bought shares with it, so the
  balance may not cover it - and a balance that drops is a pedagogical event, not a bookkeeping one. The
  amount is reported, not clawed.

**Order of moves, and what each breaks.**

1. **Guard `update` on `completed?`.** Closes the hole above. Breaks any client that edits a finalized
   book - nothing legitimate does, since the view has never offered the inputs.
2. **Add the column and the associations.** Reads nothing yet. Breaks nothing.
3. **Tag deposits with the grade book** in `DistributeEarnings`. Still pays in full. Breaks nothing; it
   only makes the next step possible.
4. **Make the amount a difference.** No behaviour change on a first finalize, by construction.
5. **Add `reopen`, admin-only**, and surface the outstanding difference in the finalize card and its
   confirmation.

**What is deliberately not in this.** No audit columns for who reopened and when. The status change and
the payment stated on the page are the visible record; if accountability for the funds needs a name
against the action, that is a `reopened_by`/`reopened_at` pair and it is the obvious next step rather than
something to guess at now.

## Built: an admin-only reopen that pays the difference

Follows the map above. All five moves are in.

**1. `update` refuses a completed book.** The hole was real and measured: a teacher PATCHed a finalized
book and moved a grade from C to A, days 3 to 40, and the perfect-attendance flag to true. The money did
not move, which is the worse half - the record and the ledger then disagree, and every figure on the page
is derived from the record. The view had never offered the inputs, so nothing that checks what a page
*offers* could have caught it.

**2. `portfolio_transactions.grade_book_id`**, nullable and not backfilled. Backfilling the historical
earnings deposits was considered and rejected: a guess about which quarter paid a row would be
indistinguishable from a fact, and the only reader is a difference calculation that must treat "unknown"
as "not paid by this book". Added as an unvalidated foreign key then validated, and the index built
concurrently, both because strong_migrations asks for it.

**3-4. `DistributeEarnings` pays the difference per user per reason.** Owed now, minus what this book has
already paid for that reason. On a first finalize the second term is zero, so behaviour is unchanged and
`distribute_earnings_characterisation_test`'s literals still pass untouched. Per reason rather than per
student, because that is how the deposits are written, so a corrected maths grade tops up the maths reason
and leaves attendance alone.

**A negative difference is never taken back.** `overpaid_cents` reports it and nothing acts on it: the
student may have bought shares with the money, so a portfolio may not cover a reversal, and a balance that
drops is a pedagogical event rather than a bookkeeping one.

**`GradeBook#paid?` derives from the ledger** - the existence of linked transactions - rather than a
second column, because after a reopen the status says `draft` while the money is still out there. One
source for "has this paid", and it cannot drift from what was deposited.

**5. `reopen`, admin-only**, with `GradeBookPolicy#reopen?` aliased to `finalize?`: reopening a paid book
is the other half of releasing the money, so whoever is trusted with one is trusted with the other. It
returns the book to `draft`, not `verified`, since a book being corrected is neither checked nor ready.

The page states the money at every step - what was paid and when, that a reopened book's payment stays
paid, and what finalizing again will actually move. Four sentences from one helper, so the card and the
confirmation dialog cannot describe one payment two ways.

### A stale derivation, found by rendering the flow

With $0.60 paid and a grade corrected from C to A, the Earns column and the total went to $3.60 while the
consequence sentence still read *"nothing more is owed: these grades earn exactly the $0.60 already
paid"*. The `update` turbo_stream replaced every other derived thing on that page - the cells, the
warnings, the footer, the breakdown, the button - and not the sentence, because it had no id.

**Third time on this branch.** The rule was already written after the second: when you find one stale
derivation, list every derived thing on the page before moving on. It is `_finalize_consequence` with an
id now, in the stream, and a system test asserts the figure refreshes and that the dialog agrees with the
card.

Two of my own waits were vacuous while chasing it, both worth noting: `assert_text "Grades saved"` never
matches, because a turbo_stream response renders no flash; and waiting for the autosave status to read
"All changes saved" proves nothing, since that is its text on load - which this repo already records as
the reason the status only changes when the words change.

### What this breaks

- **Anything PATCHing a finalized grade book** now gets a redirect and an alert. Nothing legitimate did.
- **`DistributeEarnings.execute` returns the service**, not the grade book, so `overpaid_cents` can be
  read. Nothing depended on the old return value.
- **A `grade_book` is no longer safely destroyable in a test without its deposits surviving** -
  `dependent: :nullify`, on purpose: deleting a grade book must not remove money from a portfolio.
- **Not built, deliberately:** no `reopened_by`/`reopened_at`. The status change and the payment stated on
  the page are the visible record. If accountability for the funds needs a name against the action, that
  pair is the obvious next step.

## The school form: a sticky action row, three columns, and only the years that matter

Reported on `admin/schools#edit`: the years push the action button below the fold, and the years should be
in reverse order.

**The ordering was already reverse.** `Year.ordered_by_start_year` is `DESC` and the list rendered 2036,
2035, 2034 … 2024, 2023. What made it feel wrong is that the seeds create **current−3 to current+10**, so
"newest first" opened on a year a decade away and buried the one in progress ten rows down.

**Shortening the list does not fix the button**, which is the measurement that decided the shape. At 625px
of Chromebook viewport the submit sat at y=1094, and laying the fourteen checkboxes out in columns moved it
to 786 (2 columns), 698 (3) and 654 (4) - still below the fold every time, because the breadcrumb, the page
header, the card padding, the name field and the hints take ~486px before the years begin.

So three changes, and each is measured:

- **`.tw-form-actions`** - `sticky bottom-0` with a top border and the page's own background, on every form
  footer in the app. Submit at **y=569 of 625** unscrolled, and it holds while scrolling. No JavaScript and
  no unsaved-changes state: sticky only offsets an element that would otherwise leave the scrollport, so on
  a short form the row sits exactly where it always did. This is Polaris's ContextualSaveBar and Stripe's
  sticky footer without the state machine. A form's primary action should not depend on the form's length.
- **`columns:` on `collection_check_boxes`** - three columns from `lg`, one below. Fourteen years went from
  **612px to 216px** and five rows. GOV.UK and Polaris both allow a multi-column checkbox group for short
  uniform labels, which is what a school year is.
- **`Year.offered_for`** - the current school year, the one either side, and **anything the record already
  has**. Three boxes instead of fourteen, with the current one badged.

**The already-selected clause is not tidiness, it is the difference between narrowing and data loss.**
`year_ids=` replaces the whole collection, so a school linked to 2023-2024 would have that association
destroyed by any save from a form that never showed it - along with the four quarters on the `SchoolYear`,
or an outright failure if it has classrooms, since both are `restrict_with_error`. A field whose value is
silently discarded looks like a save that worked. A test covers it directly.

### Three traps, all of them mine, all already recorded here

- **A class name built by interpolation does not compile.** `lg:grid-cols-#{columns}` is invisible to
  Tailwind, so the first version rendered a grid with no columns - and the group *looked* fixed, because
  three years fit in one column anyway. `COLUMN_LAYOUTS` spells the three results out.
- **`str.replace` without an assertion silently no-ops.** The call site passing `columns` never matched on
  indentation, so the variable became unused, `rubocop -a` stripped the assignment, and the option was
  quietly discarded. Every edit in the fix asserts its match first.
- **Two of my measurement probes were wrong before the code was.** One targeted the wrong container and
  reported no change from any column count; another never passed its argument, so `arguments[0]` was
  undefined and the grid was never applied. A probe is code and can be wrong in the direction that
  flatters the thing being measured.

### What this breaks

- **`form_actions_test`'s rule changed deliberately.** It required the action row to be transparent - "it
  sits on the page" - which a sticky row cannot be, or the page scrolls visibly through the buttons. It now
  requires the row to match the **page's own background** or be transparent, and to be `position: sticky`.
  Read from `body`, not `main`: admin's main has no background of its own.
- **Nine action rows moved onto the shared class**, including the classroom and student forms. One did
  *not*: the nested "Add transaction" submit on `admin/students#_form` is a section's action inside a card,
  and sticking it would pin a sub-form's button over the page.
- **`admin/schools` offers three years, not every year.** A school already linked to others still shows
  them.

## The sticky action row's border is gone

Reported one commit after it shipped: the divider under the card and above the action buttons is not
anywhere else in the app. Correct, and it was wrong twice over.

**design.md rules it out by name.** The Dividers section says "no extra dividers anywhere", then lists the
four that stay - a tab rail's baseline, the fixed app bar's edge, a table's row separators, and field-group
separators *inside* a form card. A form's action row is not one of them, and nothing else in the product
draws that line. I added it to a shared class and rolled it out to nine forms in a single change, which is
the same shape as the ring this document already records: sweeping a component everywhere standardises
its drift instead of removing it.

**And it was a rule with nothing behind it most of the time.** The border only means anything while the row
is actually overlapping content. On every form shorter than the viewport, and on any form scrolled to its
end, it drew a hairline against nothing - the same conditional-affordance error as a pinned table cell's
separator, which was fixed earlier the same day by making it depend on scroll state rather than drawing it
always. My own comment in `forms.css` argued *for* the border on exactly the grounds that only hold in the
overlapping case.

The opaque page-coloured background is what stops text showing through the buttons, and it needs no border
to do it. Verified rather than assumed: with the border gone, `elementFromPoint` at the row's centre still
finds the row rather than what is beneath it, and the submit is still at y=569 of a 625px viewport.

`form_actions_test` now asserts `border-top-width` is `0px`, with the reason in the failure message, so the
line cannot come back quietly.

### What this breaks

- Nothing. 896 unit and 340 system runs pass.
- The lesson, restated because it keeps recurring: **a shared class is the fastest way to propagate an
  invention.** Check a new visual treatment against design.md's own spec *before* nine call sites adopt it,
  not after.

## A school's years are provisioned, not picked

Asked for a multi-select dropdown; built a list with an explicit add and remove instead, because measuring
the existing control turned up three defects rather than a layout problem.

**What the checkbox group actually did.** Each `SchoolYear` writes four quarters on create, so every box was
a provisioning action:

1. **Unchecking silently destroyed four quarters** along with the join. No confirmation, and nothing on the
   page said the quarters existed.
2. **Unchecking a year that had a classroom raised `PG::ForeignKeyViolation`** - a 500 - because
   `year_ids=` deleted the join before `restrict_with_error` could speak.
3. **Found while removing it:** `update` rebuilt `year_ids` by hand and defaulted it to `[]`. With the
   checkboxes gone, *every name edit* would have wiped the school's years and their quarters, or 500'd on the
   first one with a classroom. The tests caught that; nothing else would have.

**Why not a multi-select.** A native `<select multiple>` is the one control the field advises against:
GOV.UK says not to use it, and Polaris, Material and Carbon ship none - beyond a handful of options they use
a combobox with chips. And neither control addresses the real problem, which is that each option is a
create-or-destroy with dependents. What the field does for *this* is one explicit action at a time -
PowerSchool's per-school Years and Terms, Infinite Campus's per-year calendar.

**What is there now.** On the school's own page, a list row per year - the name, a "Current" badge, its
quarter count - with `Remove` where it is possible and, where it is not, the reason in its place: "In use by
3 classrooms". The confirmation states the consequence ("its 4 quarters will be deleted"). Below the rows, a
select of every year not yet added, newest first, the current one marked "(current)" in the option text
because an option cannot carry markup.

**The select carries the whole list rather than a window.** Twelve options in the seeded data. A window was
right for a checkbox group, which showed every option at once and put the submit below the fold; a select
does not have that problem, and inventing a range would make some years unreachable.

**One rule now lives on the record.** `SchoolYear` validates uniqueness of `[school_id, year_id]`, so a
double-submitted add is a message rather than `RecordNotUnique`. That made the old
`Admin::SchoolYearsController#create` much smaller: it looked the school and year up by hand, called
`create!`, and rescued the database error to synthesise a base message. The rescue is unreachable now and
the hand-built message was a second copy of one rule, so both are gone.

### What this breaks

- **`school_params` no longer permits `year_ids`**, and `Year.offered_for` / `around_current` are gone with
  the checkbox group. `Year.addable_to` replaces them; `current_school_year_name` and `current?` stay.
- **Six schools-controller tests were rewritten** against the new contract, and a new
  `school_years_controller_test` covers add, remove, the duplicate message, the refusal, cross-school
  scoping and a teacher being unable to do either.
- **The duplicate-message assertion changed** from `/already exists/` to `/already added to this school/`.
- Two of my own probes read a flash before the page had re-rendered, and reported a removal as not having
  happened when the row count proved it had. The count is the honest signal; a `#notice` read straight after
  a click is not.

## The years go back on the edit page

Reported: on the edit page "all the data on the years is completely disappeared. The only thing in the card
is school name."

Both halves of that are fair, and the second is the reason. Moving year management to the show page left an
edit page whose only editable thing was a text field - navigate, change one word, save, navigate back, with
the thing you came to change on another page. **A separate edit page is a Rails scaffold convention rather
than a design pattern**, and it earns its place for a long form, not for one field.

**And the explanation I left behind was an ERB comment**, which renders to nothing. So the card held one
field and twenty lines of reasoning only a developer reading the source would ever see. I also never loaded
the page after emptying it - I measured and screenshotted the *show* page repeatedly instead, which is the
rule about reading the page you are changing, broken on the page I was asked to fix.

`admin/schools/_school_years` is one partial with a `manage:` local: the edit page renders it with the add
and remove controls, the show page renders the same list read-only and points at the edit page for changes.
The controls sit *below* the form rather than inside it, because `button_to` renders a whole `<form>` and a
browser drops a nested one - the remove would silently submit the school form.

The add and remove actions use `redirect_back_or_to(edit_admin_school_path)`, so they return to whichever
page they were used from rather than to a hardcoded one.

### What this breaks

- Three schools-controller tests now visit `edit` rather than `show`, and the school-years tests expect the
  edit page as the fallback destination. A new test covers the `Referer` branch.
- **Still open, and asked for next:** whether this should be a *single* detail page holding both, which is
  what the field actually ships - Stripe's customer page, Linear's project page, Polaris's resource detail
  pages, none of which have a separate edit screen for a record with one attribute.

## Adopted: one shape for view, edit and create, on all nine admin resources

Answering the question the entry above left open. Built as `preview/single-detail-page`, previewed page by
page, then merged into `stocksdesign`.

**Every admin record now has one page.** `/admin/<thing>/:id` holds the record's attributes *and* its
collections, edited in place; `/admin/<thing>/:id/edit` renders the same template so every existing link and
redirect still resolves. The shape is declared twice, not nine times: `admin/shared/_record_page` (column,
breadcrumbs, page header, section stack) and `admin/shared/_record_section` (heading, hint, content). See
design.md, "A record's page edits in place", for the rules and the reasoning.

What came off each resource, in every case because the form already edited it:

| Resource | Removed | Moved to the summary line |
| --- | --- | --- |
| schools | - | (years lead the page) |
| stocks | eight read-only cards, six of them the form's own fields | price, daily change, holders |
| teachers | the Classrooms card - the form's `classroom_ids` group *is* that list | active state, classroom count |
| classrooms | the whole attribute card, and the Teachers card | grades, year, trading state, archived |
| school_years | the school and year rows, and the Quarters card - four is an invariant | classroom and quarter counts |
| portfolio_transactions | Portfolio, Transaction details and Description cards | user, date, originating order |
| users | - | - |
| announcements | - | - |
| students | `admin_show_attributes`, and a four-tile figure band | username, classroom, cash, total value |

**The students page was the ninth and the largest.** Its figure band's fourth tile held the portfolio's
**id**, rendered as a `text-2xl` KPI beside cash balance and total value; the useful part of it was that it
linked, so "View portfolio" is a header action. Its two "Portfolio details" cards (present and absent
branches) became one section with an empty state, its two tables moved onto `shared/table_container` - they
had been sitting on no surface at all inside a card - and each got `region_label`, because neither holds a
focusable element and a scroll container whose contents cannot be focused cannot be scrolled from a keyboard.

**One cash balance, not three.** Merging naively would have printed it in the summary line, in a tile, and
again as the transaction form's read-only "Current cash balance". The rendered page contains it once.

### What this breaks

- Controller tests asserting `h1` "Edit teacher" / "Edit school year" / "Edit student" now assert the
  record's name. Tests asserting a removed card's `h2` assert the field or the summary line instead.
- `admin/students#show` no longer emits `data-testid="cash_balance_label"` or
  `"total_portfolio_worth_label"`: those tiles are gone and the figures are in the summary line.
- Every path that renders a record page must load what that page reads. There are three - show, edit, and a
  failed update - and `Admin::StudentsController#load_record_page` is the shape. Missing one is a
  NoMethodError on nil, found twice during the conversion.
- A merged page renders for an **invalid** record, so anything its header reads must tolerate nil
  associations. `SchoolYear#name` raised from a page title while the form was trying to show a validation
  message.
- **Still inconsistent, and not part of this change:** six of the nine create pages are still `max-w-7xl`,
  `max-w-4xl` or `max-w-2xl`. Three (schools, students, portfolio_transactions) are on the record shape.
- **Still open:** every admin index row has an "Edit" action that now leads to the same page as the row's
  name link. That is the argument that removed "View", applied to nine indexes.

## `portfolios/_earnings_summary_card` is now `shared/_earnings_breakdown`

The same figures were rendered by a card on the student's own portfolio page and by a hand-written table on
the admin record page, and **the two disagreed about the numbers**. The admin copy listed Attendance, Math
and Rewards and then printed `total_earnings_cents`, which also includes reading: on the seeded student that
is $650.00 of rows under a $1,150.00 total, with the missing $500.00 named nowhere on the page.

One partial, rendered by both, with `title` and `subtitle` optional so the admin page's section heading is
the only heading. It also gains an empty state: an all-zero breakdown with a red "-$0.00" among six $0.00
rows says nothing, so a student who has not been paid yet gets a sentence naming what pays them.

### What this breaks

- `app/views/portfolios/_earnings_summary_card.html.erb` is deleted. `portfolios#show` renders
  `shared/earnings_breakdown` with the student-facing copy.
- The admin page's rows are now `dt`/`dd` in a `dl`, not `td`s, and the labels match the student's page:
  Attendance, Reading, Math, Rewards, Total earned, Transaction fees.

## The transaction fees line counts fees

**Money display, not money arithmetic.** `EarningsSummary#transaction_fees_cents` summed
`portfolio_transactions.deposits.where(reason: :transaction_fees)`, and `TransactionFeeProcessor` writes a
fee as `transaction_type: :fee`. So the line read **-$0.00 for every fee the app has ever charged**, on the
student's own portfolio page as well as the admin one. The balance was never affected:
`Portfolio#total_fees` uses the `fees` scope and has been charging them correctly all along.

The fix sums by **reason alone**. Everything else in that class stays on `deposits`, deliberately: earnings
are deposits by definition, and a later debit tagged `math_earnings` should not reduce what a student
*earned*.

**Widening `Portfolio#total_fees` to match would have been the wrong direction and would have moved money.**
The balance counts a deposit as a credit, so a legacy row that is a *deposit* labelled `transaction_fees`
would then be added as a credit and subtracted as a fee. A display sum can be generous about how a fee was
recorded; the arithmetic cannot.

**The seed was the reason nobody noticed.** `db/seeds/partials/portfolio_transactions.rb` created a
**deposit** of $25.00 tagged `transaction_fees` - a shape nothing in the app can produce - and it was the
only row in a seeded database that matched the wrong query. So the page showed a plausible -$25.00 while
every real fee was excluded. The seed now writes a fee as a fee, at `TRANSACTION_FEE_CENTS`.

### What this breaks

- On a seeded development database the fees line changes: it now includes both the mislabelled $25.00
  deposit already there and the real $1.00 fees, so student 1 reads -$27.00 rather than -$25.00. A freshly
  seeded database reads -$1.00.
- `earnings_summary_test` keeps its existing case (fees built as deposits still count) and gains one that
  runs `TransactionFeeProcessor` and asserts the summary and `Portfolio#total_fees` agree. The old test
  could not fail: it built its fixture the same wrong way the query read it.

## An admin cash adjustment is a `CashAdjustment`, and money is parsed exactly

The four fields on the student page's money form were loose params - `transaction_type`, `add_fund_amount`,
`transaction_reason`, `transaction_description` - validated in the controller and reported by redirecting
back with `alert:`. Three consequences, and the third is the reason this is here rather than in a styling
commit.

**`(amount.to_f * 100).to_i` was the parse.** Measured across every typed amount from $0.01 to $1000.00,
**4,586 of the 100,000** stored the wrong number of cents, always one low - $0.29 deposited 28 cents. That
is the float round trip CLAUDE.md and design.md both forbid, in the one place a person types money into this
app. `BigDecimal` is exact.

**And a blank check could not see a bad value.** `"abc".to_f * 100` is `0`, which is not blank, so a typo
saved a $0.00 transaction and reported success. `"-50"` was a negative deposit. An amount past the integer
column raised `PG::NumericValueOutOfRange` - a 500 from a typo in a text box.

**The message was in the wrong place and the form was emptied on the way.** Errors now land against the
fields, and a rejected adjustment re-renders the record page with what was typed still in it.

### What this breaks

- The request shape changes: `cash_adjustment[transaction_type]`, `[amount]`, `[reason]`, `[description]`.
  `add_transaction` renders `:show` with a 422 instead of redirecting to `/edit` with a flash.
- `admin.students.add_transaction.errors.*` is deleted - `CashAdjustment` carries the messages - and so is
  the never-reachable `students.add_transaction` locale block.
- The reason picker no longer offers `grade_earnings`, which the model marks deprecated, and the validation
  rejects it.
- The amount is a text input with `inputmode="decimal"`, not a `number_field`. GOV.UK's money pattern: a
  number input carries spinners, changes on a stray scroll, and silently rejects a pasted "$12.50".
- **Unchanged and worth a decision:** a debit may still take a balance negative. Nothing blocks it, and
  nothing did before; fees can already do it, since the trading fee is charged without checking the balance.

## A student needs a classroom, and the list survives one without

`belongs_to :classroom` is `optional: true` on `User`, because a teacher or an admin has none. Nothing
required it of a **student**, while the admin form's own hint read "Classroom assignment (required)" and its
select offered a blank. Saving that blank was accepted, and `admin/students#index` renders
`student.classroom.name` - so one classroom-less student returned a 500 for the whole list.

`validates :classroom_id, presence: true, on: :student_form`, the same context as the name requirement, so
CSV import and the seeds are unaffected. The index cell is nil-safe, with `format_attribute`'s em dash, for
the students who predate the rule.

### What this breaks

- Creating or updating a student through either form with no classroom is now a 422 with the error on the
  select. `create(:student, :without_enrollment)` still works: the factory does not use the form context.
- The admin form marks `username` and `classroom_id` `required: true`, so both labels carry an asterisk. The
  teacher-facing form always did.

## A form that has just been rejected keeps its save button

`form_dirty_controller` hid an update form's action row until a field changed, and a re-rendered form arrives
with no dirty flag - so blanking a required field and pressing Update produced a page reading "1 error
stopped this student being saved" with **no Save button**, and the only way to try again was to type in a
field. It now skips any form containing an error summary or a `.field_with_errors`, per form, so a rejected
transaction does not reveal the account form's row beside it.

`form_actions_test` asserts both halves; verified by removing the guard and watching it fail.

## The student record page is bounded: five transactions, and the money form closed

Asked whether combining view and edit is what made the page a long scroll. Measured, and it is not: the same
blocks were 1974px + 1510px across two pages and are 2958px on one, so merging removed 526px. What it did was
concentrate the length, and two sections were carrying half of it.

| Section | Was | Now |
| --- | --- | --- |
| Details | 474px | 474px |
| Add a transaction | 728px, always open | folded into Transactions, closed |
| Earnings | 331px | 331px |
| Transactions | 739px, every row | 447px, five rows |
| Attendance | 298px | 298px |
| **Page** | **2958px, 3.9 viewports** | **1914px, 2.5 viewports** |

**The transaction list is the only thing on that page with no ceiling.** 13 rows measured 739px; a year of
weekly trading is about 150 rows, which is roughly 7,400px. It shows `RECENT_TRANSACTIONS` - five - then
"Showing 5 of 13" and a link to the full list.

**So the full list had to become reachable.** `admin/portfolio_transactions#index` takes `?user_id=`, says
whose transactions it is showing, and offers "Show all transactions". An id matching nobody is ignored rather
than rendered as an empty filtered list, and the notice is driven by the same object that applied the filter,
so the page cannot claim a filter it did not apply.

**And a filter had to survive being sorted.** `sort_link` built its URL with `url_for(sort:, direction:)`,
which rebuilds the path from the current controller and action and drops every other query parameter - so
sorting `/admin/students?discarded=true` silently returned the *active* list. Every admin index with a filter
had it. It merges `request.query_parameters` now. While fixing it: `sort_link` and `sort_icon` were defined
**identically** in `AdminHelper` and `ApplicationHelper`, and since Rails mixes every helper into one view
context, which copy answered depended on include order. There is one, in `ApplicationHelper`.

**The money form is a `<details>`, closed until asked for.** Stripe's "Adjust balance" is a button for the
same reason: an occasional write should not cost everyone 728px of scroll. `dropdown_controller` had already
settled the mechanism for this app - a native disclosure works without JavaScript - and it solves the case a
hand-rolled panel gets wrong: a rejected submit re-renders the page, and the panel comes back open with the
values in it because `open` is server-rendered.

### Two reflow failures found on the way, both invisible to the existing checks

**A card clips what it cannot fit, so the page never scrolls.** `.tw-card` is `overflow-hidden`. At 320px and
200% text the earnings breakdown's figures sat up to **89px past their card's edge**, cut in half, with
`document.scrollWidth` reporting no overflow at all - so `reflow_test` passed. Its rows wrap now, and a new
test compares each figure's box against its **card's** box rather than the page's. That test only works
because its fixture has real money in it: with zeros the card renders an empty state, which is why the
populated rows had never been rendered by any test. The student-pages fixture now has earnings for the same
reason.

**`.tw-btn-*` was `h-10`, a fixed height.** At 200% text a label long enough to wrap is cropped by its own
button, and "Add a transaction" was the first label in the product long enough to find it. The base is
`min-h-10 py-2`, which measures the same 40px at every size this app renders - `form_actions_test` still
asserts 40 - and grows instead of cropping. An `inline-flex` control whose label can be long also needs
`max-w-full`, because an inline-flex box is sized by its own content and nothing else bounds it.

### What this breaks

- `admin/students#show` no longer has an "Add a transaction" section; its headings are Details, Earnings,
  Transactions, Attendance. A test clicking the money form's submit has to open the disclosure first - which
  is why the summary reads "Add a transaction" and the submit "Add transaction" rather than both the same.
- `@transactions` is now five rows, not all of them, and `@transactions_count` is the total. Anything reading
  `@transactions.size` as a count is wrong.
- `sort_icon`'s unit tests moved from `admin_helper_test` to `application_helper_test` with the method.
- Every button in the app is now `min-h-10 py-2` rather than `h-10`. Identical at normal text; a long label
  wraps and the button grows.

## Every admin index fits at 1024px

Measured at Tailwind's `lg` minimum, where the sidebar leaves a table a **718px** scroller and every column
hidden below `lg` reappears at once: `admin/stocks` wanted 927px, `admin/teachers` 895px, `admin/users` 853px
and `admin/classrooms` 795px, so the trailing actions column was off screen on four of the nine indexes. It
showed at neither 1366px nor 375px, which is why two existing tests both passed.

Fewer columns, not a third breakpoint:

| Removed | Why |
| --- | --- |
| `ID`, from all seven indexes that had one | 62px, and it is in the URL of the link in the same row |
| teachers' `Username` | `Teacher#sync_username_from_email` sets `username = email`, so it printed the same string as the Email column. The **name** leads that table now |
| teachers' `Created at` | metadata, and the record page's summary line is where metadata goes |
| users' `Admin` | a yes/no badge beside a `Type` column that said "User" for the one account that can do everything. `Type` reads `account_role_label` now |
| stocks' `Website` | 185px, already reduced to a host, and it is a field on the stock's own page |
| classrooms' `Archived` + `Trading enabled` | two yes/no columns, 236px, answering two questions with "Yes". One `Status` column now, stating the state in words |

**Stocks keeps `Archived`.** `#index` lists `Stock.all`, so it is the only thing distinguishing an archived
row - and dropping the id and the website was enough by itself.

**Two tables needed a wrapping fix as well as a column cut.** An email is one unbreakable token, so it sets a
cell's min-content width and the table sizes to it. `break-words` does **not** change a min-content
contribution; `overflow-wrap: anywhere` does, which is Tailwind's `wrap-anywhere`. `admin/users` was 58px over
with the first and 0px with the second.

### What this breaks

- Sorting classrooms by `archived` or `trading_enabled` is gone: one derived `Status` column replaced both.
  With no archived filter on that page, sorting was how you grouped them - filter tabs are the better answer
  and are recorded in design-todo.
- `admin/shared/_table` no longer has its "skip a leading id column" fallback for choosing the primary
  column, because no caller passes an id.
- The teachers list links from the **name** rather than the username, falling back to `display_name` for a
  teacher who has none.
- `table_actions_reachable_test` gains the 1024px assertion, and its wide-classrooms fixture needed longer
  data - with ordinary data that table now fits, which would have made the not-pinned test vacuous.

## Required fields are marked, and a currency field stops rendering two labels

Reported: on the new portfolio transaction page nothing said which fields were required, and "amount says
amount in dollars then there is another subheader amount cents".

**The second one was a bug in the builder, not the form.** `currency_field` called `field_wrapper`, which
deletes `:label` from the options and renders it, and then called `number_field`, which wraps *again* and -
finding no label left - fell back to the humanized attribute name. Three fields across two forms rendered two
labels each: Amount / "Amount cents", Current price / "Price cents", Yesterday's price / "Yesterday price
cents". `currency_field` delegates to `number_field` now, so there is one wrapper, one label, one hint and one
message.

**And the marks were missing from half the product.** Nine of eighteen forms marked nothing: schools,
school_years, stocks, teachers, users, announcements, portfolio_transactions, the admin cash adjustment, and
the reset-password and profile password forms. Each now passes `required: true` for exactly the fields its
model requires - the red asterisk on the label plus `required` on the control, which is what assistive
technology announces.

Two decisions inside that sweep:

- **Conditional requirements are marked conditionally.** `User#email_required?` is false for a student, so the
  profile's email field passes `required: current_user.email_required?` rather than being marked always or
  never.
- **A mark needs a validation behind it.** `PortfolioTransaction` validated neither `transaction_type` nor
  `amount_cents`, both `null: false` columns - so the admin's "New transaction" form answered a blank submit
  with `ActiveRecord::NotNullViolation`, a 500 rather than a message beside the field. Both are presence
  validations now. Presence only: an amount of zero is rejected on the path a person types on
  (`CashAdjustment`), not on a model that services write to with their own arithmetic.

### What this breaks

- `PortfolioTransaction` now rejects a blank `transaction_type` or `amount_cents`. Every writer in the app
  already sets both - `ExecuteOrder` through the `.debit` / `.credit` scopes, `TransactionFeeProcessor`
  through `.fees`, `DistributeEarnings` and `CashAdjustment` explicitly - and the factory sets both too.
- A currency field's markup changes: one label element instead of two, and the second `mb-6` wrapper is gone,
  so the field's spacing matches every other field rather than being double.
- `test/integration/required_fields_test.rb` asserts the pairing per page. It fails if a required field loses
  its mark **or** if an optional field gains one, which is the half that keeps the asterisk meaning something.

## One form measure, and fields sized to their content

Reported twice in one turn: "the new transactions card width is different from the other editable pages" and
"cards for new students and new teachers are different widths, what is industry std because some of these look
very wide". Both were true, and they are two different problems.

**Five measures existed.** Measured at 1366px on the input rather than the wrapper, because the wrapper is
often the layout's `max-w-7xl` and says nothing:

| Measure | Pages |
| --- | --- |
| 384px | the three auth pages - deliberate, and kept |
| 630px | app-side classrooms#new/#edit, the teacher's students#new, profiles#edit |
| 726px | the nine record pages, plus schools#new, students#new, transactions#new |
| 854px | announcements#new |
| 1020px | school_years#new, teachers#new, users#new, stocks#new - no column of their own at all |

Every page that holds a form or a record is now **`max-w-3xl`, 768px**: the record pages already were, and a
create page cannot be a different width from the record it creates. The six create pages that hand-rolled a
column now render `admin/shared/_record_page` - the same shell the record page uses, with no lifecycle actions
and one Details section - so the two cannot drift again. The auth pages keep 384px, which is a different page
type and what Stripe, GitHub and Linear all do.

**And a column cannot fix "looks very wide".** In a 768px column a `w-full` input is a 726px box for a
two-letter ticker. `Ui::FormBuilder::FIELD_WIDTHS` adds four sizes - 128px, 192px, 384px, full - and 38 fields
now name one. GOV.UK ships exactly these modifiers and states the rule; Tailwind UI spans 2 to 6 of 12 columns
per field; Polaris pairs short fields rather than stacking full-width ones. Measured on the stock form after:
ticker 128px, employees 128px, every price and ratio 192px, company name and industry 384px, website and the
two textareas still 726px.

### What this breaks

- `admin/school_years/new`, `teachers/new`, `users/new`, `stocks/new`, `announcements/new`, `schools/new`,
  `students/new` and `portfolio_transactions/new` all render through `admin/shared/_record_page` now. A test
  asserting one of those pages' wrapper class rather than its rendered width would need updating; none did.
- App-side `classrooms#new/#edit`, `students#new/#edit` and `profiles#edit` moved from 672px to 768px.
- `width:` is a new builder option, and an unknown value **raises** rather than rendering full width, so a
  typo fails loudly.
- design.md's form-measure rule said `max-w-2xl` and its person-edit shape said the same; both now say 768px.
  The table-cell field-width note is generalised: a field is sized to its content in a form column too.

## A form is a two-column grid, and the field sizes are gone

The commit before this sized fields with four `max-w-*` values. Asked for the grid rule instead - "the short
fields should be half the size of the container and half the size of the padding were there another field
beside it in a two column format" - which is both what was wanted and the mainstream one.

`.tw-form-grid` is `grid-cols-1 gap-x-6 gap-y-0 lg:grid-cols-2`, so a short field is **351px** of a 726px card
at 1366px - half the content box less half the gutter - and two short fields pair. `gap-y-0` because the
vertical rhythm is already each field wrapper's `mb-6`; `grid-cols-1` below `lg` because two 163px fields on a
phone is a squeeze, not a pair.

`FIELD_WIDTHS` became `FIELD_SPANS`: `width: :half` is one cell, `:full` is both, the default is `:full` so an
unconsidered field keeps the width it has, and an unknown name raises.

**The two rules this chooses between.** Sizing an input to its **content** is GOV.UK's, and a minority
position taken for error prevention in transactional government forms. Sizing it to its **grid cell** is
Tailwind UI (2 to 6 of 12 columns), Polaris's `FormLayout.Group`, Carbon, Material and Bootstrap. Content width
survives in this app only where a value is genuinely tiny - the grade book's 96px table cells.

### What this breaks

- `collection_check_boxes` now always renders `lg:col-span-2`, in the builder: a group of checkboxes lays its
  own boxes out in columns and is never half a card. Outside a grid the class does nothing.
- Field groups - the password blocks, the stock form's six sections - are grids themselves with
  `lg:col-span-2`, and their headings and helper paragraphs span. A group left as a plain child would have
  rendered its whole contents in a 351px cell, which is how this was found.
- `classrooms/_form` lost `space-y-5` for the grid. That spacing was already inert: 20px of `space-y` against
  each wrapper's 24px `mb-6`, collapsed to 24px.
- `profiles#edit`'s two forms carry `.tw-form-grid` in place of `class: "contents"`, and their error summaries
  and submit rows span.
- `form_actions_test`'s disclosure threshold moved from +400px to +200px, because the money form now opens
  331px rather than 720px - its fields pair. `page_width_test` asserts 351px cells and that the second field
  of a row starts one cell plus one gutter along, which is the part that says "paired" rather than merely
  "narrow".

## A create page stops repeating itself, and a password stops vanishing

Reported on `students#new`: "the details subhead pushes the content down and doesn't seem to add value", and
the description "You can add money and see attendance once the account exists" is badly written.

**Both were mine, and both were right.** A record page has four sections, so "Details" says which one you are
in; a create page has one, so the heading repeated the h1 a line above and its hint - "Saved when you press
Create student" - repeated the button. Measured: the card sat at **y=304** with the subhead and **y=244**
without, on a 768px-tall viewport. All eight create pages render the heading `sr-only` now, so the section
keeps its accessible name and nothing is drawn twice, and `_record_section` drops the content's `mt-3`
alongside an invisible heading rather than leaving 12px of gap under nothing.

**The description described other pages.** It told somebody filling in this form what they could do on two
*different* screens, in the passive. What is not on the page is what submitting does: the account works
immediately, and a blank password field means one is generated and shown once. It now says so.

**Writing "shown once" honestly required a fix.** That password appears in the success flash - and the success
flash auto-dismisses after six seconds, which meant the only copy of a generated credential deleted itself
while the admin was reading the page behind it. `MemorablePasswordGenerator` hands it to the flash and nothing
stores it, so the recovery was another reset. Four notices carry a password - `admin/students#create`,
`students#create`, and both password regenerations - and all four now set `flash[:sticky]`, which makes
`layouts/_flash` omit the `auto-dismiss` controller.

### What this breaks

- `layouts/_flash`'s notice is built with `tag.div` rather than a literal, because the data attributes are now
  conditional and an interpolated optional attribute renders unquoted, which no selector matches.
- `flash[:sticky]` is a new flash key. Nothing iterates the flash, so it renders nothing on its own.
- Four redirects moved from `notice:` to `flash: { sticky: true, notice: … }`.
- `admin_page_structure_test` asserts that a create page's section heading is `sr-only` and a record page's is
  not, and that no create page carries a "Saved when you press…" hint. `flash_dismiss_test` asserts a
  password notice is still on screen past the delay **and** that it never carried the controller - verified by
  putting `auto-dismiss` back and watching it fail.

## The other create pages' descriptions, checked

Asked to check the rest for what students#new had. Two were the same defect and four had nothing to say.

**Narration, not information.** `schools#new` read "You will add its school years after it exists" - the same
shape as the students one, telling a reader what they would do on a *different* page. It now states the fact
behind that advice: nothing can use a school until it has a school year, because a classroom belongs to the
year rather than to the school. `stocks#new` read "Only the ticker is required. The rest can be filled in
later", whose first half is what the asterisks say now that required fields are marked, and whose second half
is narration again. It says what the ticker is *for*: the price feed looks it up, prices refresh each weekday
and the company details weekly, so most of that nineteen-field form fills itself in - `StockPricesUpdateJob`
on `0 2 * * 2-6` and `StockAttributeUpdate` weekly, both verified in `config/recurring.yml`.

**Four pages had no description**, and each had a fact worth having, each checked against the code rather than
assumed:

| Page | Description | Verified by |
| --- | --- | --- |
| teachers | a temporary password is generated and a reset email goes to this address | the line that used to sit below the last field |
| users | type decides what the account gets: a student is given a portfolio, a teacher signs in with their email | `User.new(type: "Student")` instantiates the subclass, so `ensure_portfolio` runs - checked in a console |
| announcements | only the featured one is shown, on the home page everybody lands on | `Announcement.current` is `find_by(featured: true)`, and `home#index` renders it |
| portfolio_transactions | a balance is the sum of these rows, so saving this moves the money | `Portfolio#cash_on_hand_in_cents` |

**And two things found while checking.** The teachers form stated its password behaviour **twice** - in the
new description and in a line below the last field - so the in-form line is gone; what happens on submit
belongs where it is read before the reader starts typing. And a teacher created through the *users* form has
their typed username silently replaced by their email, because `Teacher#sync_username_from_email` runs
`before_validation`: measured in a console, "typed_by_hand" came back as the email address. That is now in the
username field's hint rather than being a surprise after saving.

### What this breaks

- `admin/teachers/_form` no longer renders the temporary-password line. A test asserting that sentence inside
  the form would need to look at the page header instead; `admin_page_structure_test` asserts it appears
  **once** on the page.
- `admin_page_structure_test` also asserts every create page's header carries a description, matched on the
  fact each one is supposed to state. Scoped to the header's own paragraph, because a field hint further down
  uses the same type classes - the announcements page has one that also says "featured".

## The edit pages' hints, and two things the audit turned up

Asked to check the edit pages for what the create pages had. For eight admin resources "edit" *is* the record
page, so the equivalent of a description is the section hint - and the same two defects were there.

**"Saved when you press X" repeats the button** wherever a page has only one write. It is justified on
`schools` and `students`, where a second control applies immediately and the pair distinguishes them - the
years there say "Changes here apply immediately" - and it was noise on `school_years` (dropped),
`portfolio_transactions` (now "A balance is the sum of these rows, so changing this moves money") and `stocks`.

**`stocks` also carried the app's own history**: "Grouped as they were on the old read-only cards", which
means nothing to anybody who did not work on this branch. It now says what a reader needs: prices refresh each
weekday from the ticker and the company details weekly, so most of what you type there is replaced at the next
update.

**Two record pages had no summary line at all** - `users` and `announcements`, the odd two of nine.
`user_summary` gives the role through `account_role_label` (an admin is a `User` row with `admin: true`, so the
type column reads "User" for the account that can do everything) and `announcement_summary` states the only
thing about an announcement that changes what anybody sees: whether it is the featured one, which is the one
`home#index` renders.

**`profiles#edit` lost its description**: "How your name appears, and your password" is what its two section
headings already say.

### A behaviour bug found while looking for copy

`classrooms#show`'s hint read "Changes apply to everyone who can see this classroom", which is vague, so I
went looking for the consequence worth stating - and found that **moving a classroom to another school year
left its grade books behind**. `create_gradebooks_for_quarters` was `after_create` only: measured, a classroom
moved from year 1 to year 2 still had four grade books on 1/Q1..1/Q4, so the year it had just been moved into
had none and a teacher had nowhere to enter marks. It now runs on update too when `school_year_id` changes.
The old books stay - they hold entered grades and, once finalized, money already paid - and `find_or_create_by!`
means moving back and forth adds nothing twice. The hint says the consequence now that it is true.

### And the two the last audit turned up

- **The teachers form's duplicate sentence** is gone, and `admin_page_structure_test` asserts it appears once.
- **The users form no longer offers a username a teacher's email will overwrite.** `derived_field_controller`
  watches the Type select and makes the username read-only when Teacher is chosen - read-only rather than
  disabled, because a disabled field is skipped by keyboard navigation, which is the decision the profile
  page's username already records. Measured: choosing Teacher sets `readOnly` and the slate fill, choosing
  Student or User clears both, and typing while it is derived leaves the value empty.

### What this breaks

- `admin/users/_form`'s type select now takes its options and html options as two hashes, because it needs
  `data-action` on the control.
- Three section hints changed and one was removed; `users#show` and `announcements#show` gained a description.
- `classroom_test` gains three cases for the grade books: they follow a move, the old year's are kept, and
  moving back adds no duplicates.

## The show pages, checked

The eight admin "show" pages **are** the record pages audited in the entry above - `/edit` renders the same
template - so what was left unchecked was the app side: home, the portfolio, the trading floor, a stock, the
transactions list, a classroom, a grade book.

**Most of it was already right, and for a reason worth recording.** The trading floor says "Prices are updated
once a day, after the market closes. These are as of August 06, 2026"; the grade book's hint interpolates
every rate from `GradeEntry`'s constants; the classroom's grade-book section says "Recording attendance and
grades is what pays students their funds to invest". Each states a fact the reader cannot see and would act
on, which is the test.

**Two did not.**

`orders#index` had **no description at all**, on the page whose one recurring question is why a row still says
pending. It now answers it: orders are filled every 15 minutes - `OrderExecutionJob` on `*/15 * * * *` - and
until one is, no money has moved, because `ExecuteOrder` writes the debit at execution. Only the trading fee
is set aside, by `Portfolio#pending_transaction_fee`, and that figure is interpolated from
`TRANSACTION_FEE_CENTS` rather than typed.

`portfolios#show` described itself with the **school's name**, under a heading that already names the student.
Nobody acts on it. It now says why the number holds still: share values use the last closing price, updated
once a day. `Portfolio#school_name` had no other caller and went with it.

**`home#index` keeps its warmth deliberately.** "This is your launchpad to earn, invest, and grow" says
nothing factual, and on any admin page it would be cut - but design.md has a whole section on delight for the
student side, the audience is eleven, and a welcome is what that page is for.

### What this breaks

- `Portfolio#school_name` is gone. Nothing else used it; `SchoolYear#school_name` is a different method and
  stays.
- `derived_copy_test` asserts that the two rates quoted in copy come from their constants - it re-quotes the
  fee with the constant changed and expects the page to follow. A figure typed into copy passes the first
  test and fails this one.

## The index pages, checked

Nine admin indexes plus the three app-side lists. **The headline finding is that most of them were right to
say nothing**, and the correction to the create pages - which said too little - is not a description on every
page. A table of students does not need a sentence explaining that it lists students.

Three had a fact a reader cannot see, and now state it:

| Page | Description |
| --- | --- |
| users | "Every account there is, including the students and teachers that have their own pages in the sidebar." |
| stocks | "Prices refresh each weekday after the market closes, and this list holds archived stocks as well as active ones." |
| portfolio_transactions | "Every movement of money in the app. A student's cash balance is the sum of their rows here." |

The other six keep an empty description, and the test asserts that too, so "add one everywhere" fails as
loudly as "add none".

**Two defects in the empty states**, which are the only content on the page at the moment they show:

- `portfolio_transactions` said "withdrawals when a student trades". Trading writes a **debit** or a
  **credit** - `ExecuteOrder` uses those two scopes - and nothing in the app creates a `withdrawal` outside
  the admin form and the seeds. The copy named a transaction type the reader would never see from trading.
- "finalised" appeared three times against 42 American spellings, including the grade book's own **Finalize
  grades** button. One spelling now.

### What this breaks

- `admin_page_structure_test` gains a test that names which three indexes carry a description and asserts the
  other six carry none.

## Short fields stack again, at one column's width

"Were there another field beside it" is the subjunctive. I read it as an indicative and built a two-column
grid, which paired the fields; the width was right and the layout was not.

`.tw-form-grid` is gone. `width: :half` puts `.tw-field-half` on the **control** -
`max-width: calc(50% - 0.75rem)`, half the card's content box less half of a 24px gutter, so 351px of 726px -
and the fields stack one per row. Measured on `students#new`: five controls, all at `left=448`, tops 321, 445,
569, 794 and 918, three of them 351px and the classroom select full width.

On the control rather than the wrapper, so the label and the hint keep the full measure. That is also where
GOV.UK puts its width modifiers.

The grid took wrappers, spans and a `contents` form with it: the field groups are plain divs again,
`collection_check_boxes` no longer forces a span, and `profiles#edit`'s two forms are back to `class:
"contents"`.

### What this breaks

- `page_width_test` asserted that the second field of a row started one cell plus one gutter along. It now
  asserts the opposite property - one left edge for every control, and no two sharing a top - which is what
  distinguishes stacked from paired.
- `form_actions_test`'s disclosure threshold stays at +200px: the money form is taller stacked, so the margin
  only gets safer.

## Every empty state, photographed - and one of them was lying

Asked for previews of the empty states. They cannot be seen any other way: an empty state renders only when a
list is empty, and every development database has data in every table, so the screen a first-time admin or a
brand-new student meets is the one nobody has looked at.

`empty_state_preview_test` builds each condition, asserts a title, a body of at least 30 characters and no
"No X found" phrasing, and with `PREVIEW=1` writes `public/preview/empty-*.png`. Eleven states.

**It found a defect on its first run.** With nothing archived, `admin/students?discarded=true` said:

> **No students yet** - Add students one at a time, or import a whole classroom from a CSV. [New student]

There are students; none are archived. The sentence is false and the action would put nothing in the list
being looked at. Same on teachers and users. `archived_empty_state` now owns that sentence - "No archived
students. Archiving a student is reversible and keeps everything attached to it. The ones you archive appear
here." - with no action inside the empty state. The page header's New button stays, because creating one is
always available.

**And `admin/users` has no unfiltered empty state at all**: you are signed in as a user to see the page, so
that branch cannot render. Its empty state exists only on the Archived tab.

### What this breaks

- `components/ui/_empty_state` carries `data-testid="empty-state"` on both variants, which is how the preview
  test finds them.
- Three index views branch on `current_discard_filter` for their empty row.

## An index page has no breadcrumb trail

Reported: the top-level admin pages all carry a breadcrumb that pushes the content down and adds nothing.

Measured, and it was worse than decorative: `admin/classrooms` rendered **"Dashboard > Classrooms"** directly
above an `h1` reading "Classrooms", so the page named itself twice 30px apart, and the trail's one link went
to a Dashboard the sidebar already lists. The cost was 44px - a 20px nav plus its 24px margin - which took the
h1 from y=128 to y=172 on a 768px viewport, on all nine indexes.

`admin/shared/_breadcrumbs` now returns early when there are fewer than two crumbs, so the rule lives in the
partial rather than at nine call sites. Record and create pages keep their trail: "Dashboard > Students > Sam
Student" has a Students to click.

### What this breaks

- `admin_page_structure_test` asserts no index renders a `nav[aria-label=Breadcrumb]` and that a record page
  and a create page both do, with a link back to the list.
- `spacing_test` carried a comment saying "admin index and show pages put breadcrumbs above the header";
  corrected to record pages.

## A teacher can hold classrooms in two schools, and the form stopped destroying the second

Asked whether a teacher can be assigned to more than one school, because "School filter" does not make sense
on that page. Three answers, and the first one is a bug.

**Yes, and the form guaranteed otherwise.** `teacher_classrooms` has no school constraint, so a teacher can
hold classrooms anywhere. But `set_form_data` narrowed the checkbox list to one school, the group is the whole
of `classroom_ids`, and `update` assigns what was submitted - so the other school's classroom was removed.
It needed no interaction at all: the filter defaults to the school of the teacher's *first* classroom, so
opening the page and pressing Update did it. Measured in a console - "A room, B room" in, "A room" out.

The scope now unions the teacher's own classrooms into whatever the filter shows, so a ticked box is always
rendered and therefore always re-submitted. Two controller tests cover it, and both fail against the old
scope.

**"School filter" was the wrong name in the wrong place.** It sat between the teacher's name and their
classrooms, labelled like an attribute of the teacher - which school do they belong to? - and a teacher
belongs to classrooms, not to a school. It is inside the group it filters now, labelled **"Show classrooms
from"**, with a hint saying it changes nothing about the record and that anything already assigned stays
listed. GOV.UK and Polaris both place a filter with the list it narrows rather than in the field order.

**And the description moved onto the field it was about.** "A temporary password is generated and a reset
email goes to this address" is a fact about the email field, met in the page description before there is an
address to read it against. The email hint now reads "They sign in with this, and their temporary password and
setup link are emailed here", and the description carries what a reader of *this page* actually wonders: a
teacher is assigned to classrooms rather than to a school, and can hold them in more than one.

### What this breaks

- `set_form_data` returns a union when a school filter is applied, so the classroom list can contain a
  classroom from outside the selected school. That is the point: it is one the teacher already has.
- `admin_page_structure_test` matched the teachers description on /reset email/; it matches the multi-school
  sentence now, and its "stated once" test still passes because the sentence moved rather than multiplied.


## Four mechanical items from the record-page adoption

Four things the design-todo listed as "known and not done". None needed a decision, all four were one file
to a few, and they are grouped because they share a cause: the single record page changed what a row and a
page are for, and these are the places that had not caught up.

**1. Every index row's `Edit` is gone.** With view and edit merged it pointed where the row's name already
points, which is the argument that removed `View` from all nine indexes a fortnight earlier. Removed from
`admin/shared/_table_row_actions` (schools, stocks, announcements) and from the six indexes that write their
own actions - classrooms, portfolio transactions, school years, students, teachers, users. Every row still
has at least one action: `Delete`, or the archive/restore pair, which is the point - what stays on a row is
what a link cannot do.

The **app** side keeps its `Edit`, deliberately. `classrooms#index` links a name to the roster at
`classroom_path` and `edit_classroom_path` is a separate form page, so the two controls go to two places.
The rule in design.md is the destination, not the label.

**2. `_record_page`'s docstring says what the nine pages do.** It read "a collection first where there is
one, because that is what the page is for" - the school page's reason generalised into a rule, written on
the partial that renders the eight pages doing the opposite. Eight lead with Details; `schools#show` leads
with its years, and the measurement behind that (Details above them put the years at y=618 of a 625px
viewport) is quoted in the docstring now.

**3. `admin/users` renders one empty state instead of two.** The unfiltered branch could not fire: the
viewer is a `User` and is not archived, so the Active and All tabs always contain at least the admin reading
the page, and that index has neither search nor pagination to empty them. It claimed "No users yet" and
offered a New button for a state the app cannot be in. The Archived branch is all that is left there.

**4. `admin/classrooms` has the three archive tabs.** Since two badge columns became one derived `Status`,
sorting by `archived` was gone and nothing replaced it, so archived classrooms sat among the live ones with
no way to group them. It now renders `admin/shared/_discard_filter_tabs` with the same labels and the same
`?discarded=true` / `?all=true` params as students, teachers and users, plus the `archived_empty_state`
sentence for an empty Archived tab.

`Classroom` archives with a boolean rather than `discard`, so `scoped_by_discard_status` does not apply;
`filtered_classrooms` maps the shared filter onto `Classroom.active` / `.archived` / `.all`. What *is* shared
is reading the params, which had been written twice - `SoftDeletableFiltering#scoped_by_discard_status` for
the scope and `AdminHelper#current_discard_filter` for the rail. One `discard_filter` in the concern now,
exposed to views with `helper_method`, and the helper's copy is deleted.

### What this breaks

- **`/admin/classrooms` no longer lists archived classrooms by default.** This is a data-visibility change:
  the page used to show every classroom, and now defaults to Active like the other three indexes. The
  archived ones are one tab away, and the All tab is the previous behaviour. Any bookmark or link expecting
  the full list needs `?all=true`.
- **`AdminHelper#current_discard_filter` is deleted.** Views call `discard_filter`, which comes from
  `SoftDeletableFiltering` via `helper_method` - so a view that needs it requires its controller to include
  the concern. `Admin::ClassroomsController` now does, for the param reading alone.
- **Any test that reached an admin record page by clicking `Edit` on its index has no such link.** Three
  needed changing: `students_controller_test` counted the Edit links to prove the All tab lists both kinds of
  row (it asserts the archive link and the restore form now, which is what actually distinguishes them),
  `row_actions_test` asserted at least two actions on the school years row (one now), and
  `table_actions_reachable_test` looked for `Edit` inside a collapsed row (`Archive` now). The app-side
  `Edit` tests are untouched.
- Row actions cells are narrower everywhere, which changes measured column widths. Nothing asserts them
  directly, and the actions column is the one that overflows first at 1024px, so the change is in the safe
  direction.

## The teacher form's copy is per page, because three of its sentences were not

The create page and the record page render one `admin/teachers/_form`, and three of its sentences were
true on one of them and false on the other. Each was written while looking at a single page.

**The email hint claimed the temporary password is emailed. It is not.** `create` generates one with
`Devise.friendly_token` purely so the record can save, and sends `send_reset_password_instructions` - a
reset link and nothing else. Nobody ever sees that password, the teacher included. The hint now says a
link is emailed, which is what happens.

**And it said so on the record page, where saving emails nothing.** `update` calls `update`, and
`:confirmable` is not among the devise modules, so even changing the address is silent. The record page's
hint now carries the fact that *is* true there: the email is the username - `sync_username_from_email`
copies it - so changing it changes how they sign in.

**The school filter promised to keep classrooms that a new teacher does not have.** "Any already assigned
stay listed whichever school you pick" is the reason the filter is safe on the record page, and on create
there is nothing assigned for it to be about.

**And the multi-school fact was on the create page twice** - in the page description and again in the
classroom group's hint. The record page has no such description, so the hint keeps it there and drops it
on create.

Separately, "Teacher's full name" restated its own label. It now says what a reader cannot see: the field
is what the index, the record page title and every classroom teacher list render, and without it a teacher
appears as the first part of their email.

### What this breaks

- `admin_page_structure_test`'s "the teacher password behaviour is stated once" scanned for
  `/temporary password/i` and expected one hit. That phrase is gone from both pages, so the test would
  read zero as a regression. It asserts the setup-mail sentence appears once on create and **not at all**
  on the record page, and a second test asserts no teacher page mentions a temporary password at all.
- `_form` now needs `@teacher` set before the hints are computed, which every render already did - it is
  the same object `form_with` takes.

## The teacher form's school filter is removed

`admin/teachers/_form` had a single-select **"Show classrooms from"** above the multi-select classroom
group it narrowed. Reported as making no sense, and it did not: two controls about one thing, told apart
by their labels, one of them named for a mechanism.

What it did: on change, a Stimulus controller rewrote a turbo frame's `src` with `?school_id=`, and
`set_form_data` re-rendered the checkbox group narrowed to that school. `@selected_school_id` defaulted to
**the school of the teacher's first classroom**, so the list arrived narrowed without anyone choosing
anything - which is how it once dropped the second school's classroom on save, and why the group had to be
unioned back together and the filter's own hint had to promise that "any already assigned stay listed".

It was hiding a list shorter than the control: the group is limited to active classrooms in the current
school year, which is 2 rows against 4 schools in this database. Removed entirely. Each row now renders the
classroom's name over its school - `ClassroomsHelper#classroom_option_label`, mirroring `teacher_option_label`
beside it - so two schools running a "Grade 5" stay distinguishable and a teacher spanning both can see it.

Also: **"Tick every classroom this teacher runs" is now "Select"**. The product is American and the verb was
British. It was the only instance in rendered copy.

### What this breaks

- **`?school_id=` on the teacher form does nothing.** No route change - it was never a permitted parameter,
  only a top-level one `set_form_data` read - but a link carrying it now gets the full list.
- **`app/javascript/controllers/form_filter_controller.js` is deleted.** It had one caller. Anything
  reaching for a generic "reload a turbo frame from a select" controller needs to write it again; nothing
  did.
- **`Teacher#school_id` is deleted.** It was an `attr_accessor` existing only so `f.select :school_id` had
  something to bind to. A teacher has no school, which is the point the page description makes.
- **`@schools` and `@selected_school_id` are gone from `set_form_data`**, along with the union. Anything
  rendering that partial gets every active classroom in the current year, ordered by school then name.
- **The checkbox label is two lines, so it is no longer matched by its text.** `assert_select "label",
  text: "Test Classroom"` became `assert_select "label span", ...`; the same trap as the teacher picker.
- The empty-state callout said "associated with this school and active year" and named a filter that no
  longer exists. It says "set up for the current school year" now, and a controller test matched on the old
  sentence.

## Field hints: twenty-six said the label again, and a card's last field stopped padding it

Two things reported together, both about forms.

**Hints.** Twenty-six of the app's field hints restated their own label - "Full company name" under Company
name, "Industry sector" under Industry, "Select the school for this school year" under School, "Re-enter
password to confirm" under Password confirmation. `admin/stocks` was the worst: sixteen of its twenty.
They are deleted. The ones that stay carry a format, a consequence or who else writes the value, and
design.md now states that test with examples of each.

Three were not merely empty but **wrong**, which is what a restating hint hides:

- `admin/users` said email is "required for Teachers and Admins". `User` validates
  `presence: false, allow_blank: true`; what makes a teacher need one is `sync_username_from_email`, since
  a blank email leaves a blank username and *that* is validated. An admin needs no email at all.
- `admin/portfolio_transactions` listed the five transaction types without saying which way each moves
  money. `Portfolio#cash_on_hand_in_cents` adds deposits and credits and subtracts withdrawals, debits and
  fees - the one fact the field exists for.
- `admin/stocks` described Archived as "hidden from active listings". Archived stocks are still listed;
  what changes is that `_trade_actions` withholds Buy and `Order#prevent_archived_stock_purchase` blocks it,
  while a holder can still sell.

`admin/component_demo`'s own hints were swept too. It is where somebody copies a call from, so a hint
restating its label there becomes one in a form.

**Card padding.** Reported as too much space under the new teacher card, and it was every admin form card
except one: **21px above the first field and 45px below the last**. `Ui::FormBuilder` wraps every field in
`mb-6`, the rhythm *between* fields, and the last one's 24px landed inside the card's 20px padding. Fixed in
`cards.css` for every card at once rather than by passing `wrapper_class: "mb-0"` at eight call sites, where
reordering a field would bring it back.

### What this breaks

- **The card rule lives in `@layer utilities`, not `@layer components`.** `mb-6` is a utility, and in
  Tailwind v4 the utilities layer beats the components layer whatever the specificity - the first attempt
  was in `@layer components` and measured identically to no rule at all. Anything overriding a utility from
  a component file has the same problem.
- **It is a chain of `:last-child` selectors four levels deep**, because a field sits two levels down on
  announcements, three on teachers and four on students. A form nesting deeper regains the gap;
  `card_padding_test` measures all nine form cards, so that fails by name.
- **A card whose last element wants a bottom margin cannot have one.** Nothing did. If one ever needs it,
  the padding is the thing to change, not the margin.
- `hint_copy_test` walks nine create pages and fails on the *shape* - the label's words inside a short hint,
  or an opening "Enter" / "Select" / "Choose". A hint that legitimately repeats a label word needs to be
  longer than the label plus three words, which every real one is.
- Stock fields lost sixteen hints, so anything asserting on `p.tw-field-hint` counts on those pages change.
  Nothing did.

## One register for every hint, and the checkbox rows close up

**Register.** Three hints were rewritten on the teacher form by a reader, and the rest of the product now
matches them: `Used to sign in.` / `Displayed wherever this teacher appears. If left blank, the first part
of their email is shown instead.` / `Select all classrooms this teacher teaches.` Impersonal, purpose
first, consequence or fallback second. Both second person ("You sign in with this", on the profile) and
third ("They sign in with this", on three admin forms) were in use, sometimes on one page; the subject of a
hint is the field, so neither is needed. "Shown" is now "Displayed" throughout, and one phrasing per
constraint - "At least 6 characters", where two forms said "Minimum 6 characters" and two said "6 characters
minimum".

**The imperative rule was too broad, and its test could not see that.** Last commit banned an opening
"Select" on every hint. GOV.UK's checkbox pattern ships "Select all that apply" precisely because a group's
unknown is *how many* you may pick, so the ban is wrong for a `<fieldset>` - and "Select all classrooms this
teacher teaches" is the correct hint. It did not fail the test, and only by accident: a group names itself
with `<legend>`, and `hint_copy_test` selected `label`, so **every choice group in the app was unchecked**.
Groups are now checked for restatement and exempt from the verb.

**Checkbox rows.** `py-2` on each row and `space-y-2` between them - 24px between one option's text and the
next, 60px of pitch for a two-line row. The `space-y` is gone and the rows sit edge to edge: 52px pitch for
two lines, 36px for one. `COLUMN_LAYOUTS` loses its `gap-2` for a `gap-x-6` gutter, so a multi-column group
does not reintroduce the same stacking.

### What this breaks

- **`admin_page_structure_test` matched the old setup-mail wording** (`/emails them a link to set their
  password/`) and now matches `/sent by email once saved/`. A copy test pinned to a sentence has to move
  with the sentence; both halves - once on create, never on the record page - are unchanged.
- **`hint_copy_test` now reads `legend.tw-label-primary` as well as `label`.** Its assertion count rose,
  which is the sign the groups were previously invisible to it.
- **A checkbox group has no vertical gap utility any more.** A caller wanting one has to change the row's
  padding instead; `spacing_test` asserts the gap is zero and the pitch equals the row height.
- The teacher form's `classrooms_hint` branch is gone - the same sentence serves both pages now, because
  each row names its school and the multi-school fact no longer needs stating in words.

## Page descriptions join the hint register, and the save button moves up 16px

**Descriptions.** `admin/teachers#new` was rewritten by a reader - "Teachers are assigned to classrooms, not
schools, and can hold more than one" - and five other pages now match it: plural subject, no pronoun, a
`not X` contrast where one corrects an assumption. Two of them opened with **"They"** on a create page,
where the record does not exist yet and the pronoun refers to nothing: `admin/students#new` said "They can
sign in straight away", and its app-side twin "They can sign in as soon as you save". `admin/users#index`
said "Every account there is ... teachers that have their own pages", which is loose and uses `that` for
people.

The student-facing pages keep the second person deliberately - "You still own shares in these" is about the
reader's own portfolio - and design.md now says where the line is.

**The save button.** `.tw-form-actions` was `py-4` and is a `space-y-6` sibling of the card, so the button
sat 24 + 16 = **40px** below it on all ten forms. Same defect as the card's own bottom padding two commits
ago: one gap declared twice. GOV.UK puts 30px above a submit, Tailwind UI 24px, Polaris 20px - 40px was more
than any of them, and design.md's stacked rhythm is 24px. The row keeps `pb-4` and the top padding moves to
the sticky state, which is the only state that needs air above the button.

### What this breaks

- **An update form's action row grows 16px on the first keystroke**, when `data-form-dirty` adds `pt-4`
  along with the sticky positioning. That is the transition where Polaris's ContextualSaveBar appears out of
  nothing, so it is within the pattern this rule was modelled on - but it is a layout change on input, and
  worth knowing before something else is hung off that state.
- **A form that shows its action row without the dirty flag has no top padding on it.** Every form is either
  a create (row always visible, 24px from the card) or an update (row hidden until dirty), so nothing sits
  in between today. A third case would render the button tight against whatever is above it.
- `card_padding_test` now measures card-to-*button* on nine forms as well as the card's own symmetry, so the
  two spacings are pinned separately.

## An empty state explains; the page header acts

Reported as a rule: an empty state should not carry a primary CTA, particularly where the page already has
one. The count made the case - **five of them did, and every one duplicated a button already on the page**:

| Page | Empty state had | Page also had |
|---|---|---|
| `admin/teachers#index` | New teacher | header New teacher |
| `admin/students#index` | New student | header New student |
| `admin/classrooms#index` | New classroom | header New classroom |
| `admin/school_years#index` | New school year | header New school year |
| `classrooms#show` roster | Add the first student | header Add student |
| `grade_books#show` | Add this class's students | section header, as a secondary |

**This reverses what design.md said**, and the reversal is recorded there rather than quietly applied.
Polaris and Stripe do the opposite - the empty state owns the action and the header suppresses its own -
and that *was* the rule here, implemented on `portfolios#show` and nowhere else, which is how the five
duplicates survived a rule written against exactly them. Two things decide it the other way: a control in
the header is in the same place at every row count, where one in an empty state migrates the moment the
first record lands; and the suppression made the empty case the only case with no header action.

That second point is why `portfolios#show` needed the opposite change. Its "Invest now" was suppressed
*because* the empty state carried "Browse companies", so removing the empty state's button alone would have
left a student with no holdings - the exact reader who needs the trading floor - with no route to it. The
header now renders in every state.

`admin/shared/_empty_row` loses `action_label` / `action_path` entirely, and `admin/shared/_table` the
`empty_action_label` / `empty_action_path` options that fed them. Those existed only to render a
`tw-btn-primary` inside a table's empty row.

### What this breaks

- **`_empty_row` no longer takes an action.** A caller passing `action_label:` gets an ignored local, not an
  error - so the grep to run when adding an empty state is for the *header's* button, to check one exists.
- **`portfolios#show` renders "Invest now" whenever a student can trade**, not only when they hold
  something. `portfolio_delight_test` asserted "Browse companies" in the empty state and now asserts the
  header's link plus the absence of the old one.
- **`button_copy_test` loses its `Add the first …` exemption**, which existed for the empty state's CTA. An
  exemption that outlives its case is a hole in the rule.
- Three system tests reached a page through a button that no longer exists - the portfolio's, the
  classroom roster's, and the grade book's, where the click moves to the section header's "Add new
  students". `can_populate` is computed before the branch, so that control renders on an empty grade book
  exactly when there is somebody to add.
- `empty_state_preview_test` walks eight indexes and fails on any `.tw-btn-primary` inside a
  `[data-testid='empty-state']`, so a new empty state cannot reintroduce the pair.

## A breadcrumb showing `#<SchoolYear:0x…>`, and two more that disagreed with their page

Reported: `admin/school_years#show` rendered **`Dashboard / School years / #<SchoolYear:0x0000ffff68492f88>`**
under an h1 reading "Test School (2026 - 2027)". The controller set the crumb to `@school_year.to_s`, and
`SchoolYear` defines `#name` with no `#to_s`, so it got Object's. Three occurrences in that controller -
show, edit and the failed-update re-render.

Sweeping the other eight record pages for the same shape found two that were wrong rather than broken:
`admin/teachers` put the **username** in the trail under an h1 showing the display name, and `admin/stocks`
the **ticker** under the company name. Both now use the page's own title expression.

**`breadcrumb_label_test` is the guard**, and there was none: nothing in the suite read a crumb's text. It
compares the last crumb with the h1 on eight record pages, and separately fails on `#<Model:0x` anywhere in
a page's text - the shape any `to_s` on a record without an override produces. Verified by reverting the
controller and watching both halves name it.

**The quarter count went with it.** The same page's description read "2 classrooms · 4 quarters", reported in
the same breath. Every school year has exactly four - `create_quarters` on create, nothing else makes one,
no quarter routes - so it is the invariant the Quarters *card* was deleted for, printed smaller.

**And the Classrooms section now says it is read-only.** Asked in the same report: can classrooms be edited
from here? They can, by opening one - each name links to its record page - and a new one comes from the
Classrooms screen, where it also needs grades and teachers. None of that was on the page; it was a code
comment. It is the section's hint now. Note what the question implies: with a live Details form directly
above it, a list reads as editable, and `/admin/school_years/:id/edit` renders this same page, so a reader
clicking Edit sees the classrooms and cannot change them.

### What this breaks

- **`admin/school_years#show`'s description no longer matches `/quarters/`.** Its controller test asserted
  `text: /4 quarters/` and now asserts the classroom count and the *absence* of a quarter count.
- **Teacher and stock breadcrumbs changed text**, so anything matching a trail on `username` or `ticker`
  moves. Nothing did - which is the point: no test read them.
- `school_year_summary` returns one figure rather than two, and any caller wanting the quarter count has to
  ask for it. Nothing does.

## "6th · 2026 - 2027 · trading on" - a state is a badge, not the tail of a metadata list

Reported on `admin/classrooms#show`, as unreadable without labels and with the state hanging off the end. Two
faults, and only the first is about that page:

- **"6th" does not say what it is a 6th of.** It is "6th grade · 2026 - 2027" now, and the app-side
  classroom page - which built the same line separately, as "Grade 6th, 2026 - 2027" - calls the same
  helper.
- **A state was joined to two attributes by the same separator.** `_page_header` has had a `badge:` slot for
  exactly this since `grade_books#show` needed it, and three record pages were not using it: classroom,
  teacher and user all put their state in the *description*. `_record_page` now passes `badge:` through, and
  the state sits on the title's line where Linear, Stripe, GitHub and Shopify put it.

**The badge is derived once.** `admin/classrooms#index` rendered Archived / Trading on / Trading off inline
while the record page derived the same thing again as prose - so one classroom could read "Trading off" in
the list and "trading on" on its own page. `classroom_status_badge` and `teacher_status_badge` are what both
call.

**A user gets a badge only when archived.** An "Active" pill on every ordinary account is a pill nobody
reads; the exception is the thing worth stating.

And the app-side classroom page gets **no** badge: the trading setting below already states its state in a
sentence beside the switch, and a pill would be the third copy of one fact.

### What this breaks

- **`teacher_summary` and `user_summary` no longer contain the state**, and `classroom_summary` no longer
  contains the trading or archived words. Anything asserting on those strings in a description moves to the
  badge. Nothing did.
- `classroom_summary` is now called from the **app** side as well, so a change to it changes both pages -
  which is the point, and worth knowing before editing it for one of them.
- `_record_page` takes a `badge:` local. It is optional and passes through to a slot the header already had.
- **This overturns the reasoning in `teacher_summary`'s own comment**, which argued a state should be words
  rather than a badge's colour. The answer is that a badge has a label; the comment is rewritten rather than
  removed, so the argument is not made again.

## Section hints name their noun, and one of them was noise

Set by a reader on `admin/classrooms#show`: **"Moving a class to another school year gives it that year's
four grade books."** It replaced "Moving *it* to another school year gives *it* …", where the subject of the
sentence is not in the sentence - a reader has to look up at the h1 and carry the answer back down, and help
text is read at the field rather than from the title.

Four more had the same shape and now name their noun:

| Where | Was | Now |
| --- | --- | --- |
| `classrooms#new`, both halves | Creating **it** adds a grade book … | Creating **a class** adds … |
| `school_years#new` | Creating **one** adds its four quarters | Creating **a school year** adds … |
| `school_years#show`, Classrooms | Open **one** to edit it | Open **a classroom** to edit it |
| `portfolio_transactions#new` / `#show` | so saving **this** moves the money | so saving **this transaction** moves money |

A pronoun whose noun is in the same sentence stays - "Deposit adds to the cash balance. Debit takes from
it" names the balance first.

**And the sweep found a hint this document already forbids.** design.md: a section hint that names the
button is noise unless the page has two writes that behave differently. `admin/teachers#show` has one form
and said "Saved when you press Update teacher", which is what the button says. Removed. The two pages that
keep the sentence are the two the rule was written for: `students#show`, where the cash adjustment applies
at once and the account form waits, and `schools#show`, where the years do.

### What this breaks

- **Two copy tests were pinned to the old strings.** `admin_page_structure_test` matched
  `/moves the money/` on the transaction create page and now matches `/moves money/`; `form_actions_test`
  asserted the classroom create sentence verbatim.
- `admin/teachers#show`'s Details section renders no hint, so anything asserting a `p` under that heading
  counts one fewer.
- **The comment explaining the removal broke the page first** - written as `<%# … %>` *inside* the
  `render layout:` argument list, which ends the tag mid-hash. Fifth recorded instance of that trap, caught
  by curling the page; `no_nested_erb_tags_test` names the file and line in 19ms and is the faster check.

## The app side, checked against the same hint rules

The hint sweep and `hint_copy_test` had both been scoped to the nine admin create pages, so the forms a
teacher and a student actually use had never been held to the rules written for them. Four lines changed,
and the test now walks both halves.

**`profiles/edit`'s email hint was ambiguous and buried its consequence.** "Optional. Used to reset your
password if you have one" - "one" reads as *a password*. What the field decides is whether a student can
recover their own account at all: `devise/passwords/new` asks for an email address, so without one they must
ask an admin. It says that now.

**`classrooms/_form`, two.** The Grades group said "Select at least one grade that applies to this
classroom", where the asterisk already carries the required-ness and "that applies to this classroom" is
padding - "Select every grade level this class covers" matches the register of the teacher picker beside it.
And the trading checkbox stated its on-state as though unconditional: "Students in this classroom can place
buy and sell orders" is now "When on, …", which is what a checkbox hint is for.

**`devise/passwords/new`** opened with the control's own verb - "Enter your email and we'll send you reset
instructions" - and used a first person the product uses nowhere else. It states what happens instead.

Everything else on the app side was already in register, because the student and classroom forms were swept
when the admin ones were.

### What this breaks

- **`hint_copy_test` is two tests now**, one per half, sharing a `sweep` helper. The app-side one signs in as
  an **admin**: `ClassroomPolicy#new?` is admin-only, and the point is to render the forms rather than to
  test who reaches them. Verified by putting "The classroom name" back under a label reading "Name" and
  watching it fail by name.
- A student with no email address now reads that they cannot reset their own password. That is a statement
  about a real limitation rather than a copy change - if self-service recovery for students is wanted, it is
  a feature, and the hint is the honest description until then.

## The column of dashes came back, on the table the rule had exempted

Reported on a student's portfolio: a hyphen in the rightmost column of every row. Reproduced as an admin -
five holdings, five dashes, under a header with no visible label.

**Why it resurfaced.** The rule ("a column of dashes is not a column") was written when `classrooms#index`
shipped one, and in the same change `portfolios#show` was named as its exception, in a comment in
`table_consistency_test`: *"the dash convention stays where a column holds actions for some rows and not
others - portfolios#show."* That was wrong about that table. `Trade` is gated on `current_user.student?` -
the **viewer**, not the row - so the column is all links or all dashes and never mixed. Nobody rendered the
page as a teacher to check, and because the exemption was written into a test comment it read as settled.

The fix is the one the rule already prescribes: one flag, read by the header, the cells and the empty
state's colspan, so the three cannot disagree. The owner still gets a Trade link on every holding.

**And the check no longer depends on a list.** `dash_column_test` asserts the *ratio* - dashes strictly
fewer than rows - on every table on the portfolio, the classrooms list, the trading floor and seven admin
indexes, under student, teacher and admin. Verified by reverting the view and watching it name the page, the
role and the counts.

**One thing found on the way:** there is no reachable mixed column left in the app. `classrooms#index` keeps
a dash branch that cannot fire, because `ClassroomPolicy::Scope` gives a teacher only the classrooms they
teach and `edit?` permits exactly those. It is left in place as a guard against a wider scope - `actions_column`
already stops it becoming a column - but `.table-no-permission` currently renders nowhere.

### What this breaks

- **`portfolios#show` has five columns, not six, for a non-student viewer**, and its empty-state colspan
  follows. Anything counting `th` on that page under a teacher or admin changes.
- The dash branch is gone from that table entirely, so a viewer who cannot trade sees no actions cell rather
  than an empty one.
- `table_consistency_test`'s comment named the exemption and has been corrected in place; the assertion it
  sits on is unchanged.

## The last dash branch, and the class it was the only caller of

`classrooms#index` kept a dash for a row without the action, and that branch cannot fire:
`ClassroomPolicy::Scope` gives a teacher only the classrooms they teach, `edit?` permits exactly those, and
an admin may edit all of them - so `actions_column` being true means *every* row has the link, not merely
one. Deleted. The per-row `policy(classroom).edit?` check stays as the guard for a scope that widens; what
went is the branch behind it.

That was the last caller, so **`.table-no-permission` is deleted from `tables.css`** as well - an unused
class is indistinguishable from a supported one, which is the rule that removed five of them from
`admin.css` earlier.

**The declaration, preserved verbatim** in case a genuinely mixed column ever appears, because the dash is
still the right convention for its empty rows:

```css
/* Was slate-400 at 2.6:1, which fails AA. slate-500 is 4.76:1. */
.table-no-permission {
  @apply text-slate-500 italic;
}
```

### What this breaks

- **A row that cannot be edited would now render an empty actions cell rather than a dash.** No such row
  reaches the page today; if the scope widens, restore the class above rather than leaving a blank, which
  reads as a rendering fault.
- Three tests still reference `.table-no-permission`, all asserting its **absence** - `dash_column_test` and
  `table_consistency_test` - so they keep working and would keep working if it came back.
- `tailwind.css` no longer contains the rule. Nothing referenced it from a template, so no markup changes.

## A portfolio reached from a record had no way back

Reported: from `admin/students#show`, whose "View portfolio" button is the only link out of that page, an
admin landed on `portfolios#show` with nothing to return by. The page renders in the **app** layout, which
has no breadcrumb trail - trails are the admin half's convention - so the browser's Back button was the whole
of it. `admin/users#show` links here too, with the same result.

`ApplicationHelper#portfolio_back_link` renders one in the page header's action slot, which is where
`stocks#show` already puts "Back to trading floor". **The destination is per role**, because the two readers
arrive from different places: an admin from the student's record, a teacher from their classroom roster,
where the student's name is the link. The owner gets nothing - they came from the nav, and a back link would
name a page they were never on.

**One branch was written and deleted.** The admin case started as `admin_student_path` behind an
`is_a?(Student)` guard, with a second path for an owner of another type - and the fixture for that test
would not save: `Portfolio#user_must_be_student` means a portfolio's owner is always a Student. The helper
calls `user_show_path`, which maps a user to their own record page, and the comment records why there is no
type to branch on.

### What this breaks

- **`portfolios#show`'s header renders a second action** for a teacher or an admin. It is a `tw-btn-secondary`
  beside the student-only "Invest now" primary, and the two never appear together - the primary is
  student-gated and the back link is not-the-owner-gated.
- The link's text contains the owner's display name or the classroom's name, so a test matching the header's
  links by text on that page sees one more.

## The app half gets breadcrumbs, and the back link is withdrawn

The previous commit answered "no way back from a portfolio" with a back link, reasoning that trails were the
admin half's convention and this half's was `stocks#show`'s "Back to trading floor". That was the wrong call:
the ask was a breadcrumb, for consistency with the design system, and the reason the app half had no trail
was not a decision - the partial simply lived at `admin/shared/_breadcrumbs`.

**Eight app pages were reached from somewhere and named nowhere**: `stocks#show`, `classrooms#show`,
`classrooms#new`, `classrooms#edit`, `students#new`, `students#edit`, `grade_books#show` and
`portfolios#show`. All have a trail now.

`shared/_breadcrumbs` is one partial with the root as a local. `admin_breadcrumbs` is `page_breadcrumbs`
rooted at the dashboard, so twenty-odd admin call sites are untouched and there is one implementation.

**The root follows the reader.** An admin opens a portfolio from the student's admin record, so their trail
is `Dashboard > Students > Robin Fields > Robin Fields's portfolio` even though the page renders in the app
layout; a teacher opens it from their classroom roster and gets `Home > Classes > Period 3 > …`; the owner,
whose portfolio is a navbar item, gets none.

`announcements#show` gets none either - its only parent is Home, which is one level and the case the rule
already dropped for every admin index. It keeps its own "Back to home" button.

### What this breaks

- **`stocks#show` lost "Back to trading floor"**, and `portfolios#show` the back link added a commit ago;
  `ApplicationHelper#portfolio_back_link` is deleted with its test. Two controls to one destination is what
  the trail removes.
- **A trail costs 44px.** On `classrooms#show` the roster's first row moved 206 -> 250 in a 625px viewport,
  and `classroom_page_test`'s threshold moved 240 -> 260 with the measurement written into it. That page has
  twice paid for a block above its roster, so the new threshold leaves only ten pixels - the next addition
  fails there.
- **A failed save re-renders `new`/`edit` without the trail** unless the controller rebuilds it, which was a
  **500** on the classroom form's invalid branch: `undefined method 'size' for nil` from the partial. Both
  controllers rebuild it now *and* `page_breadcrumbs` wraps its argument in `Array()`, so a missed branch
  degrades to no trail rather than taking the page down.
- **The trail's links had no focus outline**, on either half, and no test saw it while the partial was
  admin-only - the focus audit walks the app half's forms. The first app page to render a trail failed it.
  Both links carry the named 2px outline now, which fixes the admin half too.

## The breadcrumb's house icon is gone

Reported: the root crumb carried a house glyph and no other crumb had one. It is inconsistent, and the
inconsistency had no meaning behind it - nothing marks the first crumb except being first.

**What the field does.** GOV.UK, Carbon, Primer, Bootstrap and Atlassian all ship a breadcrumb with no icons;
Polaris ships no trail at all, only a back action. The exception is Tailwind UI, whose example - clearly the
origin of the house-plus-chevron markup here - puts the icon on the first item **instead of** a word, as an
icon-only home link with an `sr-only` name. This app had both, which is that pattern's decoration without its
economy, and with two roots the glyph was wrong half the time: it labelled "Dashboard".

The chevron separators stay. They are the separator rather than a decoration, and every reference that ships
a trail at all uses one.

### What this breaks

- The root crumb is a plain text link, so a selector matching `nav[aria-label='Breadcrumb'] svg` counts two
  per three-crumb trail rather than three. Nothing asserted the icon.

## The order form joins `Ui::FormBuilder`

The last app-half form not on the builder, and the one that matters most: the student-facing buy/sell modal,
which is the product's core transaction. It carried the right classes by hand - `tw-label-primary` on a
`form.label`, `tw-input-primary` on a `form.number_field` - which is why no sweep had flagged it. Applying
the classes is not the same as using the component that owns them, and two things had drifted behind that:

- **No required asterisk.** The one form a student uses to move money was the only form that did not mark
  its required field, because the app-wide asterisk sweep went through `Ui::FormBuilder`.
- **Its own error summary.** "Please fix the following errors:" over a bulleted list - the third shape
  `shared/_form_errors` was written to remove, and the one its own docstring says it removed. It survived
  because that sweep also went through the forms already on the builder. The summary now counts the errors,
  which is what GOV.UK, Polaris and Primer put there.

The submit takes its variant from `submit_button` rather than a hand-written `tw-btn-primary`.

Measured after, in the rendered modal: label `tw-label-primary` reading "Number of shares*", input
`tw-input-primary` and `required`, submit `tw-btn-primary flex-1 hidden`.

### What this breaks

- **The field's label text gains an asterisk.** Capybara's `fill_in "Number of shares"` still matches - the
  buy/sell system tests pass unchanged - but an exact-string assertion on the label would not.
- **The error markup is different.** A test looking for "Please fix the following errors" finds nothing;
  the summary is `[data-testid='form-errors']` like every other form's.
- Two `.field_with_errors` wrappers per invalid field is *not* two messages - Rails wraps the label and the
  input separately. The message is one `<p>` with an id derived from the attribute, which is what the new
  test asserts.

## Field widths and hint punctuation, audited across every form

Two reports, both about consistency the earlier sweeps claimed and did not have.

**Nine fields were the wrong width.** `width: :half` is opt-in - the default is `:full`, deliberately, so a
field nobody has considered keeps what it has - and the first sweep opted in the fields it happened to visit.
Measured across eleven forms, the *same field* had two widths on two pages:

| Field | Was | Now |
| --- | --- | --- |
| School, Year on `admin/school_years` | 726 | 351, as on `admin/classrooms` |
| Classroom on `admin/students`, `admin/users` | 726 | 351 |
| Portfolio on `admin/portfolio_transactions` | 726 | 351, as its two neighbours already were |
| Email on `admin/teachers`, `admin/users` | 726 | 351 |
| Title on `admin/announcements` | 726 | 351 |

The two things that keep the full measure are now **readable from the element**: a `<textarea>` by its tag,
and the company website by `type="url"`. `page_width_test` had recorded that URL exception in words ("a URL
should still fill the row") and my first pass overrode it; giving the field its real type keeps the exception
and lets the rule see it. Every other exception in this codebase has been a name in a rule, which is how
`portfolios#show` kept its column of dashes through three sweeps.

**Twelve hints had no full stop, and nine of them were right.** `components/ui/_stat` takes a local also
called `hint`, and a caption under a figure is a fragment - what Stripe and Polaris put under a metric. The
three that were genuinely field hints are fixed, one by rewording: "Must start with http:// or https://"
would have ended on a stop glued to a scheme, so it reads "Must be a full web address, starting with http or
https." now.

### What this breaks

- **`form_field_test` asserts a width for every control on eleven forms**, against the element's own tag and
  type. A new field that starts at the default full measure fails there by name.
- **`hint_copy_test` asserts the full stop**, scoped to `p.tw-field-hint`, so a `_stat` caption is untouched.
- **The company website is `type="url"`**, so a browser now validates it as a URL on top of the model's
  format check, and a phone shows the URL keyboard. The model validation is unchanged and is still the one
  that matters.

## A WCAG 2.2 AA pass, and the instrument that had to be proved first

Fifteen screens, all three roles, measured on the rendered page: 1.4.3 contrast, 1.1.1 images and icon-only
controls, 1.3.1 labels and header cells and heading order, 2.4.2 titles, 2.5.8 target size, 4.1.2 names.
`wcag_audit_test` asserts all of it and the app passes.

**Two findings.** One fixed: `/profile/edit`'s username field had no `autocomplete`, where its name, email
and password fields all did - **1.3.5**, and in scope because that page collects the reader's *own* details.
The admin forms that collect a student's or a teacher's details are deliberately left alone: 1.3.5 covers
fields about the user filling them in, and an autocomplete there would offer the admin their own name for
somebody else's field.

One not fixed, and recorded in design-todo instead: **1.4.11**, where `.tw-input-primary`'s `border-slate-300`
measures 1.49:1 and `.tw-btn-secondary`'s `border-slate-200` measures 1.23:1 against a white card, and the
border is the only thing identifying either control. Clearing 3:1 needs `slate-500` (4.76:1) - `slate-400` is
2.63:1 and still fails - which is a visibly heavier border on every field in the product.

**The instrument needed proving before its report could be believed**, and this is the part worth keeping.
The first version measured contrast by painting each colour over opaque black, which destroyed the alpha,
resolved every transparent background to black, and reported slate-900 body text at **1.18:1** - it would
have produced a page of contrast failures that do not exist, which this repo has done once before by parsing
`oklch()` as RGB. Two more of its findings were its own faults: an anchor wrapping the logo `<img alt>` read
as unnamed because the audit looked for `alt` on the anchor, and 2.5.8 flagged the sr-only skip link and
every breadcrumb link until it implemented the spec's inline and spacing exceptions. A fourth was the
harness: signing out and back in inside one system test left four teacher pages auditing the *sign-in* page.

So the file carries a test that injects one violation of each kind and asserts the audit catches it. A clean
report from a broken instrument is worse than no report.

### What this breaks

- `wcag_audit_test` is 4 tests and about 45s of the system suite. It walks pages as three roles, so a new
  page is not covered until it is added to one of the three lists.
- The profile's username field now carries `autocomplete="username"`, which a browser may use to offer a
  saved value on a **readonly** field. It is readonly by design there, so nothing can be overwritten.

## Every control's boundary is slate-500, for WCAG 1.4.11

Taken as a decision from the audit's one outstanding finding. A control's boundary must reach 3:1 against
what is next to it, and every field and outlined button in this app is white on a white card, so its border
is the only thing saying a control is there.

| Token | Where | Was | Now |
| --- | --- | --- | --- |
| `.tw-input-primary` | every input, select, textarea | 1.49:1 (slate-300) | **4.76:1** (slate-500) |
| `.tw-btn-secondary`, `.tw-btn-danger-outline` | every outlined button | 1.23:1 (slate-200) | **4.55:1** |
| `CHECKBOX_CLASSES` | every checkbox | slate-300 | slate-500 |
| `.tw-switch` track | the trading switch | 2.9:1 (slate-400) | slate-500 |

`slate-400` was measured first and rejected: **2.63:1**, still short. `slate-500` is the first token that
clears the bar.

**What is deliberately untouched.** A card's hairline and a table's divider keep `slate-200`: they are
structure, not a user interface component, and 1.4.11 does not reach them. A filled primary keeps its
border-free fill, which identifies it at well over 3:1 on its own. The audit encodes that exemption rather
than listing the exceptions by name.

**And it overrules an aesthetic note the spec carried** - that slate-300 "measured darker and read as too
heavy" on the secondary button. That was a judgement about weight and 1.4.11 is a criterion; the criterion
wins. Material's outlined text field ships an outline at about 3.5:1, so the heavier border is the field's
answer too.

### What this breaks

- **Four tests pinned the old tokens** and are repinned with the reason: `form_field_test` on three page
  groups and `button_variants_test`, whose message asserted the aesthetic judgement this change overrules.
- **1.4.11 is asserted now**, not merely measured - `wcag_audit_test` fails on any control whose boundary
  falls under 3:1, with a self-check that injects a near-invisible border and confirms it is caught.
- Every field and outlined button in the product is visibly heavier. That is the trade the criterion asks
  for, and it is the whole of the visual change.

## The rest of WCAG 2.2 AA, and one more real failure

The audit covered nine criteria; AA has fifty-five. Extending it to the ones a browser can check honestly
found one more failure, in the criterion most likely to bite an app with fixed chrome.

**2.4.11 Focus Not Obscured (Minimum) - failed, fixed.** New in WCAG 2.2. A focused control must not be
*entirely* hidden by author-created content, and there are three pieces of it here: the staging ribbon, the
fixed header, and `.tw-form-actions` once an update form is dirty. Measured on `admin/stocks/new`: the
`employees` input landed at 1213-1233 inside a save bar occupying 1161-1233 - completely covered, which is
the criterion's own wording. The browser scrolls a Tab target to the scrollport's edge, which is behind the
bar. `scroll-padding-top` / `scroll-padding-bottom` on `:root`, against the chrome's own height variables,
is the whole fix.

**Checked and already passing**, so no change was made: 1.4.12 text spacing (measured per card, because
`.tw-card` clips rather than overflows and a page-level check cannot see it), 4.1.3 status messages (the
flash carries `role="status"` and `role="alert"`, callouts and the error summary likewise), 2.1.2 no
keyboard trap (the modal handles Escape and traps focus with a way out), and 3.3.8 accessible authentication
(sign-in carries `autocomplete="username"` and `"current-password"`, so a password manager works).

### What this breaks

- **`:root` now carries `scroll-padding`.** Anything added to the fixed chrome has to move those numbers,
  which is why they are `calc()` against `--sitf-header-h` and `--sitf-ribbon-h` rather than written out. A
  new sticky element at the bottom taller than 4rem would need the bottom value raised.
- `wcag_audit_test` gains two tests and is now about 50s of the system suite. The 2.4.11 one dirties a form
  first, because the sticky bar only exists in that state - verified by reverting the CSS and watching it
  name the field.

## The manual WCAG pass: the criteria a script cannot judge

Read rather than measured, because these ask whether copy and structure *mean* the right thing. Four
failures, all fixed.

**2.4.2 Page Titled - five app pages had no title of their own.** The portfolio, the trading floor,
transactions, classes and the grade book all fell through to the layout's bare "Stocks in the Future". The
machine audit only checked that a title existed, which is why it passed them. Each now sets
`content_for :title`, and a test asserts every page's title is distinct from the site name and from every
other page's.

**2.4.2 again, on the admin dashboard**: its title read "Admin | Admin | Stocks in the Future", because the
title is derived from the last breadcrumb and that page's crumb *is* "Admin". The layout de-duplicates the
segments now.

**3.1.1 Language of Page - the mailer layout declared none.** `layouts/mailer.html.erb` opened `<html>` with
no `lang`, so the password reset email had no language. Both app layouts already had `lang="en"`.

**1.1.1 - a logo whose alt repeated the text beside it.** The trading floor's row rendered
`alt="AAPL logo"` immediately before printing "AAPL" and the company name, so a screen reader said the
ticker twice. `portfolios/show` renders the same logo with `alt=""` and explains why; the two halves
disagreed and now do not.

**Checked and passing, with the evidence:**

- **1.4.1 Use of Colour** - every colour-coded figure carries a second cue: the holdings change and return
  print an explicit `+`, the fee prints `-`, `_stat`'s comparison line adds a trending arrow, badges carry a
  word, and errors carry an icon.
- **3.3.3 Error Suggestion** - the money errors state both figures ("You have $16.06 but need $18.06") and
  the sell error names the limit ("3 available"), which is what lets a reader fix it. The two that suggest
  nothing - an archived stock, a non-pending order - are cases where the reader has no action to take.
- **2.4.3 Focus Order** - no positive `tabindex` anywhere, so focus follows the DOM.
- **2.4.5 Multiple Ways** - persistent navigation, breadcrumbs on both halves, and search on the admin
  indexes.
- **3.2.4 Consistent Identification** - one label per destination, asserted by `button_copy_test`.
- **2.4.6 Headings and Labels** - every page has exactly one `h1` and it names the page.

### What this breaks

- Five app views gained a `content_for :title` line at the top. A new page without one now fails
  `wcag_audit_test` rather than quietly inheriting the site name.
- The admin title de-duplicates its segments, so `/admin` reads "Admin | Stocks in the Future" rather than
  repeating.
- **The stock logo is `alt=""`.** If that image ever becomes the only thing identifying a stock in a row, it
  needs its alt back - it is decorative only because the ticker is printed beside it.

## The AAA pass: one criterion fixed, the rest are decisions or impossible

W3C's own note is that AAA conformance is not achievable for whole sites, and that is the finding here too.
Every criterion was checked; the numbers are below so the choices can be argued with.

**Fixed - 2.4.9 Link Purpose (Link Only).** A screen reader's link list shows link text and nothing else, so
five rows of "Archive" were five identical links to five different students. In context the row names the
record, which is why 2.4.4 passes at AA; the AAA bar is the link alone. `orders#index` had already solved it
with a visible verb plus an `sr-only` remainder, so `AdminHelper#action_label` is that, in the helpers every
row action goes through - both halves, thirteen call sites. Asserted.

**Already passing at AAA**, several of them thanks to earlier work this month: 2.4.8 Location (the breadcrumb
trail, which the app half only got last week), 2.4.10 Section Headings, 2.4.12 Focus Not Obscured (Enhanced)
- zero *partially* obscured, because `scroll-padding` fixed more than the minimum asked for - 2.4.13 Focus
Appearance (a 2px solid outline at 6.18:1, where AAA asks 2px and 3:1), 2.3.3 Animation from Interactions,
and the media criteria, which are not applicable.

**Failing, and each is a decision rather than an oversight:**

| Criterion | Measured | What conformance would cost |
| --- | --- | --- |
| 1.4.6 Contrast (Enhanced), 7:1 | `slate-500` captions at 4.55-4.76:1; the **brand primary button at 6.18:1** | slate-600 for small text is easy; the primary needs the brand colour darkened |
| 2.5.5 Target Size (Enhanced), 44x44 | nav rows 36px, buttons 40px, "View site" 32px | every button in the product to 44px - which design.md records as a mistake it already made once |
| 1.4.8 Visual Presentation | up to **154 characters per line**; no justified text | a measure cap app-wide, plus user-selectable foreground and background colours, which nothing here offers |
| 2.2.3 No Timing | the success flash auto-hides after 6s | removing auto-dismiss, against design.md's rule that an outcome removes itself |
| 3.3.9 Accessible Authentication (Enhanced) | username and password | passkeys or an email link; a password is a cognitive function test by definition |
| 3.1.3 Unusual Words | "portfolio", "ticker", "shares" have no glossary | a glossary, for an app whose subject *is* those words |
| 3.1.5 Reading Level | not assessed | prose at lower-secondary level, plus a simpler alternative where it is not |

**What I did not do, deliberately.** Three of those would have been quick and wrong to take unilaterally:
44px targets contradict an explicit, measured decision in design.md; darkening the brand primary is a brand
change; and removing the flash's auto-dismiss reverses a rule that document argues for at length. They are
listed here rather than done.

### What this breaks

- **Every row action's text now ends with the record's name**, in an `sr-only` span. Two tests matched a
  whole label - `assert_select "button", text: "Restore"` and a `text.strip == "Edit"` count - and now match
  a prefix. Anything else asserting a row action's exact text will need the same.
- `portfolios#show`'s "Trade" links are left alone: every one points at the trading floor, so the text is
  unambiguous even though it repeats. Same text plus one destination is not what 2.4.9 is about.

## Small supporting text moves to slate-600

The one AAA item worth taking without a decision attached: 1.4.6 asks 7:1 for normal text, and
`text-slate-500` measures **4.76:1** - fine at AA, short of enhanced. slate-600 is **7.58:1**.

Changed where slate-500 was carrying *text*: `_stat`'s caption, the admin dashboard's stat hint, the
sidebar's section labels, the breadcrumb's current crumb, the em dash that stands in for an absent value in
two index tables and two helpers, and the component gallery's definition labels.

**Left at slate-500, and the distinction is the whole point:** a `lucide_icon` is non-text content, governed
by 1.4.11's 3:1 rather than 1.4.6's 7:1, and slate-500 clears that; a placeholder darkened to slate-600
starts reading as a filled value; and a disabled control's text is exempt by 1.4.3's own "inactive user
interface component" carve-out.

**This is an improvement, not conformance**, which is how it was offered. Measured after: `admin/students`
is clean at 7:1, and 1.4.6 still fails on the brand primary button (white on `sitf-primary`, 6.18:1), the
gain green (`green-700`, 4.95:1) and two marginal cases at 6.84 and 6.92. Each is a colour decision rather
than a token sweep.

### What this breaks

- `admin_helper_test` asserted the absent-value dash was `text-slate-500`. That dash has now been measured
  three times: it shipped at 2.6:1 and failed AA, went to slate-500 for AA, and is slate-600 for 1.4.6.
- Any view adding faint supporting text should reach for slate-600. slate-500 remains correct for an icon.

## Every empty state is two sentences

Set by a reader on the archived students list: *"Archiving a student is reversible and keeps their history
and records intact. Archived students appear here."* Applied to all thirteen.

**The second sentence was the one missing.** Half the bodies explained the record type and stopped -
"Classrooms group students with a teacher, a school year and grades" - so a reader learned what a classroom
*is* and not that adding one would fill the list they were looking at. The other half said only "they appear
here", with a pronoun for a noun that was not in the sentence.

`archived_empty_state` now takes **what archiving keeps**, per noun. "Keeps everything attached to it" was
the generic that made the sentence say nothing; a student keeps their history and records, a teacher their
classrooms, a classroom its grade books.

Two things the copy turned up on the way. The users list briefly read "No archived accounts" - the noun the
page's own description uses - which contradicts its h1 and its nav item, both "Users"; it is "user" again.
And the article has to follow the **sound**: a first-letter test rendered "an user".

**One body keeps a different first sentence, deliberately.** The student's own holdings empty state leads
with an invitation - "Pick a company you know" - which design.md argues for as the first screen a student
meets. It gained the second sentence rather than losing the first.

### What this breaks

- **`archived_empty_state` now requires `keeps:`.** A caller without it raises rather than printing a vague
  sentence, which is the point.
- `empty_state_preview_test` asserts every empty state body says what appears here and runs to at least two
  sentences. It reads the body paragraph, not the whole block - the title carries no terminal stop, so
  counting across both merges them.

## The All tab needs a status column

Asked what the All tab on `admin/students` does. It lists active and archived students together -
`scoped_by_discard_status` resolves to `with_discarded` - and the reader was right that there was no way to
tell them apart: the columns were Username, Classroom, Created at, Actions, and the **only** difference on
screen between an archived student and a live one was the verb on the row action, "Archive" against
"Restore". A control is not information.

`admin/teachers` already had a Status column. `admin/students` and `admin/users` did not, which is what
having the same idea in three files produces. All three now render `discard_status_badge`, and all three
sort by it: `discarded_at` is a real column, so the existing `sort_link` handles it, and Postgres sorting
NULLs last means ascending groups the archived rows together by when they were archived.

**What the field does**, since the question was asked: Shopify's index pages pair All / Active / Draft /
Archived tabs with a status badge on every row, and Stripe, GitHub's Open / Closed / All and Linear all do
the same. The tab is standard - it is how you find a record without knowing which state it is in. A tab
without the column is not.

**One thing left alone and worth flagging:** a student and a user are *Archived*, a teacher is
*Deactivated*, and the badges follow each page's own verb because that is what a reader connects them to.
The split lives in the actions, not the badge, so it is one decision to take rather than a rename.

### What this breaks

- **Two indexes gained a column**, so their empty-state `colspan` moved with them - 4 to 5 on students, 5 to
  6 on users. A colspan that does not follow leaves the empty row spanning the wrong width.
- **Student rows now carry `dom_id`**, which three of the six admin indexes already did. It is what lets a
  test address a row rather than a position.
- `teacher_status_badge` is a one-line call to `discard_status_badge` with its own label, so a change to the
  badge's tone or shape happens once.

## The status column belongs on the All tab only

Two questions on the column added in the last commit, and the first one was right.

**"Do you have a badge on Active where every rule says active is redundant?"** Yes, and on two of the three
tabs it was a column whose value never varied: the Active tab read `["Active", "Active", "Active"]` and the
Archived tab read "Archived" on every row. That is the column-of-dashes rule from the other direction, and
it contradicts `user_status_badge`, which renders nothing for a live account for exactly this reason - I
wrote that rule an hour before breaking it.

The column now renders **only when `discard_filter == :all`**, on all three indexes, with the header, the
cell, the stacked field below `lg` and the empty state's colspan all reading the same flag. Within All both
values are still drawn, because there they differ, and a blank cell would read as missing data rather than
as "active".

**"Would two tabs make more sense - All and Archived, with All sortable?"** Sorting groups; it does not
exclude. With two hundred students and thirty archived, an All default makes you scroll past thirty rows you
did not ask for, and dropping the Active tab leaves the default state with no tab to return to. Shopify
ships All / Active / Draft / Archived and GitHub Open / Closed / All - both keep a tab for the default. So:
three tabs, and the column only where it says something.

### What this breaks

- **The colspan is now conditional** on three indexes. A filtered tab's empty row spans one fewer column
  than the All tab's.
- **Two teacher tests asserted the badge on filtered tabs** as their evidence that filtering worked. They
  assert the surviving row's `display_name` instead - and note why the literal username never worked:
  `sync_username_from_email` overwrites it on every save, so `create(:teacher, username: "teacher1")` does
  not put "teacher1" on the page.

## Classroom archiving pairs with Restore, and a promise that is not kept

Asked how to align Deactivate/Reactivate with Archive/Restore. There were **three** vocabularies for one
idea: Archive/Restore on students and users, Archive/**Activate** on classrooms, Deactivate/Reactivate on
teachers.

The classroom pair is fixed here, because it is wrong under every possible answer to the larger question -
Archive pairs with Restore or Unarchive, and Activate pairs with Deactivate. The button, its icon, the
flash and three tests move together.

**The larger question is blocked on a behaviour, not a word, and the behaviour is a bug.** Five
confirmations say "They lose access immediately and leave this list" - on students, teachers, users,
classrooms and in the component gallery. Measured: a discarded student **signs in successfully**.
`POST /users/sign_in` returns 303 to root and the next request is authenticated. `User` has no
`active_for_authentication?` override and nothing anywhere reads `discarded?` for authorization. Archiving
removes the record from the admin lists and does nothing else.

That is recorded in design-todo with the two ways out and a recommendation: close the gap, then
**deactivate a person and archive a thing**, which is what Slack, Google Workspace, Salesforce and Okta all
do and what the confirmations already claim.

### What this breaks

- **"Activate" is gone** from the classroom row action, the record page button, and the flash, which now
  reads "Classroom has been restored." Three tests matched the old string.
- The restore icon is `rotate-ccw`, the glyph the other two restores already use, rather than
  `circle-check`.

## Deactivate a person, archive a thing - and deactivating now deactivates

Chosen from the two options recorded last commit: split by kind, and close the access gap first.

**The behaviour.** `User#active_for_authentication?` returns false for a discarded record, and
`#inactive_message` names a new `devise.failure.deactivated` string, because the default reads "not activated
yet" - true of an account nobody has used, wrong for one that was turned off. Devise's `activatable` hook
runs this on every `after_set_user`, not only at sign-in, so **a session already open ends on the next
request**. Four tests: a deactivated student cannot sign in, an active one still can, an open session ends,
and the same holds for a teacher.

That closes a gap five confirmations had been describing as if it were closed. Before this, a discarded
student signed in successfully.

**The words.**

| | Verb | Inverse | Status | Tab |
| --- | --- | --- | --- | --- |
| Student, teacher, user | Deactivate | Reactivate | Deactivated | Deactivated |
| Classroom | Archive | Restore | Archived | Archived |

`archived_empty_state` split in two - `deactivated_empty_state` for people, `archived_empty_state` for the
classroom - and `teacher_status_badge` no longer overrides anything, because every person now shares the one
default. The deactivate icon is `user-x` rather than `archive`, which is the glyph for a person rather than a
filing action.

**Two confirmations were lying in opposite directions**, and both are fixed: the people ones promised access
was revoked when it was not, and the classroom one promised "its teachers and students lose access
immediately", which archiving a classroom has never done. It now says what happens - the classroom leaves
the lists and cannot be opened, and nobody is signed out, because a classroom has no login.

### What this breaks

- **A deactivated account can no longer sign in.** That is the point, and it is a behaviour change: anyone
  deactivated before today could sign in until now and cannot from now on.
- **Routes keep the old names.** `restore_admin_student_path` and `admin_students_path(discarded: true)` are
  unchanged, so no links break; only what a reader sees moved. Renaming them is a separate change with no
  user-visible effect.
- Four tests matched the old words - two on the students index, one empty-state preview, and the classroom
  flash - and now match the new ones. The empty-state test gained the classroom case, so both vocabularies
  are asserted rather than one.

## ONBOARDING.md joins the documents that are kept current

Asked for, and it had gone stale in the one way that matters: it described archiving a student as an
administrative tidy-up, which is now an action that ends their session.

**What changed in it.** The vocabulary and its two consequences, right after the glossary - deactivating a
person stops them signing in, archiving a classroom signs nobody out. Both role sections, which said
"archive one" of a student. The three-tab shape of every list of people. `Ui::FormBuilder` covering every
form now, including the buy/sell modal. `shared/_breadcrumbs` serving both halves. Two more rules for the
first-week list - measure contrast by painting a pixel, and prefer an exception the code can see over a name
in a sentence. A table of the audit suites, because a newcomer meets those as a failure rather than as a
feature. And a note that AA is met and asserted while AAA is not, deliberately, so nobody files the four
gaps as oversights.

**And a standing instruction in `CLAUDE.md`**, alongside the one for `migration.md`. The three documents are
not interchangeable, which is why it is its own rule: `migration.md` is history and append-only, `design.md`
is the specification of the present, and `ONBOARDING.md` is orientation - what the app is, what each role
can do, and the rules that catch somebody in their first week. A change lands there when it would make the
document *wrong*, not for a spacing fix.

Every claim added was checked against the code before it went in, which is the document's own opening
contract: `active_for_authentication?`, `really_destroy!`, both breadcrumb helpers and all ten test files.

### What this breaks

- Nothing in the app. This is documentation, and the instruction that keeps it current is the part with a
  long life: a future change that alters a role, a verb's meaning, or a first-week rule now has a fourth
  file to update.

## Archiving a classroom now stops its students trading

Asked what "nobody is signed out" meant for an archived classroom, and the honest answer was worse than the
sentence suggested. Archiving took the class out of the teacher's list and stopped them opening it -
`ClassroomPolicy::Scope` is `.active` for a teacher and `check_classroom_eligibility` redirects a non-admin
- and did **nothing** to the students in it.

Measured: a student in an archived classroom signed in, opened the trading floor and placed a buy. So the
class was over, the teacher could no longer see it *or reach its trading switch* - that control lives on the
classroom page they can no longer open - and the students went on trading in it unsupervised. Only an
administrator could stop it, and only by knowing to look.

**`Classroom#trading_open?`** is the gate now: the switch's position **and** a live classroom.
`trading_enabled?` stays as the switch's own position, which is what the admin badge and the classroom form
show. Two questions on purpose - archiving does not move the switch, so restoring a class puts trading back
exactly as the teacher left it.

One predicate, and every gate reaches it by delegation: `Order`'s validation refuses the order,
`StockPolicy#show_trading_link?` withholds Buy and Sell so no button is offered that would be refused, and
`Portfolio#trading_off_notice?` raises the callout that explains it.

### What this breaks

- **Students in an already-archived classroom lose the ability to trade** the moment this deploys. That is
  the intent, and it is a behaviour change: anything archived before today was still trading.
- The classroom confirmation says what now matters to the person pressing it - "Its students can no longer
  buy or sell" - rather than the mechanical description it carried an hour ago.
- `trading_enabled?` and `trading_open?` are different questions and both are live. A new gate should ask
  `trading_open?`; a display of the *setting* should ask `trading_enabled?`.

## The secondary button goes back to slate-200, and 1.4.11 gets read properly

Reported: the outlined button's border was too dark and did not match the design system. It did not, and
the reasoning behind it was too blunt.

**1.4.11 asks for 3:1 on visual information *required to identify* a control.** Applying it as "every
border is 3:1" is what produced the heavy button. The real question is whether the boundary is the only
thing doing that job, and for a button it is not: the shared base gives every one of them `shadow-sm`, and
with a label, 16px of padding and a rounded box the border is one signal of four.

A **text input** is the opposite case and keeps `slate-500`: no fill, no shadow, no text of its own. An
empty field on a white card really is identified by its boundary alone. So do the checkbox and the switch
track, for the same reason.

**The field agrees, and agrees for this reason.** Tailwind UI ships `ring-gray-300` at about 1.5:1, GitHub a
0.15-alpha border over a tinted fill, Polaris a light border with a shadow. Material 3's outlined button is
about 3.4:1 - which reads as a counter-example until you notice it has neither fill nor shadow, so its
outline is the only identifier. Same rule, different components.

`wcag_audit_test` encodes the test rather than a list of exceptions: it skips a control whose own fill
reaches 3:1, and one that carries a shadow. That is why the audit still passes with the lighter button.

### What this breaks

- **`.tw-btn-secondary` and `.tw-btn-danger-outline` are `border-slate-200` again**, which is what
  `design.md` specified before this detour. Inputs, selects, textareas, checkboxes and the switch keep
  `slate-500`.
- `button_variants_test` moves back with them, and its comment now records both readings so the next person
  does not re-apply the blunt one.

## One action, one glyph

Reported: "Deactivate" had a different icon on students, teachers and users. It had **four**, and the fourth
was the problem:

| Where | Icon |
| --- | --- |
| the shared row-action helper, and the gallery | `user-x` |
| `admin/teachers#index` | `ban` |
| `admin/users#index` | `archive`, left from the rename |
| `admin/teachers`'s record page | **`trash-2`** - beside a real "Permanently delete" wearing the same glyph |

That last one is the one that misleads: a single icon meaning both "reversible, they keep everything" and
"gone". Auditing the rest found "Edit" split between `pencil` and `square-pen` across three shared partials,
and "Reactivate" between `circle-check` and `rotate-ccw`.

**The vocabulary now mirrors the verbs.** A person is `user-x` / `user-check`; a thing is `archive` /
`rotate-ccw`. That frees `ban` for Cancel alone and retires `circle-check` - the old table in `design.md`
gave `ban` to Deactivate *and* Cancel and `circle-check` to Activate *and* Reactivate, so two glyphs each
carried two meanings.

`icon_vocabulary_test` reads the **call sites**, because `lucide_icon` renders a bare `<svg>` with no name,
class or data attribute, so a browser test could only compare path data. It fails on any label carrying two
icons and pins the six pairs by name. Verified twice - once by restoring `ban`, once by restoring `archive`
- because the regex was rewritten for the line-length cop afterwards and a pattern that matches nothing
passes every assertion.

### What this breaks

- **Six icons changed**: Deactivate to `user-x` in three places, Reactivate to `user-check` in three, Edit
  to `pencil` in three. Nothing asserted an icon before this.
- `trash-2` now means deletion only, and `archive` means a classroom only.

## The rest of the icons, audited

Following the Deactivate report across every glyph in the app - 41 icons over 102 call sites.

**Four ideas had two glyphs, one per half of the product:**

| Idea | App navbar | Admin sidebar | Now |
| --- | --- | --- | --- |
| Transactions | `receipt` | `arrow-left-right` | `receipt` |
| Classes / Classrooms | **a hand-written Heroicons path** | `presentation` | `presentation` |
| Trading floor / Stocks | `chart-no-axes-combined` | `chart-line` | `chart-line` |
| My portfolio | `id-card` | — | `chart-pie`, which "View portfolio" and the first-share card already used |

The Classes one is worth the note: it hand-wrote its `<svg>`, so it appeared in **no** inventory - nothing
greps a path definition - and drifted unseen. Every icon in the app comes from `lucide_icon` now, and a test
counts them.

**One glyph labelled two items in the same sidebar.** `presentation` was Classrooms *and* Teachers, which is
the whole failure of a nav icon. Teachers is `book-user`; Classrooms keeps `presentation`, which the
dashboard tile uses too.

**And a near-duplicate is retired.** `arrow-left-right` is `arrow-right-left` - the Trade glyph design.md
names, citing Material's `swap_horiz` - with the words swapped. Two Lucide icons, one idea, one character
apart in the name.

Glyphs that legitimately serve several places are left alone, and the audit's own noisy pass is worth
recording: grouping by "nearby label" reported eighteen icons as ambiguous, almost all artefact, because the
nav items sit next to each other in one file. The findings above come from structured extraction - the nav
hashes, the dashboard tiles, the label-and-icon pairs - not from proximity.

### What this breaks

- **Six navigation glyphs changed**, three of them on the app half, which is the half a student sees.
- `icon_vocabulary_test` is five tests now: no label with two icons, the six action pairs by name, no nav
  glyph on two items, the four cross-half ideas, and every navbar item drawing through `lucide_icon`. Each
  was verified by reintroducing the bug it was written for.
- `arrow-left-right` and `chart-no-axes-combined` are no longer used anywhere.

**Noted, not chased:** `grade_books_test#test_teacher_marks_student_with_perfect_attendance` failed once in
a full run and passed on rerun and in every run since. The log is kept. It is the autosave assertion, which
reads a radio's checked state after a save, so a timing suspicion is reasonable - but one failure is not a
diagnosis, and `bin/flake-hunt` exists for when it recurs.

## Empty state icons, audited

The same audit as the glyphs, over all twenty empty states, and the same shape of finding.

**"No students yet" carried three icons**: `graduation-cap` on the classroom roster, `users` on the grade
book, and the partial's default `inbox` on the admin list. Three more titles carried two - "No classrooms
yet", "No school years yet" and "No transactions yet" each had a meaningful glyph in one place and the
default in another.

**Twelve of the twenty were on the default**, which is the real finding: the fallback was doing most of the
work, so the handful of pages that did pass a glyph read as the exception rather than the rule.

An empty state now carries **the glyph of the thing that is missing** - the same one its nav item and its
section use:

| Missing | Glyph |
| --- | --- |
| students | `graduation-cap` |
| classrooms | `presentation` |
| school years | `calendar-check` |
| teachers | `book-user` |
| transactions | `receipt` |
| announcements | `megaphone` |
| grade books | `book-check` |
| orders awaiting execution | `clock` |
| holdings, the portfolio chart | `chart-line` |

The two state tabs take the *state's* glyph instead, because that is what the tab is about: `user-x` for
deactivated people, `archive` for archived things.

### What this breaks

- **`inbox` has one caller left** - the gallery's generic "Nothing to show", which demonstrates the
  component with no concept behind it. It stays the partial's default, but a real empty state falling
  through to it now fails a test.
- `icon_vocabulary_test` is seven tests. Both new ones were verified by reintroducing their bug: putting
  `users` back on the grade book, and removing the teachers glyph.
- One edit produced a **duplicate `icon:` key** in `grade_books/show` - the file already passed `users`, and
  the inserted key sat above it. Ruby takes the last, so it rendered correctly and the audit still reported
  two icons for the title. Worth knowing that a duplicate hash key in ERB fails silently.

## Copy that presumes what the reader can do

Reported on the admin top bar's **"View site"**. It was one of eleven instances, on both halves, and the
audit split them into two failures of unequal strength.

**"Click" presumes a mouse.** Microsoft's style guide, Google's and GOV.UK all say so, and the app runs on
school Chromebooks with touchscreens. Two of the three instances were in the **account mailers**, which is
the first sentence a new student ever reads:

| File | Was | Now |
| --- | --- | --- |
| `devise/mailer/reset_password_instructions` | "Click on the link to login to your account and get started." | "Use the link below to set your password and sign in." |
| `devise/mailer/unlock_instructions` | "Click the link below to unlock your account:" | "Use the link below to unlock your account:" |
| `admin/component_demo/index` | "Click column headers to sort." | "Select a column header to sort." |

The mailer also used *login* as a verb for a product whose button says **Sign in**.

**A sight verb presumes the reader looks at a screen.** "View" is contested - Polaris, Primer and Material
all still ship it - and it goes anyway, because every replacement is at least as good as the original:

| Where | Was | Now |
| --- | --- | --- |
| `layouts/admin` top bar | "View site" x3 | **"Visit site"** - WordPress's own label |
| `admin/dashboard` | "View all" | **"All transactions"** |
| `admin/students#show` | "View all transactions" | **"All transactions"** |
| `admin/users#show`, `admin/students/_record_actions` | "View portfolio" | **"Open portfolio"** |
| `home#index` | "watch your earnings change with the market" | "follow your earnings as the market changes" |
| `portfolios#show` | "not while you watch it" | "not while you are on the page" |
| `classrooms/_form` | "who can see this classroom" | "who can open this classroom" |
| `classrooms/_trading_setting` | "they see a note explaining why" | "a note explains why" |
| `admin_helper#announcement_summary` | "Not featured, so nobody sees it" | "Not featured, so it does not appear on the home page" |

Two of these are better copy independently of the reason for changing them. **"All transactions"** names
its destination, so it still means something read out of context, which "View all" does not - that is WCAG
2.4.4 and GOV.UK's own link rule. And **"not while you are on the page"** says the actual thing: the figure
is a daily close.

### The rule, and what it deliberately does not catch

**The line is who the verb is about.** A verb about what the *system* does is fine; a verb about what the
*reader* does is not. "Featured - shown on everyone's home page" stayed on that basis while "nobody sees
it" went, and "the ticker is what the price feed looks up" stayed because the feed does the looking.

**An idiom is not an ability claim.** "We hope to see you again soon" is about meeting, not eyesight, and
no style guide flags it.

### What this breaks

- **Four test assertions** changed with the labels: `admin/dashboard_controller_test` ("View all"),
  `admin/students_controller_test` (twice), and `account_header_test` (`/View site/`).
- **Seven comments** named labels that no longer exist and were corrected with them - in
  `admin/shared/_navigation`, `layouts/_account_menu`, `admin/students/_record_actions`,
  `portfolios_controller`, `admin/portfolio_transactions_controller`, `admin_helper` and
  `development_only_pages_test`. Nothing in `migration.md` was edited: it is history.
- `inclusive_language_test` is new, static rather than rendered, because **a mailer is not a page and
  `component_demo` is development-only** - a browser walk cannot reach either. It was verified by
  reinstating both bugs. A rendered scan of every page found nothing the static one misses, which is what
  establishes that the static one looks in the right place.
- The audit found **nothing** in four further categories: no gendered pronouns in copy, no ableist
  metaphors, no exclusionary technical terms, and none of the "just / simply / easy / obviously" family.

### Noticed, not acted on

`devise.en.yml`'s `registrations.destroyed` ("Bye! Your account has been successfully cancelled...") is
**unreachable**: routes carry `devise_for :users, skip: %i[registrations]` and re-add only sign-up, and
`User#destroy` raises rather than hard-deleting. It is dead copy, which is a different finding from this
one and is left for a decision rather than folded into a language sweep.

## Three buttons in a page header, and the spec that had already answered wrongly

Reported on `/admin/students`: one primary and two secondary in the top-right. It was the **only**
three-action header in the app - every other page measured 0, 1 or 2 - so the question was what the rule
should be and where else it applied.

### design.md had a rule, and none of it was real

`### Header action pattern` specified **"one primary CTA plus a `More` overflow disclosure"**, with a
mobile variant rendering each action twice behind `hidden sm:contents` and `sm:hidden`. Checked rather
than followed:

| Named by the spec | In the codebase |
| --- | --- |
| `button_classes` | 0 files |
| `Dialog::GroupComponent` | 0 files |
| `rack_test` | 0 files |
| a `More` overflow in any header | none |
| `dropdown_controller` | one caller - the account menu |
| `sm:` breakpoints | banned by this same document, two sections above |

It was inherited scaffolding. The passage is replaced with what the app does. Note that this is a *new
instance of a known pattern*: design.md line 3576 already annotates a neighbouring block as "CASA prose
naming a `button_classes` helper and a `brand-600` token that do not exist". More of that file is
probably in the same state.

### What the third button was

Not a peer. **"Download template"** pointed at `/admin/students/template` - which is exactly where the
**"Download a template"** link *inside the import dialog* already pointed, beside the list of required
columns that makes it make sense. One destination, two controls, and the header's copy was the worse of
the two. Shopify's product import, Stripe's and Mailchimp's all keep the sample file inside the import
modal.

**Measured at 375px, the third button cost the primary its position:**

| | three actions | two actions |
| --- | --- | --- |
| action row | wraps - secondaries at top=124, **"New student" at top=172** | one line, all at top=124 |
| header block | 132px | **84px** |
| first table row | 339px | **291px** |
| at 1366px | 40px block, no wrap | unchanged |

So the page's main action sat last and lowest on a phone, below a duplicate.

### The rule now

At most three header actions, exactly one filled primary, and they are **peers** - each acting on the
page's subject at the same level. A supporting step goes with the task it supports. One destination gets
one control.

### What this breaks

- `one_primary_test` gains `assert_header_actions` and a test walking **25 pages**. `admin/students` was
  not in that file's walk before, which is how the third action arrived unnoticed.
- The duplicate key carries the **HTTP verb**. Without it, five record pages report a false duplicate: a
  destructive `data-turbo-method: delete` link and the form's Cancel share an href and differ only in
  method. First version of the assertion checked for duplicates *within* the header block, which cannot
  see this bug at all - the other link is in the dialog. It passed with the defect reinstated, which is
  how that was caught.
- Nothing was added to replace the button. `template_admin_students_path` still has two controller tests
  and the dialog link.

## The runner records its own failures

A run of the system suite returned `368 runs, 2411 assertions, 1 failures, 0 errors` and the failing
test's **name was lost**, because the command was piped through `tail -3`. `CLAUDE.md` had carried a
warning against exactly that since the previous occurrence, and the warning did not prevent it. So the
mechanism changed rather than the advice.

`test/support/failure_recorder.rb` is an `after_teardown` on `ActiveSupport::TestCase`. Every failing test
appends to **`tmp/test-failures.log`**:

```
2026-08-14T18:25:47Z  seed=42022  ZzScratchSysTest#test_deliberately_failing_system_test
    test/system/zz_scratch_sys_test.rb:6
    replay: PARALLEL_WORKERS=1 bin/rails test test/system/zz_scratch_sys_test.rb:6 --seed 42022
    Failure: expected to find text "..." in "Skip to main content\nSign in to your account\n..."
```

Three properties, each chosen against a way the last one was lost:

- **Piping cannot defeat it.** It writes from inside the test, not from the reporter's output.
- **Only a failing run writes.** A green run leaves the file alone, so a later pass cannot erase the
  record of an earlier failure.
- **It runs in the forked worker**, so a ten-way parallel run records. Verified in both suites by
  injecting a failure and reading the file back, with the command piped through `tail -2` each time.

**It is deliberately not a Minitest plugin.** `minitest/*_plugin.rb` is the documented mechanism and it
cannot work here: Rails calls `Minitest.load_plugins` while parsing options, which is before any test file
- and therefore before `test_helper` - has been read, so nothing a test file adds to `$LOAD_PATH` is
found. `Gem.find_files` locates the plugin perfectly well from a console, which is what makes this
misleading; instrumenting the plugin file and watching it never load is what settled it.

### What this does not do

**It does not diagnose the flake.** **46** green full-suite runs across 46 seeds - every one at exactly
2411 assertions - plus 40 runs of the suspected file alone and 20 runs of a probe asserting who is signed
in after each user switch. All green, and the recorder itself logged nothing during 20 of those runs. Zero
failures in 46 gives a 95% upper bound of about **6.5%** per run against an observation of roughly 1-in-9,
so the original rate is unlikely but a rarer flake is entirely consistent with this. `design-todo.md` carries what is known, the two hypotheses that were
tested and disproved, and the untested one.

## Pagination, and the component that could not have worked

Reported as a long scroll on the transactions page. It is, and it had no upper bound.

**Measured before changing anything**, at 1366x768 where the viewport is 625px:

| | rows | height | screens |
| --- | --- | --- | --- |
| `admin/portfolio_transactions` | 300 | 15,534px | **24.9** |
| the same at 375px, rows stacked | 300 | 58,190px | **87** |
| `orders#index` (app half) | 60 | 5,118px | 8.2 |

300 is a modest figure for this collection: an executed order writes a purchase row **and** a fee row,
and finalizing a grade book writes a deposit per student per earnings reason per quarter. Nothing bounded
it, and `OrderPolicy::Scope` makes the app half unbounded too - a teacher sees every order in their
classrooms, an admin every order in the system.

### The component in the design system did not work

`admin/shared/_pagination` has existed since the admin was built, and `admin/shared/_table` renders it
guarded on `collection.total_pages > 1`. **Kaminari was not installed**, so no collection could ever
satisfy that guard. design.md recorded "nothing paginates" as a deliberate state; it did not record that
turning it on would have rendered nothing.

Two further reasons it would not have appeared even then:

- `admin/portfolio_transactions/index` **hand-rolls its own `<table>`** rather than using the shell, so
  it never reached the shell's footer at all.
- while nothing rendered it, the partial drifted: `px-4 py-2 border border-slate-300 rounded-md
  text-slate-400 bg-slate-100`, written out four times. Wrong radius against the `rounded-lg` token, no
  `min-h-10`, a border shade the spec does not use, and `text-slate-400` - which this repo's own notes
  name as a 2.5:1 failure.

### What changed

- **`kaminari 1.2.2` added.** Its API is exactly what the partial was already written against
  (`total_pages`, `offset_value`, `limit_value`, `total_count`, `prev_page`, `next_page`).
  `bundler-audit` reports no vulnerabilities.
- **`ApplicationController::PER_PAGE = 25`**, one definition for both halves. Stripe's figure and
  Kaminari's default; Shopify uses 50, GitHub 30, Administrate 20.
- **The partial moved to `shared/`** - both halves render it now, the same move `_breadcrumbs` made.
- **It is rebuilt on the tokens**: `.tw-btn-secondary` for a live direction, `.tw-btn-disabled` for the
  one with nowhere to go. Measured 61x40 and 65x40, which is the 40px button token.
- **`.tw-btn-primary-disabled` is renamed `.tw-btn-disabled`.** It had **no callers**, and its first one
  is a secondary button, so the name lost the half that described a variant rather than a state.
- **The component owns its wrapper.** `footer: true` draws the in-card rule and gutters the admin tables
  use; the default is a standalone strip 16px under a table that has closed its own card, which is the app
  half. A caller that wrapped it instead painted a rule and 24px of padding around nothing on every
  single-page collection - and `empty:hidden` does not fix that, because ERB emits whitespace and CSS
  `:empty` counts a text node. Measured: `strayStrip: false` on a 10-row page.

**After:** 300 transactions render 1,574px and **2.5 screens** at 1366, 5,180px at 375px.

### What this breaks

- `admin/shared/_table` no longer wraps or guards the partial - both moved inside it.
- `pagination_test` is seven tests, and covers the risk design.md had already named: **the sort pair and
  `?user_id=` survive the page parameter**. `request.query_parameters` carries them; a bare `page=2` would
  have dropped them, so a reader would sort a column, turn the page and silently get the default order.
- Present-but-disabled rather than absent, so the buttons do not move between page 1 and page 2.

### Addendum: the pagination change broke the running dev server

Not the code - the process. `kaminari` was added while a Puma started **26 hours earlier** was still
serving `localhost:3700`, and code reloading covers `app/`, not `Gemfile.lock`. Every request to
`/admin/portfolio_transactions` returned `NoMethodError (undefined method 'page' for an instance of
ActiveRecord::Relation)` while 996 unit and 368 system tests were green, because each test run boots a
fresh process with the current bundle. Reported by the user, not by anything I ran.

`run-app.sh --restart` did not fix it and said it had: it tracks its own pidfile, so against a
hand-started server it printed "Nothing to stop", started nothing, and then passed its own health check
against the stale process and printed "app is up". The old Puma had to be killed by PID.

The rule this leaves: **after any change to the bundle, restart the server and load the page.** A green
suite cannot see a stale process. Recorded in `CLAUDE.md` beside the initializer version of the same trap.

## The pagination component was not in the design system

Reported as "pagination does not match the design system component for pagination", and that is exactly
what it was: `_pagination` shipped in `app/views/shared/`, alongside `_modal` and `_table_container`.

**`app/views/components/ui/` is the design system's set** - the eight partials design.md names, each
rendered at `/admin/component_demo`. Filing it in `shared/` was wrong twice. It is not a shared partial in
that sense; and `component_gallery_test` derives its list **from that directory**, so a component filed
anywhere else is one the gallery cannot be failed for missing. The test that exists to stop precisely this
could not see it.

Moved to `components/ui/_pagination`, three call sites updated, and registered in the gallery - showing
both states, first page and last, built from `Kaminari.paginate_array` so the section renders whatever the
database holds and the gallery's "no database records" assertion stays true. Verified by running the
gallery test against the move first: it named `pagination` and gave the testid to add.

### The two questions that came with it

**Prev/next, not numbered pages.** Numbered pages are GOV.UK's and Django admin's, and suit a reader with
a sense of where in the sequence they are going - nobody has that about a transaction ledger. Stripe,
Shopify and Linear ship prev/next. Infinite scroll is not a candidate: NN/g finds it hurts goal-directed
finding, and it strands anything below the table.

**25 is right for a ledger and is the wrong question for a roster.** A roster is a lookup, and no page
size answers a lookup - the primitive is **search**. `admin/shared/_search_filter` exists and is rendered
on exactly one page in the app: the component gallery. So every admin index is a lookup surface with no
lookup. Raising a roster to 50 moves the median student from page 4 to page 2, which is not the
difference between finding them and not. Recorded in `design-todo.md` as the thing to do before
paginating `admin/users`.

### Archived stocks on the trading floor: no

"If the trading floor paginates, is there value in displaying the archived stocks that were removed?"

No, and the reason is in `stocks/_archived_stocks`'s own note: they were not removed for length. A
`<details>` listing every archived stock inside `Stock::LIST_RETENTION` was removed because **no reader
could act on it** - a student cannot buy an archived company, and a teacher who wants the catalogue has
`/admin/stocks`, which carries more. Pagination makes an unusable list shorter; it does not make it
useful. The section renders today only for a student who **holds** one, whose one action is Sell.

A design preview renders both options against each other at
**`/admin/component_demo/archived_stocks`** - dev-only, behind the same `Rails.env.local?` guard as the
gallery, because the argument is easier to have against a rendering than a paragraph.
