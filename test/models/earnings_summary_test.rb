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

  # The test that was missing, and the reason this went unnoticed: the one above builds its own fees as
  # **deposits**, which agrees with the query rather than with the app. The trading fee is written by
  # `TransactionFeeProcessor` with `transaction_type: :fee`, so run the writer and read the summary.
  #
  # Measured before the fix: this returned 0 for every real fee ever charged, on the student's own portfolio
  # page as well as the admin one, while `Portfolio#total_fees` had been charging them to the balance all
  # along - the money was right and only the line item was silent.
  test "a fee charged by the fee processor is counted" do
    create(:portfolio_transaction, :deposit, portfolio: @portfolio, amount_cents: 50_000)
    stock = create(:stock, price_cents: 1_000)
    order = create(:order, user: @student, stock:, shares: 1, status: :pending, action: :buy)

    TransactionFeeProcessor.execute([order])

    assert_equal PortfolioTransaction::TRANSACTION_FEE_CENTS, @earnings_summary.transaction_fees_cents
    # `send`, because `total_fees` is private - and calling the real method is the point: reproducing its
    # query here would be a second definition of the thing this assertion exists to keep in step.
    assert_equal @portfolio.send(:total_fees), @earnings_summary.transaction_fees_cents,
                 "the fee the balance charges and the fee the summary shows have to be the same number"
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
