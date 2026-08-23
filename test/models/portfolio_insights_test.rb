# frozen_string_literal: true

require "test_helper"

# Pinned as literals, not computed from the code's own constants, so the numbers can be seen to be
# right rather than agreeing with whatever the implementation does.
class PortfolioInsightsTest < ActiveSupport::TestCase
  setup do
    @portfolio = create(:portfolio)
  end

  def insights
    PortfolioInsights.new(@portfolio.reload)
  end

  test "no comparison in a student's first month" do
    # A snapshot from this month is not a baseline: "since last month" needs one from before it.
    create(:portfolio_snapshot, portfolio: @portfolio, date: Date.current, worth_cents: 5_000)

    assert_not insights.comparison?
    assert_nil insights.change_cents
    assert_nil insights.change_percent
  end

  test "the baseline is the last snapshot before this month" do
    create(:portfolio_snapshot, portfolio: @portfolio, date: 3.months.ago.to_date, worth_cents: 1_000)
    create(:portfolio_snapshot, portfolio: @portfolio, date: 1.month.ago.to_date, worth_cents: 8_000)
    create(:portfolio_snapshot, portfolio: @portfolio, date: Date.current, worth_cents: 99_999)
    create(:portfolio_transaction, :deposit, portfolio: @portfolio, amount_cents: 10_000)

    assert insights.comparison?
    assert_equal 8_000, insights.baseline_worth_cents
    assert_equal 2_000, insights.change_cents
    assert_in_delta 25.0, insights.change_percent, 0.01
    assert insights.change_up?
  end

  test "a fall is reported as a fall" do
    create(:portfolio_snapshot, portfolio: @portfolio, date: 1.month.ago.to_date, worth_cents: 20_000)
    create(:portfolio_transaction, :deposit, portfolio: @portfolio, amount_cents: 15_000)

    assert_equal(-5_000, insights.change_cents)
    assert_not insights.change_up?
    assert_in_delta(-25.0, insights.change_percent, 0.01)
  end

  test "no percentage when the baseline was zero" do
    create(:portfolio_snapshot, portfolio: @portfolio, date: 1.month.ago.to_date, worth_cents: 0)
    create(:portfolio_transaction, :deposit, portfolio: @portfolio, amount_cents: 5_000)

    assert_equal 5_000, insights.change_cents
    assert_nil insights.change_percent, "a portfolio that was empty has not grown by a percentage"
  end

  test "the best month is the biggest month of earnings, and fees do not count" do
    travel_to Time.zone.local(2026, 3, 15) do
      create(
        :portfolio_transaction, portfolio: @portfolio, transaction_type: :deposit,
                                reason: :attendance_earnings, amount_cents: 1_800
      )
    end
    travel_to Time.zone.local(2026, 4, 15) do
      create(
        :portfolio_transaction, portfolio: @portfolio, transaction_type: :deposit,
                                reason: :reading_earnings, amount_cents: 500
      )
      # A plain deposit with no reason is not earnings, and a fee is money out.
      create(:portfolio_transaction, :deposit, portfolio: @portfolio, amount_cents: 90_000)
      create(
        :portfolio_transaction, portfolio: @portfolio, transaction_type: :fee,
                                reason: :transaction_fees, amount_cents: 100
      )
    end

    assert_equal 1_800, insights.best_month_cents
    assert_equal Date.new(2026, 3, 1), insights.best_month_date
  end

  test "no best month before anything is earned" do
    create(:portfolio_transaction, :deposit, portfolio: @portfolio, amount_cents: 50_000)

    assert_nil insights.best_month_cents
    assert_nil insights.best_month_date
  end

  test "companies are the tickers actually held, in a stable order" do
    %w[NKE KO BAC].each_with_index do |ticker, i|
      stock = create(:stock, ticker: ticker, price_cents: 1_000)
      create(:portfolio_stock, portfolio: @portfolio, stock: stock, shares: i + 1)
    end
    sold_out = create(:stock, ticker: "VZ", price_cents: 1_000)
    create(:portfolio_stock, portfolio: @portfolio, stock: sold_out, shares: 0)

    assert_equal %w[BAC KO NKE], insights.companies
    assert_equal 3, insights.company_count
    assert insights.holdings?
  end

  test "earnings exclude plain deposits" do
    create(
      :portfolio_transaction, portfolio: @portfolio, transaction_type: :deposit,
                              reason: :math_earnings, amount_cents: 700
    )
    create(:portfolio_transaction, :deposit, portfolio: @portfolio, amount_cents: 50_000)

    assert_equal 700, insights.earned_cents
  end
end
