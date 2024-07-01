require "test_helper"
require "minitest/mock"

class StockPurchaseJobTest < ActiveJob::TestCase
  test "it processes pending orders" do
    pending_order1 = Order.create!(user: users(:one), stock: stocks(:one), status: "pending", shares: 5)
    pending_order2 = Order.create!(user: users(:one), stock: stocks(:one), status: "pending", shares: 15)
    canceled_order = Order.create!(user: users(:one), stock: stocks(:one), status: "canceled", shares: 15)

    StockPurchaseJob.perform_now

    pending_order1.reload
    pending_order2.reload
    canceled_order.reload

    assert_equal "completed", pending_order1.status
    assert_equal "completed", pending_order2.status
    assert_equal "canceled", canceled_order.status
  end
end
