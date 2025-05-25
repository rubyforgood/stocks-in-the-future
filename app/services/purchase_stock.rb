class PurchaseStock
  delegate :portfolio, :shares, :stock, to: :order, private: true
  delegate :price_cents, to: :stock, prefix: true, private: true

  def initialize(order)
    @order = order
  end

  def self.execute(...)
    new(...).execute
  end

  def execute
    return unless order.pending?

    ActiveRecord::Base.transaction do
      create_withdrawal_transaction
      create_portfolio_stock
      update_order_status
    end
  end

  private

  attr_accessor :order, :portfolio_stock, :portfolio_transaction

  def create_withdrawal_transaction
    @portfolio_transaction = portfolio
      .portfolio_transactions
      .withdrawal
      .create!(amount_cents: purchase_cost)
  end

  def create_portfolio_stock
    @portfolio_stock = portfolio
      .portfolio_stocks
      .create!(stock:, shares:, purchase_price: stock_price_cents)
  end

  def update_order_status
    order.completed!
    order.update!(portfolio_stock:, portfolio_transaction:)
  end

  def purchase_cost
    -order.purchase_cost
  end
end
