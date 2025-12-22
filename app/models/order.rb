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

  # Now runs when creating orders or when user changes the share amount.
  # Skips during status changes (pending→completed) to avoid false errors.
  validate :sufficient_shares_for_sell,
           if: -> { sell? && validate_share_availability? },
           on: %i[create update]
  validate :sufficient_funds_for_buy, if: -> { buy? }, on: :create
  validate :prevent_archived_stock_purchase, if: -> { buy? }, on: %i[create update]
  validate :trading_enabled_for_classroom, on: :create

  after_update :update_portfolio_transaction_for_pending_order

  delegate :portfolio, to: :user

  scope :buy, -> { where(action: :buy) }
  scope :sell, -> { where(action: :sell) }

  scope :pending, -> { where(status: :pending) }
  scope :completed, -> { where(status: :completed) }
  scope :canceled, -> { where(status: :canceled) }

  scope :for_student, ->(student) { where(user: student) }
  scope :for_teacher, lambda { |teacher|
    joins(user: :classroom).where(users: { classroom: teacher.classrooms })
  }

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

  def number_of_shares_valid_for_calculations?
    shares.is_a?(Numeric) && shares.positive?
  end

  def sufficient_shares_for_sell
    return unless number_of_shares_valid_for_calculations?

    current_shares = user.portfolio&.shares_owned(stock_id) || 0
    return unless shares > current_shares

    formatted_shares = (current_shares % 1).zero? ? current_shares.to_i : current_shares
    errors.add(:shares, "Cannot sell more shares than you own (#{formatted_shares} available)")
  end

  def sufficient_funds_for_buy
    return unless number_of_shares_valid_for_calculations?

    current_balance_cents = (user.portfolio&.cash_balance || 0) * 100
    total_cost = purchase_cost + transaction_fee
    return if (current_balance_cents - total_cost) >= 0

    formatted_balance = format_money(current_balance_cents)
    formatted_cost = format_money(total_cost)
    errors.add(:shares, "Insufficient funds. You have #{formatted_balance} but need #{formatted_cost}")
  end

  def transaction_fee
    user.orders.pending.where.not(id:).exists? ? 0 : PortfolioTransaction::TRANSACTION_FEE_CENTS
  end

  def sufficient_funds_for_buy_when_update
    return unless number_of_shares_valid_for_calculations?
    return unless shares_changed?

    previous_shares = shares_was
    refund = (stock.price_cents * previous_shares) + PortfolioTransaction::TRANSACTION_FEE_CENTS

    current_balance_cents = ((user.portfolio&.cash_balance || 0) * 100) + refund
    total_cost = purchase_cost + transaction_fee
    return if (current_balance_cents - total_cost) >= 0

    formatted_balance = format_money(current_balance_cents)
    formatted_cost = format_money(total_cost)
    errors.add(:shares,
               "Insufficient funds. You have #{formatted_balance} but need #{formatted_cost}")
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

  def prevent_archived_stock_purchase
    return unless stock&.archived?

    errors.add(:stock, "Cannot purchase shares of archived stocks")
  end

  # Only validate share availability when shares quantity changes,
  # not during status-only updates (pending → completed)
  def validate_share_availability?
    return true if new_record?

    shares_changed?
  end

  def trading_enabled_for_classroom
    return if user&.classroom&.trading_enabled?

    errors.add(:base, "Trading is currently disabled for your classroom")
  end
end
