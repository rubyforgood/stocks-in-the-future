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

- [ ] `components/_action_icon_button.html.erb` - 6 off-tier bp, 2 FA icon
- [ ] `components/ui/_button.html.erb` - clean
- [ ] `components/ui/_checkbox.html.erb` - clean
- [ ] `components/ui/_input.html.erb` - clean
- [ ] `components/ui/_label.html.erb` - clean
- [ ] `components/ui/_textarea.html.erb` - clean
- [x] `layouts/_navbar.html.erb` - **done**: 170->138 lines, extracted `_nav_item` partial, 5 hex + ~20 inline styles -> tokens, `aria-current="page"` on all active links, decorative icons `alt=""`, chevron div -> real `<button>`, FA chevrons -> inline SVG, un-nested the duplicate `<nav>`, 44px targets, dropped phantom `Geist` font
- [ ] `layouts/_stock_item.html.erb` - clean
- [ ] `layouts/_stock_ticker.html.erb` - clean
- [ ] `layouts/admin.html.erb` - 1 off-tier bp, 1 div-as-button, 1 FA icon (partially done: `lang="en"` added)
- [x] `layouts/application.html.erb` - **done**: tokens, `lang="en"`, per-page `<title>`, skip link, semantic `<header>`/`<main id="main-content">`, 44px menu target, extracted `_flash`
- [ ] `shared/_earnings_to_invest_card.html.erb` - clean
- [x] `shared/_modal.html.erb` - **done**: `role="dialog"` + `aria-modal`, focus moved in on open, focus trapped while open, focus restored on close, close button 32px->44px and `text-gray-400` (2.54:1) -> `text-gray-600` (7.56:1), `x` glyph -> inline SVG with `sr-only` name
- [ ] `shared/_table_container.html.erb` - clean

## Auth (Devise)

- [ ] `devise/confirmations/new.html.erb` - clean
- [ ] `devise/passwords/edit.html.erb` - clean
- [ ] `devise/passwords/new.html.erb` - 1 hex, 4 off-tier bp, 1 faint text
- [ ] `devise/registrations/edit.html.erb` - clean
- [ ] `devise/registrations/new.html.erb` - 1 faint text
- [x] `devise/sessions/new.html.erb` - **done**: visible labels (was placeholder-only), tokens, single `h1`, 44px targets, base+lg only, brand focus rings, 2 faint text
- [ ] `devise/shared/_error_messages.html.erb` - clean
- [ ] `devise/shared/_links.html.erb` - clean
- [ ] `devise/unlocks/new.html.erb` - clean

## Student-facing

- [ ] `announcements/show.html.erb` - clean
- [ ] `fields/portfolio_link/_index.html.erb` - clean
- [x] `home/index.html.erb` - **done**: 25 off-tier breakpoints -> base+lg only, 3 hex + 2 inline styles -> tokens, `bg-teal-500` (2.49:1) -> `teal-700` (5.47:1), `text-gray-400` (2.54:1) -> `gray-500`, heading order fixed h1->h2->h3 (styled divs were acting as headings), steps -> `<ol>`, decorative images `alt=""`, dropped dead `hero-banner`/`funds-pill`/`flex-cols-2` classes
- [ ] `orders/_form.html.erb` - 1 hex, 1 outline-none
- [ ] `orders/_order.html.erb` - 1 off-tier bp, 2 faint text
- [ ] `orders/edit.html.erb` - clean
- [ ] `orders/index.html.erb` - 11 th no scope, 2 FA icon
- [ ] `orders/new.html.erb` - clean
- [ ] `orders/new.turbo_stream.erb` - clean
- [ ] `orders/show.html.erb` - clean
- [ ] `portfolios/_earnings_summary_card.html.erb` - 1 hex
- [ ] `portfolios/_portfolio_chart.html.erb` - 1 faint text
- [ ] `portfolios/show.html.erb` - 13 off-tier bp, 1 img no alt, 1 outline-none, 2 th no scope
- [ ] `stocks/_index_row.html.erb` - 1 img no alt
- [ ] `stocks/_stock.html.erb` - 2 off-tier bp
- [ ] `stocks/_stocks_table.html.erb` - 5 th no scope
- [ ] `stocks/index.html.erb` - clean
- [ ] `stocks/show.html.erb` - 1 outline-none
- [ ] `students/edit.html.erb` - 6 off-tier bp
- [ ] `students/new.html.erb` - 6 off-tier bp

## Teacher-facing

- [ ] `classrooms/_classroom_students_table.html.erb` - 2 faint text, 5 th no scope, 2 FA icon
- [ ] `classrooms/_form.html.erb` - 2 off-tier bp
- [ ] `classrooms/_grade_books_list.html.erb` - 2 FA icon
- [ ] `classrooms/edit.html.erb` - 1 off-tier bp
- [ ] `classrooms/index.html.erb` - 1 faint text, 6 th no scope, 2 FA icon
- [ ] `classrooms/new.html.erb` - 1 off-tier bp
- [ ] `classrooms/show.html.erb` - clean
- [ ] `grade_books/_finalize_button.html.erb` - clean
- [ ] `grade_books/_grade_entry.html.erb` - 4 off-tier bp, 1 faint text
- [ ] `grade_books/_submit_button.html.erb` - clean
- [ ] `grade_books/_table.html.erb` - 6 th no scope
- [ ] `grade_books/show.html.erb` - clean
- [ ] `grade_books/update.turbo_stream.erb` - clean
- [ ] `schools/_form.html.erb` - clean
- [ ] `schools/_school.html.erb` - clean
- [ ] `schools/edit.html.erb` - 1 off-tier bp
- [ ] `schools/index.html.erb` - clean
- [ ] `schools/new.html.erb` - 1 off-tier bp
- [ ] `schools/show.html.erb` - 1 off-tier bp

## Admin

- [ ] `admin/announcements/_form.html.erb` - clean
- [ ] `admin/announcements/edit.html.erb` - clean
- [ ] `admin/announcements/index.html.erb` - clean
- [ ] `admin/announcements/new.html.erb` - clean
- [ ] `admin/announcements/show.html.erb` - 2 FA icon
- [ ] `admin/classrooms/_form.html.erb` - clean
- [ ] `admin/classrooms/edit.html.erb` - clean
- [ ] `admin/classrooms/index.html.erb` - 3 off-tier bp, 2 faint text, 1 th no scope, 1 FA icon
- [ ] `admin/classrooms/new.html.erb` - clean
- [ ] `admin/classrooms/show.html.erb` - 2 FA icon
- [ ] `admin/component_demo/form.html.erb` - 4 th no scope, 1 FA icon
- [ ] `admin/component_demo/index.html.erb` - 5 outline-none, 7 FA icon
- [ ] `admin/component_demo/show.html.erb` - clean
- [ ] `admin/dashboard/index.html.erb` - 1 off-tier bp, 14 FA icon
- [ ] `admin/portfolio_transactions/_form.html.erb` - clean
- [ ] `admin/portfolio_transactions/edit.html.erb` - clean
- [ ] `admin/portfolio_transactions/new.html.erb` - clean
- [ ] `admin/portfolio_transactions/show.html.erb` - 1 off-tier bp, 2 FA icon
- [ ] `admin/school_years/_form.html.erb` - 1 FA icon
- [ ] `admin/school_years/edit.html.erb` - clean
- [ ] `admin/school_years/index.html.erb` - 3 off-tier bp, 2 faint text, 1 th no scope, 1 FA icon
- [ ] `admin/school_years/new.html.erb` - clean
- [ ] `admin/school_years/show.html.erb` - 2 FA icon
- [ ] `admin/schools/_form.html.erb` - clean
- [ ] `admin/schools/edit.html.erb` - clean
- [ ] `admin/schools/index.html.erb` - clean
- [ ] `admin/schools/new.html.erb` - clean
- [ ] `admin/schools/show.html.erb` - 2 FA icon
- [ ] `admin/shared/_actions.html.erb` - 3 outline-none, 2 FA icon
- [ ] `admin/shared/_breadcrumbs.html.erb` - 3 off-tier bp, 1 faint text, 2 FA icon
- [ ] `admin/shared/_navigation.html.erb` - 10 FA icon
- [ ] `admin/shared/_pagination.html.erb` - 2 off-tier bp, 2 faint text
- [ ] `admin/shared/_search_filter.html.erb` - 9 off-tier bp, 2 faint text, 2 outline-none, 1 FA icon
- [ ] `admin/shared/_show_attributes.html.erb` - 6 off-tier bp
- [ ] `admin/shared/_table.html.erb` - 4 off-tier bp, 2 faint text, 1 th no scope, 1 FA icon
- [ ] `admin/stocks/_form.html.erb` - clean
- [ ] `admin/stocks/edit.html.erb` - clean
- [ ] `admin/stocks/index.html.erb` - clean
- [ ] `admin/stocks/new.html.erb` - clean
- [ ] `admin/stocks/show.html.erb` - 4 off-tier bp, 2 FA icon
- [ ] `admin/students/_form.html.erb` - clean
- [ ] `admin/students/edit.html.erb` - clean
- [ ] `admin/students/index.html.erb` - 3 off-tier bp, 3 faint text, 3 outline-none, 1 div-as-button, 1 th no scope, 1 FA icon
- [ ] `admin/students/new.html.erb` - clean
- [ ] `admin/students/show.html.erb` - 27 off-tier bp, 13 th no scope, 2 FA icon
- [ ] `admin/teachers/_form.html.erb` - 1 outline-none, 1 FA icon
- [ ] `admin/teachers/edit.html.erb` - clean
- [ ] `admin/teachers/index.html.erb` - 3 off-tier bp, 2 faint text, 1 th no scope, 1 FA icon
- [ ] `admin/teachers/new.html.erb` - clean
- [ ] `admin/teachers/show.html.erb` - 4 FA icon
- [ ] `admin/users/_form.html.erb` - clean
- [ ] `admin/users/edit.html.erb` - clean
- [ ] `admin/users/index.html.erb` - 3 off-tier bp, 4 faint text, 1 th no scope, 1 FA icon
- [ ] `admin/users/new.html.erb` - clean
- [ ] `admin/users/show.html.erb` - 2 FA icon

## Cross-cutting work items

- [x] Fix invalid `focus-visible:ring-2a` in `input_helper.rb` - it compiled to nothing, leaving inputs app-wide with no designed focus indicator. Now an explicit 2px `sitf-primary` ring at 5.9:1.

- [x] Add SITF brand colours as semantic tokens so pages stop hardcoding hex. **done**: `sitf-surface`, `sitf-primary`, `sitf-primary-dark`, `sitf-on-primary`, `sitf-secondary`, `sitf-accent`, `sitf-warning`, `sitf-danger` in `tailwind.config.css`, sourced from `shadcn.css`.
- [x] Replace the Font Awesome CDN link with local SVG icons. **done**: all 76 usages converted to `lucide_icon` (the gem was already a dependency and already the convention in 3 views). CDN `<link>` removed from both layouts. Icons now inherit `currentColor` and carry `aria-hidden` by default.
- [x] Sweep `sm:`/`md:`/`xl:`/`2xl:` down to `base` + `lg:`. **done**: 122 remapped across 31 view files, 0 remaining. Multi-tier ramps (e.g. `text-sm sm:text-base md:text-lg lg:text-xl`) collapsed by hand. Also removed the off-tier usages in `forms.css` and deleted the dead legacy top-nav block in `navbar.css`.
- [x] Add `scope` to every `<th>`. **done**: 42 added across 8 files (the original count of 58 was inflated - the audit regex also matched `<thead>`). All were column headers; 0 row headers.
- [ ] Replace faint text colours with `gray-500` or darker (33 usages).
- [x] Give every `outline-none` a visible focus replacement. **done**: most already paired with a visible `focus:ring`. Real failures fixed: button/textarea/checkbox rings had no colour so fell back to `currentColor` (white ring on white offset on white page = invisible); borderless input used `ring-transparent`; a file input and a school name field removed the outline with no replacement; `.filter-tab:focus` relied on a background tint alone.
- [ ] Convert clickable divs to real buttons (4 usages).
- [x] Audit the trading modal (`shared/_modal`) for focus trap, restore, and Esc. **done**: Esc already worked; trap and restore were both absent and are now implemented in `modal_controller.js`.
- [ ] Add a card / badge / empty-state primitive to `components/ui/`.
- [ ] Reconcile `design.md` with this codebase (see blockers in design-instructions.md).
- [ ] Untrack `app/.DS_Store` and `app/assets/.DS_Store`.

## Deferred / noted

- 21 unused custom CSS classes remain in `admin.css` (`.filter-tab`, `.filter-tabs`, `.form-select`, `.header-controls`, `.action-buttons`) and `shadcn.css` (`.dark`). `.dark` is applied at runtime so it is a false positive; the `admin.css` ones look like scaffolding for unfinished admin work, so they were left in place rather than deleted. Note the `.filter-tab:focus-visible` fix is therefore currently inert.
- Font Awesome sweep (76 icons) is the last large cross-cutting item.

## Checklist pass (one at a time)

- [x] **Arbitrary hex (2)** - `bg-[#eceec8]` -> new `sitf-accent-soft` token (kept the exact value; near-duplicate of legacy `--sitf-10`). `text-[#8b5cf6]` was violet-500 at 4.23:1 and failed AA -> `text-violet-700` at 7.10:1.
- [x] **Images without alt (1, not 2)** - only `active_storage/blobs/_blob` genuinely lacked alt; now uses the caption or filename. The other flagged case was a false positive: the audit regex was line-based, so multi-line `image_tag` calls with `alt:` on the next line were miscounted.
- [x] **Clickable divs (1, not 3)** - the only one was a modal scrim, now `aria-hidden`. While there: replaced 4 inline `onclick` handlers with a new `dialog` Stimulus controller adding Escape, focus-move-in, focus trap and focus restore; `link_to "#"` trigger -> real `<button>` with `aria-haspopup`; close button `text-gray-400` (2.54:1) -> `text-gray-600`; 44px targets.
- [x] **Dead Tailwind v3 opacity classes (5)** - `bg-opacity-*`/`ring-opacity-*` were removed in v4 and compiled to nothing, so these were visible bugs: two modal scrims rendered fully opaque instead of translucent, and `ring-black ring-opacity-5` drew a solid black ring instead of a 5% hairline. Converted to v4 slash syntax.

### Still open

- [x] **Faint text (19 -> 4, all justified)** - 15 fixed. Empty-state guidance and content (usernames, tickers, no-username labels, price fallback) raised to gray-600 (7.56:1); em-dash no-value markers and a search placeholder to gray-500 (4.83:1). The 4 remaining are deliberate: 2 disabled pagination spans (WCAG 1.4.3 exempts inactive components; added aria-disabled so the state is conveyed programmatically), 1 dark-mode-only variant (6.99:1 on dark), and 1 decorative empty-state icon whose meaning comes from adjacent text (gray-300 -> gray-400 for visibility).
- [x] **outline-none (21 checked)** - confirmed rather than assumed: 20 pair the removal with an explicit ring colour and are genuinely fine. 1 real failure on the order form shares field, where the border measured 1.14:1 and the focus ring 1.99:1, both under the 3:1 WCAG 1.4.11 requires. Now a gray-500 border with a sitf-primary ring.
- [ ] Off-brand focus rings (`ring-blue-500`/`ring-indigo-500`) - compliant but inconsistent with the brand.
- [x] **Arbitrary `[var(--sitf-*)]` values (25)** - all replaced with token or palette utilities; 0 remain. Uncovered several real contrast failures, the worst being the Buy/Sell submit button (white label on #1db8a6 at 2.48:1 and on #f59e0b at 2.15:1), now teal-700/amber-700 at 5.47:1 and 5.02:1. Also found `--sitf-muted-foreground` referenced but never defined, so that text rendered with no colour of its own.
- [ ] 21 unused custom CSS classes in `admin.css`/`shadcn.css`.

---

## Blocked on someone else

Neither of these is a design task, and neither should be closed by whoever is
doing UI work. Both are recorded here because they were found during it.

- [ ] **Merge the Active Storage CVE fix into `main`.** `main` is still on
      `activestorage 8.1.3`, which carries **CVE-2026-66066** - arbitrary file
      read and remote code execution in variant processing. Upstream already has
      the fix as `dependabot/bundler/rails-8.1.3.1`; it needs a maintainer to
      merge it. The `stocksdesign` branch merged that same commit so it is not
      running vulnerable code and so `bin/lint` passes, but that does nothing for
      `main` or for anything deployed from it. **This is the most urgent item in
      this file and the only security one.**

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

- [ ] Before claiming sentence case is complete, **look at the rendered page**,
      not just the templates.
- [ ] Grep for `.upcase`, `.titleize` and `.capitalize` in views and helpers.
      `stock.ticker.upcase` and an avatar initial are correct; a heading is not.
- [ ] Grep for `uppercase` in markup as well as stylesheets.
- [ ] Copy also lives in `config/locales/en.yml`, including
      `activerecord.attributes` names that surface inside validation messages.
- [ ] When copy changes, propagate to tests from the **views diff**, not by
      re-running the converter over test files - those contain fixture data and
      real company names that must not be rewritten.
- [ ] Title Case is sometimes correct: acronyms, tickers, CamelCase such as
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
- [ ] 21 unused custom CSS classes in `admin.css`/`shadcn.css` (see above).
- [ ] **Decide whether `components/ui/_card` keeps the rule under its header.** It is
      the last instance of the pattern after page titles and the admin index header
      strips lost theirs. The component's own doc comment says "whitespace doing the
      separating rather than rules", so markup and comment disagree. Unlike the admin
      strips it wraps free-form content rather than a tinted table header, so nothing
      else separates its header from its body - which is the case for keeping it. It
      covers `home/index`, `stocks/_stock`, and ten admin show pages via
      `admin/shared/_show_attributes`, so this is one edit with wide reach either way.

## Page rebuilds

Foundations are applied everywhere - Figtree, slate, tokens, the table system,
sentence case, and the accessibility fixes - so every page already looks
different. These are the pages not yet **rebuilt onto the primitives**.

- [x] `home/index` - rebuilt on `_page_header`, `_card`, `_empty_state`
- [x] `admin/shared/_show_attributes` - rebuilt on `_card`, which covers ten
      admin show pages
- [x] `portfolios/show` header - sentence-case `h1` with the school as subtitle
- [ ] `portfolios/show` body - metric cards still hand-rolled with
      `rounded-[22px]` and `border-black/30`; move onto `_card`. Student's main
      screen, so highest value of what is left.
- [ ] `stocks/_stock` and `stocks/show` - trading floor, the densest remaining
      page
- [ ] Admin index pages - partly upgraded already via the shared table, but need
      `_page_header` and a `_card` wrapper
- [ ] `classrooms/*` and `grade_books/*` - teacher-facing
- [ ] `devise/registrations/*`, `announcements/show`

