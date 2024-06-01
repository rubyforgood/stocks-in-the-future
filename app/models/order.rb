class Order < ApplicationRecord
  belongs_to :user
  belongs_to :stock

  enum status: {pending: 0, completed: 1, canceled: 2}

  delegate :portfolio, to: :user

  scope :pending, -> { where(status: :pending) }

  def purchase_cost
    stock.price * shares
  end
end
