# frozen_string_literal: true

require "application_system_test_case"

# Every table, measured, against design.md's Tables section.
#
# Three reports drove this, all on the trading floor and all invisible in a class list:
#
#   - The Active and Archived tables did not share column positions. They are two <table>
#     elements from one partial, and with auto layout each sized columns from its own content, so
#     the Buy/Sell pair widened the actions column in one and pulled every other column left.
#     Measured at 1366px: column two began at 567px in one table and 699px in the other.
#   - The header strip was grey. design.md: "the thead itself is unfilled ... never a bg-slate-50
#     fill". The fill was written two ways at once - .table-header-row on the app side and an
#     inline `<thead class="bg-slate-50">` on fourteen admin and teacher tables - which is why
#     earlier sweeps kept missing half of it.
#   - Nothing in a row shared a baseline. The primary cell was `items-center` around a logo that
#     grew to 64px at lg, so the ticker sat below the price and holdings text, and every th in the
#     app computed to vertical-align: middle against top-aligned cells.
class TableConsistencyTest < ApplicationSystemTestCase
  TRANSPARENT = "rgba(0, 0, 0, 0)"
  SLATE_600 = "oklch(0.446 0.043 257.281)"

  def tables_report
    page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll("table")).map(function (t) {
        const tr = t.querySelector("thead tr");
        const th = t.querySelector("thead th");
        if (!tr || !th) return null;
        const ths = getComputedStyle(th);
        let td = null;
        for (const row of t.querySelectorAll("tbody tr")) {
          const c = row.querySelector("td");
          if (!c) continue;
          if (c.getAttribute("colspan")) continue;
          td = c;
          break;
        }
        return {
          headBg: ths.backgroundColor,
          rowBg: getComputedStyle(tr).backgroundColor,
          thColour: ths.color,
          thSize: ths.fontSize,
          thWeight: ths.fontWeight,
          thAlign: ths.verticalAlign,
          tdAlign: td ? getComputedStyle(td).verticalAlign : null,
          seam: [getComputedStyle(t).borderBottomWidth,
                 getComputedStyle(t.querySelector("thead")).borderBottomWidth,
                 getComputedStyle(tr).borderBottomWidth].filter(function (w) {
                   return w !== "0px";
                 }).length
        };
      }).filter(function (r) { return r; })
    JS
  end

  def assert_tables_to_spec(label)
    report = tables_report

    assert_not_empty report, "#{label}: no table with a header"

    report.each_with_index do |t, i|
      where = "#{label} table #{i}"

      assert_equal TRANSPARENT, t["headBg"], "#{where}: the header cell is filled"
      assert_equal TRANSPARENT, t["rowBg"], "#{where}: the header row is filled - it must be a " \
                                            "border, never a bg-slate-50 strip"
      assert_equal SLATE_600, t["thColour"], "#{where}: header ink is not slate-600"
      assert_equal "12px", t["thSize"], "#{where}: header is not text-xs"
      assert_equal "600", t["thWeight"], "#{where}: header is not font-semibold"
      assert_equal "top", t["thAlign"], "#{where}: headers must align-top so a wrapped header " \
                                        "does not centre its single-line neighbours"
      assert_equal 1, t["seam"], "#{where}: #{t['seam']} borders at the header seam; a table " \
                                 "divide-y stacking on the row's border is the usual cause"
      if t["tdAlign"]
        assert_equal "top", t["tdAlign"], "#{where}: body cells must align-top to the row's " \
                                          "first line"
      end
    end
  end

  test "tables match the spec across the app" do
    school = create(:school)
    school_year = create(:school_year, school:, year: create(:year))
    classroom = create(:classroom, :with_trading, school_year:)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 100_000)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    stock = create(:stock, ticker: "KO", company_name: "Coca-Cola Company", price_cents: 15_000)
    create(:order, user: student, stock:, shares: 1, status: :pending, action: :buy)
    create(:portfolio_stock, portfolio: student.portfolio, stock:, shares: 3)
    grade_book = classroom.grade_books.first || create(:grade_book, classroom:)
    # The grade book renders its table only when it has entries.
    create(:grade_entry, grade_book:, user: student)

    sign_in(create(:admin))
    { "admin/users" => admin_users_path,
      "admin/students#show" => admin_student_path(student),
      "admin/dashboard" => admin_root_path,
      "admin/transactions" => admin_portfolio_transactions_path }
      .each do |label, path|
      visit path
      assert_tables_to_spec(label)
    end

    sign_in(teacher)
    { "classroom#show" => classroom_path(classroom),
      "grade book" => classroom_grade_book_path(classroom, grade_book),
      "classrooms" => classrooms_path }
      .each do |label, path|
      visit path
      assert_tables_to_spec(label)
    end

    sign_in(student)
    { "orders" => orders_path,
      "portfolio" => user_portfolio_path(student, student.portfolio),
      "trading floor" => stocks_path }
      .each do |label, path|
      visit path
      assert_tables_to_spec(label)
    end
  end

  # The two trading floor tables are separate elements that must line up with each other.
  test "the trading floor's two tables share one column geometry" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 100_000)
    create(:stock, ticker: "KO", company_name: "Coca-Cola Company", price_cents: 15_000)
    create(:stock, ticker: "ZZZZ", company_name: "Archived Co.", price_cents: 900, archived: true)
    sign_in(student)

    in_chromebook_viewport do
      visit stocks_path

      geometries = page.evaluate_script(<<~JS)
        Array.from(document.querySelectorAll("table")).map(function (t) {
          return Array.from(t.querySelectorAll("thead th")).map(function (h) {
            const b = h.getBoundingClientRect();
            return Math.round(b.left) + ":" + Math.round(b.width);
          }).join(" ");
        })
      JS

      assert_equal 2, geometries.size, "expected an active and an archived table"
      assert_equal geometries.first, geometries.last,
                   "the two tables' columns are in different places, so the page steps sideways " \
                   "at the boundary between them"
    end
  end

  # The classrooms table had a cell overriding the shared padding. `table-body-cell` is `py-3`; the
  # Teacher(s) cell was `table-body-cell py-4`, and its badge strip carried `py-1` and `min-h-9` on
  # top - all three inherited from an inline `style="max-width: 510px; min-height: 36px"`. Measured
  # for a teacher: that cell's text sat at 28px from the row top against 14px for every other
  # column, and the row was 69px against the 48px design.md sets. tables.css is in
  # `@layer components`, so a `py-4` utility on the element beats the layered `py-3` and the class
  # list reads as though it is using the shared padding.
  #
  # The badge's own `py-1` still puts its text ~4px below bare text, which is what a pill does and
  # what every other table in the app measures - the tolerance covers that and not 14px.
  test "a classrooms row shares one line, at the standard row height" do
    classroom = create(:classroom, :with_trading, name: "Aligned Class")
    teacher = create(:teacher, name: "Terry Teacher")
    create(:teacher_classroom, teacher:, classroom:)
    2.times { create(:student, :with_portfolio, classroom:) }
    sign_in(teacher)

    visit classrooms_path

    report = page.evaluate_script(<<~JS)
      (function () {
        const row = document.querySelector("tbody tr.table-body-row");
        const rb = row.getBoundingClientRect();
        function firstLine(el) {
          const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT);
          let n;
          while ((n = walker.nextNode())) {
            if (!n.textContent.trim()) continue;
            const r = document.createRange();
            r.selectNodeContents(n);
            const rects = r.getClientRects();
            if (rects.length) return Math.round(rects[0].top - rb.top);
          }
          return null;
        }
        return {
          height: Math.round(rb.height),
          tops: Array.from(row.querySelectorAll("td")).map(firstLine),
          pads: Array.from(row.querySelectorAll("td")).map(function (td) {
            return getComputedStyle(td).paddingTop;
          })
        };
      })()
    JS

    assert_equal ["12px"], report["pads"].uniq,
                 "a cell is overriding table-body-cell's padding: #{report['pads'].inspect}"

    tops = report["tops"].compact

    assert_in_delta tops.min, tops.max, 5,
                    "the row's cells start on different lines: #{report['tops'].inspect}"
    assert_in_delta 48, report["height"], 2,
                    "the row is #{report['height']}px; design.md sets 48px"
  end

  # An unlabelled trailing column whose every cell is the no-permission dash tells a reader nothing.
  # ClassroomPolicy#edit? is admin-only, so that is exactly what a teacher saw. The dash stays where a
  # column holds actions for some rows and not others - portfolios#show - so this asserts the column
  # is absent for a teacher and present for an admin rather than removing the convention.
  test "the classrooms actions column is absent when the viewer has no action" do
    classroom = create(:classroom, :with_trading)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in(teacher)

    visit classrooms_path

    assert_selector "tbody tr.table-body-row"
    assert_not has_selector?(".table-no-permission", wait: 0),
               "a teacher sees a column of dashes where no action is ever available"
    assert_equal 4, page.evaluate_script('document.querySelectorAll("thead th").length'),
                 "the actions column is still being rendered for a viewer who has none"
  end

  test "the classrooms actions column is present for an admin" do
    create(:classroom, :with_trading)
    sign_in(create(:admin))

    visit classrooms_path

    assert_equal 5, page.evaluate_script('document.querySelectorAll("thead th").length')
    assert_selector "tbody tr.table-body-row a", text: "Edit"
  end

  # Everything in a row hangs off the row's first line.
  test "a trading floor row shares one baseline" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 100_000)
    create(:stock, ticker: "KO", company_name: "Coca-Cola Company", price_cents: 15_000)
    sign_in(student)

    in_chromebook_viewport do
      visit stocks_path

      lines = page.evaluate_script(<<~JS)
        (function () {
          const row = document.querySelector("tbody tr");
          const rb = row.getBoundingClientRect();
          const tds = row.querySelectorAll("td");
          function firstLine(el) {
            const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT);
            let n;
            while ((n = walker.nextNode())) {
              if (!n.textContent.trim()) continue;
              const r = document.createRange();
              r.selectNodeContents(n);
              const rects = r.getClientRects();
              if (rects.length) return Math.round(rects[0].top - rb.top);
            }
            return null;
          }
          const buys = Array.from(row.querySelectorAll("[data-testid='buy-stock-button']"));
          const buy = buys.find(function (b) { return b.getClientRects().length > 0; });
          const logo = row.querySelector("img");
          return {
            ticker: firstLine(row.querySelector("a.tw-link")),
            price: firstLine(tds[1]),
            holdings: firstLine(tds[2]),
            buyTop: buy ? Math.round(buy.getBoundingClientRect().top - rb.top) : null,
            logoTop: logo ? Math.round(logo.getBoundingClientRect().top - rb.top) : null,
            logoSize: logo ? Math.round(logo.getBoundingClientRect().height) : null
          };
        })()
      JS

      assert_equal lines["ticker"], lines["price"],
                   "the company name and the price are on different lines"
      assert_equal lines["ticker"], lines["holdings"],
                   "the company name and the holdings count are on different lines"

      # The 40px logo and the 40px button are blocks: they share a top edge with each other, one
      # text line-box above the first baseline.
      assert_in_delta lines["ticker"], lines["buyTop"], 2,
                      "the trade buttons float away from the row's first line"
      if lines["logoTop"]
        assert_in_delta lines["ticker"], lines["logoTop"], 2, "the logo floats off the first line"
        assert_equal 40, lines["logoSize"],
                     "the logo must match the two-line ticker/company block; at 64px it set the " \
                     "row height and pushed the text off every other cell's baseline"
      end
    end
  end
end
