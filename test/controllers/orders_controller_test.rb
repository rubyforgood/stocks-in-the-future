require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  test "index" do
    get orders_path

    assert_response :success
  end

  test "new" do
    get new_order_path

    assert_response :success
  end

  test "create" do
    user = create(:user)
    stock = create(:stock)
    params = {order: {user_id: user.id, stock_id: stock.id}}
    sign_in(user)

    assert_difference("Order.count") do
      post(orders_path, params:)
    end

    assert_redirected_to order_path(Order.last)
  end

  # TODO: Add test for create with invalid params

  test "show" do
    order = create(:order)

    get order_path(order)

    assert_response :success
  end

  test "edit" do
    order = create(:order)

    get edit_order_path(order)

    assert_response :success
  end

  test "update" do
    params = {order: {status: "completed"}}
    order = create(:order, :pending)

    assert_changes "order.reload.updated_at" do
      patch(order_path(order), params:)
    end

    assert_redirected_to order_path(order)
    assert order.completed?
  end

  # TODO: Add test for update with invalid params

  test "destroy" do
    order = create(:order)

    assert_difference("Order.count", -1) do
      delete order_path(order)
    end

    assert_redirected_to orders_path
  end
end
