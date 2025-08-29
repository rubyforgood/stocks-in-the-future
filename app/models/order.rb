# frozen_string_literal: true

class Order < ApplicationRecord
  include ApplicationHelper

  belongs_to :user
  belongs_to :stock
  belongs_to :portfolio_stock, optional: true
  belongs_to :portfolio_transaction, optional: true

  enum :status, { pending: 0, completed: 1, canceled: 2 }, default: :pending
  enum :action, { buy: "buy", sell: "sell" }

  validates :shares, presence: true, numericality: { greater_than: 0 }

  validate :sufficient_funds_for_buy_when_update, on: :update, if: -> { buy? }
  validate :order_is_pending, on: :update

  validate :sufficient_shares_for_sell, if: -> { sell? }, on: %i[create update]
  validate :sufficient_funds_for_buy, if: -> { buy? }, on: :create

  after_update :update_portfolio_transaction_for_pending_order

  delegate :portfolio, to: :user

  scope :pending, -> { where(status: :pending) }
  scope :completed, -> { where(status: :completed) }
  scope :canceled, -> { where(status: :canceled) }

  def cancel!
    update(status: :canceled)
  end

  def purchase_cost
    stock.price_cents * shares
  end

  def existing_transaction_type
    order_transaction_type = portfolio_transaction&.transaction_type&.to_sym
    order_transaction_type == :debit ? "buy" : "sell"
  end

  private

  def sufficient_shares_for_sell
    current_shares = user.portfolio&.shares_owned(stock_id) || 0
    return unless shares > current_shares

    formatted_shares = (current_shares % 1).zero? ? current_shares.to_i : current_shares
    errors.add(:shares, "Cannot sell more shares than you own (#{formatted_shares} available)")
  end

  def sufficient_funds_for_buy
    current_balance_cents = (user.portfolio&.cash_balance || 0) * 100
    return unless purchase_cost > current_balance_cents

    formatted_balance = format_money(current_balance_cents)
    formatted_cost = format_money(purchase_cost)
    errors.add(:shares, "Insufficient funds. You have #{formatted_balance} but need #{formatted_cost}")
  end

  def sufficient_funds_for_buy_when_update
    current_balance_cents = (user.portfolio&.cash_balance || 0) * 100

    balance_before_transaction = if portfolio_transaction.present?
                                   current_balance_cents + portfolio_transaction.amount_cents
                                 else
                                   current_balance_cents
                                 end

    return unless purchase_cost > balance_before_transaction

    formatted_balance = format_money(balance_before_transaction)
    formatted_cost = format_money(purchase_cost)
    errors.add(:shares, "Insufficient funds. You have #{formatted_balance} but need #{formatted_cost}")
  end

  def order_is_pending
    prev_status, = status_change_to_be_saved

    return if pending? || prev_status.nil? || prev_status == "pending"

    errors.add(:base, "Cannot update non-pending orders")
  end

  def update_portfolio_transaction_for_pending_order
    return unless pending? && portfolio_transaction.present?

    portfolio_transaction.amount_cents = purchase_cost
    portfolio_transaction.transaction_type = translated_transaction_type
    portfolio_transaction.save
  end

  def translated_transaction_type
    buy? ? :debit : :credit
  end
end
