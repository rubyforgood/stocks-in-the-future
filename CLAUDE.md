# Working notes for this repo

Durable context for anyone — human or agent — picking up UI work here. Kept
short on purpose. The design system lives in [`design.md`](design.md), the
process in [`design-instructions.md`](design-instructions.md), the backlog in
[`design-todo.md`](design-todo.md).

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

**Known oddity, deliberately untouched:** the trading fee is never recorded as a
transaction. `ExecuteOrder` writes only `purchase_cost` in both directions, and
the fee exists solely as a notional deduction in `Portfolio#cash_on_hand_in_cents`
while an order is pending — so it vanishes once the order completes. It behaves
like a hold, not a fee. Changing it moves real balances, so it needs a product
decision first.

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

And Title Case is sometimes correct: acronyms, tickers, CamelCase like
`DateTime`, company names, and people's names. Two were caught mid-sweep and
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

## Responsive

Only `base` and `lg:`. No `sm:`, `md:`, `xl:` or `2xl:`. Users are students on
school Chromebooks at 1366x768 and phones at 375px, so those are the two widths
to check. Minimum 44px touch targets.

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
`app/views`, `app/helpers`, `app/assets/tailwind` and `app/components`.

Also: delete unused CSS rather than leaving it. An unused class is
indistinguishable from a supported one until someone adopts it. `admin.css` held
five unreferenced classes with eight `!important` declarations and pre-token hex,
and I spent effort "fixing" a focus indicator on one of them before noticing
nothing rendered it.

## Comments are not inert

A comment containing its own terminator ends early, and the remainder becomes
content. I did this twice on this branch: a `*/` inside a CSS comment broke the
Tailwind build, and a `%>` inside an ERB comment leaked a whole sentence onto a
rendered page as visible text. Don't write those sequences inside the comment that
uses them.

Relatedly, interpolating an optional HTML attribute yields an *unquoted*
attribute, which CSS and Capybara selectors will not match. Use `tag.div`, which
omits nil attributes entirely.
