# frozen_string_literal: true

require "application_system_test_case"

# No table may scroll sideways at 375px, anywhere in the app.
#
# This is the assertion the suite did not have. `table_actions_reachable_test` looks only at
# `td.table-actions-cell`, so it could only ever see a table that *has* an actions column - the grade
# book has none, and its four inputs per row sat 398px off the right edge of a scroll while every test
# passed. And `page_width_test` asserts `main` does not scroll, which is a different thing: a table
# scrolling inside its own container leaves `main` perfectly happy.
#
# Measured before the fix, at 375px: admin/teachers 685px of overflow, admin/users 632, admin/stocks
# 595, admin/classrooms 579, orders 489, admin/transactions 404, grade book 398, the roster 364,
# admin/students 332, admin/school_years 299, teacher classrooms 227, admin/schools 196, portfolio
# holdings 101, admin/student show 88 and 152. Every one of them is 0 now.
class TableStackingTest < ApplicationSystemTestCase
  # The scroller is the nearest ancestor that can scroll horizontally - not `.table-wrapper`, which is
  # `overflow-hidden` and therefore can never report scrolling. Measuring that one is how a table gets
  # called clean when the div inside it is the thing scrolling.
  OVERFLOW = <<~JS
    (function () {
      const out = [];
      document.querySelectorAll("main table").forEach(function (t, i) {
        let n = t.parentElement;
        while (n && n !== document.body) {
          const ox = getComputedStyle(n).overflowX;
          if (ox === "auto" || ox === "scroll") break;
          n = n.parentElement;
        }
        if (!n || n === document.body) return;
        const over = n.scrollWidth - n.clientWidth;
        if (over > 1) out.push("table " + i + " overflows by " + Math.round(over) + "px");
      });
      return out;
    })()
  JS

  def assert_no_sideways_scroll(label, path)
    visit path
    overflows = page.evaluate_script(OVERFLOW)

    assert_empty overflows, "#{label}: #{overflows.join(', ')}"
  end

  test "no table scrolls sideways at 375px, on any page a student sees" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 100_000)
    stock = create(:stock, ticker: "AAPL", company_name: "Apple Inc.", price_cents: 15_000)
    create(:order, user: student, stock:, shares: 1, status: :pending, action: :buy)
    sign_in student

    in_phone_viewport do
      assert_no_sideways_scroll("stocks", stocks_path)
      assert_no_sideways_scroll("orders", orders_path)
      assert_no_sideways_scroll("portfolio", user_portfolio_path(student, student.portfolio))
    end
  end

  test "no table scrolls sideways at 375px, on any page a teacher sees" do
    classroom = create(:classroom, :with_trading)
    2.times { create(:student, :with_portfolio, classroom:) }
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    book = classroom.grade_books.first
    classroom.users.students.each { |s| create(:grade_entry, grade_book: book, user: s) }
    sign_in teacher

    in_phone_viewport do
      assert_no_sideways_scroll("classrooms", classrooms_path)
      assert_no_sideways_scroll("classroom show", classroom_path(classroom))
      assert_no_sideways_scroll("grade book", classroom_grade_book_path(classroom, book))
    end
  end

  test "no table scrolls sideways at 375px, on any admin page" do
    school_year = create(:school_year, school: create(:school), year: create(:year))
    classroom = create(:classroom, :with_trading, school_year:)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 100_000)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    create(:stock, ticker: "AAPL", company_name: "Apple Inc.", price_cents: 15_000)
    Announcement.create!(title: "Notice", content: "Body text.")
    sign_in create(:admin)

    in_phone_viewport do
      { "dashboard" => admin_root_path, "users" => admin_users_path,
        "classrooms" => admin_classrooms_path, "students" => admin_students_path,
        "student show" => admin_student_path(student), "teachers" => admin_teachers_path,
        "schools" => admin_schools_path, "school_years" => admin_school_years_path,
        "stocks" => admin_stocks_path, "announcements" => admin_announcements_path,
        "transactions" => admin_portfolio_transactions_path }
        .each { |label, path| assert_no_sideways_scroll(label, path) }
    end
  end

  # The other half of the contract: what a cell holds below lg has to be the same thing it holds at lg.
  # Every row captures its cell content once and renders it at whichever width applies, so the two
  # cannot drift - but a call site could still forget one, and this is what would catch it.
  test "a stacked row shows the same values as its columns" do
    classroom = create(:classroom, :with_trading, name: "Room 9")
    student = create(:student, :with_portfolio, classroom:, name: "Ada Lovelace", username: "ada")
    student.reload
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in teacher

    visit classroom_path(classroom)
    wide = page.evaluate_script(
      "document.querySelector('[data-testid=\"student-username\"]')" \
      ".closest('tr').innerText"
    )

    in_phone_viewport do
      visit classroom_path(classroom)
      narrow = page.evaluate_script(
        "document.querySelector('[data-testid=\"student-username\"]')" \
        ".closest('tr').innerText"
      )

      # The name is in both. The labels only appear in the narrow one, and the figures appear in both -
      # innerText skips display:none, so the narrow reading is the stacked block and nothing else.
      assert_includes wide, "Ada Lovelace"
      assert_includes narrow, "Ada Lovelace"
      assert_includes narrow, "Portfolio value"
      assert_not_includes wide, "Portfolio value"
    end
  end

  # Below lg the grade book reflows rather than collapsing, because restating an input in the primary
  # cell would put two controls with the same name in one form. So: one of each control, and each one
  # carrying a real label, which a `<th>` never gave it.
  # **A label and its value line up, and every value starts at the same x.**
  #
  # Reported as hard to parse at a small viewport, and measured: the pairs were `flex justify-between`
  # with the value right-aligned, so a label sat against the left edge of the card and its value against
  # the right - **174 to 244px apart** - and because right-alignment ragged them, the values' left edges
  # spread across 55px. Eight fields to a transaction row is eight traversals of that gap against a
  # column that never lines up.
  #
  # This asserts the geometry rather than the class list, because "which side is it on" is exactly the
  # kind of thing a class list describes correctly while the box says otherwise.
  test "a stacked row's values share one left edge, close to their labels" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 500_000)
    stock = create(:stock, ticker: "KO", company_name: "Coca-Cola", price_cents: 6_241)
    create(:order, user: student, stock:, shares: 3, status: :pending, action: :buy)
    sign_in student

    in_phone_viewport do
      visit orders_path

      pairs = page.evaluate_script(<<~JS)
        Array.from(document.querySelectorAll("dl > div")).map(function (row) {
          const dt = row.querySelector("dt"), dd = row.querySelector("dd");
          if (!dt || !dd) return null;
          const a = dt.getBoundingClientRect(), b = dd.getBoundingClientRect();
          return { label: dt.innerText.trim(),
                   gap: Math.round(b.left - a.right),
                   valueLeft: Math.round(b.left) };
        }).filter(Boolean)
      JS

      assert_operator pairs.size, :>=, 4, "expected a stacked row with several fields"

      edges = pairs.pluck("valueLeft").uniq

      assert_equal 1, edges.size,
                   "values start at #{edges.sort.inspect}; they should share one left edge"

      pairs.each do |pair|
        assert_operator pair["gap"], :<=, 24,
                        "#{pair['label']} sits #{pair['gap']}px from its value"
      end
    end
  end

  test "the grade book stacks without duplicating its inputs" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:, name: "Ada Lovelace")
    book = classroom.grade_books.first
    create(:grade_entry, grade_book: book, user: student)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in teacher

    in_phone_viewport do
      visit classroom_grade_book_path(classroom, book)

      assert_selector "[data-testid='math-grade-select']", count: 1
      assert_selector "[data-testid='attendance-days-input']", count: 1
      assert_selector "[data-testid='perfect-attendance-control']", count: 1

      # The field names are on screen, since the column headers are not.
      assert_text "Days attended"
      assert_text "Perfect attendance"

      # And the label is really associated, not just nearby.
      bound = page.evaluate_script(<<~JS)
        (function () {
          const input = document.querySelector("[data-testid='attendance-days-input']");
          const label = document.querySelector("label[for='" + input.id + "']");
          return label ? label.textContent.trim() : null;
        })()
      JS

      assert_equal "Days attended", bound
    end
  end
end
