# frozen_string_literal: true

class PortfolioTransaction < ApplicationRecord
  # deposit/witdrawal is for cash transactions ie grades and attendance
  # credit/debit is for stock transactions ie buy/sell stocks
  enum :transaction_type, { deposit: 0, withdrawal: 1, credit: 2, debit: 3, fee: 4 }

  belongs_to :portfolio
  has_one :order, dependent: :destroy

  scope :deposits, -> { where(transaction_type: :deposit) }
  scope :debits, -> { where(transaction_type: :debit) }
  scope :credits, -> { where(transaction_type: :credit) }
  scope :withdrawals, -> { where(transaction_type: :withdrawal) }
  scope :fees, -> { where(transaction_type: :fee) }

  def completed?
    order.present? ? order.completed? : true
  end

  def canceled?
    order.present? ? order.canceled? : false
  end
end
