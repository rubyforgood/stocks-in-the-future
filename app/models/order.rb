# frozen_string_literal: true

class Order < ApplicationRecord
  include ApplicationHelper

  attr_accessor :transaction_type

  belongs_to :user
  belongs_to :stock
  belongs_to :portfolio_stock, optional: true
  belongs_to :portfolio_transaction, optional: true

  enum :status, { pending: 0, completed: 1, canceled: 2 }, default: :pending

  validates :shares, presence: true, numericality: { greater_than: 0 }

  # only those orders that are pending can be updated
  validate :sufficient_funds_for_buy_when_update, on: :update, if: -> { transaction_type == "buy" }
  validate :sufficient_funds_for_sell_when_update, on: :update, if: -> { transaction_type == "sell" }

  validate :sufficient_shares_for_sell, if: -> { transaction_type == "sell" }, on: :create
  validate :sufficient_funds_for_buy, if: -> { transaction_type == "buy" }, on: :create

  after_create :create_portfolio_transaction

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

  # def pending?
  #   status == "pending"
  # end

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

  def sufficient_funds_for_sell_when_update
    # we would want to execute this method only when we are just updating the shares
    # we are not marking the order as completed

    current_shares = (user.portfolio&.shares_owned(stock_id) || 0) + (shares_before_last_save || 0)
    return unless shares > current_shares

    formatted_shares = (current_shares % 1).zero? ? current_shares.to_i : current_shares
    errors.add(:shares, "Cannot sell more shares than you own (#{formatted_shares} available)")
  end

  def sufficient_funds_for_buy_when_update

    current_balance_cents = (user.portfolio&.cash_balance || 0) * 100
    balance_before_transaction = current_balance_cents + portfolio_transaction.amount_cents

    return unless purchase_cost > balance_before_transaction

    formatted_balance = format_money(balance_before_transaction)
    formatted_cost = format_money(purchase_cost)
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

  def update_portfolio_transaction_for_pending_order

    return unless pending?

    # here updating the portfolio transaction once the order gets updated
    portfolio_transaction.amount_cents = purchase_cost
    portfolio_transaction.transaction_type = translated_transaction_type
    portfolio_transaction.save
  end

  def translated_transaction_type
    transaction_type == "buy" ? :debit : :credit
  end

end
