# frozen_string_literal: true

require "test_helper"

class TransactionFeeProcessorTest < ActiveSupport::TestCase
  test "it applies 1 fee per student for multiple orders" do
    user_with_multiple_orders = create(:student)
    user_with_multiple_orders.portfolio.portfolio_transactions.create!(amount_cents: 10_000, transaction_type: :deposit) # $100.00
    user_with_one_order = create(:student)
    user_with_one_order.portfolio.portfolio_transactions.create!(amount_cents: 10_000, transaction_type: :deposit) # $100.00

    stock1 = create(:stock, price_cents: 1_000) # $10.00
    stock2 = create(:stock, price_cents: 2_000) # $20.00

    order1 = create(:order, :pending, user: user_with_multiple_orders, stock: stock1, shares: 1, action: :buy)
    order2 = create(:order, :pending, user: user_with_multiple_orders, stock: stock2, shares: 1, action: :buy)
    order3 = create(:order, :pending, user: user_with_one_order, stock: stock1, shares: 1, action: :buy)

    assert_equal 0, user_with_multiple_orders.portfolio.portfolio_transactions.fees.count
    assert_equal 0, user_with_one_order.portfolio.portfolio_transactions.fees.count

    TransactionFeeProcessor.execute([order1, order2, order3])
    # Each user should have one transaction fee

    assert_equal 1, user_with_multiple_orders.portfolio.portfolio_transactions.fees.count
    assert_equal 1, user_with_one_order.portfolio.portfolio_transactions.fees.count
  end
end
