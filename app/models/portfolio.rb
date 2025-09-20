# frozen_string_literal: true

class Portfolio < ApplicationRecord
  include ::UrlHelpers

  belongs_to :user
  validate :user_must_be_student

  has_many :portfolio_transactions, dependent: :destroy
  has_many :portfolio_stocks, dependent: :destroy
  has_many :stocks, through: :portfolio_stocks
  has_many :portfolio_snapshots, dependent: :destroy

  def cash_balance
    cash_on_hand
  end

  def path
    portfolio_path(self)
  end

  def shares_owned(stock_id)
    portfolio_stocks.where(stock_id: stock_id).sum(:shares)
  end

  private

  def cash_on_hand
    cash_on_hand_in_cents / 100.0
  end

  def cash_on_hand_in_cents
    credits = total_credits + total_deposits
    debits = total_debits + total_withdrawals + total_fees + pending_transaction_fee
    credits - debits
  end

  def total_withdrawals
    portfolio_transactions.withdrawals.sum(:amount_cents)
  end

  def total_deposits
    portfolio_transactions.deposits.sum(:amount_cents)
  end

  def total_fees
    portfolio_transactions.fees.sum(:amount_cents)
  end

  def total_credits
    portfolio_transactions.credits.sum(:amount_cents)
  end

  def total_debits
    pending_orders_amount = user.orders.pending.buy.sum(&:purchase_cost) || 0
    portfolio_transactions.debits.sum(:amount_cents) + pending_orders_amount
  end

  def pending_transaction_fee
    user.orders.pending.exists? ? PortfolioTransaction::TRANSACTION_FEE_CENTS : 0
  end

  def user_must_be_student
    errors.add(:user, "must be a student") unless user&.student?
  end
end
