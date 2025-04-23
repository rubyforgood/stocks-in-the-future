require "test_helper"

class PurchaseStockTest < ActiveSupport::TestCase
  setup do
    @student = users(:one)
  end

  test "it creates a withdrawl transaction in portfolio_transactions" do
    order = Order.create(stock: Stock.first, shares: 5, status: :pending, user: @student)
    assert_difference("PortfolioTransaction.count") do
      PurchaseStock.execute(order)
    end

    portfolio_transaction = PortfolioTransaction.last
    assert_equal "withdrawal", portfolio_transaction.transaction_type
    assert_equal portfolio_transaction, order.portfolio_transaction
    assert_operator portfolio_transaction.amount, :<, 0
  end

  test "it creates an linked entry in portfolio_stocks" do
    order = Order.create(stock: Stock.first, shares: 5, status: :pending, user: @student)
    assert_difference("PortfolioStock.count") do
      PurchaseStock.execute(order)
    end
    portfolio_stock = PortfolioStock.last
    assert_equal portfolio_stock, order.portfolio_stock
  end

  test "it updates the order status to completed" do
    order = Order.create(stock: Stock.first, shares: 5, status: :pending, user: @student)
    PurchaseStock.execute(order)
    order.reload

    assert_equal "completed", order.status
  end

  test "it does not update order when status is not pending" do
    order = Order.create(stock: Stock.first, shares: 5, status: :canceled, user: @student)

    PurchaseStock.execute(order)

    order.reload

    assert_equal "canceled", order.status
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
