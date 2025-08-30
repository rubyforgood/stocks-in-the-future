# frozen_string_literal: true

require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  test "index" do
    user = create(:teacher)
    sign_in(user)

    get orders_path

    assert_response :success
  end

  test "new" do
    user = create(:student)
    stock = create(:stock)
    sign_in(user)

    get new_order_path(stock_id: stock.id, transaction_type: "buy")

    assert_response :success
  end

  test "create" do
    student = create(:student)
    student.portfolio.portfolio_transactions.create!(amount_cents: 10_000, transaction_type: :deposit) # $100
    stock = create(:stock, price_cents: 1_000) # $10 per share
    params = { order: { user_id: student.id, stock_id: stock.id, shares: 1, action: "buy" } }
    sign_in(student)

    assert_difference("Order.count") do
      post(orders_path, params:)
    end

    assert_redirected_to orders_path
  end

  # TODO: Add test for create with invalid params

  test "edit" do
    user = create(:student)
    stock = create(:stock)
    create(:portfolio_stock, portfolio: user.portfolio, stock: stock, shares: 10)
    order = create(:order, action: :sell, user: user, stock: stock, shares: 1)
    sign_in(order.user)

    get edit_order_path(order)

    assert_response :success
  end

  test "update" do
    user = create(:student)
    stock = create(:stock)
    create(:portfolio_stock, portfolio: user.portfolio, stock: stock, shares: 10)
    params = { order: { shares: 3 } }
    order = create(:order, :pending, action: :sell, user: user, stock: stock, shares: 1)
    sign_in(user)

    assert_changes "order.reload.updated_at" do
      patch(order_path(order), params:)
    end

    assert_redirected_to orders_path
    assert order.shares, 3
  end

  # TODO: Add test for update with invalid params

  test "cancel" do
    user = create(:student)
    stock = create(:stock)
    create(:portfolio_stock, portfolio: user.portfolio, stock: stock, shares: 10)
    order = create(:order, :pending, action: :sell, user: user, stock: stock, shares: 1)
    sign_in(order.user)

    assert_difference("Order.pending.count", -1) do
      assert_difference("Order.canceled.count", 1) do
        patch(cancel_order_path(order))
      end
    end

    assert_redirected_to orders_path
    assert_equal "Order was successfully canceled", flash[:notice]
  end

  test "cancel route exists" do
    assert_routing({ path: "orders/1/cancel", method: "patch" },
                   { controller: "orders", action: "cancel", id: "1" })
  end

  test "cancel with unauthorized user" do
    user = create(:student)
    stock = create(:stock)
    create(:portfolio_stock, portfolio: user.portfolio, stock: stock, shares: 10)
    order = create(:order, :pending, action: :sell, user: user, stock: stock, shares: 1)
    unauthorized_user = create(:student)

    sign_in(unauthorized_user)

    assert_no_difference("Order.count") do
      patch(cancel_order_path(order))
    end

    assert_response :redirect
    assert_equal "You do not have access to this page.", flash[:alert]
  end

  test "cancel with non-pending order" do
    user = create(:student)
    stock = create(:stock)
    create(:portfolio_stock, portfolio: user.portfolio, stock: stock, shares: 10)
    order = create(:order, :completed, action: :sell, user: user, stock: stock, shares: 1)
    sign_in(order.user)

    assert_no_difference("Order.count") do
      patch(cancel_order_path(order))
    end

    assert_response :redirect
    assert_equal "Only pending orders can be canceled", flash[:alert]
  end
end
