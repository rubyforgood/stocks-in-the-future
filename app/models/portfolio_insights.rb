# frozen_string_literal: true

# Derived figures for the student portfolio page. Pure: it reads, it never writes, and every
# amount it returns is integer cents so nothing round-trips through a Float.
#
# EarningsSummary already answers "how much from each source". This answers the questions that
# need a comparison or a grouping - how much the portfolio moved, which month was the best - and
# the counts the page's plain-English summary reads out.
class PortfolioInsights
  # The reasons that are money a student earned, as opposed to a fee or an adjustment.
  EARNING_REASONS = %w[math_earnings reading_earnings attendance_earnings awards].freeze

  attr_reader :portfolio

  def initialize(portfolio)
    @portfolio = portfolio
  end

  # --- change since the end of last month ------------------------------------------------
  #
  # The baseline is the most recent snapshot dated before this month began, so the comparison is
  # "since last month" rather than "since some point mid-month". A student with no such snapshot
  # has no baseline and gets no comparison line at all, which is the honest answer in their first
  # month rather than a change of zero.
  def comparison?
    !baseline_snapshot.nil?
  end

  def baseline_worth_cents
    baseline_snapshot&.worth_cents
  end

  def change_cents
    return nil unless comparison?

    portfolio.calculate_total_value_cents - baseline_worth_cents
  end

  # nil rather than zero when there is nothing to divide by: a portfolio that was empty last month
  # has not grown by a percentage, it has just started.
  def change_percent
    return nil unless comparison?
    return nil if baseline_worth_cents.zero?

    (change_cents.to_f / baseline_worth_cents) * 100
  end

  def change_up?
    change_cents.to_i >= 0
  end

  # --- best month ------------------------------------------------------------------------
  #
  # Grouped in the database by calendar month. Returns nil when a student has earned nothing yet,
  # so the card can be withheld rather than showing a best of zero.
  def best_month
    @best_month ||= earnings_by_month.max_by { |_month, cents| cents }
  end

  def best_month_date
    best_month&.first&.to_date
  end

  def best_month_cents
    best_month&.last
  end

  # --- figures the summary sentence reads out --------------------------------------------
  def earned_cents
    @earned_cents ||= earning_deposits.sum(:amount_cents)
  end

  def invested_cents
    portfolio.holdings_value_cents
  end

  def cash_cents
    portfolio.cash_balance_cents
  end

  def company_count
    companies.size
  end

  # Tickers the student actually holds, in a stable order so the row does not reshuffle between
  # page loads.
  def companies
    @companies ||= portfolio.portfolio_stocks
      .where(shares: 1..)
      .joins(:stock)
      .order("stocks.ticker")
      .pluck("stocks.ticker")
  end

  def holdings?
    company_count.positive?
  end

  private

  def baseline_snapshot
    return @baseline_snapshot if defined?(@baseline_snapshot)

    @baseline_snapshot = portfolio.portfolio_snapshots
      .where(date: ...Date.current.beginning_of_month)
      .order(date: :desc)
      .first
  end

  def earning_deposits
    portfolio.portfolio_transactions.deposits.where(reason: EARNING_REASONS)
  end

  def earnings_by_month
    earning_deposits.group(Arel.sql("DATE_TRUNC('month', portfolio_transactions.created_at)"))
      .sum(:amount_cents)
  end
end
