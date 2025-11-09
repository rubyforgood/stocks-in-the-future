# frozen_string_literal: true

require "test_helper"

class EarningsSummaryTest < ActiveSupport::TestCase
  test "returns empty array when there are no fee transactions" do
    portfolio = create(:portfolio)
    # Create transactions with different types (not fee)
    create(:portfolio_transaction, :deposit, portfolio: portfolio)
    create(:portfolio_transaction, :debit, portfolio: portfolio)

    result = EarningsSummary.new(portfolio).earnings_breakdown
    assert_equal [], result
  end

  test "returns earnings breakdown for single reason" do
    portfolio = create(:portfolio)
    create(:portfolio_transaction, portfolio: portfolio, transaction_type: :fee,
                                   reason: "math_earnings", amount_cents: 100)
    create(:portfolio_transaction, portfolio: portfolio, transaction_type: :fee,
                                   reason: "math_earnings", amount_cents: 150)

    result = EarningsSummary.new(portfolio).earnings_breakdown

    assert_equal 1, result.size
    assert_equal "math_earnings", result.first[:reason]
    assert_equal "Earnings from Math", result.first[:reason_humanized]
    assert_equal 250, result.first[:total_cents]
    assert_in_delta 2.50, result.first[:total], 0.0001
  end

  test "returns earnings breakdown for multiple reasons" do
    portfolio = create(:portfolio)
    create(:portfolio_transaction, portfolio: portfolio, transaction_type: :fee,
                                   reason: "math_earnings", amount_cents: 100)
    create(:portfolio_transaction, portfolio: portfolio, transaction_type: :fee,
                                   reason: "reading_earnings", amount_cents: 200)
    create(:portfolio_transaction, portfolio: portfolio, transaction_type: :fee,
                                   reason: "attendance_earnings", amount_cents: 300)

    result = EarningsSummary.new(portfolio).earnings_breakdown

    assert_equal 3, result.size

    math_entry = result.find { |h| h[:reason] == "math_earnings" }
    assert_equal "Earnings from Math", math_entry[:reason_humanized]
    assert_equal 100, math_entry[:total_cents]
    assert_in_delta 1.00, math_entry[:total], 0.0001

    reading_entry = result.find { |h| h[:reason] == "reading_earnings" }
    assert_equal "Earnings from Reading", reading_entry[:reason_humanized]
    assert_equal 200, reading_entry[:total_cents]
    assert_in_delta 2.00, reading_entry[:total], 0.0001

    attendance_entry = result.find { |h| h[:reason] == "attendance_earnings" }
    assert_equal "Earnings from Attendance", attendance_entry[:reason_humanized]
    assert_equal 300, attendance_entry[:total_cents]
    assert_in_delta 3.00, attendance_entry[:total], 0.0001
  end

  test "humanizes unknown reason when not in REASONS constant" do
    portfolio = create(:portfolio)
    create(:portfolio_transaction, portfolio: portfolio, transaction_type: :fee,
                                   reason: "custom_bonus", amount_cents: 500)

    result = EarningsSummary.new(portfolio).earnings_breakdown

    assert_equal 1, result.size
    assert_equal "custom_bonus", result.first[:reason]
    assert_equal "Custom bonus", result.first[:reason_humanized]
    assert_equal 500, result.first[:total_cents]
    assert_in_delta 5.00, result.first[:total], 0.0001
  end

  test "only includes transactions for specified portfolio" do
    portfolio1 = create(:portfolio)
    portfolio2 = create(:portfolio)

    create(:portfolio_transaction, portfolio: portfolio1, transaction_type: :fee,
                                   reason: "math_earnings", amount_cents: 100)
    create(:portfolio_transaction, portfolio: portfolio2, transaction_type: :fee,
                                   reason: "math_earnings", amount_cents: 200)

    result = EarningsSummary.new(portfolio1).earnings_breakdown

    assert_equal 1, result.size
    assert_equal 100, result.first[:total_cents]
  end

  test "groups and sums transactions by reason correctly" do
    portfolio = create(:portfolio)
    create(:portfolio_transaction, portfolio: portfolio, transaction_type: :fee,
                                   reason: "awards", amount_cents: 100)
    create(:portfolio_transaction, portfolio: portfolio, transaction_type: :fee,
                                   reason: "awards", amount_cents: 250)
    create(:portfolio_transaction, portfolio: portfolio, transaction_type: :fee,
                                   reason: "awards", amount_cents: 150)

    result = EarningsSummary.new(portfolio).earnings_breakdown

    assert_equal 1, result.size
    assert_equal "Award", result.first[:reason_humanized]
    assert_equal 500, result.first[:total_cents]
    assert_in_delta 5.00, result.first[:total], 0.0001
  end

  test "handles all defined reasons from REASONS constant" do
    portfolio = create(:portfolio)
    PortfolioTransaction::REASONS.each_key do |key|
      create(:portfolio_transaction, portfolio: portfolio, transaction_type: :fee,
                                     reason: key.to_s, amount_cents: 100)
    end

    result = EarningsSummary.new(portfolio).earnings_breakdown

    assert_equal PortfolioTransaction::REASONS.size, result.size

    PortfolioTransaction::REASONS.each do |key, label|
      entry = result.find { |h| h[:reason] == key.to_s }
      assert_not_nil entry, "Missing entry for #{key}"
      assert_equal label, entry[:reason_humanized]
      assert_equal 100, entry[:total_cents]
    end
  end
end
