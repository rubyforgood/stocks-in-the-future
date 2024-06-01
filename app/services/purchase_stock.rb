class PurchaseStock
  attr_accessor :order

  def initialize(order)
    @order = order
  end

  def execute
    return unless order.pending?

    process_order!
  end

  private

  def process_order!
    ActiveRecord::Base.transaction do
      transaction = portfolio.portfolio_transactions.create(amount: withdrawal_amount, transaction_type: :withdrawal)

      portfolio_stock = portfolio.portfolio_stocks.create(stock: order.stock, shares: order.shares, purchase_price: order.stock.price)

      order.update(portfolio_transaction: transaction, portfolio_stock: portfolio_stock, status: :completed)
    end
  end

  def portfolio
    @portfolio ||= order.portfolio
  end

  def withdrawal_amount
    -order.purchase_cost
  end
end
