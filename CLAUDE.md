# Working notes for this repo

Durable context for anyone — human or agent — picking up UI work here. Kept
short on purpose. The design system lives in [`design.md`](design.md), the
process in [`design-instructions.md`](design-instructions.md), the backlog in
[`design-todo.md`](design-todo.md), and long-term-consequence changes in
[`migration.md`](migration.md).

## Standing instruction: keep migration.md current

**When you make a change with a long-term blast radius, add it to
[`migration.md`](migration.md) as part of that change — not afterwards.**

That means anything which:

- removes a capability, controller, route, view or stylesheet
- changes data behaviour, especially anything touching money or balances
- adds or drops a dependency, or vendors an asset
- establishes or overturns a convention
- alters an interaction flow that tests depend on

Routine styling and copy edits do not belong there; they live in the git history
and in `design-todo.md`. The test is whether it would surprise someone six months
from now.

**Architecture work needs a migration map in `migration.md` before any code
moves** — current structure, target structure, the order of moves, and what each
step breaks.

## Standing instruction: check both references, and both sides

**Before choosing any value — a size, a colour, a spacing, a pattern — check two things:**

1. **`design.md`**, which is the written spec for this app. It has usually already decided,
   and more than once it had recorded the exact bug being rediscovered.
2. **What the field does** — Stripe, Shopify, GitHub, Polaris, Primer, Material, Tailwind
   UI. Where `design.md` is silent, this is the tiebreak; where it disagrees with all of
   them, that is worth raising rather than silently following either.

Checking a component that already exists is *not* the same as checking the spec. Sweeping
fourteen badges onto a component that itself carried an unspecified ring standardised the
drift instead of removing it.

**Apply every instruction to both the app and the admin side.** They are one product, and a
fix applied to one half creates exactly the inconsistency the instruction was meant to
remove. This has bitten repeatedly: a teal sidebar against a white one, a page background
that changed when you crossed into admin, `slate-50` here and `sitf-surface` there. Shared
helpers and partials — `NavHelper`, `_page_header`, `_card`, `_badge`, `.tw-btn-*` — are the
mechanism that makes "both sides" automatic; prefer changing those over changing call sites.

## Things that will trip you up

**Sign in with a username, not an email.** Devise is configured with
`config.authentication_keys = [:username]`. Seeded accounts are `admin`,
`teacher`, `student` and `mike`, all with password `password`.

**Run the app with `/workspace/run-app.sh`**, not by hand. The container binds
port 3000 internally and publishes it on the host port in `$EXPLORE_CLIENT_PORT`.
The app answering inside the container tells you nothing about whether a browser
on the host can reach it — check the gateway address (`172.17.0.1:$PORT`) rather
than inferring from the absence of a Docker socket.

**`bin/lint` is the gate**, and it includes `bundler-audit`. A dependency CVE
makes it fail even when the code is clean.

**Tests are parallel and use FactoryBot**, no global fixtures. System tests drive
real Chromium and cover the buy/sell flow — run them for anything touching
orders, money or the modal.

**Do not run two `bin/rails test` invocations at once.** Parallel workers share ten
numbered databases (`stocks_in_the_future_test_0` … `_9`), so a second run collides
with the first and both fill with `PG::TRDeadlockDetected` across unrelated tests. It
looks exactly like a parallelism bug in the suite and is not one. If you background a
loop to hunt a flake, do not also run the suite in the foreground.

**Resize the viewport through `in_phone_viewport` / `in_chromebook_viewport`, never
`resize_to` directly.** Capybara reuses one browser for the whole suite, so a test that resizes
and does not restore hands a 375px window to whatever runs next. I bypassed the helpers for one
commit and the *page-header* spacing test started failing about one run in three at 76px instead
of 24px — at 375px that header stacks, so its 40px action sits below the h1. It reads as a
spacing regression in an unrelated file, and it passes on rerun. A varying assertion *count*
between full-suite runs is the tell that state is leaking between tests.

**A factory sequence must not walk into values tests hard-code.** `Grade#level` is
unique, the sequence was `{ |n| n }`, and eleven tests hard-code levels 5–10. Roughly
one run in twenty failed with "Level has already been taken" and passed on rerun. The
sequence now starts at 1000. Check for this shape when a uniqueness validation meets a
sequence.

**A `dark:` variant is live even with no dark mode.** Tailwind v4 compiles it to
`@media (prefers-color-scheme: dark)`, so a `dark:text-slate-400` applies on any dark-OS device
regardless of whether the app has a theme switch. `.dark` is declared in `shadcn.css` and nothing
applies it, which made one look unreachable — and an audit scored it "justified, 6.99:1 on dark"
while it rendered **2.45:1** over a background that stays light. There is no dark mode here, so
there should be no `dark:`.

**Two greps in this repo's audits cannot be right, and both have produced a wrong number twice.**
`<th` matches `<thead>`, so "N `<th>` without scope" is inflated by every table. And a line-based
regex cannot see an attribute on the following line, so "images without alt" counts every
multi-line `image_tag`. Read the hits before recording a count.

**`form_with` takes `scope:`, not `as:`** — and `as:` is accepted silently into `**options`, so the
fix looks applied and changes nothing. This matters here because **`User` is an STI base**:
`form_with model: current_user` derives the param key from the record's class, so a Student posts
`student[name]` and a Teacher `teacher[name]`. A controller expecting `user` gets
`ActionController::ParameterMissing` and returns **400** for every submit. The rendered input names
are the only proof either way.

**A controller test that hand-writes its params cannot catch that.** `patch profile_path, params: { user: { … } }`
passes against a form that posts `student[…]`, because it agrees with the controller rather than with
the browser. Eight controller tests passed while every real submit 400'd. Assert the *rendered*
field names, or click the button.

**Route order decides, so a route declared after `devise_for` never fires.** A
`devise_scope :user { get "users/sign_up", to: redirect("/") }` sat below `devise_for :users` and
looked like it closed public sign-up. It did not - `/users/sign_up` rendered the form with a 200.
To override a Devise path, declare yours *first*, or `skip:` the module and re-add what you want.

**A destructive control with no test may never have worked.** "Delete account" posted to Devise's
`registrations#destroy`, which calls `resource.destroy`, and `User` raises *"Hard delete attempted …
Use #discard instead"*. It returned a 500 every time, for as long as it had existed. Before moving
or restyling a destructive control, run it.

**`mt-16` is not padding, and one `<main>` had no `padding-top` at all.** The signed-in layout was
`px-4 lg:px-6 ... mt-16 pb-6` — sides and bottom only — while the signed-out branch and admin's inner
wrapper both had `p-4 lg:p-6`. I removed per-page `py-6` / `pt-4` citing "main's `p-4 lg:p-6`", which
was two of the three cases, and every signed-in page's title went flush against the fixed nav.
**Before removing a page's padding, read the actual `<main>` that renders it** — there are three, and
they disagreed.

**A partial rendered into a `space-y-*` container must have a single root element.** `space-y-6`
compiles to `> :not([hidden]) ~ :not([hidden])`, which outspecifies `mt-1` / `mt-3`, so every
top-level element the partial emits becomes a spaced sibling. `_stocks_table` emitted three — heading,
helper line, table — and all three rendered 24px apart while the markup said 4px and 12px. Nothing in
either file was wrong on its own; the bug lived in the relationship.

**Two collections side by side is a two-column layout used wrong.** A narrow secondary column is for
metadata - status, tags, counts - which is what Polaris says and what Stripe, GitHub and Linear do.
`classrooms#show` put the roster at 765px beside a 256px grade-book rail, so one collection read as
subordinate and the other had less room than it needed. Stack them full width as `<section>`s with `h2`s
and let the order say which is primary.

**A setting in the page header reads as a page action.** The trading switch sat beside "Add student",
carried its state in the track's colour, and said nothing about what it did. A setting states its state
**in words** and what it means for the people it affects, and it belongs on its **section's header line**
- Polaris's card header action, Primer's `Subhead`, Stripe's list sections - not in the page header and
not in a card of its own. **Ask what the switch's colour is being asked to communicate**; if it is the
only thing saying which way the setting points, the state is not readable.

**A pseudo-element cannot be measured, so its geometry never gets checked.** The switch thumb was an
`::after`, and it had **0px of gap** at the bottom always and at the right when checked - a 16px thumb at
a 2px inset in a 34x18 padding box, moved by `translate-x-full`. Three passes over that markup carried the
same string forward, because `getBoundingClientRect` cannot see a pseudo-element and no test could assert
the inset. **If a control's position carries meaning, make it a real element.** It is `.tw-switch` in
`forms.css` now, defined once.

**Show what an irreversible action will do, in the confirmation.** Finalizing a grade book deposits real
money into every student's portfolio and cannot be undone, and both the page and the dialog were silent
about the amount. `EarningsCalculator` had existed for this since it was extracted - its docstring says
so - and nothing used it. **When a preview and a payment must agree, run the same object**, do not
reimplement. And note what `turbo_confirm` is here: a **native OS dialog** with no override in this app,
so the string is the only thing available to improve.

**"Derived" includes the warnings, not just the figures.** I wrote the rule below, fixed the Earns
column with it, and in the same commit left both halves of a warning out of the same turbo_stream - so
correcting the data fixed the figures and the notification kept accusing. **When you find one stale
derivation, list every derived thing on the page before moving on**: figures, totals, summaries,
warnings, counts. An element also has to *exist* to be replaced, so a conditional block needs an
always-rendered container with the id on it.

**Gate the action, not the information.** The grade book's earnings summary sat inside an
`if current_user.admin?` block with the finalize button, so the teacher entering the grades could not see
what they added up to while the admin who only presses the button could. A summary is for whoever can
open the page; only the irreversible action is administrative. If a permission check wraps both, it is
wrapping too much.

**A section's description belongs in the heading's column, never spanning under the action.** The grade
book's helper text was a sibling of the heading *row*, so it ran the full width and passed beneath the
button - at every width, not only narrow ones. Title and subtitle are one block, actions sit beside that
block, and `items-start` keeps the action level with the title rather than sinking to the subtitle. That
is what `_page_header` already does.

**A derived figure must refresh with whatever derives it.** The grade book's autosave replaced only the
buttons, so an Earns column would have gone on showing what the grades used to earn. Replace the derived
cells by id, never the table - the cursor is in an input, and replacing the table takes the focus and any
half-typed value with it.

**An input in a table cell is sized to its content**, not `w-full`. A days field at 322px for a two-digit
value is `tw-input-primary`'s `w-full` taking the column's slack. GOV.UK ships width modifiers for this.

**A yes/no answer is a segmented control on native radios, and its selected state is light.** GOV.UK
reserves a single checkbox for opting in. iOS and Material 3 both raise the chosen segment on a light
surface; a saturated brand fill repeated down 25 rows is the over-emphasis the row-action rule forbids.
A badge is never the control - it has no editing affordance.

**Check every path that creates a record before requiring a field on it.** `validates :name, presence:
true, on: :create` looked right and would have broken CSV import and the seeds, which build students
without one. The requirement is a `:student_form` context the forms opt into, plus an explicit check in
`ImportStudentService` - every path a *person* creates a student through, while a console or a seed still
can. **And `update` runs before a context validation**, so it writes the blank value and then reports it;
assign-then-`save(context:)` is the shape.

**A rejected import row is a failure, not a skip.** A skip means "this row was fine and there was nothing
to do", which is a duplicate; a row missing a required field is something an operator has to go and fix,
and the per-row failure list is what tells them which line. **Read how a bucket is *reported* before
putting anything in it** - the words the user sees are the contract, not the enum name.

**A message that summarises a bucket must derive from its contents.** "Skipped N existing usernames" was
true while a duplicate was the only thing that produced a skip, and became a lie the moment anything else
did. Deriving the wording from the actual reasons makes that class of bug impossible rather than fixing one
instance of it - the same reasoning as interpolating a rate from its constant instead of writing it out.

**Helper text that lists a format is part of that format.** The import dialog said "columns: classroom_id,
username" and kept saying it after `name` became required, so it told an admin to build a file the importer
would reject on every row. When a required field changes, grep the copy as well as the code.

**A control that can only report that it did nothing is not a control.** "Add new students" was offered on
a fully populated grade book - the normal state - where it added nobody and flashed "Every student already
has a row", which then auto-dismissed after 6s so even the explanation vanished. It renders only when
somebody is actually missing an entry. Same rule as the column of dashes: ask whether the affordance can
ever do anything for this viewer, in this state.

**Replacing a global browser primitive breaks whatever was driving the old one.** Styling
`data-turbo-confirm` took an afternoon; the 20 tests calling Capybara's `accept_confirm` - which waits
for a *native* dialog - took longer. **Before swapping a primitive, grep for what tests it**, not just
what uses it. `accept_confirmation` / `dismiss_confirmation` drive the app's dialog now.

**Proving that nothing happened needs a bounded wait.** `click`/`send_keys` do not block, so reading the
database straight after asserts against a request still in flight - and a "the action did *not* happen"
test then passes whichever way the action went. Mine passed with focus on the accept button, which is the
exact opposite of what it claimed. There is no positive state to wait on when the correct outcome is
nothing, so a short documented `sleep` is the honest instrument. **Verify such a test by making the thing
happen** and watching it fail.

**A native `<dialog>` needs `m-auto` and `w-auto` under Tailwind.** Preflight resets
`dialog { margin: 0 }`, killing the UA's centring, and the UA sets `width: fit-content`, so a panel is
sized by its own text. Both are invisible until measured - mine sat against the left edge at 301px wide.

**A `<th>` does not name a form control.** An input inside a table cell takes no accessible name from its
column header, so a table of inputs is a table of unnamed controls - the grade book had eight, four per
row. Give each an `aria-label` naming the field *and* the row, because a row is identified visually only.

**The last column of a table right-aligns**, whether it holds actions, a number or a checkbox. design.md
stated it for actions and for numerics, and every table satisfied it by accident because every other one
ends in actions; the one table that does not was the one that looked wrong.

**A native `<select>` arrow cannot be inset.** Chrome draws it against the edge of the field's padding, so
it always reads tighter than the rest of the field's contents. `appearance-none` plus our own chevron,
styled on `select.tw-input-primary` so every select in the app is fixed at once rather than call site by
call site.

**Read the page you are linking to.** I added four links to `grade_books#show`, asserted its status
badges, rebuilt the section around it twice, and never opened it. It had a table on **no surface** (0px
border, transparent, 0px radius), a checkbox rendered at **187x44px** because it carried the text-input
class, no sign of its own status, centred form actions and **two filled primaries**. A page one click
downstream of the one you are fixing has usually drifted for the same reasons.

**A pill never prefixes a sentence, and a switch is never labelled with a verb.** Both were my second
attempt at that setting, and both are inventions: Polaris, Primer and Carbon place a pill against a
*title* or on its own line, and Polaris's "Turn on" verb goes on a **button** - a switch's position is
its state, so iOS, Material and Polaris all pair a switch with a **noun**. A pill beside a sentence that
already says the state is the third copy of one fact. When the ask is "design system consistency",
reaching for a reference component's *content* rule and inventing its *wrapper* is the failure mode.

**A card per list item is card soup.** Four grade books as four `.tw-card` links, plus the roster's table
card and a setting card, put six surfaces on one page. A row with a name and a status is a **list row**:
one card, `divide-y` between rows, which is Polaris's `ResourceList` and the only divider the Dividers
spec permits there. A card earns its edges for a summary figure, a person or a preview.

**Adding to the top of a page costs the thing the page is for.** A four-across `_stat` band is 134px, and
with a setting card above it the roster's first row landed at 567px of a 625px viewport. Measure the
first row before and after any block added above the primary content - 146px before, 567px with the band,
296px without it. This is the same mistake as the trading floor's earnings card, made while fixing
something else.

**`tables.css` is layered, so a utility on the cell beats `table-body-cell`.** The class list reads
`table-body-cell py-4` and looks like the shared padding is in force; it is not, and `py-4` wins. That
put one classrooms cell's text 14px below every other column and made the row 69px against the app's
48px. **A cell that carries its own `py-*` is a bug, not a tweak** - and the same applies to any
wrapper inside it, since `py-1` and `min-h-9` on the badge strip were doing half the damage.

**Pundit's `permitted_attributes` returns filtered params, not the attribute list.** Passing its return
value into `params.expect` raises `ParameterMissing`, so every write 400s. Worse, the negative tests
("a teacher cannot change X") all **passed** while it did, because a 400 changes nothing either. When
asserting that a request cannot do something, assert in the same file that a permitted request can -
otherwise a broken endpoint reads as a secure one.

**When a role gains edit rights, the permitted attributes are the real decision.** A teacher may edit
their classroom's name, grades and trading flag; `school_id` / `year_id` move it between school years
and `teacher_ids` is *who may see and edit it*, so those stay admin-only in
`ClassroomPolicy#permitted_attributes`. The form hides what the filter drops - a field whose value is
silently discarded looks like a save that worked.

**A column of dashes is not a column.** The `table-no-permission` dash means "no action on this row",
which only says something when other rows have one. `ClassroomPolicy#edit?` **was** admin-only, so a
teacher's classrooms table was an unlabelled trailing column of italic hyphens, every row. Ask whether
**any** row has a permitted action; if none does, drop the header, the cells, and one from the empty
state's `colspan`. Teachers can edit their own classrooms now, so that guard fires only for a viewer
with no rows - the rule outlives the case that found it.

**A callout's dismiss is a round trip, never a Stimulus controller.** A client-side close on page state
brings the banner straight back on the next load, because "trading is turned off for your classroom" is
still true. Dismissals go in the **`dismissals` table** - one row per user per key - via
`POST /dismissals`, and `Dismissible` on `User` gives you `dismissed?(key, since:)` and `dismiss!(key)`.
**Adding a dismissible banner is a key in `Dismissal::KEYS` and a `button_to`**: no migration, no
route, no controller action. A form error summary gets no close at all - it describes the form as it
stands and is rebuilt on submit, so hiding it hides the list of what is still wrong.

**`||=` in a `before_save` cannot maintain an invariant.** `trading_disabled_at ||= Time.current` kept a
**stale** value, so a row sitting in the inconsistent state - trading on with a date still set, which is
what `update_column`, `update_all` or a row predating the callback all leave behind - reported the
previous switch-off as the onset of the new one, and a dismissal made in between suppressed the callout
for good. Stamp on the **transition** (`will_save_change_to_*?`) and treat nil as its own case. Every
test passed, because they all enabled first and enabling nils the column: **a callback that reconciles
two fields needs a test that starts from them disagreeing.**

**Pass `since:` or the dismissal is a mute button.** It defaults to nil, which means permanent, and a
caller who forgets it fails *silently* - the banner simply never comes back. Correct for something that
happens once (`celebrate_first_share?` omits it on purpose); wrong for any condition a teacher can turn
off, on and off again. That is why `classrooms.trading_disabled_at` exists and why `Classroom` **clears
it when trading comes back on**: each switch-off carries its own date and outranks an earlier
dismissal. Ask what the dismissal dismisses - this message, or every future instance of it.

**A `button_to` dismiss cannot live in the component.** `button_to` renders a whole `<form>`, and the
callout in `admin/teachers/_form` sits inside the teacher form, where the parser drops the nested form
and the button silently submits the outer one. That is why the dismiss is passed as a block per call
site - a component-level default would have broken that page and still rendered fine.

**A message that removes itself must be an outcome, not a state.** The success flash auto-hides after
6s; `#alert` never does, and neither do callouts or form error summaries. "Trading is turned off" is
true until a teacher changes it, so a callout that deleted itself would be lying about the page, and
an error is often the only record of what went wrong. Before giving anything `auto-dismiss`, ask
whether the sentence is still true in a minute. `flash_dismiss_test.rb` asserts this on the attribute,
so a wrong one fails by name.

**Two ways an auto-hiding element gets stuck on screen.** Fade with an **inline style**, because
Tailwind only emits classes it can see in the templates and an `opacity-0` added from JS may not be in
the build. Remove on **its own timer**, not `transitionend`, because a transition that never fires -
skipped under reduced motion, interrupted by a display change - leaves the message up forever.

**A banner is only as wide as the container it is in, and the flash was in `<main>`.** The content
column was per-page (`mx-auto max-w-7xl` in the view) while `layouts/_flash` was a bare child of
`<main>`, so at 1920px the sign-in notice measured 1601px over cards of 1280px. **Anything the layout
renders alongside `yield` has to share the page's column**, which is why the column now lives in the
layout around both. Note the near miss: constraining the flash instead would have inverted the bug on
the four pages that declared no column at all.

**A layout width bug is invisible at every width the suite tests.** This one needs a viewport above
~1584px - below that, main's content box is already narrower than `max-w-7xl`, so the cap does
nothing and everything lines up. 1400, 1366 and 375 all measured a perfect match. **When a report
only reproduces on a wide monitor, add the wide viewport rather than trusting the existing ones.**

**Wrapping `yield` moves every selector that reaches through `main`.** `main > div` used to be the
page; it is now the content column, and the page is one level deeper. `spacing_test`'s `section_gaps`
read `main > div > *`, got a single element, never entered its comparison loop, and the test **passed
while asserting nothing** - the only signal was minitest's "missing assertions", and the assertion
count dropping 21 to 19. Adding a wrapper to a layout is a selector change: check the count, not just
the pass.

**`bin/dev` needs `tailwindcss:watch[always]`, or it kills itself with no TTY.** Plain `-w` makes the
tailwind CLI exit the moment stdin closes — Docker, or any backgrounded run — and foreman terminates
the whole formation when any one process exits. So `bin/dev` booted Puma, printed `Done in 929ms`,
SIGTERM'd itself, and left **no error**: the failure reads like a clean shutdown. If a dev process
disappears without complaint, check whether a sibling exited first.

**And `-b 0.0.0.0`, or nothing reaches the browser.** A bare `bin/rails server` binds `127.0.0.1`,
and Docker's published port cannot forward to loopback inside the container. `docker-compose.yml`
always passed the flag; `Procfile.dev` did not, so swapping a hand-run `bin/rails server -b 0.0.0.0`
for `bin/dev` silently took the app off the browser while every check still passed.

**`172.17.0.1:$PORT` is my check, not the browser's URL.** The gateway address is how *this container*
reaches the published port, and curling it proves the publish works. It is not where the user goes: on a
macOS host that IP lives inside Docker Desktop's Linux VM and no browser there can route to it. The host
URL is **`localhost:$EXPLORE_CLIENT_PORT`** - `localhost:3700` here. I handed over the gateway address
and the page "did not load", which cost a round trip; note that the container cannot verify the host URL
either, since 3700 is not bound in here, so getting it right matters more than usual.

**A page under `/admin` needs the `admin` account.** `Admin::BaseController#authenticate_admin` redirects
any non-admin to the app root with an alert, so as `teacher` a preview link lands on the trading floor
rather than failing visibly - which reads like a broken link.

**A container cannot check its own reachability over loopback.** `curl 127.0.0.1:3000` from inside
succeeds whether the bind is loopback-only or not, so it cannot distinguish the working case from the
broken one — I called the server verified on exactly that evidence. Use the container's own address,
`hostname -i` (172.17.0.2 here), or read `Listening on` in the log. The same trap applies to any
"is it up" check run from the same side as the thing being tested.

**Two more shapes that lie about being dead or alive.** `pkill -f "bin/rails server"` does not match
Puma, which renames itself to `puma 8.0.2 (tcp://0.0.0.0:3000)`; it survives, keeps the port and
`tmp/pids/server.pid`, and the next boot fails with *"A server is already running"* while curl still
answers 302 from the corpse. Solid Queue likewise renames to `solid-queue-fork-supervisor`, so
grepping for `solid_queue` finds nothing and it looks dead when it is fine — `SolidQueue::Process`
is the honest check. And a `-w always` watcher can outlive foreman's SIGTERM, leaving two watchers
on one output file.

**Tailwind v4 in watch mode only grows.** Deleting a class does not shrink `tailwind.css` until the
watcher restarts, and tailwind skips the write entirely when output bytes are unchanged — so a
stale mtime is not evidence that a rebuild did not happen.

## Money

**Integer cents are authoritative. Never convert to a Float and back.**

`Portfolio#cash_balance_cents` is for arithmetic and comparison.
`Portfolio#cash_balance` is a Float for display only. The float round trip
silently loses value for most two-decimal amounts: 131,252 of the first two
million cent values come back low, which once made an exactly-affordable order
fail with "You have $16.06 but need $16.06".

Always render money through `number_to_currency`. Interpolated raw, a
whole-dollar price prints as `$15.0`.

Postgres types `price_cents / 100.0` as `numeric`, not double precision, so
existing SQL that does this is exact. Do not "fix" it.

**The trading fee has two halves, in different files.** `Portfolio#pending_transaction_fee`
*holds* the amount while any order is pending, without persisting anything.
`TransactionFeeProcessor`, called by `OrderExecutionJob` after `ExecuteOrder`,
then writes the real `PortfolioTransaction` with `transaction_type: :fee`.

Reading `ExecuteOrder` alone suggests the fee is never charged — it writes only
`purchase_cost`. I concluded exactly that and was wrong, twice, because a grep for
`transaction_type: :fee` and `.fee.create` missed the plural scope `.fees.create!`.
**To audit fee behaviour, run `OrderExecutionJob`, not `ExecuteOrder` directly**,
or you will see the hold released and no charge appear.

The fee is once per student per job run, not per order. That is deliberate.

**Earnings amounts live in `EarningsCalculator`, which is pure.** `DistributeEarnings`
only persists what it returns. Anything that needs to *show* earnings should call the
calculator rather than re-implement the rules. Three things about those rules surprise
people, all pinned in `distribute_earnings_characterisation_test.rb`:

- C and below earn nothing for the grade, but improvement still pays — F → D earns
  200 cents.
- Improving within a band counts. A- → A pays the improvement.
- Quarter 1 pays no improvement, but *not* because `Quarter#previous` is nil: it falls
  back to quarter 4 of the previous school year. What stops it is that a classroom
  belongs to one school year and only has grade books for that year's quarters, so the
  lookup asks for a grade book that cannot exist. Give classrooms grade books spanning
  years and improvement quietly switches on in quarter 1.

When changing money rules, pin the current numbers as **literals** first. The older
`distribute_earnings_test.rb` computes its expectations from `GradeEntry`'s constants,
so it agrees with whatever the code does and cannot detect drift.

## Copy

**Sentence case everywhere.** Capitalise the first word and proper nouns only.
Never all-caps, and never the `uppercase` CSS transform on labels — use size,
weight and colour for hierarchy.

**A view grep will not keep this done.** It took six passes here, each finding
copy the previous one structurally could not see:

1. Headings, `form.label`, `form.submit`, placeholders.
2. Table cells, definition lists, spans.
3. `link_to` / `button_to` label arguments.
4. Text inside a `link_to ... do` block — it sits on its own line, so no
   `link_to "..."` pattern ever matches it. Same for labels alone on a line in
   multi-line calls.
5. `div`, `label` and `th` text nodes.
6. The `uppercase` CSS transform written inline in markup, and copy whose
   punctuation broke the pattern (`Perfect Attendance?`).

**The hard limit: copy that is not a literal cannot be swept.** The portfolio
heading was `username.upcase` plus PORTFOLIO in capitals. No text search would
ever have found it — only reading the rendered page did. So:

- **Look at the rendered page**, not just the templates, before calling it done.
- Grep for `.upcase`, `.titleize`, `.capitalize` in views and helpers.
  `stock.ticker.upcase` and an avatar initial are correct; a heading is not.
- Grep for `uppercase` in markup as well as stylesheets.
- `config/locales/en.yml` counts, including `activerecord.attributes` names that
  surface inside validation messages.
- Propagate to tests from the **views diff**, never by running the converter over
  test files — those hold fixture data and real company names.

**Pass seven found three more categories, none reachable from `app/views`:**

7. **Breadcrumb labels live in controllers**, not views — `label: "New Teacher"` in every
   admin controller. These also feed the admin layout's `sr-only` h1, so the hidden
   heading read "New Teacher" while the visible one read "New teacher".
8. **Strings inside array and hash literals** in a view — `['Attendance Earnings', ...]`
   — which no `label:`/`link_to`/`<th>` pattern matches.
9. **Submit labels**, both explicit (`f.submit "Update Stock"`) and — the one that cannot
   be grepped at all — **bare `form.submit`**, where Rails generates "Create Classroom"
   from the model name. That string exists nowhere in the source. Give every submit an
   explicit label.

And Title Case is sometimes correct. The full list, from sweeping twice and
re-catching the same false positives both times: acronyms and tickers, CamelCase class
names (`DateTime`, `Admin::FormBuilder`), company names and competitor lists, CEO and
person names, industry classifications ("Consumer Electronics"), seed fixture values,
placeholders that are examples of the thing ("John Doe", "Apple Inc."), and **API
response keys** — `'Global Quote'` in `AlphaVantageApiClient` is a JSON key, and
lowercasing it would break the parse. Two were caught mid-sweep and
reverted: `John Doe` and `DateTime`.

## Components

Build on `app/views/components/ui/`: `_card`, `_page_header`, `_badge`,
`_empty_state`, `_data_table`, plus `_button`, `_input`, `_label`, `_checkbox`,
`_textarea`. `admin/shared/_empty_row` wraps `_empty_state` for use inside a
table body.

Partials rendered with `render layout:` must check whether the yielded content is
present rather than calling `block_given?` — that is unreliable inside a partial
layout.

Icons come from `lucide_icon`, which renders `aria-hidden` by default. An
icon-only control therefore needs its own visually hidden text, or it has no
accessible name at all.

`button_to` renders a whole `<form>`. Never place one inside another form: the
browser drops the nested `<form>` tag during parsing, and the button silently ends
up submitting the *outer* form to the outer form's action. It looks fine, renders
fine, and passes a controller test that POSTs to the route directly. Only a system
test that actually clicks the button catches it. When an empty state needs an
action, branch around the form rather than putting the empty state inside it.

## Responsive

Only `base` and `lg:`. No `sm:`, `md:`, `xl:` or `2xl:`. Users are students on
school Chromebooks at 1366x768 and phones at 375px, so those are the two widths
to check.

**Buttons are 40px (`h-10`), not 44px.** That is design.md's height token and what
`.tw-btn-*` and the admin button helpers use. WCAG 2.5.8 (AA) asks for 24x24, so 40px
clears it comfortably; 44px is the AAA / Apple HIG figure. I once set the admin buttons
to `min-h-11` citing "44px touch targets" and they ended up visibly taller than every
other button in the app. Reserve 44px for bare tap targets with no other affordance -
icon-only controls, sidebar nav rows.

## Measure the rendered box

**Class names describe intent. Only the rendered box describes the result.** When spacing
or alignment looks wrong, measure `getBoundingClientRect()` in a browser before changing
anything — reading the markup will usually tell you it is already correct.

This cost three rounds on this branch. A page title reading `mb-6` rendered a 44px gap
(a `pb-5` left behind when the rule under it went), then a card header reading `py-4`
over a `p-5` body rendered 37px (two paddings stacking at the seam), then a header
reading `mb-6` rendered 32px (a 40px action beside a 32px h1 in an `items-start` row,
leaving 8px of dead space under the title). None was visible in the class list.

Two of the three were caused by **removing something and leaving its spacing behind**.
When you delete a rule, a border or a divider, delete the padding that existed to hold
content off it.

`test/system/spacing_test.rb` asserts pixels, not classes, for exactly this reason.

**"Present in the DOM" is not "on screen."** The trading floor's Buy and Sell buttons - the only
call to action in the student-facing product - sat at `left=370` inside a scroll wrapper `326px`
wide at 375px, past the right edge of a horizontal scroll. Every test passed: `assert_selector`
found them, `click_on "Buy"` clicked them, because Capybara's visibility check is `display` /
`visibility` / size and knows nothing about whether an ancestor has scrolled the element out of
view. I then wrote a design.md rule *about* those buttons without ever rendering the page. When a
control lives in a table's trailing column, measure its box against the scroll container's box at
375px, and check `scrollWidth` against `clientWidth`.

**A class you pass can be silently overridden by the thing you pass it to.** `Shadcn::FormBuilder`
prepends its own base to whatever `class:` it is given, so a field handed `tw-input-primary` carried
both strings - and since utilities beat component classes, the shadcn ones won. Sign in and sign up
kept a 40px `rounded-md` field while every other form moved to 44px `rounded-lg`, and the markup read
as if it were fixed. Check the rendered element, not the argument.

**A named class with one caller drifts as surely as no class at all.** `tw-input-primary` existed for
months with a comment describing the exact placeholder failure it fixed, while `Admin::FormBuilder`
rendered nine forms with `placeholder:text-gray-400` at 2.54:1. Same for `.tw-btn-*` before the
button sweep. When you write a shared class, convert every caller in the same change, or it becomes
documentation of a fix nobody got.

**Contrast maths on `oklch()` needs a real conversion.** `getComputedStyle().color` returns
`oklch(0.446 0.043 257.281)` in this browser, and pulling the three numbers out as if they were RGB
reports slate-600 on slate-50 as **1.05:1**. I wrote an audit that way and reported five contrast
failures that did not exist. Canvas `fillStyle` returns `oklch()` unchanged too, so normalising
through it does not help - **paint one pixel and read it with `getImageData`**, which cannot be fooled.

**A conditional affordance needs a condition.** The pinned actions cell's separator was
unconditional below `lg`, so it drew a rule with nothing behind it on any table that fitted or had
not yet been scrolled. Scroll state, not a breakpoint: `data-table-scrolled` from a capturing
listener on `body`. Same class of error as the hover fill hanging off the edge - a decoration that
only makes sense in one state, applied in all of them.

**Measure the element that actually scrolls.** I concluded a table "never scrolls at any width" while
measuring `.table-wrapper`, which is `overflow-hidden` and can therefore never report scrolling. The
scroll container was the `overflow-x-auto` div inside it. `closest("[class*='overflow-x']")` from the
cell finds the right one. A `scrollWidth == clientWidth` result should prompt "is this the scroller?"
before it prompts a conclusion.

**The box that paints is the box that aligns.** A 44px target centring a 24px icon puts the glyph
10px inside its box, and the fix is *not* to pull the box out. I tried that three times - a filled
button, then a borderless one with a `hover:` fill, then a 44px target wrapping a 40px state layer -
and every version put paint past the content edge, because a negative margin drags whatever paints
with it. Tailwind UI's `-m-2.5 p-2.5` inset works only because its trigger paints nothing at all, in
any state. If a control has a hover fill, align its box and let the glyph sit inside.

**Where design.md names a value, that is the value.** The radius token is `controls rounded-lg`. I
changed the trigger to `rounded-full` and wrote the justification into design.md - an aesthetic
argument for overriding an explicit spec, on a turn whose instruction was to follow the spec. The
field is the tiebreak only where the document is silent, and it was not silent.

**Check `overflow-auto` on `<main>` before measuring gutters.** It makes main its own scroll
container, so the scrollbar sits inside the padding box and the right gutter measures ~15px wider
than the left. Also measure against `document.documentElement.clientWidth`, not `window.innerWidth`:
the latter includes the scrollbar and will report a phantom asymmetry.

**A style written in two places survives every sweep of one of them.** The grey table header was
`.table-header-row` on the app side *and* an inline `<thead class="bg-slate-50">` on fourteen admin
tables; three sweeps fixed one form and left the other. Same shape as the two button bases. When you
find a token in a shared class, grep for the inline form too - and vice versa.

**Match cells on the class list, not on an exact string.** Half the hand-written `<td>`s were missed
because they read `whitespace-nowrap px-3 py-2 text-sm ...` with the padding in the middle rather
than at the front. Search for any `<td>`/`<th>` whose class has a `px-`/`py-` and no `table-*-cell`.

**A row partial is invisible to a scan for rows inside a `<tbody>`.** `grade_books/_grade_entry` is a
bare `<tr>` whose tbody lives in another file, so it kept its own padding and lost its separator when
the tbody's `divide-y` went.

**Two stacked tables need one column geometry.** Separate `<table>` elements size their columns
independently, so a wider actions column in one shifts every column relative to the other and the
page steps sideways at the boundary. Give every column but the first an explicit width.

**"It uses the named class" is not "it matches the spec."** I moved Buy/Sell onto
`.tw-btn-secondary` and reported it as design-system alignment. The class itself was off spec:
`ring-1 ring-slate-300 ring-inset` where design.md says `border border-slate-200`. Four other
variants were off too - `font-medium` on the filled ones, a `border border-transparent` design.md
forbids by name, `border-slate-300`, and a missing `justify-center` - because the base was written
**twice**, in `buttons.css` and as `ADMIN_BUTTON_BASE` in Ruby. Two definitions of one thing is the
drift mechanism; the admin helpers are aliases now. Read the spec's own token list against the
rendered box before calling a variant correct.

**An unlayered CSS rule beats every layered one, whatever the specificity.** The `.tw-*` component
files are imported after `@import "tailwindcss"`; until they were wrapped in `@layer components`,
`.tw-btn-buy`'s `display: inline-flex` beat `.hidden`, so the order modal showed Cancel, Back,
Review order and Buy shares simultaneously. `hidden` appeared in the markup and did nothing. If a
utility "isn't working", check whether the thing beating it is unlayered before touching
specificity - and assert it: at 375px, any element carrying `.hidden` whose computed `display` is
not `none` is a cascade failure.

**Measure `main.scrollWidth` against `main.clientWidth` at 375px on every page, not just tables.**
Three unrelated things pushed the page sideways: a `flex` row with no `lg:flex-row`, an unwrappable
`inline-flex` breadcrumb trail, and an element that should have been `display: none`. A page-level
scroll defeats a pinned table cell, because the cell pins to a container that is itself being
pushed. `flex-1` panes want `min-w-0` or a wide table inside them refuses to shrink.

**Sweep the whole app when you find one of these, not just the page reported.** The trading floor
turned out to be one instance of a pattern: every admin index table had its row actions off screen
at 375px too (212-699px of overflow), and `classroom#show` had a `flex gap-8` that never stacked,
so `<main>` itself scrolled and carried the actions away. Two different fixes - pin the actions
cell, stack the row - and only measuring told them apart. A useful audit is a script that walks the
pages and, for every clickable, compares its box to the box of the nearest ancestor whose
`scrollWidth > clientWidth`.

**Widening a control can push it off screen.** Converting row actions from icon-only to labelled
ghosts took the actions column from ~100px to ~250px, which is 73% of a 343px viewport. The change
looked purely cosmetic and was the reason the actions stopped fitting.

**Check what each role actually sees before describing a screen.** `StockPolicy#show_holdings?`
hides the holdings and action columns from anyone who is not a student with a persisted portfolio,
so as `admin` or `teacher` the trading floor is a two-column price list with no buttons at all.
Signing in as the role you have been working under and looking is one command:
`curl` the page with a session cookie and grep for the testid.

## Accessibility

Measure contrast, do not guess. Failures found here that are easy to repeat:
`gray-400`/`slate-400` as text (2.5:1), `red-500` (3.8:1), `teal-500` with white
(2.5:1), `amber-500` with white (2.2:1), `--sitf-ring` as a focus indicator
(2.0:1), and the lime `--sitf-accent1-chart3` as any foreground (1.4:1 — fill
only).

Tailwind v4 resolves an unset `--tw-ring-color` to `currentColor`, so a
`focus-visible:ring-2` with no colour gives a white ring on a white button. Always
name the ring colour.

`bg-opacity-*` and `ring-opacity-*` were removed in Tailwind v4 and compile to
nothing. Use the slash syntax (`bg-black/50`).

## Audit helpers and stylesheets, not just templates

Twice on this branch a sweep looked complete because it only covered
`app/views`:

- A faint-text pass reported four justified exceptions while `admin_helper.rb`
  was still rendering absent values at 2.6:1. A failing test found it, not the
  audit.
- A markup sweep removed every arbitrary hex and `[var(--...)]` from views, and
  `buttons.css` kept both — including `bg-[#BOEAE5]`, which is not a valid hex
  (letter O, not zero). Tailwind emitted it verbatim, the browser dropped the
  declaration, and that button rendered white text on no background. The Buy
  control on the trading floor was separately at 1.81:1 in the same file.

`@apply` classes are Tailwind, so they look migrated and get skipped. They are
not exempt from the token rules or from contrast. Any audit should cover
`app/views`, `app/helpers`, `app/assets/tailwind`, `app/components` **and
`app/form_builders`**.

That last one was missing and it hid the biggest colour divergence in the app:
`Admin::FormBuilder#submit_button` backs eleven admin forms and was `bg-blue-600`
at `rounded-md px-4 py-2`, so every admin form's primary button was generic blue
and a different size from the primary button in the page header above it.
`Shadcn::FormBuilder#submit` delegated to the shadcn `render_button`, whose
`--primary` is a near-black navy - the sign-up button was the only off-brand
primary in the product. **Tailwind scans `.rb`, so a button defined in Ruby
compiles and ships exactly like one in a template.**

Also: delete unused CSS rather than leaving it. An unused class is
indistinguishable from a supported one until someone adopts it. `admin.css` held
five unreferenced classes with eight `!important` declarations and pre-token hex,
and I spent effort "fixing" a focus indicator on one of them before noticing
nothing rendered it.

## Hover states are invisible to the tests

**You cannot verify a `hover:` style from a system test here.** Tailwind v4 emits
hover utilities inside `@media (hover:hover)`, and the headless Chromium Capybara
drives reports `(hover: none)`. Measured: with the pointer over a Delete link,
`el.matches(":hover")` is `true`, the class list contains `hover:text-rose-700`,
the rule and the `--color-rose-700` token both exist in the compiled CSS - and the
computed colour is still slate. Nothing is broken; the declaration simply never
applies in that browser.

So assert hover as a **class contract** in a helper test, and assert the resting
colour, icon and geometry as rendered pixels in a system test. I spent four rounds
chasing a bug that was not there.

Related trap: **the compiled stylesheet is minified.** Grepping
`app/assets/builds/tailwind.css` for `@media (hover: hover)` returns nothing while
`@media (hover:hover)` returns nine hits, which is what sent me looking for a
specificity problem instead. When a grep of that file comes back empty, try it
without the spaces before concluding anything.

## Comments are not inert

A comment containing its own terminator ends early, and the remainder becomes
content. I did this twice on this branch: a `*/` inside a CSS comment broke the
Tailwind build, and a `%>` inside an ERB comment leaked a whole sentence onto a
rendered page as visible text. Don't write those sequences inside the comment that
uses them.

Relatedly, interpolating an optional HTML attribute yields an *unquoted*
attribute, which CSS and Capybara selectors will not match. Use `tag.div`, which
omits nil attributes entirely.
