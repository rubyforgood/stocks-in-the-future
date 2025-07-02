# frozen_string_literal: true

require "test_helper"

class OrderTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:order).validate!
  end

  test ".pending" do
    order1 = create(:order, :pending)
    create(:order, :completed)
    create(:order, :canceled)
    order4 = create(:order, :pending)

    assert_equal [order1, order4], Order.pending
  end

  test ".completed" do
    order1 = create(:order, :completed)
    create(:order, :pending)
    create(:order, :canceled)
    order4 = create(:order, :completed)

    assert_equal [order1, order4], Order.completed
  end

  test ".canceled" do
    order1 = create(:order, :canceled)
    create(:order, :pending)
    create(:order, :completed)
    order4 = create(:order, :canceled)

    assert_equal [order1, order4], Order.canceled
  end

  test "#purchase_cost" do
    stock = create(:stock, price_cents: 1_000)
    order = create(:order, stock:, shares: 5.1)

    result = order.purchase_cost

    assert_equal 5_100, result
  end
end
