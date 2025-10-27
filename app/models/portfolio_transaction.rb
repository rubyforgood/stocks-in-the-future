# frozen_string_literal: true

class PortfolioTransaction < ApplicationRecord
  TRANSACTION_FEE_CENTS = 1_00
  # deposit/witdrawal is for cash transactions ie grades and attendance
  # credit/debit is for stock transactions ie buy/sell stocks
  enum :transaction_type, { deposit: 0, withdrawal: 1, credit: 2, debit: 3, fee: 4 }

  REASONS = {
    math_earnings: "Earnings from Math",
    reading_earnings: "Earnings from Reading",
    attendance_earnings: "Earnings from Attendance",
    grade_earnings: "Earnings from Grades", # TODO: Remove this
    transaction_fees: "Transaction Fees",
    awards: "Award",
    administrative_adjustments: "Administrative Adjustment"
  }.freeze

  belongs_to :portfolio
  has_one :order, dependent: :destroy

  scope :deposits, -> { where(transaction_type: :deposit) }
  scope :debits, -> { where(transaction_type: :debit) }
  scope :credits, -> { where(transaction_type: :credit) }
  scope :withdrawals, -> { where(transaction_type: :withdrawal) }
  scope :fees, -> { where(transaction_type: :fee) }

  def reason_humanized
    reason&.humanize
  end
end
