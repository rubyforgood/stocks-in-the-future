# frozen_string_literal: true

require "test_helper"

class OrderExecutionWorkflowTest < ActionDispatch::IntegrationTest
  test "buy order execution updates portfolio correctly" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, classroom: classroom)
    portfolio = student.portfolio
    initial_deposit_cents = 100_000
    create(:portfolio_transaction, :deposit, portfolio: portfolio, amount_cents: initial_deposit_cents)

    stock = create(:stock, ticker: "AAPL", price_cents: 15_000)
    shares_to_buy = 3
    order = create(:order, :pending, :buy, user: student, stock: stock, shares: shares_to_buy)
    purchase_cost_cents = stock.price_cents * shares_to_buy

    # Sanity check: order is pending
    assert order.pending?, "order should be pending before job execution"

    OrderExecutionJob.perform_now

    order.reload
    portfolio.reload

    assert order.completed?, "order should be marked as completed"
    assert_not_nil order.portfolio_transaction, "order should have linked transaction"
    assert_not_nil order.portfolio_stock, "order should have linked portfolio stock"

    assert order.portfolio_transaction.debit?, "buy order should create debit transaction"
    assert_equal purchase_cost_cents, order.portfolio_transaction.amount_cents

    assert_equal shares_to_buy, order.portfolio_stock.shares
    assert_equal stock.id, order.portfolio_stock.stock_id

    # Verify cash balance (cash_balance returns dollars)
    expected_cash_cents = initial_deposit_cents - purchase_cost_cents - PortfolioTransaction::TRANSACTION_FEE_CENTS
    actual_cash_cents = (portfolio.cash_balance * 100).to_i
    assert_equal expected_cash_cents, actual_cash_cents
  end

  test "sell order execution updates portfolio correctly" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, classroom: classroom)
    portfolio = student.portfolio

    stock = create(:stock, ticker: "GOOGL", price_cents: 20_000)
    shares_owned = 10
    shares_to_sell = 4
    create(
      :portfolio_stock, portfolio: portfolio, stock: stock, shares: shares_owned,
                        purchase_price: stock.current_price
    )

    order = create(:order, :pending, :sell, user: student, stock: stock, shares: shares_to_sell)
    sale_proceeds_cents = stock.price_cents * shares_to_sell

    # Sanity check
    assert order.pending?, "order should be pending before job execution"

    OrderExecutionJob.perform_now

    order.reload
    portfolio.reload

    assert order.completed?, "order should be marked as completed"
    assert order.portfolio_transaction.credit?, "sell order should create credit transaction"
    assert_equal sale_proceeds_cents, order.portfolio_transaction.amount_cents
    assert_equal(-shares_to_sell, order.portfolio_stock.shares, "sell order should create negative shares record")

    remaining_shares = portfolio.shares_owned(stock.id).to_i
    assert_equal shares_owned - shares_to_sell, remaining_shares
  end

  test "multiple orders in single job run with single fee per user" do
    classroom = create(:classroom, :with_trading)

    student1 = create(:student, classroom: classroom)
    create(:portfolio_transaction, :deposit, portfolio: student1.portfolio, amount_cents: 200_000)

    student2 = create(:student, classroom: classroom)
    create(:portfolio_transaction, :deposit, portfolio: student2.portfolio, amount_cents: 200_000)

    stock = create(:stock, ticker: "AAPL", price_cents: 10_000)

    order1_s1 = create(:order, :pending, :buy, user: student1, stock: stock, shares: 2)
    order2_s1 = create(:order, :pending, :buy, user: student1, stock: stock, shares: 1)
    order1_s2 = create(:order, :pending, :buy, user: student2, stock: stock, shares: 3)

    # Sanity checks
    assert order1_s1.pending?
    assert order2_s1.pending?
    assert order1_s2.pending?
    assert_equal 0, student1.portfolio.portfolio_transactions.fees.count
    assert_equal 0, student2.portfolio.portfolio_transactions.fees.count

    OrderExecutionJob.perform_now

    [order1_s1, order2_s1, order1_s2].each do |order|
      order.reload
      assert order.completed?, "all orders should be completed"
    end

    student1.portfolio.reload
    student2.portfolio.reload

    # Each user should have exactly 1 fee transaction, regardless of order count
    assert_equal 1, student1.portfolio.portfolio_transactions.fees.count, "student1 should have exactly 1 fee"
    assert_equal 1, student2.portfolio.portfolio_transactions.fees.count, "student2 should have exactly 1 fee"
    assert_equal PortfolioTransaction::TRANSACTION_FEE_CENTS,
                 student1.portfolio.portfolio_transactions.fees.sum(:amount_cents)

    s1_purchase_cost_cents = stock.price_cents * 3 # 2 + 1 shares
    s1_expected_cash_cents = 200_000 - s1_purchase_cost_cents - PortfolioTransaction::TRANSACTION_FEE_CENTS
    s1_actual_cash_cents = (student1.portfolio.cash_balance * 100).to_i
    assert_equal s1_expected_cash_cents, s1_actual_cash_cents

    s2_purchase_cost_cents = stock.price_cents * 3
    s2_expected_cash_cents = 200_000 - s2_purchase_cost_cents - PortfolioTransaction::TRANSACTION_FEE_CENTS
    s2_actual_cash_cents = (student2.portfolio.cash_balance * 100).to_i
    assert_equal s2_expected_cash_cents, s2_actual_cash_cents
  end

  test "mixed buy and sell orders execute correctly" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, classroom: classroom)
    portfolio = student.portfolio
    initial_deposit_cents = 100_000
    create(:portfolio_transaction, :deposit, portfolio: portfolio, amount_cents: initial_deposit_cents)

    stock1 = create(:stock, ticker: "AAPL", price_cents: 10_000)
    stock2 = create(:stock, ticker: "GOOGL", price_cents: 20_000)

    initial_stock2_shares = 5
    create(
      :portfolio_stock, portfolio: portfolio, stock: stock2, shares: initial_stock2_shares,
                        purchase_price: stock2.current_price
    )

    buy_shares = 2
    sell_shares = 3
    buy_order = create(:order, :pending, :buy, user: student, stock: stock1, shares: buy_shares)
    sell_order = create(:order, :pending, :sell, user: student, stock: stock2, shares: sell_shares)

    # Sanity checks
    assert buy_order.pending?
    assert sell_order.pending?

    buy_cost_cents = stock1.price_cents * buy_shares
    sell_proceeds_cents = stock2.price_cents * sell_shares

    OrderExecutionJob.perform_now

    buy_order.reload
    sell_order.reload
    portfolio.reload

    assert buy_order.completed?, "buy order should be completed"
    assert sell_order.completed?, "sell order should be completed"

    assert_equal buy_shares, portfolio.shares_owned(stock1.id).to_i
    assert_equal initial_stock2_shares - sell_shares, portfolio.shares_owned(stock2.id).to_i

    # Cash = initial + sell proceeds - buy cost - fee
    expected_cash_cents = initial_deposit_cents + sell_proceeds_cents - buy_cost_cents - PortfolioTransaction::TRANSACTION_FEE_CENTS
    actual_cash_cents = (portfolio.cash_balance * 100).to_i
    assert_equal expected_cash_cents, actual_cash_cents
  end
end
