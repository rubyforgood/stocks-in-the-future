# frozen_string_literal: true

class EarningsSummary
  attr_reader :portfolio

  def initialize(portfolio)
    @portfolio = portfolio
  end

  def attendance_earnings_cents
    sum_by_reason(:attendance_earnings)
  end

  def reading_earnings_cents
    sum_by_reason(:reading_earnings)
  end

  def math_earnings_cents
    sum_by_reason(:math_earnings)
  end

  def awards_cents
    sum_by_reason(:awards)
  end

  def total_earnings_cents
    attendance_earnings_cents + reading_earnings_cents + math_earnings_cents + awards_cents
  end

  # By **reason alone**, not by reason and type.
  #
  # Everything above is a deposit by definition - money paid in for attendance, reading, math or a reward -
  # so `sum_by_reason` filters on `deposits`, and a later debit tagged `math_earnings` does not reduce what a
  # student *earned*. A fee is the opposite: `TransactionFeeProcessor` writes it with
  # `transaction_type: :fee`, so filtering on deposits excluded every fee the app has ever charged and this
  # line read -$0.00 on both the student's portfolio page and the admin record page. The money itself was
  # always right - `Portfolio#total_fees` uses the `fees` scope and charges it to the balance.
  #
  # Widening `Portfolio#total_fees` to match would have been the other way round and is wrong: the balance
  # counts a deposit as a credit, so a legacy deposit *labelled* `transaction_fees` - which is what the dev
  # seed wrote - would be added as a credit and subtracted as a fee, moving a student's money. A display sum
  # can be generous about how a fee was recorded; the balance arithmetic cannot.
  def transaction_fees_cents
    portfolio.portfolio_transactions.where(reason: :transaction_fees).sum(:amount_cents)
  end

  private

  def sum_by_reason(reason)
    portfolio.portfolio_transactions
      .deposits
      .where(reason: reason)
      .sum(:amount_cents)
  end
end
