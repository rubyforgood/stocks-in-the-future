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

- [ ] `components/_action_icon_button.html.erb` - 6 off-tier bp, 2 FA icon
- [ ] `components/ui/_button.html.erb` - clean
- [ ] `components/ui/_checkbox.html.erb` - clean
- [ ] `components/ui/_input.html.erb` - clean
- [ ] `components/ui/_label.html.erb` - clean
- [ ] `components/ui/_textarea.html.erb` - clean
- [ ] `layouts/_navbar.html.erb` - 5 hex, 4 img no alt, 1 div-as-button, 2 FA icon
- [ ] `layouts/_stock_item.html.erb` - clean
- [ ] `layouts/_stock_ticker.html.erb` - clean
- [ ] `layouts/admin.html.erb` - 1 off-tier bp, 1 div-as-button, 1 FA icon
- [ ] `layouts/application.html.erb` - 7 hex, 1 off-tier bp
- [ ] `shared/_earnings_to_invest_card.html.erb` - clean
- [ ] `shared/_modal.html.erb` - 1 faint text, 1 div-as-button
- [ ] `shared/_table_container.html.erb` - clean

## Auth (Devise)

- [ ] `devise/confirmations/new.html.erb` - clean
- [ ] `devise/passwords/edit.html.erb` - clean
- [ ] `devise/passwords/new.html.erb` - 1 hex, 4 off-tier bp, 1 faint text
- [ ] `devise/registrations/edit.html.erb` - clean
- [ ] `devise/registrations/new.html.erb` - 1 faint text
- [ ] `devise/sessions/new.html.erb` - 1 hex, 5 off-tier bp, 2 faint text
- [ ] `devise/shared/_error_messages.html.erb` - clean
- [ ] `devise/shared/_links.html.erb` - clean
- [ ] `devise/unlocks/new.html.erb` - clean

## Student-facing

- [ ] `announcements/show.html.erb` - clean
- [ ] `fields/portfolio_link/_index.html.erb` - clean
- [ ] `home/index.html.erb` - 3 hex, 25 off-tier bp, 1 faint text
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

- [ ] Add SITF brand colours as semantic tokens so pages stop hardcoding hex.
- [ ] Replace the Font Awesome CDN link with local SVG icons (78 usages).
- [ ] Sweep `sm:`/`md:`/`xl:`/`2xl:` down to `base` + `lg:` (153 usages).
- [ ] Add `scope` to every `<th>` (58 usages).
- [ ] Replace faint text colours with `gray-500` or darker (33 usages).
- [ ] Give every `outline-none` a visible focus replacement (17 usages).
- [ ] Convert clickable divs to real buttons (4 usages).
- [ ] Audit the trading modal (`shared/_modal`) for focus trap, restore, and Esc.
- [ ] Add a card / badge / empty-state primitive to `components/ui/`.
- [ ] Reconcile `design.md` with this codebase (see blockers in design-instructions.md).
- [ ] Untrack `app/.DS_Store` and `app/assets/.DS_Store`.
