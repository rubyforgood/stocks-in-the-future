# frozen_string_literal: true

require "test_helper"

# Money is stored in integer cents everywhere, which is correct. The problem was
# the round trip: Portfolio#cash_balance divided cents by 100.0 to return a
# Float, and Order#sufficient_funds_for_buy multiplied that Float back by 100 to
# get cents again. Binary floating point cannot represent most two-decimal
# values exactly, so the recovered figure can land just below the true one.
#
# 131,252 of the first two million cent values round-trip low. When one of them
# is the student's exact balance, they are told they cannot afford something they
# can afford to the penny.
class MoneyPrecisionTest < ActiveSupport::TestCase
  # $15.06 a share plus the $1.00 fee is $16.06, and 1606 cents is one of the
  # values that round-trips low.
  PRICE_CENTS = 1506
  FEE_CENTS = PortfolioTransaction::TRANSACTION_FEE_CENTS

  setup do
    @student = create(:student)
    @portfolio = @student.portfolio
    @stock = create(:stock, price_cents: PRICE_CENTS)
  end

  def fund!(cents)
    create(:portfolio_transaction, :deposit, portfolio: @portfolio, amount_cents: cents)
  end

  test "the float round trip loses value for the amounts involved" do
    total_cents = PRICE_CENTS + FEE_CENTS

    assert_operator (total_cents / 100.0) * 100, :<, total_cents,
                    "this test is pointless unless the round trip actually loses value"
  end

  test "a student with exactly enough money can place the order" do
    total_cents = PRICE_CENTS + FEE_CENTS
    fund!(total_cents)

    order = Order.new(user: @student, stock: @stock, shares: 1, action: :buy, status: :pending)

    assert order.valid?,
           "expected an affordable order to be valid, got: #{order.errors.full_messages.join(', ')}"
    assert_empty order.errors[:shares]
  end

  test "a student one cent short still cannot place the order" do
    total_cents = PRICE_CENTS + FEE_CENTS
    fund!(total_cents - 1)

    order = Order.new(user: @student, stock: @stock, shares: 1, action: :buy, status: :pending)

    assert_not order.valid?, "expected an unaffordable order to be rejected"
    assert_match(/Insufficient funds/, order.errors.full_messages.join(", "))
  end

  test "cash balance in cents is an integer, not a float" do
    fund!(1606)

    assert_kind_of Integer, @portfolio.cash_balance_cents,
                   "balances used for arithmetic must stay in integer cents"
    assert_equal 1606, @portfolio.cash_balance_cents
  end

  test "cash balance in cents matches the float accessor used for display" do
    fund!(1606)

    assert_in_delta @portfolio.cash_balance_cents / 100.0, @portfolio.cash_balance, 0.0001
  end
end
