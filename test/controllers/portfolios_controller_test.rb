# frozen_string_literal: true

require "test_helper"

class PortfoliosControllerTest < ActionDispatch::IntegrationTest
  test "show with empty portfolio" do
    portfolio = create(:portfolio)
    sign_in(portfolio.user)

    get portfolio_path(portfolio)

    assert_response :success
  end

  test "show with portfolio positions renders" do
    portfolio = create(:portfolio)
    stock = create(:stock, price_cents: 15_000, yesterday_price_cents: 14_500)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 10)

    sign_in(portfolio.user)

    get portfolio_path(portfolio)

    assert_response :success
  end

  test "trade button links to trading floor" do
    portfolio = create(:portfolio)
    stock = create(:stock)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 5)

    sign_in(portfolio.user)

    get portfolio_path(portfolio)

    assert_response :success
    assert_select "a[href='#{stocks_path}']", text: "Trade"
  end

  test "show displays empty state when less than 2 snapshots" do
    portfolio = create(:portfolio)
    create(:portfolio_snapshot, portfolio: portfolio, date: Date.current, worth_cents: 10_000)

    sign_in(portfolio.user)

    get portfolio_path(portfolio)

    assert_response :success
    assert_select ".text-gray-600", text: "Not Enough Data"
  end

  test "show displays chart when 2 or more snapshots exist" do
    portfolio = create(:portfolio)
    create(:portfolio_snapshot, portfolio: portfolio, date: 1.month.ago.to_date, worth_cents: 10_000)
    create(:portfolio_snapshot, portfolio: portfolio, date: Date.current, worth_cents: 15_000)

    sign_in(portfolio.user)

    get portfolio_path(portfolio)

    assert_response :success
    assert_select "canvas[data-controller='portfolio-chart']"
  end
end
