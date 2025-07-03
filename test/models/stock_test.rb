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
end
