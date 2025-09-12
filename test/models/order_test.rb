# frozen_string_literal: true

require "test_helper"

class OrderTest < ActiveSupport::TestCase
  test "factory" do
    user = create(:student)
    stock = create(:stock)
    create(:portfolio_stock, portfolio: user.portfolio, stock: stock, shares: 10)

    order = create(:order, user: user, stock: stock, shares: 1, action: :sell)
    assert order.valid?
  end

  test "defaults to pending status when created" do
    user = create(:student)
    stock = create(:stock)
    create(:portfolio_stock, portfolio: user.portfolio, stock: stock, shares: 10)

    order = create(:order, user: user, stock: stock, shares: 1, action: :sell)

    assert_equal "pending", order.status
  end

  test ".pending" do
    user = create(:student)
    stock = create(:stock)
    create(:portfolio_stock, portfolio: user.portfolio, stock: stock, shares: 10)

    order1 = create(:order, status: :pending, action: :sell, user: user, stock: stock, shares: 1)
    create(:order, status: :completed, action: :sell, user: user, stock: stock, shares: 1)
    create(:order, status: :canceled, action: :sell, user: user, stock: stock, shares: 1)
    order4 = create(:order, status: :pending, action: :sell, user: user, stock: stock, shares: 1)

    assert_equal [order1, order4], Order.pending
  end

  test ".completed" do
    user = create(:student)
    stock = create(:stock)
    create(:portfolio_stock, portfolio: user.portfolio, stock: stock, shares: 10)

    order1 = create(:order, status: :completed, action: :sell, user: user, stock: stock, shares: 1)
    create(:order, status: :pending, action: :sell, user: user, stock: stock, shares: 1)
    create(:order, status: :canceled, action: :sell, user: user, stock: stock, shares: 1)
    order4 = create(:order, status: :completed, action: :sell, user: user, stock: stock, shares: 1)

    assert_equal [order1, order4], Order.completed
  end

  test ".canceled" do
    user = create(:student)
    stock = create(:stock)
    create(:portfolio_stock, portfolio: user.portfolio, stock: stock, shares: 10)

    order1 = create(:order, status: :canceled, action: :sell, user: user, stock: stock, shares: 1)
    create(:order, status: :pending, action: :sell, user: user, stock: stock, shares: 1)
    create(:order, status: :completed, action: :sell, user: user, stock: stock, shares: 1)
    order4 = create(:order, status: :canceled, action: :sell, user: user, stock: stock, shares: 1)

    assert_equal [order1, order4], Order.canceled
  end

  test "cannot buy archived stocks" do
    user = create(:student)
    stock = create(:stock, archived: true)

    order = build(:order, action: :buy, user: user, stock: stock, shares: 1)

    assert_not order.valid?
    assert_includes order.errors[:stock], "Cannot purchase shares of archived stocks"
  end

  test "can sell archived stocks" do
    user = create(:student)
    stock = create(:stock, archived: true)
    create(:portfolio_stock, portfolio: user.portfolio, stock: stock, shares: 10)

    order = build(:order, action: :sell, user: user, stock: stock, shares: 1)

    assert order.valid?
  end

  test "#purchase_cost for buy order includes additive transaction fee" do
    user = create(:student)
    stock = create(:stock, price_cents: 1_000)
    # Add funds for buy order
    user.portfolio.portfolio_transactions.create!(amount_cents: 10_000, transaction_type: :deposit)

    order = create(:order, action: :buy, user: user, stock: stock, shares: 5.1, transaction_fee_cents: 100)

    assert_equal 5_200, order.purchase_cost
  end

  test "#purchase_cost for sell order includes negative transaction fee" do
    user = create(:student)
    stock = create(:stock, price_cents: 1_000)
    create(:portfolio_stock, portfolio: user.portfolio, stock: stock, shares: 10)

    order = create(:order, action: :sell, user: user, stock: stock, shares: 5, transaction_fee_cents: 100)

    assert_equal 4_900, order.purchase_cost
  end

  test "creates a buy order without portfolio transaction" do
    user = create(:student)
    user.portfolio.portfolio_transactions.create!(amount_cents: 5000, transaction_type: :deposit) # $50.00
    stock = create(:stock, price_cents: 1_000)
    order = build(:order, action: :buy, user: user, stock: stock, shares: 2.5)

    assert_difference "PortfolioTransaction.count", 0 do
      order.save!
    end

    assert_equal "buy", order.action
    assert order.buy?
  end

  test "sell order validation allows selling when sufficient shares owned" do
    user = create(:student)
    portfolio = create(:portfolio, user: user)
    stock = create(:stock, price_cents: 1_000)

    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 10, purchase_price: 200.0)

    order = build(:order, action: :sell, user: user, stock: stock, shares: 5)

    assert order.valid?
  end

  test "sell order validation prevents selling more shares than owned" do
    user = create(:student)
    portfolio = create(:portfolio, user: user)
    stock = create(:stock, price_cents: 1_000)

    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 5, purchase_price: 200.0)

    order = build(:order, action: :sell, user: user, stock: stock, shares: 10)

    assert_not order.valid?
    assert_includes order.errors[:shares], "Cannot sell more shares than you own (5 available)"
  end

  test "sell order validation prevents selling when no shares owned" do
    user = create(:student)
    create(:portfolio, user: user)
    stock = create(:stock, price_cents: 1_000)

    order = build(:order, action: :sell, user: user, stock: stock, shares: 1)

    assert_not order.valid?
    assert_includes order.errors[:shares], "Cannot sell more shares than you own (0 available)"
  end

  test "sell order validation with multiple portfolio_stock records" do
    user = create(:student)
    portfolio = create(:portfolio, user: user)
    stock = create(:stock, price_cents: 1_000)

    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 10, purchase_price: 200.0)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 5, purchase_price: 250.0)

    order = build(:order, action: :sell, user: user, stock: stock, shares: 12)
    assert order.valid?

    order = build(:order, action: :sell, user: user, stock: stock, shares: 20)
    assert_not order.valid?
    assert_includes order.errors[:shares], "Cannot sell more shares than you own (15 available)"
  end

  test "buy order validation is not affected by sell validation" do
    user = create(:student)
    portfolio = create(:portfolio, user: user)
    portfolio.portfolio_transactions.create!(amount_cents: 15_000, transaction_type: :deposit) # $150.00
    stock = create(:stock, price_cents: 1_000)

    order = build(:order, :buy, user: user, stock: stock, shares: 10)

    assert order.valid?
  end

  test "creates a sell order without portfolio transaction" do
    user = create(:student)
    stock = create(:stock, price_cents: 1_000)
    create(:portfolio_stock, portfolio: user.portfolio, stock: stock, shares: 5, purchase_price: 800)

    order = build(:order, action: :sell, user: user, stock: stock, shares: 2.5)

    assert_difference "PortfolioTransaction.count", 0 do
      order.save!
    end

    assert_equal "sell", order.action
    assert order.sell?
  end

  test "buy order validation prevents buying when insufficient funds" do
    user = create(:student)
    portfolio = create(:portfolio, user: user)
    portfolio.portfolio_transactions.create!(amount_cents: 100, transaction_type: :deposit)

    stock = create(:stock, price_cents: 1000)
    order = build(:order, action: :buy, user: user, stock: stock, shares: 5, transaction_fee_cents: 100)

    assert_not order.valid?
    assert_includes order.errors[:shares], "Insufficient funds. You have $1.00 but need $51.00"
  end

  test "buy order validation prevents buying when insufficient funds with fee" do
    user = create(:student)
    portfolio = create(:portfolio, user: user)
    portfolio.portfolio_transactions.create!(amount_cents: 1_00, transaction_type: :deposit)

    stock = create(:stock, price_cents: 50)
    order = build(:order, action: :buy, user: user, stock: stock, shares: 2, transaction_fee_cents: 100)

    assert_not order.valid?
    assert_includes order.errors[:shares], "Insufficient funds. You have $1.00 but need $2.00"
  end

  test "buy order validation allows buying when sufficient funds" do
    user = create(:student)
    portfolio = create(:portfolio, user: user)
    portfolio.portfolio_transactions.create!(amount_cents: 10_000, transaction_type: :deposit)

    stock = create(:stock, price_cents: 1000)
    order = build(:order, action: :buy, user: user, stock: stock, shares: 5)

    assert order.valid?
  end

  test "update order allows user to update pending buy order when transaction amount less than portfolio value" do
    user = create(:student)
    portfolio = create(:portfolio, user: user)
    portfolio.portfolio_transactions.create!(amount_cents: 100_00, transaction_type: :deposit)

    stock = create(:stock, price_cents: 10_00)
    order = build(:order, action: :buy, user: user, stock: stock, shares: 5)

    assert_difference "PortfolioTransaction.count", 0 do
      order.save!
    end

    assert order.valid?

    # NOTE: PortfolioTransaction updates are handled by PurchaseStock service
    order.update!(shares: 6)
    assert_equal 6, order.shares
  end

  test "update order does not allow user to update pending buy order when transaction amount exceeds portfolio value" do
    user = create(:student)
    portfolio = create(:portfolio, user: user)
    portfolio.portfolio_transactions.create!(amount_cents: 10_000, transaction_type: :deposit)

    stock = create(:stock, price_cents: 1000)
    order = build(:order, action: :buy, user: user, stock: stock, shares: 5, transaction_fee_cents: 100)

    assert_difference "PortfolioTransaction.count", 0 do
      order.save!
    end

    order.shares = 12

    assert_not order.valid?
    assert_includes order.errors[:shares], "Insufficient funds. You have $100.00 but need $121.00"
  end

  test "order is invalid when transaction fee causes total cost to exceed portfolio value" do
    user = create(:student)
    portfolio = create(:portfolio, user: user)
    portfolio.portfolio_transactions.create!(amount_cents: 2_00, transaction_type: :deposit)

    stock = create(:stock, price_cents: 1_00)
    order = build(:order, action: :buy, user: user, stock: stock, shares: 1, transaction_fee_cents: 100)

    assert_no_difference "PortfolioTransaction.count" do
      order.save!
    end

    order.shares = 2

    assert_not order.valid?
    assert_includes order.errors[:shares], "Insufficient funds. You have $2.00 but need $3.00"
  end

  test "update order allows user to update pending sell order when shares less than portfolio value" do
    user = create(:student)
    stock = create(:stock, price_cents: 1_000)
    create(:portfolio_stock, portfolio: user.portfolio, stock: stock, shares: 5, purchase_price: 800)

    order = build(:order, action: :sell, user: user, stock: stock, shares: 2.5)

    assert_difference "PortfolioTransaction.count", 0 do
      order.save!
    end

    order.update!(shares: 3)
    assert_equal 3, order.shares
  end

  test "update order prevents overselling shares when updating sell order" do
    user = create(:student)
    stock = create(:stock, price_cents: 1_000)
    create(:portfolio_stock, portfolio: user.portfolio, stock: stock, shares: 5, purchase_price: 1_000)

    order = build(:order, action: :sell, user: user, stock: stock, shares: 2)
    order.save!

    order.shares = 6

    assert_not order.valid?
    assert_includes order.errors[:shares], "Cannot sell more shares than you own (5 available)"
  end

  test "validations handle invalid shares safely without exceptions" do
    user = create(:student)
    stock = create(:stock)
    user.portfolio.portfolio_transactions.create!(amount_cents: 10_000, transaction_type: :deposit)

    [nil, "", "not_a_number"].each do |invalid_shares|
      buy_order = build(:order, action: :buy, user: user, stock: stock, shares: invalid_shares)
      sell_order = build(:order, action: :sell, user: user, stock: stock, shares: invalid_shares)

      assert_nothing_raised do
        assert_equal false, buy_order.valid?
        assert_equal false, sell_order.valid?
      end
      assert buy_order.errors[:shares].any?
      assert sell_order.errors[:shares].any?
    end
  end
end
