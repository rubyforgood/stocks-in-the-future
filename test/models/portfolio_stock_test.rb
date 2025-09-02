# frozen_string_literal: true

require "test_helper"

class PortfolioStockTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:portfolio_stock).validate!
  end

  test "aggregated_positions scope groups by stock and sums shares" do
    portfolio = create(:portfolio)
    stock1 = create(:stock, ticker: "AAPL")
    stock2 = create(:stock, ticker: "GOOGL")

    create(:portfolio_stock, portfolio: portfolio, stock: stock1, shares: 10, purchase_price: 100.0)
    create(:portfolio_stock, portfolio: portfolio, stock: stock1, shares: 5, purchase_price: 200.0)
    create(:portfolio_stock, portfolio: portfolio, stock: stock1, shares: 3, purchase_price: 300.0)

    create(:portfolio_stock, portfolio: portfolio, stock: stock2, shares: 20, purchase_price: 150.0)

    results = portfolio.portfolio_stocks.aggregated_positions

    assert_equal 2, results.length

    aapl_result = results.find { |r| r.stock_id == stock1.id }
    googl_result = results.find { |r| r.stock_id == stock2.id }

    assert_equal 18, aapl_result.total_shares
    assert_equal 20, googl_result.total_shares
  end

  test "aggregated_positions scope excludes positions with zero shares" do
    portfolio = create(:portfolio)
    stock = create(:stock)

    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 10, purchase_price: 100.0)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: -10, purchase_price: 120.0)

    results = portfolio.portfolio_stocks.aggregated_positions

    assert_equal 0, results.length
  end

  test "aggregated_positions scope calculates weighted average purchase price correctly" do
    portfolio = create(:portfolio)
    stock = create(:stock)

    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 10, purchase_price: 100.0)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 5, purchase_price: 200.0)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 5, purchase_price: 300.0)

    result = portfolio.portfolio_stocks.aggregated_positions.first

    assert_equal 20, result.total_shares
    assert_equal 175.0, result.avg_price.to_f
  end

  test "aggregated_positions scope orders by ticker" do
    portfolio = create(:portfolio)
    stock_z = create(:stock, ticker: "ZZZ")
    stock_a = create(:stock, ticker: "AAA")

    create(:portfolio_stock, portfolio: portfolio, stock: stock_z, shares: 10, purchase_price: 100.0)
    create(:portfolio_stock, portfolio: portfolio, stock: stock_a, shares: 5, purchase_price: 200.0)

    results = portfolio.portfolio_stocks.aggregated_positions

    assert_equal stock_a.id, results.first.stock_id
    assert_equal stock_z.id, results.last.stock_id
  end
end
