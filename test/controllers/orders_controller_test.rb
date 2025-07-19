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
    stock = create(:stock)
    params = { order: { user_id: student.id, stock_id: stock.id, shares: 1 } }
    sign_in(student)

    assert_difference("Order.count") do
      post(orders_path, params:)
    end

    assert_redirected_to order_path(Order.last)
  end

  # TODO: Add test for create with invalid params

  test "show" do
    order = create(:order)
    sign_in(order.user)

    get order_path(order)

    assert_response :success
  end

  test "edit" do
    order = create(:order)
    sign_in(order.user)

    get edit_order_path(order)

    assert_response :success
  end

  test "update" do
    user = create(:student)
    params = { order: { shares: 3 } }
    order = create(:order, :pending, user:)
    sign_in(user)

    assert_changes "order.reload.updated_at" do
      patch(order_path(order), params:)
    end

    assert_redirected_to order_path(order)
    assert order.shares, 3
  end

  # TODO: Add test for update with invalid params

  test "destroy" do
    order = create(:order)
    sign_in(order.user)

    assert_difference("Order.count", -1) do
      delete order_path(order)
    end

    assert_redirected_to orders_path
  end
end
