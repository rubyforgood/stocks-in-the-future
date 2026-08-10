# Design Migration Backlog

> Live "what's left" list for the `stocksdesign` UI migration.
> Process: [`design-instructions.md`](design-instructions.md). System: [`design.md`](design.md).
> Tick a page only once **both** the accessibility and responsiveness gates pass.

Generated from an automated audit of 117 templates.
Counts are indicative, found by pattern matching - confirm by reading the file.

## Legend

| Flag | Meaning | Gate |
|------|---------|------|
| `hex` | Arbitrary hex colour instead of a token | design system |
| `off-tier bp` | Uses `sm:`/`md:`/`xl:`/`2xl:`; only `base` and `lg:` are allowed | responsiveness |
| `faint text` | `text-gray-300/400` or lighter - fails 4.5:1 | WCAG |
| `img no alt` | `image_tag` with no `alt:` | WCAG |
| `outline-none` | Focus outline removed; needs a visible replacement | WCAG |
| `div-as-button` | Clickable `<div>` instead of `<button>` | WCAG |
| `th no scope` | `<th>` without `scope` | WCAG |
| `FA icon` | Font Awesome glyph loaded from CDN | design system |

## Totals across all templates

| Flag | Count |
|------|-------|
| Arbitrary hex colours | 19 |
| Off-tier breakpoints | 153 |
| Faint text colours | 33 |
| Images without alt | 6 |
| `outline-none` | 17 |
| Clickable divs | 4 |
| `<th>` without scope | 58 |
| Font Awesome CDN icons | 78 |

## Foundations (do these first - every page depends on them)

- [x] `layouts/_nav_item.html.erb` - **new** shared sidebar link partial
- [x] `layouts/_flash.html.erb` - **new** accessible flash partial

**This per-file survey is superseded.** It was the *pre-work* inventory: 128 rows counting Font
Awesome icons, off-tier breakpoints, `<th>` without `scope`, arbitrary hex, images without `alt`,
`outline-none` and faint text. Every one of those categories has since been swept, so the rows
described the codebase as it was, not as it is - and leaving 128 unchecked boxes made finished work
look outstanding.

Re-measured rather than assumed, across `app/views`, `app/helpers`, `app/form_builders` and
`app/assets/tailwind`:

| Category | Now | Note |
|---|---|---|
| Font Awesome | **0** | one grep hit, a comment recording the removal |
| `sm:` / `md:` / `xl:` / `2xl:` | **0** | hits were `compact:`-style locals and prose, not utilities |
| `<th>` without `scope` | **0** | all 20 hits are `<thead>`, matched by the `<th` prefix - the same inflation this file already recorded for the original count of 58 |
| Arbitrary hex | **0** | |
| `image_tag` without `alt` | **0** | all hits carry `alt:` on the following line - the line-based-regex miscount recorded above |
| `outline-none` with no paired colour | **0** | |
| Faint text | **3** | all justified: two `aria-disabled` pagination spans and one `dark:` variant at 6.99:1 |

Two greps in that list produce false positives *by construction*, and both had already fooled an
earlier pass: `<th` matches `<thead`, and a line-based regex cannot see an attribute on the next
line. A count from either is worthless without reading the hits.


## Cross-cutting work items

### Delight: built

The six recommended features are implemented on `portfolios#show` - see design.md, "Delight on the
student side". **The preview page is deleted**: its proposals shipped, so it had become a stale copy
showing a teal panel and a party-popper the built version does not use - an off-brand mock of a
brand-corrected feature, which is worse than no page.

**The token decision is made.** `--sitf-secondary-teal` (#00b8b0) is deleted and so is the
`--color-sitf-secondary` utility. `--sitf-secondary-chart2` (#1db8a6) survives as what it actually
is - chart series 2 - because mint is not this product's brand, and a named "secondary" utility
holding mint is how mint kept arriving on brand surfaces. If a secondary brand colour is wanted,
choose it against #00698c rather than inheriting a chart colour.

**The reading streak is closed, not open: decided against.** Earnings are distributed when an adult
clicks Finalize on a grade book (`grade_books_controller#finalize`), and a school year has four
quarters. So a student's streak breaks when a *teacher* is late; four data points a year gives none of
the feedback that makes a streak work at all; and one break is unrecoverable within the year, landing
hardest on the student who had a bad term - the last person to discourage. If that recognition is
wanted, the shape that survives all three is a **cumulative count** ("earned reading money in 3
quarters"), which is monotonic and cannot be taken away. Rated below the six that shipped.

### ~~Eight unused images~~ - done (thirteen files, and the count was nine)

Deleted: `piggy_bank.png`, `investment-funds.png`, `party_popper.png`, `boy_using_computer.png`,
`girl_skateboarding_holding_laptop.png` and `1_Number.png` through `4_Number.png` - **nine**, not
eight; the heading undercounted its own list.

Four more went with them, and they are the ones worth remembering: `house.svg`, `id-card.svg`,
`receipt.svg` and `chart-no-axes-combined.svg`. **Their filenames match Lucide icon names**, so a
grep for `house` finds `lucide_icon("house")` and reports the file as used. It is not - `lucide_icon`
renders from the gem, and nothing `image_tag`s any of them. All four exist in
`lucide-rails/icons/stripped/`.

**`SITF-Horz-logo.svg` is kept.** It is unreferenced, but it is the only logo variant carrying the
tagline, and deleting the sole tagline logo is a brand decision rather than a sweep.

### ~~There is no user profile page~~ - done

`/profile/edit`, via a new `ProfilesController`. Two forms, because the two changes cost different
things: a display name should not require proving your password, and a password change must. That
merge is exactly why Devise's `registrations#edit` was never usable here.

The display name writes the `users.name` column, which **had existed all along with nothing reading
it** - `display_name` was `username.presence || …`, so a user had no name they could set. It prefers
`name` now, which also means the avatar initials and tone follow it.

Username is shown `readonly` rather than edited: it is the sign-in key and a teacher assigns it. And
"Edit profile" now sits above "Sign out" in the account menu, which the panel was already built for.

**The bug it shipped with is the lesson.** `User` is an STI base, so `form_with model: current_user`
scoped its fields to `student[…]` / `teacher[…]` while the controller expected `user`, and every
submit was a 400. Ten controller tests passed throughout, because a test that hand-writes
`params: { user: … }` agrees with the controller rather than with the browser. Two further traps in
one fix: `form_with` takes `scope:`, not `as:` - and it swallows `as:` silently, so the first fix
looked applied and changed nothing.

**Still open, and now a duplicate:** Devise's `registrations#edit` is routed and reachable, and
overlaps this page. Decide whether `/users/edit` should redirect here.

### `Admin::FormBuilder` field styling is still pre-token

The button sweep routed `submit_button` and `cancel_button` through the shared button classes, and
the field sweep routed `INPUT_CLASSES`, `INPUT_ERROR_CLASSES`, `LABEL_CLASSES`, `ERROR_CLASSES` and
`HINT_CLASSES` at the named form classes. What is left is the rest of
`app/form_builders/admin/form_builder.rb` is still on the pre-migration palette:
roughly 35 references to `gray-*` rather than `slate-*`, `blue-600` focus rings
instead of the brand teal, `ring-red-300` / `text-red-300` error affordances, and
an `sm:` responsive tier this app does not use (`sm:text-sm sm:leading-6` on every
input). Eleven admin forms render through it.

Two measured AA failures in there, both `text-gray-400` at **2.54:1** on white:
`placeholder:text-gray-400` in `INPUT_CLASSES`, and the `—` rendered for an absent
value in `format_value`. That second one is the *same* failure `admin_helper.rb`
had for absent values, which a test caught rather than an audit.

Not done here because it is a form-field migration, not a button one, and it wants
its own pass with contrast measured per state. `app/components/shadcn/` has the same
problem with its own token set (`--primary` is a near-black navy) and only three
call sites left.

### ~~Devise pages that are still raw scaffolding~~ - done

`devise/passwords/edit` and `devise/registrations/edit` are on the shared page header, the named
field classes and the card primitive. Finished in this pass: both dropped a `py-6` that stacked on
`main`'s own padding, the password card came off `p-6` onto the `p-5` token, the account page's
delete section said "Cancel your account" while its button said "Delete account" (Cancel means
*dismiss* on eleven form buttons and the order modal), and it reached into `admin_danger_button_class`
from a user-facing page - an alias for `tw-btn-danger-outline`, but it reads as though the two sides
have different buttons.

`devise/shared/_links` was the last stock generator markup: bare unstyled `<a>`s separated by `<br>`,
with "Log in" against ten "Sign in"s. **Four of its six branches were dead** - the model enables
`database_authenticatable, registerable, recoverable, rememberable, validatable`, so the two
"Didn't receive … instructions?" branches and the omniauth branch could never render.
`devise/unlocks/new` and `devise/confirmations/new` had already been deleted for the same reason.

- [x] Fix invalid `focus-visible:ring-2a` in `input_helper.rb` - it compiled to nothing, leaving inputs app-wide with no designed focus indicator. Now an explicit 2px `sitf-primary` ring at 5.9:1.

- [x] Add SITF brand colours as semantic tokens so pages stop hardcoding hex. **done**: `sitf-surface`, `sitf-primary`, `sitf-primary-dark`, `sitf-on-primary`, `sitf-secondary`, `sitf-accent`, `sitf-warning`, `sitf-danger` in `tailwind.config.css`, sourced from `shadcn.css`.
- [x] Replace the Font Awesome CDN link with local SVG icons. **done**: all 76 usages converted to `lucide_icon` (the gem was already a dependency and already the convention in 3 views). CDN `<link>` removed from both layouts. Icons now inherit `currentColor` and carry `aria-hidden` by default.
- [x] Sweep `sm:`/`md:`/`xl:`/`2xl:` down to `base` + `lg:`. **done**: 122 remapped across 31 view files, 0 remaining. Multi-tier ramps (e.g. `text-sm sm:text-base md:text-lg lg:text-xl`) collapsed by hand. Also removed the off-tier usages in `forms.css` and deleted the dead legacy top-nav block in `navbar.css`.
- [x] Add `scope` to every `<th>`. **done**: 42 added across 8 files (the original count of 58 was inflated - the audit regex also matched `<thead>`). All were column headers; 0 row headers.
- [x] **Faint text** - **done**, see the measured entry below. Three justified cases remain: two disabled pagination spans (`aria-disabled`, and WCAG 1.4.3 exempts inactive components) and one `dark:` variant at 6.99:1 on dark. The fourth, the `—` for an absent value in `Admin::FormBuilder#format_value` at 2.54:1, is now `slate-500`.
- [x] Give every `outline-none` a visible focus replacement. **done**: most already paired with a visible `focus:ring`. Real failures fixed: button/textarea/checkbox rings had no colour so fell back to `currentColor` (white ring on white offset on white page = invisible); borderless input used `ring-transparent`; a file input and a school name field removed the outline with no replacement; `.filter-tab:focus` relied on a background tint alone.
- [x] **Clickable divs** - **done**. Zero `onclick` handlers and zero `<div data-action="click...">` remain in `app/views`.
- [x] Audit the trading modal (`shared/_modal`) for focus trap, restore, and Esc. **done**: Esc already worked; trap and restore were both absent and are now implemented in `modal_controller.js`.
- [x] **Primitives** - **done**. `components/ui/` holds eleven: `_card`, `_page_header`, `_badge`, `_empty_state`, `_data_table`, `_stat`, `_callout`, `_icon_tile`, `_button`, `_input`, `_label`, `_checkbox`, `_textarea`.
- [ ] Reconcile `design.md` with this codebase (see blockers in design-instructions.md).
- [x] **Untrack the `.DS_Store` files** - **done**; `git ls-files` finds none.

## Deferred / noted

- ~~21 unused custom CSS classes in `admin.css`/`shadcn.css`~~ - moot, `admin.css` is deleted.
- ~~Font Awesome sweep (76 icons)~~ - done; all 76 are `lucide_icon` and the CDN link is gone from both layouts.

## Checklist pass (one at a time)

- [x] **Arbitrary hex (2)** - `bg-[#eceec8]` -> new `sitf-accent-soft` token (kept the exact value; near-duplicate of legacy `--sitf-10`). `text-[#8b5cf6]` was violet-500 at 4.23:1 and failed AA -> `text-violet-700` at 7.10:1.
- [x] **Images without alt (1, not 2)** - only `active_storage/blobs/_blob` genuinely lacked alt; now uses the caption or filename. The other flagged case was a false positive: the audit regex was line-based, so multi-line `image_tag` calls with `alt:` on the next line were miscounted.
- [x] **Clickable divs (1, not 3)** - the only one was a modal scrim, now `aria-hidden`. While there: replaced 4 inline `onclick` handlers with a new `dialog` Stimulus controller adding Escape, focus-move-in, focus trap and focus restore; `link_to "#"` trigger -> real `<button>` with `aria-haspopup`; close button `text-gray-400` (2.54:1) -> `text-gray-600`; 44px targets.
- [x] **Dead Tailwind v3 opacity classes (5)** - `bg-opacity-*`/`ring-opacity-*` were removed in v4 and compiled to nothing, so these were visible bugs: two modal scrims rendered fully opaque instead of translucent, and `ring-black ring-opacity-5` drew a solid black ring instead of a 5% hairline. Converted to v4 slash syntax.

### Still open

- [x] **Faint text (19 -> 4, all justified)** - 15 fixed. Empty-state guidance and content (usernames, tickers, no-username labels, price fallback) raised to gray-600 (7.56:1); em-dash no-value markers and a search placeholder to gray-500 (4.83:1). The 4 remaining are deliberate: 2 disabled pagination spans (WCAG 1.4.3 exempts inactive components; added aria-disabled so the state is conveyed programmatically), 1 dark-mode-only variant (6.99:1 on dark), and 1 decorative empty-state icon whose meaning comes from adjacent text (gray-300 -> gray-400 for visibility).
- [x] **outline-none (21 checked)** - confirmed rather than assumed: 20 pair the removal with an explicit ring colour and are genuinely fine. 1 real failure on the order form shares field, where the border measured 1.14:1 and the focus ring 1.99:1, both under the 3:1 WCAG 1.4.11 requires. Now a gray-500 border with a sitf-primary ring.
- [x] **Off-brand focus rings** - **done**. The last three lived in `Admin::FormBuilder`'s two checkboxes (`text-blue-600 focus:ring-blue-600`), which is why sweeps over `app/views` never saw them. Zero remain app-wide.
- [x] **Arbitrary `[var(--sitf-*)]` values (25)** - all replaced with token or palette utilities; 0 remain. Uncovered several real contrast failures, the worst being the Buy/Sell submit button (white label on #1db8a6 at 2.48:1 and on #f59e0b at 2.15:1), now teal-700/amber-700 at 5.47:1 and 5.02:1. Also found `--sitf-muted-foreground` referenced but never defined, so that text rendered with no colour of its own.
- [x] **21 unused custom CSS classes** - **moot**: `admin.css` was deleted, so `.filter-tab`, `.filter-tabs`, `.form-select`, `.header-controls` and `.action-buttons` no longer exist anywhere. The only remaining reference to any of those names is `data-testid="filter-tabs"`, which is a test hook rather than a class. `.dark` in `shadcn.css` is applied at runtime and was always a false positive.

---

## Blocked on someone else

Neither of these is a design task, and neither should be closed by whoever is
doing UI work. Both are recorded here because they were found during it.

- [x] ~~**Merge the Active Storage CVE fix into `main`.**~~ **Closed - a maintainer merged it.**
      `main` is on `activestorage 8.1.3.1` via PR #1190 (`6f48931`), so CVE-2026-66066 is fixed
      on the default branch and on anything deployed from it. `stocksdesign` has merged `main`,
      and `bundler-audit` finds no vulnerabilities against the merged lockfile. Lesson: this was
      carried as "the most urgent item" for the whole branch and had been fixed upstream for some
      of that time. Re-check a standing claim before repeating it.

- [ ] **Three product decisions block Tier 3 Steps 2-4.** The migration map is
      written in `migration.md` and Steps 0 and 1 are done. Each remaining step
      needs a call that is not a design or engineering judgement:

      1. **Should students see provisional grades?** Step 2 gives a student a
         read-only view of their own grade entries. Entries exist and are editable
         from the moment a teacher opens the grade book, so a student would see
         figures that can still change - possibly a grade the teacher has not
         finished entering. Showing entries only once the grade book is finalised is
         accurate, but delays the feedback the whole earnings model rests on.

      2. **Should teachers finalize their own grade books?** Finalizing pays
         students, and `GradeBookPolicy#finalize?` is `user.admin?` today, so a
         teacher enters every grade and then waits for an admin to release the
         money. Widening it shortens the loop, but hands the payout trigger to the
         same person who entered the numbers, with no second pair of eyes.

      3. **Is a projected earnings figure pedagogically desirable?** Step 4 would
         show "on current grades you would earn X" for the open quarter.
         `EarningsCalculator` can already produce it without touching money. The
         risk is that a student reads a projection as money they hold, and that a
         projection falling when a grade is corrected feels like a loss.

      Step 3 - pairing an earnings transaction with the grade that caused it - is
      the closest to unblocked, since it only labels money already paid. It still
      reads better alongside a decision on 1.

- [x] ~~**Decide what the trading fee actually is.**~~ **Closed, and the premise
      was wrong.** This claimed the fee was never recorded as a transaction and
      that balances were therefore too high. It is recorded:
      `TransactionFeeProcessor`, called by `OrderExecutionJob` after the orders
      execute, writes a real `PortfolioTransaction` with `transaction_type: :fee`.
      The mistake came from a grep that searched for `transaction_type: :fee` and
      `.fee.create` and missed the plural scope, `.fees.create!`.

      What was genuinely missing: the fee row named no orders, so a student could
      not tell which trade caused it and the charge could not be audited. It now
      records what it covers in `description`, the UI calls it a "daily trading
      fee" rather than implying per-trade, and the order form distinguishes
      holding from charging. Amount and timing unchanged - see `migration.md`.


## Sentence case - treat as verified-so-far, not done

design.md requires sentence case everywhere, never all-caps, and no `uppercase`
CSS transform on labels. That is now true of everything found, across **six
passes** - and the reason it took six is worth recording, because a seventh is
likely.

Each pass found copy the previous one structurally could not see:

1. Headings, `form.label`, `form.submit`, placeholders.
2. Table cells, definition lists, spans.
3. `link_to` / `button_to` label arguments, single line.
4. Text inside a `link_to ... do` block, which sits on its own line so no
   `link_to "..."` pattern ever matches it. Also labels alone on a line in
   multi-line calls.
5. `div`, `label` and `th` text nodes.
6. The `uppercase` CSS transform written inline in markup (24 places), plus
   copy whose punctuation broke the Title Case pattern (`Perfect Attendance?`).

**The hard limit: copy that is not a literal cannot be swept.** The portfolio
heading was built as `username.upcase` plus the word PORTFOLIO in capitals. No
text search over the views would ever have found it - it was only caught by
reading the page. The same applies to `titleize`, `humanize` and anything
assembled at runtime.

So the standing checks are:

**Guidance, not tasks** - these are the checks a seventh pass should run, not outstanding work:

- Before claiming sentence case is complete, **look at the rendered page**,
      not just the templates.
- Grep for `.upcase`, `.titleize` and `.capitalize` in views and helpers.
      `stock.ticker.upcase` and an avatar initial are correct; a heading is not.
- Grep for `uppercase` in markup as well as stylesheets.
- Copy also lives in `config/locales/en.yml`, including
      `activerecord.attributes` names that surface inside validation messages.
- When copy changes, propagate to tests from the **views diff**, not by
      re-running the converter over test files - those contain fixture data and
      real company names that must not be rewritten.
- Title Case is sometimes correct: acronyms, tickers, CamelCase such as
      `DateTime`, company names, and people's names. Two were caught mid-sweep
      and reverted: `John Doe` and `DateTime`.

## Dead code found while sweeping

- [x] **`app/views/schools/` is unreachable.** **Done: deleted.** The controller,
      nine templates and the misnamed test are gone, along with the orphaned
      top-level `schools:` locale block. Deletion rather than wiring up, because
      the controller had full CRUD behind `authenticate_user!` with no Pundit
      policy - adding routes would have let any signed-in student delete schools -
      and because its apparent test coverage was actually exercising
      `Admin::SchoolsController`. Recorded in `migration.md`.
- [x] ~~21 unused custom CSS classes in `admin.css`/`shadcn.css`~~ - moot, `admin.css` is deleted.
- [x] ~~**Nav depth: flatten the Trading floor disclosure.**~~ **Done.** `_navbar` renders one flat
      "Trading floor" row through `_nav_item`; the only `<details>` left in that file is the comment
      recording the removal. Navigation holds destinations, and the stocks live on the page the row
      points at.
- [x] ~~**One mobile drawer mechanism.**~~ **Done.** Both layouts share
      `data-controller="drawer table-scroll"`, and the controller has Escape, focus move-in, a focus
      trap, focus return and a dynamically-set `aria-expanded` (the triggers carry it in markup too).
      Its step 0 - a testable 375px viewport - is `in_phone_viewport` plus `mobile_navigation_test`.
- [x] ~~**Decide whether `components/ui/_card` keeps the rule under its header.**~~
      **Closed: the header keeps its rule.** The surface half is settled and was documented
      all along - `.tw-card` in `app/assets/tailwind/cards.css` is
      `rounded-2xl border border-slate-200 bg-white shadow-sm`, replacing four treatments
      across seven class strings in 22 files, none of which matched the spec.

      The divider half I got wrong twice in opposite directions. First I called it an open
      product decision when `design.md` appeared to answer it; then I removed the rule on
      the strength of a sentence scoped to *compact content* cards, which also names the
      substitute structure it relies on. Our cards mostly hold attribute lists and tables
      and have no such substitute, so they were left with no boundary and a 36px gap where
      the header padding stacked on the body's. The rule is back, matching Stripe's Box,
      Primer's `Box.Header` and Tailwind UI. Both `design.md` sections now say so.

## Page rebuilds

Foundations are applied everywhere - Figtree, slate, tokens, the table system,
sentence case, and the accessibility fixes - so every page already looks
different. These are the pages not yet **rebuilt onto the primitives**.

- [x] `home/index` - rebuilt on `_page_header`, `_card`, `_empty_state`
- [x] `admin/shared/_show_attributes` - rebuilt on `_card`, which covers ten
      admin show pages
- [x] `portfolios/show` header - sentence-case `h1` with the school as subtitle
- [x] `portfolios/show` body - **done.** Zero `rounded-[22px]` / `border-black/30` remain; the
      KPI band, chart, earnings breakdown and holdings table are all `.tw-card`.
- [x] `stocks/_stock` and `stocks/show` - **done.** `show` renders `_page_header` with `_badge`
      for archived and the trading floor's own Buy/Sell partial; `_stock` lost its unreachable
      second branch.
- [x] Admin index pages - **done.** All eight render `_page_header` above the card,
      with the title as the page's real `h1` and the actions beside it. The card holds
      the table only.
- [x] Admin show pages - **done.** All ten hoist title and actions to `_page_header`;
      the old outer card is gone (it used to wrap `admin_show_attributes`, which renders
      a card of its own), and each trailing section is now its own card instead of a
      `border-t` block.
- [x] `classrooms/*` and `grade_books/*` - **done.** `classrooms/show` was the last page
      hand-rolling its own header: two redundant `mx-auto w-full` wrappers, `my-6` on the title row,
      an h1 joining name, grade and year with commas, and a form control inside that h1. It renders
      `_page_header` now, and the roster moved onto `shared/_table_container` - it had been a bare
      `overflow-x-auto` with no surface at all, beside a grade-book list that is a card.
- [x] `devise/registrations/*`, `announcements/show` - **done.** `registrations/new` now matches
      `sessions/new` (logo, page title, `py-12` rather than `min-h-screen` inside `main`), and both
      auth links share the new `.tw-link-tap` rather than a hand-rolled string in one of them.


## Found while putting the icon tile on a component (2026-08)

- **`orders/_form`'s four modal buttons carry `min-h-11` on top of `.tw-btn-*`**, so they render
  44px against the 40px `h-10` token. `min-h-11` wins over `h-10`, so the modal's Cancel / Back /
  Review / Buy are the only 44px buttons left that are not bare tap targets. One-line fix, but the
  modal was not in scope for the home page work.
- **The admin dashboard's three context stats are `:info` blue.** They were `sky`, which was off
  the vocabulary. Counts of students, classrooms and stocks carry no *state*, and design.md
  hue-codes state, so `:neutral` is arguably right — that flattens three tiles to grey, which is a
  visual call worth making deliberately rather than as part of a sweep.
- **Getting started never goes away.** It is permanent onboarding copy on a dashboard a student
  sees every day. Shopify and Stripe both make setup guidance stateful and self-dismissing. The
  app has the data to do it (funds, orders, holdings), so this is a real feature rather than a
  styling fix — see the note in the home page discussion.

## Found in the button copy sweep (2026-08)

- ~~**`stocks#show` has two buttons to one destination.**~~ Fixed: the page renders
  `stocks/_trade_actions`, so Buy and Sell open the order modal for that stock.
- **Two "Back" buttons use `link_to :back`** (`announcements#show`, `admin/portfolio_transactions#show`),
  so their labels cannot name a destination the way the other nine do. Polaris and Primer both
  advise a known path over history. Behaviour change, so not done here.
- **Devise's confirmable and lockable views are dead.** The model enables only
  `database_authenticatable, registerable, recoverable, rememberable, validatable`, so
  `devise/shared/_links`'s confirmation and unlock branches never render and
  `devise/mailer/confirmation_instructions` / `unlock_instructions` never send. Their copy was left
  alone rather than polished.
- **`devise/shared/_links` renders bare unstyled links with `<br>`** - stock Devise markup, no
  `tw-link`, on the password-reset page.
- ~~**`stocks#show` escaped the earlier sweeps.**~~ Fixed: it renders the shared page header, uses
  `_badge`, and lost the emoji, the double padding, the spacer div and the unbalanced `</div>`.

## Found while closing the backlog (2026-08)

- **`announcements#show` is an orphan.** The route is show-only, there is no index, and **nothing in
  the app links to it** - the home card renders the announcement inline instead. Its "Back" button
  therefore could not name a destination; it goes to home now. Either link the home card's title to
  the full page, or drop the route.
- **20 of 27 `--sitf-*` values have no references.** Only `sitf-primary`, `sitf-primary-dark` and
  `sitf-on-primary` are live; the chart is single-series and uses `chart1` alone. The ones the
  backlog named are deleted. The rest are a palette-level decision and several sit behind sanctioned
  semantic names (`sitf-surface`, `sitf-warning`, `sitf-danger`, `sitf-accent`), which a future page
  would reasonably reach for, so they are reported rather than swept:
  `--sitf-4` … `--sitf-10`, `--sitf-background`, `--sitf-foreground`, `--sitf-muted`, `--sitf-input`,
  `--sitf-dark-blue`, `--sitf-primary-blue`, `--sitf-accent1-chart3`, `--sitf-accent2-chart5`,
  `--sitf-chart4`, `--sitf-on-accent`, `--sitf-accent-soft`, `--sitf-status-destructive`.
- **Left deliberately, because they are not design calls:** the eight unused images (brand assets),
  the three product decisions blocking Tier 3, a real profile page, and making "Getting started"
  stateful. Each is recorded above with what it needs.

## Closing pass (2026-08)

Everything actionable in this file is now done or explicitly handed back. Two findings from the
pass itself are worth keeping:

- **`dark:text-slate-400` on the sign-up page was a live AA failure, recorded as justified.** It was
  the only `dark:` variant in the app, and `.dark` is declared in `shadcn.css` but nothing applies
  it - so the earlier audit read the variant as unreachable and scored it "6.99:1 on dark". Tailwind
  v4 compiles `dark:` to `@media (prefers-color-scheme: dark)`, which the compiled stylesheet
  confirms, so on any device with a dark OS setting that paragraph rendered slate-400 over a
  background that stays light: **2.45:1**. A variant is not dead just because the app has no theme
  switch.
- **Two of this file's own counts came from greps that cannot be right.** `<th` matches `<thead>`,
  and a line-based regex cannot see `alt:` on the next line. Both had already produced a wrong
  number once and both did it again. Read the hits.

**Left with whoever owns the decision**, each with what it needs written above: the eight unused
images, the three product decisions blocking Tier 3, a real profile page, making "Getting started"
stateful, and the 20 unreferenced palette values.

## Profile page follow-ups (2026-08)

- ~~**`devise/registrations#edit` now duplicates `/profile/edit`.**~~ **Done**: the view is deleted,
  `/users/edit` 301s to `/profile/edit`, and `PATCH /users`, `DELETE /users` and `/users/cancel` are
  unrouted. Two product questions came out of it, below.
- **`SITF-Horz-logo.svg` is unreferenced** - the only tagline logo, kept deliberately.

## Product questions from the account work (2026-08)

- **Should public sign-up be open?** `/users/sign_up` renders and creates accounts. Someone had tried
  to close it with a redirect declared after `devise_for`, which never fired, so it has been open the
  whole time. Students and teachers are otherwise created by an admin or a teacher, which suggests it
  should not be - but closing it is a behaviour change with tests attached, so it is a decision, not
  a sweep.
- **Should anyone be able to close their own account?** The button that claimed to had never worked -
  `User` refuses a hard delete - and a working version would have destroyed the student's portfolio
  and orders, which are `dependent: :destroy`. If self-service closure is wanted it has to be a
  `discard`, and someone has to decide whether a child may lock themselves out of their coursework.
  Admin Deactivate / Reactivate covers the adult-administered case today.

## Decide whether the archived stocks table should exist at all

**Status: open. Needs a product decision, not a design one.**

`stocks.archived_at` and `Stock::LIST_RETENTION` are in place, so the archived list now has a date, a
12-month window, and an exemption for anything you hold. That makes it defensible. It does not make it
*justified*, and this item exists because the question was never asked.

**Why it is on the list:**

- **Its only action is selling a position you already hold**, and that case is now surfaced separately
  as "Archived stocks you hold". Once that table exists, the remaining disclosure is a list of
  companies nobody on the page can buy or sell. Everything it tells a student is history.
- **It is the second thing on the app's busiest screen.** The trading floor is where the product
  actually happens, and measured on a 1366x768 Chromebook the usable height is 625px. Anything below
  the active table competes for that scroll.
- **The audiences do not overlap.** A student needs the held case, which no longer lives here. An
  admin already has `admin/stocks`, with archived as a sortable column. A **teacher** is the only
  reader left without another route - and a teacher cannot trade, so the value to them is oversight of
  a catalogue they do not administer.
- **It was noise for most of its life.** Until this pass it listed every archived stock, at any age,
  with no date, no explanation and an empty actions column, directly under the list of things a
  student *can* buy.
- **The cheap alternatives are real.** Give teachers read access to the admin stocks index; or fold
  archived companies into the active table as a disabled row with a badge, which is what a brokerage
  does with a delisted holding; or drop it and let `stocks#show` carry the history for anyone with a
  link.

**What would settle it:** whether a teacher ever needs to see archived companies while looking at the
trading floor, rather than in an admin list. If not, the disclosure goes and the held table stays.

**Do not close this by deleting the table without checking the teacher case** - the held-stock table
and the policy that withholds Buy on an archived stock are load-bearing and must survive whatever
replaces it.

## Archived stocks: retention, answered (2026-08)

- ~~There is no `archived_at`.~~ Added, nullable, and **not backfilled**: `updated_at` is not the
  archive date, and inventing one in a trading record is worse than admitting it is unknown.
  `Stock.archived_recently` treats NULL as in-window so nothing silently disappears.
- ~~Nothing purges them.~~ Nothing ever will. `orders.stock_id` and `portfolio_stocks.stock_id` are
  `NOT NULL` with foreign keys and both associations are `dependent: :restrict_with_error`, so a
  traded stock cannot be deleted without destroying a student's history. `Stock::LIST_RETENTION`
  (12 months) ages the **list**, not the rows, and a stock you hold is exempt.
- **Still open:** whether `archived_at` should become the source of truth and the boolean go. The
  migration map is in `migration.md`; steps 4 and 6 (the admin checkbox, and ~30 tests setting
  `archived: true`) are the work.

## `@classroom_stats` is computed and never rendered (2026-08)

`ClassroomsController#show` sets `@classroom_stats = facade.stats` for a teacher or admin — four
figures, four queries — and no template reads it. It has presumably never been rendered.

The classroom page redesign nearly answered it with the four-across `_stat` strip, and that was
wrong: measured at 1366x768 the strip is **134px**, and with the trading setting card above the
roster it put the first student at **567px of a 625px viewport**. The roster is why a teacher opens
the page, so the band came out and the first row landed at 296px.

**Open:** either render the figures somewhere that costs ~24px rather than ~134px — a one-line meta
summary beside the title, which is what GitHub and Linear do for an entity's counts — or delete the
computation. Both are better than the present state, which pays for the queries and shows nothing.
Worth deciding with a teacher: "students who have traded" and "orders this week" are the two that
sound like they'd change how a lesson is run.

## Perfect attendance is entered by hand, and already contradicts the data (2026-08)

Reported as not adding value: a teacher ticks a box per student per quarter to say they attended every
day, having already typed the day count into the cell beside it.

It is worse than redundant. In the development seeds one entry carries `is_perfect_attendance: true` with
`attendance_days` **nil** and is paid the 100-cent bonus, and another treats 3 days as perfect. The flag
is independent of the number it summarises, so it can pay a bonus the attendance record contradicts.

**It cannot be derived today**: nothing stores how many school days a quarter has. `quarters` holds a
name and a number, `school_years` two foreign keys, `years` a name - and a search of the whole schema for
`start_date|end_date|school_days|total_days` finds nothing. Taking the denominator from the highest
`attendance_days` in the grade book would pay the best attender in a quarter where nobody was perfect.

The map is in `migration.md`. Two things need answering before any of it:

1. **Who sets a quarter's school days?** There is no quarters UI at all, so one has to be built. An admin
   per school year, or the teacher at the start of the quarter - the teacher knows the number and is the
   one the change is meant to help.
2. **What happens to grade books already finalized?** They have paid out. Deriving the bonus retroactively
   changes money that has been distributed, so either the derivation applies only from the change onward
   or historical rows keep their stored flag. That belongs to whoever is accountable for the funds.

Until then the checkbox stays, and the section copy at least states what the bonus pays - which it did not
before.

## Raised while rebuilding the grade book, not done (2026-08)

- ~~**A styled confirmation dialog.**~~ **Done.** `shared/_confirm_dialog` is a native `<dialog>` and
  `confirm_dialog_controller` registers `Turbo.config.forms.confirm`, so all 28 `data-turbo-confirm`
  call sites are covered without touching any. The trap noted here was real and cost the most time:
  **20 tests drove the old dialog with Capybara's `accept_confirm`**, which waits for a *native* dialog
  and raised `ModalNotFound` the moment the confirmation became HTML. `accept_confirmation` /
  `dismiss_confirmation` in `ApplicationSystemTestCase` replace it.

  **Still open, small:** the accept button takes its verb from the submitter, which Turbo provides for a
  `button_to` and **not** for a link carrying `turbo_method` - so the ~20 link-driven confirms say
  "Confirm" rather than "Delete". Inferring the verb from the message's first word breaks on the several
  that begin "Are you sure...", so it would need an explicit attribute per call site. Worth doing only if
  "Confirm" proves unclear in use.
- ~~**Students have no name, only a username.**~~ **Done.** `students#new` and `#edit` and the admin form
  all take an optional full name, `:name` is permitted on both controllers, and `User` normalizes it so a
  blank submission stores nil rather than `""`. The roster shows the name over the username - design.md's
  primary-identifier shape - and the grade book, its sort order and the portfolio title use
  `display_name`. Left on the username deliberately: `admin/users`, `admin/teachers` and the transaction
  screens, where the account rather than the person is the subject.
- [x] ~~**Should a teacher see the split by reason, not just the total?**~~ **Answered: no.** The preview
  answered it by failing. Shown four options, the reaction was *"I still don't understand the distinction
  between the two or the relationship between the two"* - and then the two questions that matter: is the
  split the same money as the table, and is the total just the sum of the Earns column? Yes to both, and
  needing to ask is the verdict. **If the relationship between two summaries has to be explained, they
  should not both be on the screen.**

  Why it reads that way, which is worth keeping: the figures are a **cross-tabulation whose middle is
  never shown**. Earns is the row totals (per student), the split is the column totals (per reason), and
  the only cell they share is the corner - $52.60 either way. Nothing on the page renders the grid that
  would make that obvious, so two totals of the same money sit side by side looking like rivals. Showing
  the grid is not the fix either: it means three money columns per student on a table that already has
  five columns and 25 rows.

  A second collision made it worse and is now avoided by name: **"Math" was a column of letter grades and
  a line of money on the same screen.** The split's labels say what earned the money - "Math grades",
  "Reading grades".

  What changed instead: the split stays where the payment is authorised, and it now **states its
  relationship** rather than leaving it to be inferred - "Each student is paid in three deposits, which is
  how the total divides and what their statement will show." That sentence is also the only place the
  product says a student receives three deposits rather than one, which is what `DistributeEarnings`
  actually writes. The teacher view keeps one summary on one axis: each row's Earns and the column total.

  The preview at `/admin/component_demo/earnings_split` is deleted - it existed to decide this. In
  `5cc9fb4` if it is ever wanted back.

## An archived plain user cannot be restored (2026-08)

- [ ] **`admin/users` archives, and nothing un-archives.** Found while making the destructive
  confirmations tell the truth. The action discards - it used to call `destroy`, which raised outside
  production - and `admin/students#restore` and the teachers' reactivation cover the two subclasses, so a
  user who is neither a student nor a teacher has no route back. Either add `restore` to `admin/users`,
  which is the same shape as the students one and would cover every type at once, or say in the
  confirmation that this cannot be reversed from the admin screens. The second is honest and worse. Not a
  design call: it decides whether an admin can lock themselves out of an account permanently by clicking
  one row action.

## Should the confirmation dialog get a solid destructive accept? (2026-08)

- [x] ~~**May "no red at rest, anywhere" become "no red at rest on a page", with the confirmation dialog
  named as the exception?**~~ **Answered: yes, and built.** `.tw-btn-danger` is rose-700 filled with a
  rose-800 focus ring, used by the accept button of a destructive confirmation and nothing else. A benign
  confirmation keeps the brand primary, so the fill carries information rather than decorating every
  dialog. Cancel still holds `autofocus`, so the destructive answer is not the default.

  The rule in design.md now reads "no red at rest **for any control that sits on a page**", which is 15 of
  the app's 16 destructive controls and the rule as it was always meant. `:danger_outline` keeps its own
  home - a destructive action among bordered buttons on a page, which is the grade book's Finalize.

  Measured: white on rose-700 is 6.03:1, level with the brand primary's 6.18:1; rose-600, which the variant
  list used to state, is 4.53:1 and clears AA by 0.03. `confirm_dialog_test` asserts the fill and its
  contrast by painting the pixel, and asserts the primary on a benign confirmation.

  The preview at `/admin/component_demo/destructive_buttons` is deleted - it existed to decide this. In
  `db1ffba` if it is ever wanted back.

## The nav's scrolling stock ticker (2026-08)

- [x] ~~**Remove it, and decide what replaces it.**~~ **Done: removed, replaced by `home/_todays_movers`.**
  The reasoning is in design.md and the removal is mapped in migration.md. In short: WCAG 2.2.2 at Level A
  with no pause control, 2.74:1 and 3.78:1 colours, no real data - all 18 stocks read 0.00% and every one
  was green with an up arrow because the test was `>= 0` - and a ticker is a broadcast component that no
  finance application uses in its chrome.

  The replacement went through a "Today's movers" card on the home page - reported as making no sense there,
  because it pushed the balance, the announcements and the getting-started steps down to list three of the
  companies the trading floor lists anyway - and ended as a **Change column on the trading floor**, beside
  the price it is about, with the caution as that page's description.
  `app/assets/stylesheets/application.css` is now in CLAUDE.md's audit scope, which is why those colours
  survived every sweep.

## Price staleness, and whether the Change column earns its place (2026-08)

- [x] ~~**Remove the Change column and add a price date; keep the column and add the date; or stop.**~~
  **Answered: option 1 - the column is removed and the price states its age.** Reasons in design.md, removal
  mapped in migration.md.

  Stale is defined as "older than the freshest price on this page" rather than "older than today", because the
  job runs at 02:00 for the previous close and a fresh price normally carries yesterday's date. The page states
  the cadence and the date once; a row speaks only when it is behind.

## The trading floor's Buy/Sell sit 10.5px below the row's first line (2026-08)

- [ ] **Same class of misalignment as the row actions, different geometry.** Found while fixing those. The
  trading floor's Buy and Sell are **40px** buttons, not 32px ghosts, and its primary cell stacks a 40px logo
  over a ticker and a company name - so the row is 65px and the control's centre is 10.5px below the ticker's
  line. Its actions cell does not carry `table-actions-pinned`, so the `pt-1.5` correction does not reach it
  and 6px would not be the right number anyway.

  Left alone deliberately rather than bent to fit the other fix: the right treatment depends on whether the
  ticker's line or the whole stacked block is what a 40px pair should align to, and on whether that table's
  rows should be 65px at all. Worth measuring against the stacked cell rather than guessing a padding.


## The admin form partials still each render their own card (2026-08)

The card-body padding sweep unified the *value* (`p-5`, from design.md) but left the *shape*: ten admin
form partials open with `<div class="tw-card"><div class="p-5">`, hand-rolled, rather than
`components/ui/_card`. So the surface and its padding are declared eleven times - which is the mechanism
that produced four different padding values in the first place, and it will produce a fifth.

Each of those cards also carries an `h3 text-lg font-medium` section title ("Stock details", "Teacher
details", ...) that `_card`'s `title:` local already renders, with the 16px header seam design.md
specifies instead of the current `mb-6`.

Not done here because it is eleven files of partial surgery with no visible change on any of them, and
because the section titles are worth a separate question: on a single-card form page, a card titled
"Teacher details" under an h1 reading "Edit teacher" states the same thing twice. Polaris drops the card
header when the page has one card. Worth answering before converting, or the conversion preserves it.

## Should a form card be `p-5` or `p-6`? (2026-08)

design.md says `p-5` and the app now says `p-5` everywhere, so this is consistent and closed as a
consistency question. It is open as a *value* question: the admin side had chosen 24px independently in
ten places, which is some evidence that a dense form wants more room than a stat card, and shadcn's Card
(`p-6`) agrees while Polaris (16/20px) does not. If it changes it changes in `design.md` and in one
sweep, not per call site.

## Should the whole app carry an environment banner, not just the demo? (2026-08)

The component demo's banner names the environment because that is the honest way to write it, but it is
scoped to three pages, and the thing it is really signalling is "this page is not part of the product".

The other half of the field's pattern is a **whole-app environment ribbon** - GitLab's, Stripe's test
mode, Shopify's development store banner - which answers a different question: *which* deployment am I
looking at. This repo has `config/environments/staging.rb` and a `deploy-staging.yml` workflow, so the
question is live: an admin on staging has nothing on screen telling them the data they are editing is
not real.

Not done here because it touches both layouts on every page and because it needs two decisions first:
whether it appears in development (where it is noise - the URL says localhost) and whether it can be
collapsed, given this app's rule that a message describing a *state* gets no dismiss. If it is built, it
belongs in the layout beside the flash, inside the content column, and the demo's banner should then say
only what the *page* is and let the ribbon name the environment.

## Decide the teacher's trading floor, then delete the preview (2026-08) - DONE, preview deleted

`/admin/component_demo/trading_floor_columns` is a preview, built to decide one question and to be deleted
once decided - the same shape as `earnings_split`, `destructive_buttons`, `delight` and `stock_ticker`
before it.

**The question.** A teacher's `/stocks` is two columns: `StockPolicy#show_holdings?` requires a student
with a persisted portfolio, so the holdings column and the Buy/Sell cell are both removed and what is left
is the buy list with the buying taken out. Nobody designed that page; it is a residue. An admin does not
care - `/admin/stocks` is the real stock list and carries more - but a teacher cannot open `/admin/stocks`
at all, so this is their only view of the catalogue.

**What the preview proposes**, all in the columns a student's holdings and actions already occupy, so the
table gains no width and nothing changes at 375px:

1. **Held by** - "2 of 3", with the share total under it, in the slot where a student sees their own
   holdings. This is the only one that answers a question nothing in the app answers: *what is my class
   buying?* There is no `group(:stock_id)` anywhere in `app/` today, and `PortfolioPolicy#show?` only lets
   a teacher open one student's portfolio at a time. The denominator is students with a **portfolio**, not
   students - a student without one cannot hold anything.
2. **The exchange**, in the identity line. The live header already says "Company (exchange)" and the cell
   has never contained one; `stock_exchange` is populated on all ten active stocks and rendered only on
   `stocks#show`. Either render it or rename the header - the current state is a header naming a field its
   column does not have.
3. **Industry**, `hidden lg:table-cell`, on the active table only. Populated on 10 of 10 active stocks and
   0 of 8 archived ones, so putting it on both makes the archived table a column of dashes.

**Recommended answers**, both now rendered in the preview:

- **One column, scoped through `ClassroomPolicy::Scope`.** "Does an admin see it too" and "scoped or
  global" are one question. That scope already resolves to every classroom for an admin and to their own
  for a teacher, so the column's meaning stays fixed - who owns this, among the people you can see - and
  the viewer decides only the denominator. A column that exists for one role and not the other is two
  rules and a page that changes shape depending on who opens it.
- **Here, not `classrooms#show`.** Measured on that page at 1366x768: viewport 625px, Students at 168px,
  Grade books at 420px, page ends at 637px - a holdings section would start around 700px, third in line
  and below the fold. It cannot go higher, because the roster is what the page is for and this repo has
  already recorded what happens when a band goes above it (first student at 567px of 625px). On the
  trading floor the same information is a column in a table already on screen, next to the thing being
  bought.

**Still open**: "how is 5B invested?" - a portfolio summary with totals and cash, on the classroom page -
is a different and real question. Worth building later. It is not this.

## "How is 5B invested?" is still unanswered (2026-08)

Shipped: the trading floor's `Held by` column, which answers *of the things available, what is being
bought* - a catalogue question, next to the catalogue.

Not shipped, and a different question: a **portfolio summary for a classroom** - total invested, cash
uninvested, the class's largest positions, gain or loss. That belongs on `classrooms#show`, and the
measurement that kept it off the trading floor applies to it: on that page at 1366x768 the Students
section starts at 168px, Grade books at 420px, and the whole page ends at 637px in a 625px viewport, so
a third section starts around 700px. It cannot go above the roster - the roster is what the page is for,
and adding a band there once put the first student at 567px of 625px. So it goes below the grade books,
and the question to answer first is whether a teacher would scroll to it, or whether it wants its own
page.

## The remaining form drift, and one error that points at no field (2026-08) - DONE

The classroom pair is unified. Two things it surfaced and did not finish:

**Both are done.** `Ui::FormBuilder` builds every entity form on both halves - the map is in
migration.md - and `SchoolYearFields` moved the validation onto the two fields the forms actually have.

What is left, and deliberately not done: the component gallery still renders three of eleven partials,
which is its own entry above.
