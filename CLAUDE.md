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

**A factory sequence must not walk into values tests hard-code.** `Grade#level` is
unique, the sequence was `{ |n| n }`, and eleven tests hard-code levels 5–10. Roughly
one run in twenty failed with "Level has already been taken" and passed on rerun. The
sequence now starts at 1000. Check for this shape when a uniqueness validation meets a
sequence.

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

**An icon-only control aligns by its glyph, not its box - but only if it is borderless.** A 44px hit
area centring a 24px icon puts the glyph 10px inside the container's padding, so a header trigger on
the same `px-4` as the content still looks 10px further in. Pull the hit area out (`-ml-2.5`). If the
control has a *visible* fill or border, do the opposite - align the box - or it ends up hanging off
the edge. I pulled a filled teal hamburger out and left it 6px from the viewport edge before noticing.

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
