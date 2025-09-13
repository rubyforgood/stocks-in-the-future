# frozen_string_literal: true

class Portfolio < ApplicationRecord
  include ::UrlHelpers

  belongs_to :user
  validate :user_must_be_student

  has_many :portfolio_transactions, dependent: :destroy
  has_many :portfolio_stocks, dependent: :destroy
  has_many :stocks, through: :portfolio_stocks

  def cash_balance
    cash_on_hand
  end

  def path
    portfolio_path(self)
  end

  def shares_owned(stock_id)
    portfolio_stocks.where(stock_id: stock_id).sum(:shares)
  end

  # private

  def cash_on_hand
    cash_on_hand_in_cents / 100.0
  end

  def cash_on_hand_in_cents
    deposits - acceptable_debits_sum_in_cents + acceptable_credits_sum_in_cents - withdrawals - fees - pending_transaction_fee
  end

  def withdrawals
    portfolio_transactions.withdrawals.sum(:amount_cents)
  end

  def deposits
    portfolio_transactions.deposits.sum(:amount_cents)
  end

  def fees
    portfolio_transactions.fees.sum(:amount_cents)
  end

  def pending_transaction_fee
    user.orders.pending.exists? ? PortfolioTransaction::TRANSACTION_FEE_CENTS : 0
  end

  def acceptable_credits_sum_in_cents
    acceptable_credits.sum(&:amount_cents)
  end

  def acceptable_credits
    portfolio_transactions.credits.select(&:completed?)
  end

  def acceptable_debits_sum_in_cents
    acceptable_debits.sum(&:amount_cents)
  end

  def acceptable_debits
    portfolio_transactions.debits.reject(&:canceled?)
  end

  def user_must_be_student
    errors.add(:user, "must be a student") unless user&.student?
  end
end
