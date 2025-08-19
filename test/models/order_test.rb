# frozen_string_literal: true

require "test_helper"

class OrderTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:order).validate!
  end

  test ".pending" do
    order1 = create(:order, :pending)
    create(:order, :completed)
    create(:order, :canceled)
    order4 = create(:order, :pending)

    assert_equal [order1, order4], Order.pending
  end

  test ".completed" do
    order1 = create(:order, :completed)
    create(:order, :pending)
    create(:order, :canceled)
    order4 = create(:order, :completed)

    assert_equal [order1, order4], Order.completed
  end

  test ".canceled" do
    order1 = create(:order, :canceled)
    create(:order, :pending)
    create(:order, :completed)
    order4 = create(:order, :canceled)

    assert_equal [order1, order4], Order.canceled
  end

  test "#purchase_cost" do
    stock = create(:stock, price_cents: 1_000)
    order = create(:order, stock:, shares: 5.1)

    result = order.purchase_cost

    assert_equal 5_100, result
  end

  test "creates a debit portfolio transaction on buy" do
    user = create(:student)
    user.portfolio.portfolio_transactions.create!(amount_cents: 5000, transaction_type: :deposit) # $50.00
    stock = create(:stock, price_cents: 1_000)
    order = build(:order, user:, stock:, shares: 2.5, transaction_type: "buy")

    assert_difference "PortfolioTransaction.count", 1 do
      order.save!
    end

    transaction = PortfolioTransaction.last
    assert_equal user.portfolio, transaction.portfolio
    assert_equal 2_500, transaction.amount_cents
    assert_equal "debit", transaction.transaction_type
    assert_equal order, transaction.order
  end

  test "sell order validation allows selling when sufficient shares owned" do
    user = create(:student)
    portfolio = create(:portfolio, user: user)
    stock = create(:stock, price_cents: 1_000)

    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 10, purchase_price: 200.0)

    order = build(:order, user: user, stock: stock, shares: 5, transaction_type: "sell")

    assert order.valid?
  end

  test "sell order validation prevents selling more shares than owned" do
    user = create(:student)
    portfolio = create(:portfolio, user: user)
    stock = create(:stock, price_cents: 1_000)

    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 5, purchase_price: 200.0)

    order = build(:order, user: user, stock: stock, shares: 10, transaction_type: "sell")

    assert_not order.valid?
    assert_includes order.errors[:shares], "Cannot sell more shares than you own (5 available)"
  end

  test "sell order validation prevents selling when no shares owned" do
    user = create(:student)
    create(:portfolio, user: user)
    stock = create(:stock, price_cents: 1_000)

    # User owns 0 shares
    order = build(:order, user: user, stock: stock, shares: 1, transaction_type: "sell")

    assert_not order.valid?
    assert_includes order.errors[:shares], "Cannot sell more shares than you own (0 available)"
  end

  test "sell order validation with multiple portfolio_stock records" do
    user = create(:student)
    portfolio = create(:portfolio, user: user)
    stock = create(:stock, price_cents: 1_000)

    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 10, purchase_price: 200.0)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 5, purchase_price: 250.0)

    order = build(:order, user: user, stock: stock, shares: 12, transaction_type: "sell")
    assert order.valid?

    order = build(:order, user: user, stock: stock, shares: 20, transaction_type: "sell")
    assert_not order.valid?
    assert_includes order.errors[:shares], "Cannot sell more shares than you own (15 available)"
  end

  test "buy order validation is not affected by sell validation" do
    user = create(:student)
    portfolio = create(:portfolio, user: user)
    portfolio.portfolio_transactions.create!(amount_cents: 15_000, transaction_type: :deposit) # $150.00
    stock = create(:stock, price_cents: 1_000)

    order = build(:order, user: user, stock: stock, shares: 10, transaction_type: "buy")

    assert order.valid?
  end

  test "creates a credit portfolio transaction on sell" do
    user = create(:student)
    stock = create(:stock, price_cents: 1_000)
    create(:portfolio_stock, portfolio: user.portfolio, stock: stock, shares: 5, purchase_price: 800)

    order = build(:order, user:, stock:, shares: 2.5, transaction_type: "sell")

    assert_difference "PortfolioTransaction.count", 1 do
      order.save!
    end

    transaction = PortfolioTransaction.last
    assert_equal user.portfolio, transaction.portfolio
    assert_equal 2_500, transaction.amount_cents
    assert_equal "credit", transaction.transaction_type
    assert_equal order, transaction.order
  end

  test "buy order validation prevents buying when insufficient funds" do
    user = create(:student)
    portfolio = create(:portfolio, user: user)
    portfolio.portfolio_transactions.create!(amount_cents: 100, transaction_type: :deposit) # Only $1.00

    stock = create(:stock, price_cents: 1000) # $10.00 per share
    order = build(:order, user: user, stock: stock, shares: 5, transaction_type: "buy") # Needs $50.00

    assert_not order.valid?
    assert_includes order.errors[:shares], "Insufficient funds. You have $1.00 but need $50.00"
  end

  test "buy order validation allows buying when sufficient funds" do
    user = create(:student)
    portfolio = create(:portfolio, user: user)
    portfolio.portfolio_transactions.create!(amount_cents: 10_000, transaction_type: :deposit) # $100.00

    stock = create(:stock, price_cents: 1000) # $10.00 per share
    order = build(:order, user: user, stock: stock, shares: 5, transaction_type: "buy") # Needs $50.00

    assert order.valid?
  end
end
