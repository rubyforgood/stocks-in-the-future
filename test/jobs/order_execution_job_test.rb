# frozen_string_literal: true

require "test_helper"

class OrderExecutionJobTestlist < ActiveJob::TestCase
  test "processes pending orders and changes status to completed" do
    user = create(:student)
    user.portfolio.portfolio_transactions.create!(amount_cents: 10_000, transaction_type: :deposit) # $100.00

    stock = create(:stock, price_cents: 1_000)
    order = create(:order, user: user, stock: stock, shares: 2, action: :buy)
    assert_equal "pending", order.status

    OrderExecutionJob.perform_now
    order.reload
    assert_equal "completed", order.status

    assert_not_nil order.portfolio_stock
    assert_equal 2, order.portfolio_stock.shares
    assert_equal stock, order.portfolio_stock.stock

    assert_not_nil order.portfolio_transaction
    assert_equal user.portfolio, order.portfolio_transaction.portfolio
  end

  test "only processes pending orders" do
    user1 = create(:student)
    user1.portfolio.portfolio_transactions.create!(amount_cents: 10_000, transaction_type: :deposit)
    user2 = create(:student)
    user2.portfolio.portfolio_transactions.create!(amount_cents: 10_000, transaction_type: :deposit)

    stock = create(:stock, price_cents: 1_000)
    pending_order = create(:order, user: user1, stock: stock, shares: 1, action: :buy)
    completed_order = create(:order, :completed, user: user2, stock: stock, shares: 1, action: :buy)

    assert_equal "pending", pending_order.status
    assert_equal "completed", completed_order.status

    OrderExecutionJob.perform_now

    pending_order.reload
    completed_order.reload

    assert_equal "completed", pending_order.status
    assert_equal "completed", completed_order.status

    assert_not_nil pending_order.portfolio_stock
    assert_nil completed_order.portfolio_stock
  end

  test "handles multiple pending orders" do
    user1 = create(:student)
    user1.portfolio.portfolio_transactions.create!(amount_cents: 10_000, transaction_type: :deposit)
    user2 = create(:student)
    user2.portfolio.portfolio_transactions.create!(amount_cents: 10_000, transaction_type: :deposit)

    stock1 = create(:stock, price_cents: 1_000)
    stock2 = create(:stock, price_cents: 2_000)

    order1 = create(:order, user: user1, stock: stock1, shares: 1, action: :buy)
    order2 = create(:order, user: user2, stock: stock2, shares: 2, action: :buy)

    assert_equal "pending", order1.status
    assert_equal "pending", order2.status

    OrderExecutionJob.perform_now

    order1.reload
    order2.reload

    assert_equal "completed", order1.status
    assert_equal "completed", order2.status

    assert_not_nil order1.portfolio_stock
    assert_not_nil order1.portfolio_transaction
    assert_not_nil order2.portfolio_stock
    assert_not_nil order2.portfolio_transaction
  end

  test "it adds 1 transaction fee per portfolio if there are pending orders" do
    user = create(:student)
    portfolio = user.portfolio
    portfolio.portfolio_transactions.create!(amount_cents: 10_000, transaction_type: :deposit) # $100.00

    stock1, stock2 = create_list(:stock, 2, price_cents: 1_000)
    create(:order, :pending, user: user, stock: stock1, shares: 2, action: :buy)
    create(:order, :pending, user: user, stock: stock2, shares: 1, action: :buy)

    assert_changes -> { portfolio.portfolio_transactions.fees.count }, from: 0, to: 1 do
      OrderExecutionJob.perform_now
    end
  end
end
