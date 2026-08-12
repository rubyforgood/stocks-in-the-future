# frozen_string_literal: true

class PortfolioTransaction < ApplicationRecord
  TRANSACTION_FEE_CENTS = 1_00
  # deposit/witdrawal is for cash transactions ie grades and attendance
  # credit/debit is for stock transactions ie buy/sell stocks
  enum :transaction_type, { deposit: 0, withdrawal: 1, credit: 2, debit: 3, fee: 4 }

  enum :reason, {
    math_earnings: 0,
    reading_earnings: 1,
    attendance_earnings: 2,
    grade_earnings: 3, # Deprecated, will be removed in future
    transaction_fees: 4,
    awards: 5,
    administrative_adjustments: 6
  }, allow_nil: true

  belongs_to :portfolio

  # Both columns are `null: false`, and until now nothing checked them - so the admin's "New transaction"
  # form could post a blank type or a blank amount and get `ActiveRecord::NotNullViolation`, which is a 500
  # rather than a message next to the field. Every writer in the app already sets both: `ExecuteOrder` through
  # the `.debit` / `.credit` scopes, `TransactionFeeProcessor` through `.fees`, `DistributeEarnings` and
  # `CashAdjustment` explicitly.
  #
  # Presence only. An amount of zero is not something a person should be able to submit - `CashAdjustment`
  # rejects it - but that rule belongs on the path a person types on rather than on the model, which is also
  # written to by services whose arithmetic is their own.
  validates :transaction_type, presence: true
  validates :amount_cents, presence: true

  # Which grade book paid this, for an earnings deposit. Optional, and nil for every purchase, sale and
  # fee - and for every earnings deposit made before the column existed, which is why a difference
  # calculation has to treat nil as "not paid by this book" rather than as "unknown".
  belongs_to :grade_book, optional: true
  has_one :order, dependent: :destroy

  scope :deposits, -> { where(transaction_type: :deposit) }
  scope :debits, -> { where(transaction_type: :debit) }
  scope :credits, -> { where(transaction_type: :credit) }
  scope :withdrawals, -> { where(transaction_type: :withdrawal) }
  scope :fees, -> { where(transaction_type: :fee) }
end
