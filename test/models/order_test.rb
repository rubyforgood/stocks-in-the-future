require "test_helper"

class OrderTest < ActiveSupport::TestCase
  setup do
    @student = users(:one)
  end

  test "can create order" do
    order = Order.new
    order.user = Student.first
    order.stock = Stock.first
    order.shares = 5
    order.status = :pending

    assert order.save
  end

  test "can filter orders by pending status" do
    pending_orders = [Order.create(stock: Stock.first, shares: 5, status: :pending, user: @student)]
    Order.create(stock: Stock.first, shares: 5, status: :completed, user: @student)

    assert_equal pending_orders, Order.pending
  end

  test "calculates purchase cost" do
    stock = Stock.create(ticker: "EVG", price: 10.00)
    order = Order.create(stock: stock, shares: 5, status: :completed, user: @student)
    assert_equal 50, order.purchase_cost
  end
end
