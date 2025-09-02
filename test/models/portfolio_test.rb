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

    # This simulates previous completed purchases
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 20, purchase_price: 100)

    # pending debit for stock purchase, should decrease cash_balance
    pending_buy_order = create(:order, :pending, :buy, stock: stock, shares: 2, user: user)
    create(:portfolio_transaction, :debit, portfolio: portfolio, amount_cents: 200, order: pending_buy_order) # -$2.00

    # pending credit for stock sale, should NOT affect cash_balance
    create(:order, :pending, :sell, stock:, shares: 3, user:)

    # canceled debit for stock purchase, should NOT affect cash_balance
    create(:order, :canceled, :buy, stock:, shares: 1, user:)

    # canceled credit for stock sale, should NOT affect cash_balance
    create(:order, :canceled, :sell, stock:, shares: 4, user:)

    # successful completed stock purchase, should decrease cash_balance
    buy_order = create(:order, :completed, :buy, stock: stock, shares: 5, user: user)
    create(:portfolio_transaction, :debit, portfolio: portfolio, amount_cents: 500, order: buy_order) # -$5.00
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 5, purchase_price: 100)

    # successful completed stock sale, should increase cash_balance
    sell_order = create(:order, :completed, :sell, stock: stock, shares: 6, user: user)
    create(:portfolio_transaction, :credit, portfolio: portfolio, amount_cents: 600, order: sell_order) # +$6.00
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: -6, purchase_price: 100)

    # withdrawal from the account, should decrease cash_balance
    create(:portfolio_transaction, :withdrawal, portfolio:, amount_cents: 200)

    result = portfolio.cash_balance
    assert_equal 7.0, result
  end

  test "#cash_balance with transactions without orders" do
    portfolio = create(:portfolio)
    credit_transaction = create(:portfolio_transaction, :credit, portfolio: portfolio, amount_cents: 1000)
    debit_transaction = create(:portfolio_transaction, :debit, portfolio: portfolio, amount_cents: 500)

    create(:portfolio_transaction, :deposit, portfolio: portfolio, amount_cents: 2000)
    # expected balance = (2000 + 1000 - 500) / 100.0 = 25.0
    result = portfolio.cash_balance
    assert_equal 25.0, result

    assert credit_transaction.completed?
    assert debit_transaction.completed?
  end
end
