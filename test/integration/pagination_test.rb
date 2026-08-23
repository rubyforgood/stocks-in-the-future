# frozen_string_literal: true

require "test_helper"

# Pagination, and the two things design.md says to check when it is switched on.
#
# It had never rendered. The partial has existed since the admin was built and `admin/shared/_table`
# renders it, guarded on `collection.total_pages > 1` - which nothing could satisfy, because **Kaminari
# was not installed**. So the component in the design system was a component that could not work, and
# "nothing paginates" was recorded as a choice rather than as the consequence.
#
# Measured before turning it on, at 1366x768: 300 admin transactions render 15,534px, **24.9 screens**,
# and 58,190px at 375px where the rows stack. The collection has no upper bound - an executed order writes
# a purchase row and a fee row, and finalizing a grade book writes a deposit per student per earnings
# reason per quarter.
class PaginationTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:admin)
    @classroom = create(:classroom, :with_trading)
    @student = create(:student, :with_portfolio, classroom: @classroom)
    @student.reload
    sign_in @admin
  end

  def make_transactions(count, portfolio: @student.portfolio)
    count.times { |i| create(:portfolio_transaction, :deposit, portfolio:, amount_cents: 1_000 + i) }
  end

  test "a collection that fits on one page renders no pagination" do
    make_transactions(ApplicationController::PER_PAGE)

    get admin_portfolio_transactions_path

    assert_response :success
    assert_select "nav[aria-label=?]", "Pagination", count: 0
    assert_select "tbody tr", count: ApplicationController::PER_PAGE
  end

  test "a longer collection paginates, and the last page holds the remainder" do
    make_transactions(ApplicationController::PER_PAGE + 5)

    get admin_portfolio_transactions_path

    assert_response :success
    assert_select "nav[aria-label=?]", "Pagination"
    assert_select "tbody tr", count: ApplicationController::PER_PAGE

    get admin_portfolio_transactions_path(page: 2)

    assert_response :success
    assert_select "tbody tr", count: 5
  end

  # **The thing design.md names.** `sort_link` and the filter both carry query parameters, and a bare
  # `page=2` would drop them - the reader would sort a column, turn the page, and silently get the default
  # order back.
  test "the sort parameters survive the page" do
    make_transactions(ApplicationController::PER_PAGE + 5)

    get admin_portfolio_transactions_path(sort: "amount_cents", direction: "desc")

    assert_response :success
    next_link = css_select("nav[aria-label='Pagination'] a[rel='next']").first

    assert next_link, "no next link on the first page"
    assert_includes next_link["href"], "sort=amount_cents"
    assert_includes next_link["href"], "direction=desc"
    assert_includes next_link["href"], "page=2"
  end

  test "the user filter survives the page" do
    make_transactions(ApplicationController::PER_PAGE + 5)
    other = create(:student, :with_portfolio, classroom: @classroom)
    other.reload
    make_transactions(3, portfolio: other.portfolio)

    get admin_portfolio_transactions_path(user_id: @student.id)

    assert_response :success
    next_link = css_select("nav[aria-label='Pagination'] a[rel='next']").first

    assert next_link, "no next link on the filtered first page"
    assert_includes next_link["href"], "user_id=#{@student.id}"

    get admin_portfolio_transactions_path(user_id: @student.id, page: 2)

    assert_response :success
    # 30 for this student, 25 on page 1 - the other student's 3 are not mixed in.
    assert_select "tbody tr", count: 5
  end

  # Present but not pressable, rather than absent: omitting the unavailable direction moves the other
  # button sideways between page 1 and page 2.
  test "the unavailable direction is disabled rather than removed" do
    make_transactions(ApplicationController::PER_PAGE + 5)

    get admin_portfolio_transactions_path

    assert_select "nav[aria-label='Pagination'] span.tw-btn-disabled[aria-disabled=?]", "true", text: "Previous"
    assert_select "nav[aria-label='Pagination'] a[rel=?]", "next", text: "Next"

    get admin_portfolio_transactions_path(page: 2)

    assert_select "nav[aria-label='Pagination'] a[rel=?]", "prev", text: "Previous"
    assert_select "nav[aria-label='Pagination'] span.tw-btn-disabled[aria-disabled=?]", "true", text: "Next"
  end

  # The design system's own classes, not the four hand-written strings the partial carried while nothing
  # rendered it - `rounded-md`, no `min-h-10`, `border-slate-300` and `text-slate-400`.
  test "the controls use the button tokens" do
    make_transactions(ApplicationController::PER_PAGE + 5)

    get admin_portfolio_transactions_path

    assert_select "nav[aria-label='Pagination'] a.tw-btn-secondary", count: 1
    assert_select "nav[aria-label='Pagination'] [class*=rounded-md]", count: 0
    assert_select "nav[aria-label='Pagination'] [class*=text-slate-400]", count: 0
  end

  test "the app side Transactions page paginates too" do
    stock = create(:stock, price_cents: 100)
    create(:portfolio_transaction, :deposit, portfolio: @student.portfolio, amount_cents: 5_000_000)
    (ApplicationController::PER_PAGE + 2).times do
      create(:order, user: @student, stock:, shares: 1, status: :pending, action: :buy)
    end

    sign_in @student
    get orders_path

    assert_response :success
    assert_select "nav[aria-label=?]", "Pagination"
    assert_select "tbody tr", count: ApplicationController::PER_PAGE

    get orders_path(page: 2)

    assert_select "tbody tr", count: 2
  end
end
