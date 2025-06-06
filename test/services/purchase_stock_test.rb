require "test_helper"

class PurchaseStockTest < ActiveSupport::TestCase
  test "it creates a withdrawl transaction in portfolio_transactions" do
    student = create(:student)
    create(:portfolio, user: student)
    stock = create(:stock, price_cents: 100)
    order = create(:order, :pending, shares: 5, stock:, user: student)

    assert_difference("PortfolioTransaction.count") do
      PurchaseStock.execute(order)
    end

    portfolio_transaction = PortfolioTransaction.last
    assert portfolio_transaction.withdrawal?
    assert_equal portfolio_transaction, order.portfolio_transaction
    assert_operator portfolio_transaction.amount_cents, :<, 0
  end

  test "it creates an linked entry in portfolio_stocks" do
    student = create(:student)
    create(:portfolio, user: student)
    stock = create(:stock, price_cents: 100)
    order = create(:order, :pending, shares: 5, stock:, user: student)

    assert_difference("PortfolioStock.count") do
      PurchaseStock.execute(order)
    end

    portfolio_stock = PortfolioStock.last
    assert_equal portfolio_stock, order.portfolio_stock
  end

  test "it updates the order status to completed" do
    student = create(:student)
    create(:portfolio, user: student)
    stock = create(:stock, price_cents: 100)
    order = create(:order, :pending, shares: 5, stock:, user: student)

    PurchaseStock.execute(order)
    order.reload

    assert order.completed?
  end

  test "it does not update order when status is not pending" do
    order = create(:order, :completed)

    PurchaseStock.execute(order)
    order.reload

    assert order.completed?
  end

  # TODO: Fix this test
  test "it does not update order if portfolio transaction fails to save" do
    skip "Can we update this test to not use a mock?"
    order = Order.create(stock: Stock.first, shares: 5, status: :pending, user: @student)

    # Simulate failure to create portfolio_transaction by stubbing the create method to return false
    order.portfolio.portfolio_transactions.stubs(:create!).raises(ActiveRecord::RecordInvalid.new(PortfolioTransaction.new))

    assert_raises(ActiveRecord::RecordInvalid) do
      PurchaseStock.execute(order)
    end

    order.reload

    assert_equal "pending", order.status
    assert_nil order.portfolio_transaction
    assert_nil order.portfolio_stock
  end
end
