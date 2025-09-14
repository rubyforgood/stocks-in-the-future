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
    create(:portfolio_transaction, :deposit, portfolio: portfolio, amount_cents: 10_00)

    stock = create(:stock, price_cents: 100)

    # This simulates previous completed purchases
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 20, purchase_price: 100)

    # pending debit for stock purchase, should decrease cash_balance
    # -$2.00 - $1.00 fee = -$3.00
    create(:order, :pending, :buy, stock: stock, shares: 2, user: user)

    # pending credit for stock sale, should NOT affect cash_balance
    create(:order, :pending, :sell, stock:, shares: 3, user:)

    # canceled debit for stock purchase, should NOT affect cash_balance
    create(:order, :canceled, :buy, stock:, shares: 1, user:)

    # canceled credit for stock sale, should NOT affect cash_balance
    create(:order, :canceled, :sell, stock:, shares: 4, user:)

    # successful completed stock purchase, should decrease cash_balance
    # -$5.00
    buy_order = create(:order, :completed, :buy, stock: stock, shares: 5, user: user)
    create(:portfolio_transaction, :debit, portfolio: portfolio, amount_cents: 5_00,
                                           order: buy_order)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 5, purchase_price: 100)

    # successful completed stock sale, should increase cash_balance
    #  # +$6.00
    sell_order = create(:order, :completed, :sell, stock: stock, shares: 6, user: user)
    create(:portfolio_transaction, :credit, portfolio: portfolio, amount_cents: 6_00,
                                            order: sell_order)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: -6, purchase_price: 100)

    # withdrawal from the account, should decrease cash_balance
    create(:portfolio_transaction, :withdrawal, portfolio:, amount_cents: 2_00) # -$2.00

    # fee, should decrease cash_balance
    # -$1.00
    create(:portfolio_transaction, :fee, portfolio:, amount_cents: 1_00)

    # expected balance = (10.00 - 3.00 - 5.00 + 6.00 - 2.00 - 1.00) = 5.00
    result = portfolio.cash_balance
    assert_equal 5.0, result
  end

  test "#shares_owned with single purchase" do
    portfolio = create(:portfolio)
    stock = create(:stock)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 15, purchase_price: 200.0)

    result = portfolio.shares_owned(stock.id)
    assert_equal 15, result
  end

  test "#shares_owned with multiple purchases aggregates correctly" do
    portfolio = create(:portfolio)
    stock = create(:stock)

    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 10, purchase_price: 200.0)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 5, purchase_price: 250.0)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 3, purchase_price: 300.0)

    result = portfolio.shares_owned(stock.id)
    assert_equal 18, result # 10 + 5 + 3
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

  test "#shares_owned with buy and sell orders" do
    portfolio = create(:portfolio)
    stock = create(:stock)

    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 20, purchase_price: 200.0)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: -7, purchase_price: 250.0)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 3, purchase_price: 300.0)

    result = portfolio.shares_owned(stock.id)
    assert_equal 16, result # 20 - 7 + 3
  end

  test "#shares_owned returns 0 when no shares owned" do
    portfolio = create(:portfolio)
    stock = create(:stock)

    result = portfolio.shares_owned(stock.id)
    assert_equal 0, result
  end

  test "#shares_owned with different stocks" do
    portfolio = create(:portfolio)
    stock1 = create(:stock)
    stock2 = create(:stock)

    create(:portfolio_stock, portfolio: portfolio, stock: stock1, shares: 10, purchase_price: 200.0)
    create(:portfolio_stock, portfolio: portfolio, stock: stock2, shares: 5, purchase_price: 300.0)

    assert_equal 10, portfolio.shares_owned(stock1.id)
    assert_equal 5, portfolio.shares_owned(stock2.id)
  end
end
