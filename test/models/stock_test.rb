# frozen_string_literal: true

require "test_helper"

class StockTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:stock).validate!
  end

  test "#current_price" do
    stock = create(:stock, price_cents: 1_000)

    result = stock.current_price

    assert_equal 10.0, result
  end

  test "archived defaults to false" do
    stock = create(:stock)

    assert_equal false, stock.archived
  end

  test "active and archived scopes filter correctly" do
    active_stock = create(:stock, archived: false)
    archived_stock = create(:stock, archived: true)

    active_stocks = Stock.active
    archived_stocks = Stock.archived

    assert_includes active_stocks, active_stock
    assert_not_includes active_stocks, archived_stock
    assert_includes archived_stocks, archived_stock
    assert_not_includes archived_stocks, active_stock
  end
end
