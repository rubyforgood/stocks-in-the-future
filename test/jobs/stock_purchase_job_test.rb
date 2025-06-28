# frozen_string_literal: true

require "test_helper"

class StockPurchaseJobTest < ActiveJob::TestCase
  test "it calls the related service" do
    order1 = create(:order, :pending)
    order2 = create(:order, :pending)
    order3 = create(:order, :completed)

    PurchaseStock.expects(:execute).with(order1)
    PurchaseStock.expects(:execute).with(order2)
    PurchaseStock.expects(:execute).with(order3).never

    StockPurchaseJob.perform_now
  end
end
