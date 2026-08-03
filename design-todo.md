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
