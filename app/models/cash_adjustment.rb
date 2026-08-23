# frozen_string_literal: true

# An administrator moving money into or out of a student's portfolio by hand, from the student's own
# record page.
#
# **Why a form object.** The four fields used to be loose params - `transaction_type`,
# `add_fund_amount`, `transaction_reason`, `transaction_description` - checked in the controller and
# reported by redirecting back with `alert:`. Three things followed from that. The message appeared at
# the top of the page instead of against the field it was about; a redirect threw away everything
# typed, so a wrong reason meant retyping the amount and the description; and the checks could only
# ask whether a value was *blank*, which is how the two defects below survived. Bound to an object,
# the fields carry their own errors through `field_error_proc` like every other form in the app.
#
# **Integer cents, parsed exactly.** The controller did `(amount.to_f * 100).to_i`. Measured over
# every typed amount from $0.01 to $1000.00, **4,586 of the 100,000** stored the wrong number of
# cents, always one low: $0.29 became 28, $1.15 became 114, $2.01 became 200. That is the float round
# trip design.md and CLAUDE.md both forbid, in the one place where a person types money into this
# app. BigDecimal is exact.
#
# **What "present" could not catch.** `"abc".to_f * 100` is `0`, and `0` is not blank, so a typo
# deposited $0.00 and reported success. `"-50"` was accepted as a negative deposit. And an amount past
# 2,147,483,647 cents raised `PG::NumericValueOutOfRange` from the insert - a 500 from a typo in a
# text box. The format below is the whole guard: digits, optionally two decimal places, at most seven
# digits before the point.
class CashAdjustment
  include ActiveModel::Model

  DIRECTIONS = %w[deposit debit].freeze

  # Every reason except the deprecated one. `PortfolioTransaction`'s enum marks `grade_earnings`
  # "Deprecated, will be removed in future" and the picker offered it anyway, which is how a
  # deprecated value stays alive: something still writes it. One list, used by the select and by the
  # validation, so the form cannot offer a value the model would reject.
  REASONS = (PortfolioTransaction.reasons.keys - %w[grade_earnings]).freeze

  # Deliberately not `numericality`. That accepts "1e3", "0x10", leading whitespace and "12.345", and
  # its message - "is not a number" - does not tell anybody what to type. Money has a shape.
  MONEY = /\A\d{1,7}(\.\d{1,2})?\z/

  attr_accessor :portfolio, :transaction_type, :amount, :reason, :description

  # Reachable only by posting straight to the route: the form renders where a portfolio exists. It
  # still needs saying rather than raising, because `belongs_to :portfolio` would fail the insert.
  # The messages are in `config/locales/en.yml` under `activemodel.errors.models.cash_adjustment`, which is
  # where this app keeps the two it already had - and what makes each one readable next to its own field:
  # "Amount must be an amount in dollars, like 12.50", not "Amount is invalid".
  validates :portfolio, presence: true
  validates :transaction_type, presence: true, inclusion: { in: DIRECTIONS, allow_blank: true }
  validates :reason, presence: true, inclusion: { in: REASONS, allow_blank: true }
  validates :amount, presence: true, format: { with: MONEY, allow_blank: true }
  validate :amount_moves_something

  # Integer cents, or nil when the typed value is not money. Never a Float, in either direction.
  def amount_cents
    return nil unless amount.to_s.match?(MONEY)

    (BigDecimal(amount.to_s) * 100).to_i
  end

  # Named `save` and returning a boolean, like the ActiveRecord method it stands in for. The predicate-name
  # cop wants `save?`, which no caller of a form object would think to write.
  def save # rubocop:disable Naming/PredicateMethod
    return false unless valid?

    portfolio.portfolio_transactions.create(
      amount_cents: amount_cents,
      transaction_type: transaction_type,
      reason: reason,
      description: description.presence
    ).persisted?
  end

  private

  # "0", "0.00" and "0.0" all pass the format and all do nothing. A transaction that moves no money is
  # a row in a student's history saying something happened when nothing did.
  # `&.zero?`, because `amount_cents` is nil for anything that is not money and `nil.zero?` raises - the
  # blank and malformed cases are already reported by their own validations.
  def amount_moves_something
    errors.add(:amount, :greater_than_zero) if amount_cents&.zero?
  end
end
