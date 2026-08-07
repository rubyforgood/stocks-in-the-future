# frozen_string_literal: true

require "test_helper"

module Admin
  class DashboardControllerTest < ActionDispatch::IntegrationTest
    test "admin can access admin dashboard" do
      admin = create(:admin, admin: true)
      sign_in(admin)

      get admin_root_path

      assert_response :success
      assert_select "h1", "Admin dashboard"
    end

    test "non-admin cannot access admin dashboard" do
      teacher = create(:teacher)
      sign_in(teacher)

      get admin_root_path

      assert_redirected_to root_path
      assert_equal "Access denied. Admin privileges required.", flash[:alert]
    end

    test "unauthenticated user redirected to sign in" do
      get admin_root_path

      assert_redirected_to new_user_session_path
    end

    # The dashboard used to be a second copy of the sidebar. These assert it now reports the two
    # figures an admin can act on, and that every row it shows links somewhere - a row you can
    # see but cannot act on was the substance of the complaint.
    test "reports pending orders and grade books awaiting payout" do
      classroom = create(:classroom, :with_trading)
      student = create(:student, :with_portfolio, classroom: classroom)
      stock = create(:stock)
      # A buy is validated against the balance, so the portfolio needs funding first.
      student.portfolio.portfolio_transactions.create!(
        amount_cents: 50_000, transaction_type: :deposit,
        reason: :math_earnings
      )
      create(:order, user: student, stock: stock, action: :buy, shares: 1, status: :pending)
      classroom.grade_books.first.update!(status: :verified)
      sign_in(create(:admin))

      get admin_root_path

      assert_response :success
      assert_select "[data-testid='pending-orders']", text: /1/
      assert_select "[data-testid='grade-books-awaiting']", text: /1/
    end

    test "sums only deposits into the distributed figure" do
      student = create(:student, :with_portfolio)
      student.portfolio.portfolio_transactions.create!(
        amount_cents: 500, transaction_type: :deposit,
        reason: :math_earnings
      )
      student.portfolio.portfolio_transactions.create!(
        amount_cents: 100, transaction_type: :fee,
        reason: :transaction_fees
      )
      sign_in(create(:admin))

      get admin_root_path

      # $5.00 in, and the fee is money leaving - summing both would report a meaningless figure.
      assert_select "[data-testid='total-distributed']", text: /\$5\.00/
    end

    test "every listed transaction links to its own page" do
      student = create(:student, :with_portfolio, username: "finn")
      transaction = student.portfolio.portfolio_transactions.create!(
        amount_cents: 250, transaction_type: :deposit, reason: :attendance_earnings
      )
      sign_in(create(:admin))

      get admin_root_path

      assert_select "a[href=?]", admin_portfolio_transaction_path(transaction), text: "finn"
      assert_select "a[href=?]", admin_portfolio_transactions_path, text: "View all"
    end

    test "no longer duplicates the sidebar as a link directory" do
      sign_in(create(:admin))

      get admin_root_path

      # Scoped to main: the sidebar links to Schools legitimately, and it is the dashboard
      # duplicating those links that was the problem. It also carried a banner about links
      # marked "#" that no longer existed.
      assert_select "main a[href=?]", admin_schools_path, count: 0
      assert_no_match(/Development status/, response.body)
    end
  end
end
