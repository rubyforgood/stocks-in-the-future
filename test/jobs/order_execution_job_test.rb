# frozen_string_literal: true

require "test_helper"

class OrderExecutionJobTest < ActiveJob::TestCase
  test "with pending orders" do
    portfolio1 = create(:portfolio)
    student1 = create(:student, portfolio: portfolio1)
    create(
      :portfolio_transaction,
      :deposit,
      portfolio: portfolio1,
      amount_cents: 10_000
    )
    portfolio2 = create(:portfolio)
    student2 = create(:student, portfolio: portfolio2)
    create(
      :portfolio_transaction,
      :deposit,
      portfolio: portfolio2,
      amount_cents: 10_000
    )
    stock = create(:stock, price_cents: 1_000)
    order1 = create(:order, :pending, :buy, user: student1, stock:, shares: 1)
    order2 = create(:order, :pending, :buy, user: student2, stock:, shares: 2)

    ExecuteOrder.expects(:execute).with(order1).once
    ExecuteOrder.expects(:execute).with(order2).once
    TransactionFeeProcessor.expects(:execute).once
    StockPricesUpdateJob.expects(:perform_later).once

    OrderExecutionJob.perform_now
  end

  test "with no pending orders" do
    ExecuteOrder.expects(:execute).never
    TransactionFeeProcessor.expects(:execute).never
    StockPricesUpdateJob.expects(:perform_later).once

    OrderExecutionJob.perform_now
  end

  test "when an error occurs" do
    portfolio = create(:portfolio)
    student = create(:student, portfolio:)
    create(:portfolio_transaction, :deposit, portfolio:, amount_cents: 10_000)
    stock = create(:stock, price_cents: 1_000)
    create(:order, :pending, :buy, user: student, stock:, shares: 1)
    ExecuteOrder.stubs(:execute).raises(StandardError.new("Test error"))

    assert_raises(StandardError) do
      OrderExecutionJob.perform_now
    end
  end
end
