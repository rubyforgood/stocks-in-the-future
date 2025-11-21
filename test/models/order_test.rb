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

  test "#purchase_cost" do
    user = create(:student)
    stock = create(:stock, price_cents: 1_000)
    # Add funds for buy order
    user.portfolio.portfolio_transactions.create!(amount_cents: 10_000, transaction_type: :deposit)

    order = create(:order, action: :buy, user: user, stock: stock, shares: 5.1)

    assert_equal 5_100, order.purchase_cost
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
    order = build(:order, action: :buy, user: user, stock: stock, shares: 5)

    assert_not order.valid?
    assert_includes order.errors[:shares], "Insufficient funds. You have $1.00 but need $51.00"
  end

  test "buy order validation prevents buying if not enough funds to cover stocks and transaction fee" do
    user = create(:student)
    portfolio = create(:portfolio, user: user)
    portfolio.portfolio_transactions.create!(amount_cents: 10_00, transaction_type: :deposit)

    stock = create(:stock, price_cents: 10_00)
    order = build(:order, action: :buy, user: user, stock: stock, shares: 1)

    assert_not order.valid?(:create)
    assert_includes order.errors[:shares], "Insufficient funds. You have $10.00 but need $11.00"
  end

  test "buy order validation allows buying if enough funds when multiple orders share transaction fees" do
    user = create(:student)
    portfolio = create(:portfolio, user: user)
    portfolio.portfolio_transactions.create!(amount_cents: 21_00, transaction_type: :deposit)

    stock = create(:stock, price_cents: 10_00)
    pending_order = build(:order, :pending, action: :buy, user: user, stock: stock, shares: 1)
    assert_nothing_raised do
      pending_order.save!
    end

    order = build(:order, action: :buy, user: user, stock: stock, shares: 1)

    assert order.valid?(:create)
  end

  test "buy order validation allows buying when sufficient funds" do
    user = create(:student)
    portfolio = create(:portfolio, user: user)
    portfolio.portfolio_transactions.create!(amount_cents: 100_00, transaction_type: :deposit)

    stock = create(:stock, price_cents: 10_00)
    order = build(:order, action: :buy, user: user, stock: stock, shares: 5)

    assert order.valid?(:create)
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

    # NOTE: PortfolioTransaction updates are handled by ExecuteOrder service
    order.update!(shares: 6)
    assert_equal 6, order.shares
  end

  test "update order does not allow user to update pending buy order when transaction amount exceeds portfolio value" do
    user = create(:student)
    portfolio = create(:portfolio, user: user)
    portfolio.portfolio_transactions.create!(amount_cents: 10_00, transaction_type: :deposit)

    stock = create(:stock, price_cents: 1_00)
    order = build(:order, :pending, action: :buy, user: user, stock: stock, shares: 5)

    assert_no_changes "PortfolioTransaction.count" do
      order.save!
    end

    order.shares = 10

    assert_not order.valid?(:update)
    assert_includes order.errors[:shares], "Insufficient funds. You have $10.00 but need $11.00"
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

  test ".for_student" do
    stock = create(:stock, price_cents: 1_000)
    classroom = create(:classroom, :with_trading)
    student1, order1 = create_student_and_order(stock, classroom)
    _student2, _order2 = create_student_and_order(stock, classroom)

    result = Order.for_student(student1)

    assert_equal [order1], result
  end

  test ".for_teacher" do
    stock = create(:stock, price_cents: 1_000)
    classroom1, order1 = create_classroom_and_student_order(stock)
    _classroom2, _order2 = create_classroom_and_student_order(stock)
    classroom3, order3 = create_classroom_and_student_order(stock)
    teacher = create(:teacher, classrooms: [classroom1, classroom3])

    result = Order.for_teacher(teacher)

    assert_equal [order1.id, order3.id], result.pluck(:id).sort
  end

  test ".for_teacher with no classrooms" do
    teacher = create(:teacher)
    stock = create(:stock, price_cents: 1_000)
    _classroom, _order = create_classroom_and_student_order(stock)

    result = Order.for_teacher(teacher)

    assert_empty result
  end

  private

  def create_classroom_and_student_order(stock)
    classroom = create(:classroom, :with_trading)
    _student, order = create_student_and_order(stock, classroom)

    [classroom, order]
  end

  def create_student_and_order(stock, classroom)
    student = create(:student, classroom:)
    portfolio = create(:portfolio, user: student)
    create(:portfolio_transaction, :deposit, portfolio:, amount_cents: 10_000)
    order = create(:order, :buy, user: student, stock:)

    [student, order]
  end
end
