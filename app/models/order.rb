class Order < ApplicationRecord
  belongs_to :user
  belongs_to :stock
  belongs_to :portfolio_stock, optional: true
  belongs_to :portfolio_transaction, optional: true

  enum :status, {pending: 0, completed: 1, canceled: 2}

  delegate :portfolio, to: :user

  scope :pending, -> { where(status: :pending) }

  def purchase_cost
    stock.price * shares
  end
end
