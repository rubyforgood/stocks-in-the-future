# frozen_string_literal: true

require "test_helper"

class EarningsSummaryTest < ActiveSupport::TestCase
  setup do
    @student = create(:student)
    @portfolio = @student.portfolio
    @earnings_summary = EarningsSummary.new(@portfolio)
  end

  test "should calculate attendance earnings" do
    create(:portfolio_transaction, :deposit, portfolio: @portfolio, amount_cents: 500, reason: :attendance_earnings)
    create(:portfolio_transaction, :deposit, portfolio: @portfolio, amount_cents: 300, reason: :attendance_earnings)

    assert_equal 800, @earnings_summary.attendance_earnings_cents
  end

  test "should calculate reading earnings" do
    create(:portfolio_transaction, :deposit, portfolio: @portfolio, amount_cents: 600, reason: :reading_earnings)

    assert_equal 600, @earnings_summary.reading_earnings_cents
  end

  test "should calculate math earnings" do
    create(:portfolio_transaction, :deposit, portfolio: @portfolio, amount_cents: 400, reason: :math_earnings)
    create(:portfolio_transaction, :deposit, portfolio: @portfolio, amount_cents: 100, reason: :math_earnings)

    assert_equal 500, @earnings_summary.math_earnings_cents
  end

  test "should calculate awards" do
    create(:portfolio_transaction, :deposit, portfolio: @portfolio, amount_cents: 1000, reason: :awards)

    assert_equal 1000, @earnings_summary.awards_cents
  end

  test "should calculate total earnings from all sources" do
    create(:portfolio_transaction, :deposit, portfolio: @portfolio, amount_cents: 500, reason: :attendance_earnings)
    create(:portfolio_transaction, :deposit, portfolio: @portfolio, amount_cents: 600, reason: :reading_earnings)
    create(:portfolio_transaction, :deposit, portfolio: @portfolio, amount_cents: 400, reason: :math_earnings)
    create(:portfolio_transaction, :deposit, portfolio: @portfolio, amount_cents: 1000, reason: :awards)

    assert_equal 2500, @earnings_summary.total_earnings_cents
  end

  test "should calculate transaction fees" do
    create(:portfolio_transaction, :deposit, portfolio: @portfolio, amount_cents: 100, reason: :transaction_fees)
    create(:portfolio_transaction, :deposit, portfolio: @portfolio, amount_cents: 50, reason: :transaction_fees)

    assert_equal 150, @earnings_summary.transaction_fees_cents
  end

  test "should return zero for earnings with no transactions" do
    assert_equal 0, @earnings_summary.attendance_earnings_cents
    assert_equal 0, @earnings_summary.reading_earnings_cents
    assert_equal 0, @earnings_summary.math_earnings_cents
    assert_equal 0, @earnings_summary.awards_cents
    assert_equal 0, @earnings_summary.total_earnings_cents
    assert_equal 0, @earnings_summary.transaction_fees_cents
  end

  test "should only sum deposits not debits" do
    create(:portfolio_transaction, :deposit, portfolio: @portfolio, amount_cents: 500, reason: :math_earnings)
    create(:portfolio_transaction, :debit, portfolio: @portfolio, amount_cents: 200, reason: :math_earnings)

    assert_equal 500, @earnings_summary.math_earnings_cents
  end

  test "should only sum transactions for the specific portfolio" do
    other_student = create(:student)
    other_portfolio = other_student.portfolio

    create(:portfolio_transaction, :deposit, portfolio: @portfolio, amount_cents: 500, reason: :math_earnings)
    create(:portfolio_transaction, :deposit, portfolio: other_portfolio, amount_cents: 1000, reason: :math_earnings)

    assert_equal 500, @earnings_summary.math_earnings_cents
  end
end
