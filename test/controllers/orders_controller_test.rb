# frozen_string_literal: true

require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  test "index" do
    user = create(:teacher)
    sign_in(user)

    get orders_path

    assert_response :success
  end

  test "index as guest" do
    get orders_path

    assert_redirected_to new_user_session_path
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

    assert_difference("Order.count", 1) do
      post(orders_path, params:)
    end

    assert_redirected_to orders_path
  end

  test "create with invalid shares handles validation errors" do
    student = create(:student)
    student.portfolio.portfolio_transactions.create!(amount_cents: 10_000, transaction_type: :deposit)
    stock = create(:stock, price_cents: 1_000)
    sign_in(student)

    [nil, "", "not_a_number"].each do |invalid_shares|
      buy_params = { order: { stock_id: stock.id, shares: invalid_shares, action: :buy } }
      sell_params = { order: { stock_id: stock.id, shares: invalid_shares, action: :sell } }

      assert_no_difference("Order.count") do
        assert_nothing_raised do
          post(orders_path, params: buy_params)
          assert_response :unprocessable_content

          post(orders_path, params: sell_params)
          assert_response :unprocessable_content
        end
      end
    end
  end

  # **One summary, one message per field.** The order form hand-rolled its own error panel - "Please fix the
  # following errors:" over a bulleted list - which is the third shape `shared/_form_errors` was written to
  # remove. It survived the sweep that replaced the other two because that sweep went through the forms
  # already on `Ui::FormBuilder`, and this one was not on it.
  #
  # The pair matters together: the builder's wrapper deliberately renders no message, because
  # `field_error_proc` renders one for every text-like control. Adding a second put two under every invalid
  # admin field once, so this asserts exactly one of each.
  test "an invalid order renders the shared summary and one message per field" do
    student = create(:student)
    student.portfolio.portfolio_transactions.create!(amount_cents: 10_000, transaction_type: :deposit)
    stock = create(:stock, price_cents: 1_000)
    sign_in(student)

    post orders_path, params: { order: { stock_id: stock.id, shares: "", action: :buy } }

    assert_response :unprocessable_content
    assert_select "[data-testid='form-errors']", count: 1
    # The summary's heading counts the errors - "1 error prohibited ..." - which is what GOV.UK, Polaris and
    # Primer put there and what "Please fix the following errors:" did not say.
    assert_select "[data-testid='form-errors'] p", text: /error/i
    assert_select "p", text: /Please fix the following errors/, count: 0
    # And exactly one message under the field itself, from `field_error_proc`, which gives it an id derived
    # from the attribute. The builder's wrapper adds none on purpose - two messages under one field is a
    # failure this pairing has produced before. Asserted on the message, not on `.field_with_errors`: Rails
    # wraps the label and the input separately, so two of those is one invalid field.
    assert_select "p#order_shares_error", count: 1
  end

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

  test "update with invalid shares handles validation errors" do
    user = create(:student)
    stock = create(:stock, price_cents: 1_000)
    create(:portfolio_stock, portfolio: user.portfolio, stock: stock, shares: 10)
    order = create(:order, :pending, action: :sell, user: user, stock: stock, shares: 5)
    sign_in(user)

    [nil, "", "not_a_number", -1, 0].each do |invalid_shares|
      params = { order: { shares: invalid_shares } }

      assert_no_changes "order.reload.shares" do
        assert_nothing_raised do
          patch(order_path(order), params: params)
          assert_response :unprocessable_content
        end
      end
    end
  end

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
    assert_routing(
      { path: "orders/1/cancel", method: "patch" },
      { controller: "orders", action: "cancel", id: "1" }
    )
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
