# frozen_string_literal: true

require "test_helper"

class TransactionFeeProcessorTest < ActiveSupport::TestCase
  test "it applies 1 fee per student for multiple orders" do
    user_with_multiple_orders = create(:student)
    user_with_multiple_orders.portfolio.portfolio_transactions.create!(amount_cents: 100_00, transaction_type: :deposit)
    user_with_one_order = create(:student)
    user_with_one_order.portfolio.portfolio_transactions.create!(amount_cents: 100_00, transaction_type: :deposit)

    stock1 = create(:stock, price_cents: 10_00) # $10.00
    stock2 = create(:stock, price_cents: 20_00) # $20.00

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
  test "the fee records which orders it covers" do
    student = create(:student)
    student.portfolio.portfolio_transactions.create!(amount_cents: 100_00, transaction_type: :deposit)
    apple = create(:stock, ticker: "AAPL", price_cents: 10_00)
    google = create(:stock, ticker: "GOOGL", price_cents: 20_00)

    order1 = create(:order, :pending, user: student, stock: apple, shares: 1, action: :buy)
    order2 = create(:order, :pending, user: student, stock: google, shares: 2, action: :buy)

    TransactionFeeProcessor.execute([order1, order2])

    fee = student.portfolio.portfolio_transactions.fees.sole

    # A student seeing "-$1.00 Transaction fees" in their history could not
    # previously tell which trade caused it, and nobody could audit the charge.
    assert fee.description.present?, "expected the fee to record what it covers"
    assert_includes fee.description, "AAPL"
    assert_includes fee.description, "GOOGL"
  end

  test "the fee names only the orders belonging to that student" do
    student_a = create(:student)
    student_b = create(:student)
    [student_a, student_b].each do |s|
      s.portfolio.portfolio_transactions.create!(amount_cents: 100_00, transaction_type: :deposit)
    end
    apple = create(:stock, ticker: "AAPL", price_cents: 10_00)
    tesla = create(:stock, ticker: "TSLA", price_cents: 20_00)

    order_a = create(:order, :pending, user: student_a, stock: apple, shares: 1, action: :buy)
    order_b = create(:order, :pending, user: student_b, stock: tesla, shares: 1, action: :buy)

    TransactionFeeProcessor.execute([order_a, order_b])

    assert_includes student_a.portfolio.portfolio_transactions.fees.sole.description, "AAPL"
    assert_not_includes student_a.portfolio.portfolio_transactions.fees.sole.description, "TSLA"
    assert_includes student_b.portfolio.portfolio_transactions.fees.sole.description, "TSLA"
  end
end
