# frozen_string_literal: true

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
      @orders.each do |order|
        add_transaction_fee order
      end
    end
  end

  private

  def add_transaction_fee(order)
    return if @users.include?(order.portfolio.user_id)

    order.portfolio.portfolio_transactions.fees.create!(amount_cents: PortfolioTransaction::TRANSACTION_FEE_CENTS,
                                                        reason: PortfolioTransaction::REASONS[:transaction_fee])
    @users << order.portfolio.user_id
  end
end
