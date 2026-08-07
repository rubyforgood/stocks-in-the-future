# frozen_string_literal: true

class Portfolio < ApplicationRecord
  include ::UrlHelpers

  belongs_to :user
  validate :user_must_be_student

  delegate :username, :student?, :school_name, :trading_enabled?, to: :user

  has_many :portfolio_transactions, dependent: :destroy
  has_many :portfolio_stocks, dependent: :destroy
  has_many :stocks, through: :portfolio_stocks
  has_many :portfolio_snapshots, dependent: :destroy

  # Integer cents. Use this for any arithmetic or comparison. Converting to a
  # Float and back loses value for most two-decimal amounts, which previously
  # made an exactly-affordable order read as unaffordable.
  def cash_balance_cents
    cash_on_hand_in_cents
  end

  # Float, for display only. Never multiply this back up to get cents.
  def cash_balance
    cash_on_hand
  end

  def path
    portfolio_path(self)
  end

  # The first-share moment shows once: when a student holds something and has not dismissed it.
  # A timestamp rather than a flag, so the record says when as well as whether.
  def celebrate_first_share?
    first_share_acknowledged_at.nil? && portfolio_stocks.exists?(shares: 1..)
  end

  def acknowledge_first_share!
    update!(first_share_acknowledged_at: Time.current)
  end

  def shares_owned(stock_id)
    portfolio_stocks.where(stock_id: stock_id).sum(:shares)
  end

  def positions
    PortfolioPosition.for_portfolio(self)
  end

  def calculate_total_value_cents
    cash_on_hand_in_cents + holdings_value_cents
  end

  def calculate_total_value
    calculate_total_value_cents / 100.0
  end

  def total_portfolio_worth
    calculate_total_value
  end

  def holdings_value
    holdings_value_cents / 100.0
  end

  def holdings_value_cents
    portfolio_stocks.joins(:stock).sum(
      "portfolio_stocks.shares * stocks.price_cents"
    )
  end

  def chart_data
    snapshots = portfolio_snapshots.order(date: :asc).last(12)

    snapshots.map do |snapshot|
      {
        label: snapshot.date.strftime("%b %Y"),
        value: snapshot.current_worth
      }
    end
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
