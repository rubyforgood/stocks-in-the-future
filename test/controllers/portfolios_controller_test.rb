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

    assert_select "a[href='#{stocks_path}']", text: "Trade"
  end
end
