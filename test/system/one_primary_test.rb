# frozen_string_literal: true

require "application_system_test_case"

# design.md, Buttons: "One primary CTA per page." A view gets exactly one filled :primary - its
# main action - and every other action is lower emphasis. A dialog keeps its own primary confirm,
# which is visible only while the modal is open, so it does not count against the page.
#
# Two pages broke it, both in the shapes the rule names:
#
#   - admin/students#edit stacked "Update student" with a second card's "Add transaction". That is
#     the sub-form submit case: an inline submit inside a management card is :secondary, never
#     :primary.
#   - portfolios#show rendered a filled "Trade" in every holdings row - a per-row filled CTA, the
#     thing the row-action rule exists to prevent, and a table the earlier ghost sweep missed -
#     plus "Go to the trading floor" in its empty state alongside the earnings card's "Invest now",
#     two primaries pointing at the same path.
class OnePrimaryTest < ApplicationSystemTestCase
  # Excludes anything inside a dialog or the modal turbo-frame.
  PAGE_PRIMARIES = <<~JS
    (function () {
      const out = [];
      document.querySelectorAll(".tw-btn-primary").forEach(function (el) {
        if (el.getClientRects().length === 0) return;
        if (el.closest("dialog, [role=dialog], turbo-frame#modal_frame")) return;
        out.push((el.value || el.textContent || "").replace(/\\s+/g, " ").trim().slice(0, 30));
      });
      return out;
    })()
  JS

  def assert_one_primary(label, path)
    visit path
    primaries = page.evaluate_script(PAGE_PRIMARIES)

    assert_operator primaries.size, :<=, 1,
                    "#{label} has #{primaries.size} filled primary buttons: " \
                    "#{primaries.join(' | ')}. One per page - the page's main action; everything " \
                    "else is secondary or ghost."
  end

  test "student pages have at most one primary" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 100_000)
    stock = create(:stock, ticker: "AAPL", company_name: "Apple Inc.", price_cents: 15_000)
    sign_in(student)

    assert_one_primary("home", root_path)
    assert_one_primary("stocks", stocks_path)
    assert_one_primary("stock show", stock_path(stock))
    assert_one_primary("orders", orders_path)
    assert_one_primary("portfolio", user_portfolio_path(student, student.portfolio))
  end

  test "a holdings row action is a ghost, not a filled CTA" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 100_000)
    stock = create(:stock, ticker: "AAPL", company_name: "Apple Inc.", price_cents: 15_000)
    create(:portfolio_stock, portfolio: student.portfolio, stock:, shares: 2)
    sign_in(student)

    visit user_portfolio_path(student, student.portfolio)

    trade = find("tbody a", text: "Trade")

    assert_equal 1, trade.all("svg", visible: :all).size, "the row action needs its leading icon"
    assert_no_selector "tbody a.tw-btn-primary"
  end

  test "the trading floor card does not link to the page it is on" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 100_000)
    sign_in(student)

    visit stocks_path

    # A primary CTA whose href is the current page does nothing.
    assert_no_link "Invest now"
  end

  test "admin pages have at most one primary" do
    school = create(:school)
    school_year = create(:school_year, school:, year: create(:year))
    classroom = create(:classroom, :with_trading, school_year:)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 100_000)
    sign_in(create(:admin))

    {
      "dashboard" => admin_root_path,
      "users" => admin_users_path,
      "student edit" => edit_admin_student_path(student),
      "student show" => admin_student_path(student),
      "classroom show" => admin_classroom_path(classroom),
      "school_year show" => admin_school_year_path(school_year)
    }.each { |label, path| assert_one_primary(label, path) }
  end
end
