# frozen_string_literal: true

require "test_helper"

class PortfolioStockTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:portfolio_stock).validate!
  end

  test "#change_amount returns profit/loss from purchase price" do
    stock = create(:stock, price_cents: 15000) # $150 current price
    portfolio_stock = create(:portfolio_stock,
                            stock: stock,
                            shares: 10,
                            purchase_price: 100.0) # bought at $100

    # Should be (150 - 100) * 10 = $500 profit
    expected_change = 500.0
    assert_equal expected_change, portfolio_stock.change_amount
  end

  test "#change_amount returns negative for losses" do
    stock = create(:stock, price_cents: 8000) # $80 current price
    portfolio_stock = create(:portfolio_stock,
                            stock: stock,
                            shares: 5,
                            purchase_price: 120.0) # bought at $120

    # Should be (80 - 120) * 5 = -$200 loss
    expected_change = -200.0
    assert_equal expected_change, portfolio_stock.change_amount
  end

  test "#total_return_amount returns current market value" do
    stock = create(:stock, price_cents: 12500) # $125 current price
    portfolio_stock = create(:portfolio_stock,
                            stock: stock,
                            shares: 8,
                            purchase_price: 100.0) # purchase price irrelevant

    # Should be 125 * 8 = $1000
    expected_total_return = 1000.0
    assert_equal expected_total_return, portfolio_stock.total_return_amount
  end

  test "#change_amount handles fractional shares" do
    stock = create(:stock, price_cents: 10050) # $100.50 current price
    portfolio_stock = create(:portfolio_stock,
                            stock: stock,
                            shares: 2.5,
                            purchase_price: 100.0) # bought at $100

    # Should be (100.50 - 100) * 2.5 = $1.25 profit
    expected_change = 1.25
    assert_equal expected_change, portfolio_stock.change_amount
  end

  test "#total_return_amount handles fractional shares" do
    stock = create(:stock, price_cents: 10050) # $100.50 current price
    portfolio_stock = create(:portfolio_stock,
                            stock: stock,
                            shares: 2.5,
                            purchase_price: 80.0) # purchase price irrelevant

    # Should be 100.50 * 2.5 = $251.25
    expected_total_return = 251.25
    assert_equal expected_total_return, portfolio_stock.total_return_amount
  end
end