# frozen_string_literal: true

require "test_helper"

class PortfolioPositionTest < ActiveSupport::TestCase
  test "current_value and current_value_cents calculation" do
    stock = create(:stock, price_cents: 12_000)
    position = PortfolioPosition.new(stock: stock, shares: 8)

    assert_equal 960.0, position.current_value
    assert_equal 96_000, position.current_value_cents
  end

  test "stock_previous_close returns yesterday_price when available" do
    stock = create(:stock, price_cents: 15_000, yesterday_price_cents: 14_500)
    position = PortfolioPosition.new(stock: stock, shares: 5)

    assert_equal 145.0, position.stock_previous_close
  end

  test "stock_previous_close falls back to current_price when yesterday_price is nil" do
    stock = create(:stock, price_cents: 15_000, yesterday_price_cents: nil)
    position = PortfolioPosition.new(stock: stock, shares: 5)

    assert_equal 150.0, position.stock_previous_close
  end

  test "for_portfolio aggregates buy/sell transactions correctly" do
    portfolio = create(:portfolio)
    stock = create(:stock, ticker: "AAPL")

    # Multiple buy/sell transactions: 10 + 5 - 3 = 12 shares
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 10)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 5)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: -3)

    positions = PortfolioPosition.for_portfolio(portfolio)

    assert_equal 1, positions.length
    position = positions.first
    assert_equal 12, position.shares
    assert_equal stock, position.stock
  end

  test "for_portfolio excludes stocks with zero net holdings" do
    portfolio = create(:portfolio)
    stock1 = create(:stock, ticker: "ZERO")
    stock2 = create(:stock, ticker: "POSITIVE")

    # Stock with zero net holdings
    create(:portfolio_stock, portfolio: portfolio, stock: stock1, shares: 10)
    create(:portfolio_stock, portfolio: portfolio, stock: stock1, shares: -10)

    # Stock with positive holdings
    create(:portfolio_stock, portfolio: portfolio, stock: stock2, shares: 5)

    positions = PortfolioPosition.for_portfolio(portfolio)

    assert_equal 1, positions.length
    assert_equal "POSITIVE", positions.first.stock_ticker
    assert_equal 5, positions.first.shares
  end

  test "for_portfolio returns empty array when no positive holdings" do
    portfolio = create(:portfolio)
    stock = create(:stock)

    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 10)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: -10)

    positions = PortfolioPosition.for_portfolio(portfolio)

    assert_empty positions
  end

  test "for_portfolio handles complex trading scenarios" do
    portfolio = create(:portfolio)
    stock = create(:stock, ticker: "TSLA")

    # Buy 100, buy 50, sell 30, buy 25, sell 20 = 125 net
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 100)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 50)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: -30)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 25)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: -20)

    positions = PortfolioPosition.for_portfolio(portfolio)

    assert_equal 1, positions.length
    assert_equal 125, positions.first.shares
  end
end
