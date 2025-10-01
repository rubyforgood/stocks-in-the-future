# frozen_string_literal: true

require "test_helper"

class PortfolioTransactionTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:portfolio_transaction).validate!
  end

  test ".deposits" do
    transaction1 = create(:portfolio_transaction, :deposit)
    create(:portfolio_transaction, :debit)
    create(:portfolio_transaction, :credit)
    transaction4 = create(:portfolio_transaction, :deposit)

    assert_equal [transaction1, transaction4], PortfolioTransaction.deposits
  end

  test ".debits" do
    transaction1 = create(:portfolio_transaction, :debit)
    create(:portfolio_transaction, :deposit)
    create(:portfolio_transaction, :credit)
    transaction4 = create(:portfolio_transaction, :debit)

    assert_equal [transaction1, transaction4], PortfolioTransaction.debits
  end

  test ".credits" do
    transaction1 = create(:portfolio_transaction, :credit)
    create(:portfolio_transaction, :deposit)
    create(:portfolio_transaction, :debit)
    transaction4 = create(:portfolio_transaction, :credit)

    assert_equal [transaction1, transaction4], PortfolioTransaction.credits
  end

  test ".withdrawals" do
    transaction1 = create(:portfolio_transaction, :withdrawal)
    create(:portfolio_transaction, :deposit)
    create(:portfolio_transaction, :debit)
    transaction4 = create(:portfolio_transaction, :withdrawal)

    assert_equal [transaction1, transaction4], PortfolioTransaction.withdrawals
  end

  test "reasons constant values" do
    assert_equal "Earnings from Math", PortfolioTransaction::REASONS[:math_earnings]
    assert_equal "Earnings from Reading", PortfolioTransaction::REASONS[:reading_earnings]
    assert_equal "Earnings from Attendance", PortfolioTransaction::REASONS[:attendance_earnings]
    assert_equal "Earnings from Grades", PortfolioTransaction::REASONS[:grade_earnings]
    assert_equal "Transaction Fees", PortfolioTransaction::REASONS[:transaction_fees]
    assert_equal "Award", PortfolioTransaction::REASONS[:awards]
  end
end
