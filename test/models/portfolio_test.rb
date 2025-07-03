# frozen_string_literal: true

require "test_helper"

class PortfolioTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:portfolio).validate!
  end

  test "#cash_balance" do
    portfolio = create(:portfolio)
    user = portfolio.user

    create(:portfolio_transaction, :deposit, portfolio: portfolio, amount_cents: 1000)

    stock = create(:stock, price_cents: 100)

    # pending debit for stock purchase
    create(:order, :pending, stock:, shares: 2, transaction_type: "buy", user:)

    # pending credit for stock sale
    create(:order, :pending, stock:, shares: 3, user:)

    # canceled debit for stock purchase
    create(:order, :canceled, stock:, shares: 1, transaction_type: "buy", user:)

    # canceled credit for stock sale
    create(:order, :canceled, stock:, shares: 4, transaction_type: "sell", user:)

    # successful completed stock purchase
    create(:order, :completed, stock:, shares: 5, transaction_type: "buy", user:)

    # successful completed stock sale
    create(:order, :completed, stock:, shares: 6, transaction_type: "sell", user:)

    # withdrawal from the account
    create(:portfolio_transaction, :withdrawal, portfolio:, amount_cents: 200)

    result = portfolio.cash_balance
    assert_equal 7.0, result
  end
end
