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
      document.querySelectorAll("td.table-actions-pinned a, td.table-actions-pinned button").forEach(function (c) {
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
  test "the pinned cell holds its place when the table is scrolled to the end" do
    sign_in(create(:admin))
    # Long enough to overflow seven columns at 1366px. With the factory's short name this table fits,
    # and the test would then assert against a scroll that never happened - which is how it would pass
    # while proving nothing.
    classroom = create(
      :classroom, :with_trading,
      name: "Mrs Abernathy's Advanced Placement Sixth Grade Homeroom",
      school_year: create(:school_year, school: create(:school), year: create(:year))
    )
    create(
      :teacher_classroom, teacher: create(:teacher, name: "Wilhelmina Abernathy-Fitzgerald"),
                          classroom: classroom
    )

    in_lg_minimum_viewport do
      visit admin_classrooms_path

      # The precondition, asserted rather than assumed: there is a scroll for the cell to hold its
      # place against.
      overflow = page.evaluate_script(<<~JS)
        (function () {
          const wrap = document.querySelector("td.table-actions-pinned").closest("[class*='overflow-x']");
          return Math.round(wrap.scrollWidth - wrap.clientWidth);
        })()
      JS

      assert_operator overflow, :>, 1,
                      "this table does not scroll at 1024px, so the rest of this test proves nothing"

      page.execute_script(<<~JS)
        const wrap = document.querySelector("td.table-actions-pinned").closest("[class*='overflow-x']");
        wrap.scrollLeft = wrap.scrollWidth;
      JS

      # The scroll event fires asynchronously, so the state the separator depends on is not set in
      # the same tick that sets scrollLeft. Wait for it before reading any style - an earlier
      # version of this test read the background synchronously and saw the unscrolled value.
      assert_selector "[data-table-scrolled='true']", visible: :all

      result = page.evaluate_script(<<~JS)
        (function () {
          const cell = document.querySelector("td.table-actions-pinned");
          const wrap = cell.closest("[class*='overflow-x']");
          return {
            edge: Math.round(wrap.getBoundingClientRect().right),
            right: Math.round(cell.getBoundingClientRect().right),
            position: getComputedStyle(cell).position,
            opaque: getComputedStyle(cell).backgroundColor
          };
        })()
      JS

      assert_equal "sticky", result["position"], "the actions cell is not pinned"
      assert_operator result["right"], :<=, result["edge"] + 1,
                      "the actions cell left the visible area once the table was scrolled"
      assert_not_equal "rgba(0, 0, 0, 0)", result["opaque"],
                       "a pinned cell needs an opaque background once the table is scrolled, or " \
                       "the columns sliding under it show through"
    end
  end

  # And the separator is absent when there is nothing behind it. It used to be unconditional below
  # lg, which drew a stray rule on the student portfolio's holdings table - measured, that table
  # never scrolls at any width, because it adapts by wrapping the company name.
  test "an unscrolled table shows no separator" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 100_000)
    stock = create(:stock, ticker: "KO", company_name: "Coca-Cola Company", price_cents: 15_000)
    create(:portfolio_stock, portfolio: student.portfolio, stock:, shares: 2)
    sign_in(student)

    in_phone_viewport do
      visit user_portfolio_path(student, student.portfolio)

      pinned = page.evaluate_script(<<~JS)
        (function () {
          const cell = document.querySelector("td.table-actions-pinned");
          if (!cell) return null;
          const wrap = cell.closest("[class*='overflow-x']");
          const s = getComputedStyle(cell);
          return {
            border: s.borderLeftWidth,
            bg: s.backgroundColor,
            scrollLeft: wrap.scrollLeft,
            scrollable: wrap.scrollWidth > wrap.clientWidth + 1
          };
        })()
      JS

      assert_not_nil pinned
      # The point is not whether it *can* scroll - it is that nothing is behind the cell until it
      # *has* been scrolled. An earlier version asserted the table does not scroll at all, which was
      # measured against .table-wrapper - an overflow-hidden element that can never report scrolling.
      assert_equal 0, pinned["scrollLeft"]
      assert_equal "0px", pinned["border"],
                   "a separator with nothing behind it is a stray rule beside the button"
      assert_equal "rgba(0, 0, 0, 0)", pinned["bg"],
                   "an opaque cell on an unscrolled row swallows the row's hover tint"
    end
  end

  # classroom#show laid the roster and the grade book list side by side with a bare `flex gap-8`
  # at every width: 812px of content in a 328px viewport, which made <main> itself scroll sideways
  # and carried every row action off screen with it. Pinning could not help, because the cell pins
  # to its own table's container and that container was the thing being pushed right.
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
end
