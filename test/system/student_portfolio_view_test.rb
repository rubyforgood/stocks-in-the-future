# frozen_string_literal: true

require "application_system_test_case"

class StudentPortfolioViewTest < ApplicationSystemTestCase
  test "student views portfolio with cash and stock holdings" do
    classroom = create(:classroom)
    student = create(:student, :with_portfolio, classroom: classroom)
    student.reload
    portfolio = student.portfolio

    # Give student some cash
    create(:portfolio_transaction, :deposit, portfolio: portfolio, amount_cents: 100_000)

    # Give student some stocks
    stock_aapl = create(:stock, ticker: "AAPL", company_name: "Apple Inc.", price_cents: 15_000)
    stock_googl = create(:stock, ticker: "GOOGL", company_name: "Google LLC", price_cents: 20_000)
    create(:portfolio_stock, portfolio: portfolio, stock: stock_aapl, shares: 5)
    create(:portfolio_stock, portfolio: portfolio, stock: stock_googl, shares: 3)

    sign_in(student)
    visit portfolio_path(portfolio)

    # Verify page heading
    assert_text "PORTFOLIO"
    assert_text student.username.upcase

    # Verify cash balance is displayed
    within "[data-testid='cash-balance']" do
      assert_text "$1,000.00"
    end

    # Verify stock holdings are displayed
    within "[data-testid='holdings-table']" do
      # AAPL holdings
      assert_text "AAPL"
      assert_text "5"
      assert_text "$150.00"

      # GOOGL holdings
      assert_text "GOOGL"
      assert_text "3"
      assert_text "$200.00"
    end

    # Verify total stocks count
    within "[data-testid='total-stocks']" do
      assert_text "8"
    end

    sign_out(student)
  end

  test "student views portfolio with only cash (no stocks)" do
    classroom = create(:classroom)
    student = create(:student, :with_portfolio, classroom: classroom)
    student.reload
    portfolio = student.portfolio

    # Give student cash but no stocks
    create(:portfolio_transaction, :deposit, portfolio: portfolio, amount_cents: 50_000)

    sign_in(student)
    visit portfolio_path(portfolio)

    # Verify page heading
    assert_text "PORTFOLIO"

    # Verify cash balance is displayed
    within "[data-testid='cash-balance']" do
      assert_text "$500.00"
    end

    # Verify no stock holdings
    # The view may show an empty table but no "Trade" buttons
    within "[data-testid='holdings-table']" do
      # Table should be empty (no holdings rows with Trade buttons)
      assert_no_text "Trade"
    end

    # Total stocks should be 0
    within "[data-testid='total-stocks']" do
      assert_text "0"
    end

    sign_out(student)
  end

  test "student views portfolio with no cash (only stocks)" do
    classroom = create(:classroom)
    student = create(:student, :with_portfolio, classroom: classroom)
    student.reload
    portfolio = student.portfolio

    # Give student stocks but no cash (portfolio starts with $0)
    stock_tsla = create(:stock, ticker: "TSLA", company_name: "Tesla Inc.", price_cents: 25_000)
    create(:portfolio_stock, portfolio: portfolio, stock: stock_tsla, shares: 4)

    sign_in(student)
    visit portfolio_path(portfolio)

    # Verify page heading
    assert_text "PORTFOLIO"

    # Verify cash balance is $0
    within "[data-testid='cash-balance']" do
      assert_text "$0.00"
    end

    # Verify stock holdings are displayed
    within "[data-testid='holdings-table']" do
      assert_text "TSLA"
      assert_text "4"
      assert_text "$250.00"
    end

    # Verify total stocks count
    within "[data-testid='total-stocks']" do
      assert_text "4"
    end

    sign_out(student)
  end

  test "student views empty portfolio (new account)" do
    classroom = create(:classroom)
    student = create(:student, :with_portfolio, classroom: classroom)
    student.reload
    portfolio = student.portfolio

    # Portfolio was just created with no transactions or stocks
    sign_in(student)
    visit portfolio_path(portfolio)

    # Verify page heading
    assert_text "PORTFOLIO"

    # Verify cash balance is $0
    within "[data-testid='cash-balance']" do
      assert_text "$0.00"
    end

    # Verify no stock holdings
    within "[data-testid='holdings-table']" do
      assert_no_text "Trade"
    end

    # Total stocks should be 0
    within "[data-testid='total-stocks']" do
      assert_text "0"
    end

    sign_out(student)
  end

  test "portfolio reflects real-time stock prices" do
    classroom = create(:classroom)
    student = create(:student, :with_portfolio, classroom: classroom)
    student.reload
    portfolio = student.portfolio

    # Create stock with initial price
    stock = create(:stock, ticker: "NFLX", company_name: "Netflix", price_cents: 30_000)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 2)

    sign_in(student)
    visit portfolio_path(portfolio)

    # Verify initial price is displayed
    within "[data-testid='holdings-table']" do
      assert_text "$300.00" # Last Price column
    end

    # Update stock price in database (simulating price update)
    stock.update!(price_cents: 35_000)

    # Refresh page to see updated price
    visit portfolio_path(portfolio)

    # Verify updated price is displayed
    within "[data-testid='holdings-table']" do
      assert_text "$350.00" # Updated Last Price
    end

    sign_out(student)
  end

  test "student cannot view another student's portfolio" do
    classroom = create(:classroom)
    student_a = create(:student, :with_portfolio, classroom: classroom)
    student_b = create(:student, :with_portfolio, classroom: classroom)
    student_a.reload
    student_b.reload
    portfolio_b = student_b.portfolio

    # Give student B some cash and stocks
    create(:portfolio_transaction, :deposit, portfolio: portfolio_b, amount_cents: 20_000)
    stock = create(:stock, ticker: "AMZN", company_name: "Amazon", price_cents: 40_000)
    create(:portfolio_stock, portfolio: portfolio_b, stock: stock, shares: 1)

    # Student A attempts to access Student B's portfolio
    sign_in(student_a)

    # Attempt to visit Student B's portfolio URL directly
    visit portfolio_path(portfolio_b)

    # Should be denied access (Pundit policy blocks) and redirected to own portfolio
    # Verify Student A is viewing their own portfolio (not Student B's)
    assert_text student_a.username.upcase

    # Verify this is NOT Student B's portfolio by checking stock count
    # Student B has 1 share of AMZN, Student A has 0
    within "[data-testid='total-stocks']" do
      assert_text "0"
    end

    # Verify Student B's stock is NOT shown
    within "[data-testid='holdings-table']" do
      assert_no_text "AMZN"
    end

    sign_out(student_a)
  end
end
