# frozen_string_literal: true

require "test_helper"

class PortfolioStockTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:portfolio_stock).validate!
  end

  test "#change_amount returns profit/loss from purchase price" do
    stock = create(:stock, price_cents: 15_000)
    portfolio_stock = create(:portfolio_stock,
                             stock: stock,
                             shares: 10,
                             purchase_price: 100.0)

    expected_change = 500.0
    assert_equal expected_change, portfolio_stock.change_amount
  end

  test "#change_amount returns negative for losses" do
    stock = create(:stock, price_cents: 8000)
    portfolio_stock = create(:portfolio_stock,
                             stock: stock,
                             shares: 5,
                             purchase_price: 120.0)

    expected_change = -200.0
    assert_equal expected_change, portfolio_stock.change_amount
  end

  test "#total_return_amount returns current market value" do
    stock = create(:stock, price_cents: 12_500)
    portfolio_stock = create(:portfolio_stock,
                             stock: stock,
                             shares: 8,
                             purchase_price: 100.0)

    expected_total_return = 1000.0
    assert_equal expected_total_return, portfolio_stock.total_return_amount
  end

  test "#change_amount handles zero current price" do
    stock = create(:stock, price_cents: 0)
    portfolio_stock = create(:portfolio_stock,
                             stock: stock,
                             shares: 10,
                             purchase_price: 50.0)

    expected_change = -500.0
    assert_equal expected_change, portfolio_stock.change_amount
  end

  test "#total_return_amount handles zero current price" do
    stock = create(:stock, price_cents: 0)
    portfolio_stock = create(:portfolio_stock,
                             stock: stock,
                             shares: 10,
                             purchase_price: 50.0)

    expected_total_return = 0.0
    assert_equal expected_total_return, portfolio_stock.total_return_amount
  end
end
