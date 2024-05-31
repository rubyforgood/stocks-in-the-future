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
end
