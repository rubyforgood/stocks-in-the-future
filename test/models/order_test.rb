require "test_helper"

class OrderTest < ActiveSupport::TestCase
  test "can create order" do
    order = Order.new
    order.user = Student.first
    order.stock = Stock.first
    order.shares = 5
    order.status = :pending

    assert order.save
  end

  test "can filter orders by pending status" do
    student = Student.first
    pending_orders = [Order.create(stock: Stock.first, shares: 5, status: :pending, user: student)]
    Order.create(stock: Stock.first, shares: 5, status: :completed, user: student)

    assert_equal pending_orders, Order.pending
  end
end
