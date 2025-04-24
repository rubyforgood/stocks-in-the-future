require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @order = orders(:one)
  end

  test "should get index" do
    get orders_url
    assert_response :success
  end

  test "should get new" do
    get new_order_url
    assert_response :success
  end

  test "should show order" do
    get order_url(@order)
    assert_response :success
  end

  test "should get edit" do
    get edit_order_url(@order)
    assert_response :success
  end

  test "should update order" do
    patch(
      order_url(@order),
      params: {
        order: {
          shares: @order.shares,
          status: @order.status,
          stock_id: @order.stock_id,
          user_id: @order.user_id
        }
      }
    )

    assert_redirected_to order_url(@order)
  end

  test "should destroy order" do
    assert_difference("Order.count", -1) do
      delete order_url(@order)
    end

    assert_redirected_to orders_url
  end

  test "" do
    sign_in Student.first

    stock_id = Stock.first.id
    num_shares = 5

    assert_difference("Order.count") do
      post orders_url, params: {order: {shares: num_shares, stock_id:}}
    end

    assert_equal(num_shares, Order.last.shares)
    assert_redirected_to order_url(Order.last)
  end
end
