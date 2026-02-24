# frozen_string_literal: true

require "application_system_test_case"

class UserManagesOrdersTest < ApplicationSystemTestCase
  test "creating a new order" do
    student = create(:student)
    student.reload
    portfolio = student.portfolio
    create(:portfolio_transaction, :deposit, portfolio: portfolio, amount_cents: 100_000)
    stock = create(:stock)
    shares_to_buy = 1

    sign_in(student)

    visit stocks_path

    assert_text "Trading Floor"
    assert_text stock.ticker

    within "tr", text: stock.company_name do
      click_on "Buy"
    end

    fill_in "Number of shares", with: shares_to_buy

    assert_difference("Order.buy.pending.count", +1) do
      click_button "Buy Shares"

      assert_text "Order was successfully created"
    end

    order = Order.buy.pending.find_by(user: student, stock: stock)
    assert_equal shares_to_buy, order.shares
    assert_equal stock.id, order.stock_id

    sign_out(student)
  end

  test "updating an order" do
    student = create(:student)
    student.reload
    portfolio = student.portfolio
    create(:portfolio_transaction, :deposit, portfolio: portfolio, amount_cents: 100_000)
    initial_shares = 4
    updated_shares = 2
    order = create(:order, :pending, action: :buy, user: student, shares: initial_shares)

    assert_not_equal initial_shares, updated_shares, "test requires shares to change"

    sign_in(student)

    visit orders_path

    within "tr", text: order.stock.ticker do
      find("[data-testid='edit-order-button']").click
    end

    fill_in "Number of shares", with: updated_shares

    assert_no_difference("Order.buy.pending.count") do
      click_button "Buy Shares"

      assert_text "Order was successfully updated"
    end

    order.reload
    assert_equal updated_shares, order.shares

    sign_out(student)
  end

  test "canceling an order" do
    student = create(:student)
    student.reload
    portfolio = student.portfolio
    create(:portfolio_transaction, :deposit, portfolio: portfolio, amount_cents: 50_000)
    order = create(:order, :pending, action: :buy, user: student)

    sign_in(student)

    visit orders_path

    assert_difference -> { Order.pending.count } => -1, -> { Order.canceled.count } => +1 do
      accept_confirm do
        within "tr", text: order.stock.company_name do
          find("[data-testid='cancel-order-button']").click
        end
      end

      assert_text "Order was successfully canceled"
    end

    order.reload
    assert order.canceled?
    within "tr", text: order.stock.company_name do
      assert_text "Canceled"
    end

    sign_out(student)
  end
end
