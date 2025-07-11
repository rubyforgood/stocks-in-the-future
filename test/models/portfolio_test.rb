# frozen_string_literal: true

require "test_helper"

class PortfolioTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:portfolio).validate!
  end

  test "#cash_balance" do
    portfolio = create(:portfolio)
    user = portfolio.user

    # should increase cash_balance
    create(:portfolio_transaction, :deposit, portfolio: portfolio, amount_cents: 1000)

    stock = create(:stock, price_cents: 100)

    # pending debit for stock purchase, should decrease cash_balance
    create(:order, :pending, :buy, stock:, shares: 2, user:)

    # pending credit for stock sale, should NOT affect cash_balance
    create(:order, :pending, :sell, stock:, shares: 3, user:)

    # canceled debit for stock purchase, should NOT affect cash_balance
    create(:order, :canceled, :buy, stock:, shares: 1, user:)

    # canceled credit for stock sale, should NOT affect cash_balance
    create(:order, :canceled, :sell, stock:, shares: 4, user:)

    # successful completed stock purchase, should decrease cash_balance
    create(:order, :completed, :buy, stock:, shares: 5, user:)

    # successful completed stock sale, should increase cash_balance
    create(:order, :completed, :sell, stock:, shares: 6, user:)

    # withdrawal from the account, should decrease cash_balance
    create(:portfolio_transaction, :withdrawal, portfolio:, amount_cents: 200)

    result = portfolio.cash_balance
    assert_equal 7.0, result
  end
end
