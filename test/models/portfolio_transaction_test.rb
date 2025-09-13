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

  test "#completed? is always true if no order is associated" do
    transaction = build(:portfolio_transaction)
    assert_nil transaction.order
    assert transaction.completed?
  end

  test "#completed? is false if associated order is not complete" do
    transaction = build(:portfolio_transaction)
    order = build(:order, :pending, portfolio_transaction: transaction)

    assert_not order.completed?
    assert_not transaction.completed?
  end

  test "#completed? is true if associated order is complete" do
    transaction = build(:portfolio_transaction)
    order = build(:order, :completed, portfolio_transaction: transaction)

    assert order.completed?
    assert transaction.completed?
  end

  test "#canceled? is always false if no order is associated" do
    transaction = build(:portfolio_transaction)
    assert_nil transaction.order
    assert_not transaction.canceled?
  end

  test "#canceled? is false if associated order is not canceled" do
    transaction = build(:portfolio_transaction)
    order = build(:order, :pending, portfolio_transaction: transaction)

    assert_not order.canceled?
    assert_not transaction.canceled?
  end

  test "#canceled? is true if associated order is canceled" do
    transaction = build(:portfolio_transaction)
    order = build(:order, :canceled, portfolio_transaction: transaction)

    assert order.canceled?
    assert transaction.canceled?
  end
end
