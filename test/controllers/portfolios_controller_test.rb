# frozen_string_literal: true

require "test_helper"

class PortfoliosControllerTest < ActionDispatch::IntegrationTest
  test "show empty state portfolio" do
    portfolio = create(:portfolio)

    sign_in(portfolio.user)

    get portfolio_path(portfolio)

    assert_response :success
  end

  test "show portfolio with stock" do
    portfolio = create(:portfolio)
    stock = create(:stock, ticker: "AAPL", company_name: "Apple Inc.")
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 10, purchase_price: 200.0)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 5, purchase_price: 250.0)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 3, purchase_price: 300.0)

    sign_in(portfolio.user)

    get portfolio_path(portfolio)

    assert_response :success
  end
end
