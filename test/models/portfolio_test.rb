# frozen_string_literal: true

require "test_helper"

class PortfolioTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:portfolio).validate!
  end

  test "#cash_balance" do
    portfolio = create(:portfolio)
    create(:portfolio_transaction, :deposit, portfolio:, amount_cents: 1000)

    # pending debit for stock purchase
    pending_debit_transaction = create(:portfolio_transaction, :debit, portfolio:, amount_cents: 200)
    create(:order, :pending, portfolio_transaction: pending_debit_transaction)

    # pending credit for stock sale
    pending_credit_transaction = create(:portfolio_transaction, :credit, portfolio:, amount_cents: 300)
    create(:order, :pending, portfolio_transaction: pending_credit_transaction)

    # canceled debit for stock purchase
    canceled_debit_transaction = create(:portfolio_transaction, :debit, portfolio:, amount_cents: 100)
    create(:order, :canceled, portfolio_transaction: canceled_debit_transaction)

    # canceled credit for stock sale
    canceled_credit_transaction = create(:portfolio_transaction, :credit, portfolio:, amount_cents: 400)
    create(:order, :canceled, portfolio_transaction: canceled_credit_transaction)

    # successful completed stock purchase
    completed_debit_transaction = create(:portfolio_transaction, :debit, portfolio:, amount_cents: 500)
    create(:order, :completed, portfolio_transaction: completed_debit_transaction)

    # successful completed stock sale
    completed_credit_transaction = create(:portfolio_transaction, :credit, portfolio:, amount_cents: 600)
    create(:order, :completed, portfolio_transaction: completed_credit_transaction)

    # withdrawal from the account
    create(:portfolio_transaction, :withdrawal, portfolio:, amount_cents: 200)

    result = portfolio.cash_balance
    assert_equal 9.0, result
  end
end
