# frozen_string_literal: true

class Order < ApplicationRecord
  attr_accessor :transaction_type

  belongs_to :user
  belongs_to :stock
  belongs_to :portfolio_stock, optional: true
  belongs_to :portfolio_transaction, optional: true

  enum :status, { pending: 0, completed: 1, canceled: 2 }

  validates :shares, presence: true, numericality: { greater_than: 0 }

  after_create :create_portfolio_transaction

  delegate :portfolio, to: :user

  scope :pending, -> { where(status: :pending) }
  scope :completed, -> { where(status: :completed) }
  scope :canceled, -> { where(status: :canceled) }

  def purchase_cost
    stock.price_cents * shares
  end

  private

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
