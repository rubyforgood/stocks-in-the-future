# frozen_string_literal: true

require "application_system_test_case"

# Row actions have to be on screen at 375px, in every table, on both sides of the product.
#
# They were not. Every admin index table overflowed its scroll container at 375px - between 212px
# and 699px of it - and the actions were the last column, so View / Edit / Delete sat past the
# right edge. Measured on admin/users before the fix: Edit at right=887 against a visible edge of
# 343. Converting those actions from icon-only controls to ghosts with visible labels is what
# widened the column enough to matter, so this is the test that change needed.
#
# Nothing failed at the time, because every assertion in the suite asks whether a control is
# present, and presence is not reachability - Capybara's visibility check is display / visibility
# / size and knows nothing about an ancestor having scrolled an element out of view.
class TableActionsReachableTest < ApplicationSystemTestCase
  # Only the trailing actions cell. A column's sort link scrolls with its own column, which is
  # inherent to a scrollable data table and is not a hidden action: scrolling brings the column
  # and its control into view together. A row action has no such relationship to the scroll.
  REACHABILITY = <<~JS
    (function () {
      const out = [];
      document.querySelectorAll("td.table-actions-cell a, td.table-actions-cell button").forEach(function (c) {
        if (c.getClientRects().length === 0) return;
        let wrap = c.parentElement;
        while (wrap && wrap !== document.body) {
          const ox = getComputedStyle(wrap).overflowX;
          if ((ox === "auto" || ox === "scroll") && wrap.scrollWidth > wrap.clientWidth + 1) break;
          wrap = wrap.parentElement;
        }
        if (!wrap || wrap === document.body) return;
        const b = c.getBoundingClientRect();
        const w = wrap.getBoundingClientRect();
        if (b.right > w.right + 1 || b.left < w.left - 1) {
          out.push((c.textContent || "").trim().slice(0, 20) +
                   " right=" + Math.round(b.right) + " edge=" + Math.round(w.right));
        }
      });
      return out;
    })()
  JS

  def assert_actions_reachable(label)
    unreachable = page.evaluate_script(REACHABILITY)

    assert_empty unreachable,
                 "#{label}: row actions outside their scroll container at 375px - #{unreachable.join('; ')}"
  end

  test "admin row actions are reachable at 375px" do
    admin = create(:admin)
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 50_000)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    create(:stock, ticker: "AAPL", company_name: "Apple Inc.", price_cents: 15_000)
    create(:school_year)
    sign_in(admin)

    pages = {
      "admin/users" => admin_users_path,
      "admin/classrooms" => admin_classrooms_path,
      "admin/students" => admin_students_path,
      "admin/teachers" => admin_teachers_path,
      "admin/school_years" => admin_school_years_path,
      "admin/stocks" => admin_stocks_path,
      "admin/portfolio_transactions" => admin_portfolio_transactions_path
    }

    in_phone_viewport do
      pages.each do |label, path|
        visit path
        assert_actions_reachable(label)
      end
    end
  end

  # **Every admin index fits at 1024px**, which is Tailwind's `lg` minimum, a docked Chromebook window, and
  # the width where every column hidden below `lg` reappears at once. The sidebar takes 256px, so the table
  # gets a 718px scroller - and three tables wanted 927px, 895px and 853px, which put the row actions off
  # screen. Nothing about that was visible at 1366px or at 375px, which is why it survived both existing
  # tests.
  #
  # This is the guard against column creep: a column added later has to earn its width against 718px, or a
  # table starts scrolling again and the actions are the first thing to go.
  test "no admin index table overflows at the lg minimum" do
    admin = create(:admin)
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 50_000)
    teacher = create(:teacher, name: "Wilhelmina Abernathy")
    create(:teacher_classroom, teacher:, classroom:)
    create(
      :stock,
      ticker: "AAPL", company_name: "Apple Inc.", price_cents: 15_000,
      company_website: "https://www.apple.com/investor-relations"
    )
    create(:school_year)
    sign_in(admin)

    overflowing = {}

    in_lg_minimum_viewport do
      { "admin/users" => admin_users_path,
        "admin/classrooms" => admin_classrooms_path,
        "admin/students" => admin_students_path,
        "admin/teachers" => admin_teachers_path,
        "admin/schools" => admin_schools_path,
        "admin/school_years" => admin_school_years_path,
        "admin/stocks" => admin_stocks_path,
        "admin/announcements" => admin_announcements_path,
        "admin/portfolio_transactions" => admin_portfolio_transactions_path }.each do |label, path|
        visit path
        # Reports the columns as well as the overflow, because "+58px" does not say which column to argue
        # with and the answer is never the one you assume.
        result = page.evaluate_script(<<~JS)
          (function () {
            const wrap = document.querySelector("main [class*='overflow-x']");
            if (!wrap) return { over: 0, columns: [] };
            const columns = [...document.querySelectorAll("main thead th")]
              .map((th) => [th.innerText.replace(/\s+/g, " ").trim().slice(0, 18) || "actions",
                            Math.round(th.getBoundingClientRect().width)])
              .filter((pair) => pair[1] > 0);
            return { over: Math.round(wrap.scrollWidth - wrap.clientWidth), columns: columns };
          })()
        JS
        overflowing[label] = result if result["over"].to_i > 1
      end
    end

    assert_empty overflowing, "these tables scroll sideways at 1024px: #{overflowing.inspect}"
  end

  # At 1024px, which is Tailwind's `lg` minimum and the only width where this mechanism does anything.
  #
  # Below `lg` no table scrolls sideways any more - each one collapses to a single column - so there is
  # no scroll at 375px for a pinned cell to hold its place against. And a Chromebook no longer overflows
  # either, since the primary cell wraps and the Website column shows its host rather than a 267px URL.
  # What is left is 1024px: admin/users runs 202px past its container there, admin/stocks 298px,
  # admin/teachers 251px.
  #
  # This test found that itself. It was written at a Chromebook width and its precondition assertion -
  # "this table does not scroll at 1366px, so the rest of this test proves nothing" - failed the moment
  # the wrapping change landed, which is exactly the failure a precondition is for.
  # Three tests used to live here about the pinned actions cell: that it held its place when the table
  # was scrolled, that it was opaque as soon as it overlapped, and that a table which does not scroll
  # shows no separator. **The cell is not pinned any more**, so all three describe a thing that no longer
  # exists. What replaces them is the property that made pinning look necessary and the one that made it
  # harmful.
  #
  # Why it went: a frozen trailing column covers whatever is scrolled under it at every intermediate
  # position, reported as "half a column is displayed, and the rest is covered by the column on the right
  # with the action buttons". Measured, these tables overflow only between 1024px and about 1200px - at
  # 1366 and 1920 it is zero on every one of them - so the pin served one narrow band, and below `lg` the
  # actions are already repeated in the primary cell. The convention it reached for freezes the *leading*
  # column anyway.
  test "the actions cell scrolls with its table rather than floating over it" do
    sign_in(create(:admin))
    a_wide_classrooms_table

    in_lg_minimum_viewport do
      visit admin_classrooms_path

      result = page.evaluate_script(<<~JS)
        (function () {
          const cell = document.querySelector("td.table-actions-cell");
          const wrap = cell.closest("[class*='overflow-x']");
          const before = Math.round(cell.getBoundingClientRect().left);
          wrap.scrollLeft = 120;
          const after = Math.round(cell.getBoundingClientRect().left);
          wrap.scrollLeft = 0;
          return {
            position: getComputedStyle(cell).position,
            overflow: Math.round(wrap.scrollWidth - wrap.clientWidth),
            movedBy: before - after
          };
        })()
      JS

      assert_operator result["overflow"], :>, 1,
                      "the table does not overflow here, so this proves nothing about scrolling"
      assert_equal "static", result["position"],
                   "a sticky actions cell covers the column scrolled under it"
      assert_equal 120, result["movedBy"],
                   "the actions cell did not move with the scroll, so it is still pinned somehow"
    end
  end

  # The reason pinning is not needed: below `lg` the row collapses into its primary cell and the actions
  # come with it. That is asserted at 375px above; this pins the mechanism so the two cannot drift - if
  # the stacked fields ever stop carrying `actions:`, the phone loses them entirely and no pin would help.
  test "the collapsed row carries its actions" do
    sign_in(create(:admin))
    a_wide_classrooms_table

    in_phone_viewport do
      visit admin_classrooms_path

      within "tbody tr:first-child" do
        assert_no_selector "td.table-actions-cell", visible: true
        assert_selector "a", text: "Edit"
      end
    end
  end

  test "no page makes the main region scroll sideways at 375px" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in(teacher)

    in_phone_viewport do
      [classrooms_path, classroom_path(classroom)].each do |path|
        visit path

        overflow = page.evaluate_script(<<~JS)
          (function () {
            const m = document.querySelector("main");
            return m.scrollWidth - m.clientWidth;
          })()
        JS

        assert_operator overflow, :<=, 1,
                        "#{path} overflows <main> by #{overflow}px at 375px; a two-column row " \
                        "that does not stack below lg is the usual cause"
      end
    end
  end
  # Long names on purpose: the table has to be genuinely wider than its container for a pinned cell to
  # be pinned at all, and a fixture with short values makes the test pass while proving nothing.
  # Deliberately extreme, and it has to be: with ordinary data this table **fits** at 1024px now, since the
  # id column went and the Archived and Trading columns became one Status. That is asserted just above. The
  # property this fixture exists for - that the actions cell scrolls with its table rather than floating over
  # the column beneath it - can only be measured on a table that scrolls, so the data forces one.
  def a_wide_classrooms_table
    classroom = create(
      :classroom, :with_trading,
      name: "Mrs Abernathy's Advanced Placement Sixth Grade Homeroom",
      school_year: create(
        :school_year,
        school: create(:school, name: "Saint Bartholomew's Consolidated Elementary and Middle School"),
        year: create(:year)
      )
    )
    create(
      :teacher_classroom, teacher: create(:teacher, name: "Wilhelmina Abernathy-Fitzgerald"),
                          classroom: classroom
    )
  end
end
