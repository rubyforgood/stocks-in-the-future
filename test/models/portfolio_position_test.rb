# frozen_string_literal: true

require "test_helper"

class PortfolioPositionTest < ActiveSupport::TestCase
  test "works with stock object" do
    portfolio = create(:portfolio)
    stock = create(:stock, ticker: "AAPL", company_name: "Apple Inc.", price_cents: 15_000)

    position = PortfolioPosition.new(portfolio: portfolio, stock: stock)

    assert_equal stock.id, position.stock_id
    assert_equal "AAPL", position.stock_ticker
    assert_equal "Apple Inc.", position.stock_company_name
  end

  test "works with stock id" do
    portfolio = create(:portfolio)
    stock = create(:stock, ticker: "AAPL", company_name: "Apple Inc.", price_cents: 15_000)

    position = PortfolioPosition.new(portfolio: portfolio, stock: stock.id)

    assert_equal stock.id, position.stock_id
    assert_equal "AAPL", position.stock_ticker
    assert_equal "Apple Inc.", position.stock_company_name
  end

  test "works with precomputed values" do
    portfolio = create(:portfolio)
    stock = create(:stock)

    position = PortfolioPosition.new(
      portfolio: portfolio,
      stock: stock,
      total_shares: 15,
      avg_purchase_price: 200.0
    )

    assert_equal 15, position.total_shares
    assert_equal 200.0, position.avg_purchase_price
  end

  test "total_shares with single purchase" do
    portfolio = create(:portfolio)
    stock = create(:stock)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 15, purchase_price: 200.0)

    position = PortfolioPosition.new(portfolio: portfolio, stock: stock)

    assert_equal 15, position.total_shares
  end

  test "total_shares with multiple purchases aggregates correctly" do
    portfolio = create(:portfolio)
    stock = create(:stock)

    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 10, purchase_price: 200.0)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 5, purchase_price: 250.0)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 3, purchase_price: 300.0)

    position = PortfolioPosition.new(portfolio: portfolio, stock: stock)

    assert_equal 18, position.total_shares
  end

  test "total_shares with buy and sell orders" do
    portfolio = create(:portfolio)
    stock = create(:stock)

    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 20, purchase_price: 200.0)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: -7, purchase_price: 250.0)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 3, purchase_price: 300.0)

    position = PortfolioPosition.new(portfolio: portfolio, stock: stock)

    assert_equal 16, position.total_shares
  end

  test "total_shares returns 0 when no shares owned" do
    portfolio = create(:portfolio)
    stock = create(:stock)

    position = PortfolioPosition.new(portfolio: portfolio, stock: stock)

    assert_equal 0, position.total_shares
  end

  test "avg_purchase_price calculation" do
    portfolio = create(:portfolio)
    stock = create(:stock)

    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 10, purchase_price: 200.0)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 5, purchase_price: 250.0)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 3, purchase_price: 300.0)

    position = PortfolioPosition.new(portfolio: portfolio, stock: stock)

    assert_equal 250.0, position.avg_purchase_price.to_f
  end

  test "to_s string representation" do
    portfolio = create(:portfolio)
    stock = create(:stock, ticker: "AAPL", company_name: "Apple Inc.")
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 15, purchase_price: 200.0)

    position = PortfolioPosition.new(portfolio: portfolio, stock: stock)

    assert_equal "Apple Inc. (AAPL): 15.0 shares", position.to_s
  end
end
