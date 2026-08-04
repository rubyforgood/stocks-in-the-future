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

  test "the pinned cell holds its place when the table is scrolled to the end" do
    sign_in(create(:admin))
    create(:school_year)

    in_phone_viewport do
      visit admin_school_years_path

      result = page.evaluate_script(<<~JS)
        (function () {
          const cell = document.querySelector("td.table-actions-pinned");
          let wrap = cell.parentElement;
          while (wrap && getComputedStyle(wrap).overflowX !== "auto") wrap = wrap.parentElement;
          const edge = Math.round(wrap.getBoundingClientRect().right);
          wrap.scrollLeft = wrap.scrollWidth;
          return {
            edge: edge,
            right: Math.round(cell.getBoundingClientRect().right),
            position: getComputedStyle(cell).position,
            opaque: getComputedStyle(cell).backgroundColor
          };
        })()
      JS

      assert_equal "sticky", result["position"], "the actions cell is not pinned below lg"
      assert_operator result["right"], :<=, result["edge"] + 1,
                      "the actions cell left the visible area once the table was scrolled"
      assert_not_equal "rgba(0, 0, 0, 0)", result["opaque"],
                       "a pinned cell needs an opaque background or the scrolling columns show " \
                       "through it"
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
