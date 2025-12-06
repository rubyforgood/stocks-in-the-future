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

  def transaction_fees_cents
    sum_by_reason(:transaction_fees)
  end

  private

  def sum_by_reason(reason)
    portfolio.portfolio_transactions
             .deposits
             .where(reason: reason)
             .sum(:amount_cents)
  end
end
