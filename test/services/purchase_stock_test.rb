require "test_helper"

# Q: Can transaction cash balance go negative?

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
end
