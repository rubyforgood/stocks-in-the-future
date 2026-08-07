# frozen_string_literal: true

# Charges the trading fee once per student per run, however many orders they
# placed. Called by OrderExecutionJob after the orders themselves are executed.
#
# The fee is deliberately not per-order: batching several trades into one charge
# is the behaviour we want students to notice, and Portfolio#pending_transaction_fee
# holds a matching flat amount while any order is outstanding.
#
# The charge records which orders it covers. Without that, a student seeing
# "-$1.00 Transaction fees" in their history had no way to tell which trade caused
# it, and the charge could not be audited against the orders.
class TransactionFeeProcessor
  def initialize(orders)
    @orders = orders
    @users = Set.new
  end

  def self.execute(...)
    new(...).execute
  end

  def execute
    ActiveRecord::Base.transaction do
      orders_by_user.each_value { |user_orders| charge_fee(user_orders) }
    end
  end

  private

  attr_reader :orders

  # One entry per student, holding only that student's orders, so the description
  # never names another student's trades.
  def orders_by_user
    orders.group_by { |order| order.portfolio.user_id }
  end

  def charge_fee(orders)
    orders.first.portfolio.portfolio_transactions.fees.create!(
      amount_cents: PortfolioTransaction::TRANSACTION_FEE_CENTS,
      reason: :transaction_fees,
      description: describe(orders)
    )
  end

  def describe(orders)
    covered = orders.map { |order| "#{order.action} #{format_shares(order.shares)} #{order.stock.ticker}" }
    "Daily trading fee, covering #{covered.size} #{'order'.pluralize(covered.size)}: #{covered.join(', ')}."
  end

  # shares is a decimal, so a whole number renders as "1.0" unless trimmed. Same
  # treatment Order uses in its validation messages.
  def format_shares(shares)
    (shares % 1).zero? ? shares.to_i : shares
  end
end
