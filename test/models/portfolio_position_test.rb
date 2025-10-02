# frozen_string_literal: true

require "test_helper"

class PortfolioPositionTest < ActiveSupport::TestCase
  test "current_value and current_value_cents calculation" do
    portfolio = create(:portfolio)
    stock = create(:stock, price_cents: 12_000)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 8, purchase_price: 100.0)

    position = PortfolioPosition.for_portfolio(portfolio).first

    assert_equal 960.0, position.current_value
    assert_equal 96_000, position.current_value_cents
  end

  test "for_portfolio aggregates buy/sell transactions correctly" do
    portfolio = create(:portfolio)
    stock = create(:stock, ticker: "AAPL")

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

    create(:portfolio_stock, portfolio: portfolio, stock: stock1, shares: 10)
    create(:portfolio_stock, portfolio: portfolio, stock: stock1, shares: -10)

    create(:portfolio_stock, portfolio: portfolio, stock: stock2, shares: 5)

    positions = PortfolioPosition.for_portfolio(portfolio)

    assert_equal 1, positions.length
    assert_equal "POSITIVE", positions.first.stock_ticker
    assert_equal 5, positions.first.shares
  end

  test "change_amount with multiple purchases and sells" do
    portfolio = create(:portfolio)
    stock = create(:stock, price_cents: 15_000)

    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 10, purchase_price: 100.0)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 5, purchase_price: 120.0)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: -3, purchase_price: 130.0)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 8, purchase_price: 140.0)

    positions = PortfolioPosition.for_portfolio(portfolio)
    position = positions.first

    cost_basis = (100.0 * 10) + (120.0 * 5) + (-3 * 130.0) + (140.0 * 8)
    expected_change = (150.0 * 20) - cost_basis
    assert_equal expected_change, position.change_amount
  end

  test "change_amount calculates profit correctly" do
    portfolio = create(:portfolio)
    stock = create(:stock, price_cents: 700)

    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 4, purchase_price: 5.0)

    position = PortfolioPosition.for_portfolio(portfolio).first

    assert_equal 4, position.shares
    assert_in_delta 8.0, position.change_amount, 0.001
  end

  test "change_amount calculates loss correctly" do
    portfolio = create(:portfolio)
    stock = create(:stock, price_cents: 100)

    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 2, purchase_price: 5.0)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 3, purchase_price: 7.0)

    position = PortfolioPosition.for_portfolio(portfolio).first

    assert_equal 5, position.shares
    assert_in_delta(-26.0, position.change_amount, 0.001)
  end

  test "total_return_amount with multiple purchases and sells" do
    portfolio = create(:portfolio)
    stock = create(:stock, price_cents: 15_000)

    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 10, purchase_price: 100.0)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 5, purchase_price: 120.0)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: -3, purchase_price: 130.0)

    positions = PortfolioPosition.for_portfolio(portfolio)
    position = positions.first

    expected_value = 150.0 * 12
    assert_equal expected_value, position.total_return_amount
  end
end
