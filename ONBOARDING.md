# Onboarding

Two audiences, one document, because they need the same middle third.

- **New to using the app** — a teacher, an administrator, or someone showing it to students. Read
  [What the app is](#what-the-app-is), then [your role](#what-each-role-can-do).
- **New to maintaining it** — read the whole thing. The role sections are not padding: almost every bug
  recorded in this repo's history was a rule that applied to one role and not another.

Everything below is derived from the code, not from memory. Where a figure appears it is the constant,
named, so you can check it.

---

## What the app is

Students learn about investing by earning real classroom money and spending it on real stock prices.

1. A **teacher** enters grades and attendance into a **grade book**, one per quarter of a school year.
2. Finalizing that grade book **pays each student** — into a portfolio, as a ledger of transactions.
3. Students spend that balance on the **trading floor**, buying and selling shares at real closing
   prices, and watch their portfolio move.

The money is not real, and the prices are. That is the whole design: the consequences are true even
though the stake is not.

### The words

| Term | What it is |
|---|---|
| **Classroom** | A group of students, belonging to one **school year**, taught by one or more teachers |
| **School year** | A school and a year, which owns exactly **four quarters** |
| **Grade book** | One per quarter per classroom. Holds one **grade entry** per student |
| **Grade entry** | A student's maths grade, reading grade, days attended and perfect-attendance answer |
| **Portfolio** | A student's money. A balance is **derived from** its transactions, never stored |
| **Order** | A buy or a sell, placed by a student, executed later by a job |
| **Trading floor** | `/stocks` — the list of companies, prices, and the Buy/Sell controls |

### The money rules, exactly

Earnings are per student per quarter, paid when a grade book is finalized. From
`GradeEntry` — these are the constants, in cents:

- **`EARNINGS_PER_DAY_ATTENDANCE = 20`** — 20¢ for each day attended.
- **`EARNINGS_FOR_A_GRADE = 300`**, **`EARNINGS_FOR_B_GRADE = 200`** — per subject, maths and reading.
  **C and below earn nothing for the grade.**
- **`EARNINGS_FOR_IMPROVED_GRADE = 200`** — per subject, for improving on the previous quarter.
  **Improvement pays even when the grade itself earns nothing**: F → D earns 200. Improving *within* a
  band counts too: A- → A pays.
- **`EARNINGS_FOR_PERFECT_ATTENDANCE = 100`** — a teacher's answer, not a calculation.
- **`PortfolioTransaction::TRANSACTION_FEE_CENTS = 100`** — a trading fee, charged **once per student
  per job run**, not per order. That is deliberate.

Quarter 1 pays no improvement, and not for the reason people expect: a classroom belongs to one school
year and only has grade books for that year's quarters, so the previous-quarter lookup asks for a grade
book that cannot exist.

### What happens on a schedule

From `config/recurring.yml`:

| Job | When | What |
|---|---|---|
| `OrderExecutionJob` | every 15 minutes | Fills pending orders at the current price, and charges the fee |
| `StockPricesUpdateJob` | 02:00, Tuesday–Saturday | Fetches yesterday's closing prices |
| `MonthlyPortfolioSnapshotJob` | last day of the month, 23:00 | Records each portfolio's value |
| `StockAttributeUpdateJob` | Saturdays, 04:00 | Refreshes company details |

Two consequences worth knowing before you are surprised by them: an order is **not** filled the moment
it is placed, and prices are a day old by design — the trading floor states the date they carry.

---

## What each role can do

Derived from `app/policies/`. Where a rule looks arbitrary, the policy is the authority.

### Student

- **Trading floor** (`/stocks`) — every company, its last price, how many shares they own, Buy and Sell.
  Buy and Sell appear only when the student has a portfolio **and their classroom has trading enabled**
  (`StockPolicy#show_trading_link?`).
- **Portfolio** — balance, holdings, gain or loss, monthly snapshots.
- **Transactions** (`/orders`) — their own orders, with cancel while an order is pending.
- **Profile** — display name, email, password. Their username is shown but not editable: a teacher
  changes it.
- They see **their own** portfolio and nobody else's, and **no grades at all** - `GradeBookPolicy#show?`
  is teacher-or-admin. What reaches a student is the money those grades earned, broken down by
  attendance, maths and reading, once the grade book is finalized.

### Teacher

- **Classrooms they teach** — the roster, and the trading switch for that classroom.
- **Grade books** — enter grades, days attended and the attendance bonus; the page autosaves as fields
  lose focus. **A teacher cannot finalize**: `GradeBookPolicy#finalize?` is `user.admin?`, so the person
  who enters the grades is not the person who releases the money.
- **Students** — add one, edit them, reset a password (shown once, on screen — no email is sent), and
  archive one.
- **Their classroom's name, grades and trading flag** are editable. **School, year and which teachers
  are assigned are not** — those move a classroom between school years and decide who can see it, and
  they stay with administrators (`ClassroomPolicy#permitted_attributes`).
- On the trading floor a teacher sees **Held by** — how many of their students own each company —
  instead of Buy and Sell.
- **A teacher cannot open `/admin`.** Anything under it redirects them to the app root.

### Administrator

- Everything a teacher can see, across **every** classroom, plus `/admin`: schools, school years,
  classrooms, students, teachers, users, stocks, announcements and portfolio transactions.
- **Finalizing a grade book** — the irreversible one. It deposits real balances into every student's
  portfolio and locks the entries. The page states the total before you press, and so does the
  confirmation.
- **Archiving** rather than deleting people: `User#destroy` is overridden to discard. Only
  `admin/teachers#destroy` genuinely removes a record, by calling `really_destroy!`.

---

## For new maintainers

### Getting it running

`bin/rails db:setup && bin/dev` — see [README](README.md) for the Docker route. Four seeded logins, all
with the password `password`, and you **sign in with a username, not an email**:

| `admin` | `teacher` | `student` | `mike` |
|---|---|---|---|

`mike` is the student with holdings and transactions; `student` is a clean one.

### Where the documentation is, and what each file is for

This repo carries more written history than most, deliberately. Read them for their purpose, not their
size:

| File | What it is | Read it when |
|---|---|---|
| [`design.md`](design.md) | The design system. A **specification of the present** | Before choosing any size, colour, spacing or pattern |
| [`CLAUDE.md`](CLAUDE.md) | Traps this codebase has actually sprung, with the measurement | Before you trust an assumption about it |
| [`migration.md`](migration.md) | A **changelog of long-term-consequence changes**. History, not spec | When you need to know why something is the way it is |
| [`design-instructions.md`](design-instructions.md) | The process for design work | Before a UI change |
| [`design-todo.md`](design-todo.md) | The backlog, including decisions nobody has made | Before starting something |

**Two of these are history and must not be rewritten to match the present.** `migration.md`'s entries
say "this *was* called X" and that is correct. `design.md` and `CLAUDE.md` describe now, and are
corrected when the code moves.

### The rules that will bite you first

The long list is in `CLAUDE.md`. These are the ones that catch people in their first week:

1. **Integer cents are authoritative.** `cash_balance_cents` for arithmetic, `cash_balance` (a Float)
   for display only. The round trip loses value for most two-decimal amounts, which once made an
   exactly-affordable order fail with "You have $16.06 but need $16.06".
2. **Only `base` and `lg:`.** No `sm:`, `md:`, `xl:`. The users are students on 1366×768 school
   Chromebooks and 375px phones, and those are the two widths to check.
3. **Sentence case everywhere.** Capitalise the first word and proper nouns. No `uppercase` transform.
4. **Measure the rendered box.** Class names describe intent; only `getBoundingClientRect()` describes
   the result. Three separate spacing bugs here were invisible in the markup.
5. **Never write an ERB comment's terminator inside a comment, and never put a tag inside another tag.**
   Both have shipped broken pages. `test/views/no_nested_erb_tags_test.rb` catches the second in 30ms.
6. **Do not run two `bin/rails test` invocations at once.** Parallel workers share ten numbered
   databases and a second run fills both with deadlocks that look like a suite bug.
7. **`bin/lint` is the gate**, and it includes `bundler-audit` — a dependency CVE fails it even when your
   code is clean.

### How the app is built

- **Rails 8.1**, Hotwire (Turbo + Stimulus), importmap, Propshaft, Tailwind v4, Postgres, Solid Queue.
- **Devise** for authentication, keyed on **username**. **Pundit** for authorization. **Discard** for
  soft deletion.
- **Forms are `Ui::FormBuilder`** (`app/form_builders/ui/form_builder.rb`) — every entity form on both
  halves of the product. It renders label, hint, input and, through
  `config/initializers/field_error_proc.rb`, the error, in that order.
- **Shared UI is `app/views/components/ui/`** — eight partials, every one of them rendered at
  `/admin/component_demo` (development and test only). `component_gallery_test` fails when a new one is
  added and the gallery is not.
- **Admin authorization is one `before_action`** in `Admin::BaseController`. There is no per-record
  policy in that namespace, and `admin_access_test` walks every admin route to prove nothing bypasses it.

### Testing

`bin/rails test` and `bin/rails test:system` — Minitest, FactoryBot, no fixtures, Capybara driving real
Chromium. **There are no skipped tests and it should stay that way**: all six that existed were
investigated and none was flaky; five were stale and each carried a confident-sounding diagnosis that
stopped anyone reading the failure.

Two habits this codebase has learned the hard way:

- **Verify a new test by making it fail.** A test that has never failed has never been shown to test
  anything — several here passed while asserting nothing.
- **A controller test that hand-writes its params cannot catch a form/controller mismatch.** Eight of
  them passed while every real submit returned 400. Assert the rendered field names, or click the button.

### Things that are deliberately absent

So you do not "fix" them: there is no dark mode (a `dark:` variant is a bug here), no TomSelect or
type-ahead, no pagination on most tables, and no email on password reset — a teacher reads the new
password off the screen and passes it on.

And **a student never sees a grade.** `GradeBookPolicy#show?` is teacher-or-admin, so grade books are
closed to them entirely. What they see is the *money*: once a grade book is finalized, their portfolio
breaks the deposit down by attendance, maths and reading, which is what the home page means by
"summaries of your grades and attendance". Whether they should see the grades themselves — and whether
they should see a projection before finalizing — are two of the three open product questions in
`design-todo.md`. Neither is an oversight.
