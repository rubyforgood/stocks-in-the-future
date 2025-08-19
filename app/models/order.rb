# frozen_string_literal: true

class Order < ApplicationRecord
  attr_accessor :transaction_type

  belongs_to :user
  belongs_to :stock
  belongs_to :portfolio_stock, optional: true
  belongs_to :portfolio_transaction, optional: true

  enum :status, { pending: 0, completed: 1, canceled: 2 }

  validates :shares, presence: true, numericality: { greater_than: 0 }
  validate :sufficient_shares_for_sell, if: -> { transaction_type == "sell" }
  validate :sufficient_funds_for_buy, if: -> { transaction_type == "buy" }

  after_create :create_portfolio_transaction

  delegate :portfolio, to: :user

  scope :pending, -> { where(status: :pending) }
  scope :completed, -> { where(status: :completed) }
  scope :canceled, -> { where(status: :canceled) }

  def purchase_cost
    stock.price_cents * shares
  end

  private

  def sufficient_shares_for_sell
    current_shares = user.portfolio&.shares_owned(stock_id) || 0
    return unless shares > current_shares

    # Format the number to remove unnecessary decimals
    formatted_shares = (current_shares % 1).zero? ? current_shares.to_i : current_shares
    errors.add(:shares, "Cannot sell more shares than you own (#{formatted_shares} available)")
  end

  def sufficient_funds_for_buy
    current_balance_cents = (user.portfolio&.cash_balance || 0) * 100
    return unless purchase_cost > current_balance_cents

    # Format the balance to display as currency
    formatted_balance = format("$%.2f", current_balance_cents / 100.0)
    formatted_cost = format("$%.2f", purchase_cost / 100.0)
    errors.add(:shares, "Insufficient funds. You have #{formatted_balance} but need #{formatted_cost}")
  end

  def create_portfolio_transaction
    PortfolioTransaction.create!(
      portfolio: portfolio,
      amount_cents: purchase_cost,
      transaction_type: translated_transaction_type,
      order: self
    )
  end

  def translated_transaction_type
    transaction_type == "buy" ? :debit : :credit
  end
end
