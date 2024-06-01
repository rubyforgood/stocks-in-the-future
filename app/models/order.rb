class Order < ApplicationRecord
  belongs_to :user
  belongs_to :stock

  enum status: {pending: 0, completed: 1, canceled: 2}

  scope :pending, -> { where(status: :pending) }
end
