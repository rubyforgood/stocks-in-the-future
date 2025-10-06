# frozen_string_literal: true

require "test_helper"

class OrdersHelperTest < ActionView::TestCase
  test "buy_button renders link with correct path and attributes" do
    stock_id = 1
    result = buy_button(stock_id)
    expected_path = CGI.escapeHTML(new_order_path(stock_id: stock_id, transaction_type: :buy))

    assert_includes result, expected_path
    assert_match(/data-turbo-frame="modal_frame"/, result)
  end

  test "buy_button accepts additional class option" do
    stock_id = 1
    result = buy_button(stock_id, class: "extra-class")

    assert_match(/class="tw-btn-buy extra-class"/, result)
  end

  test "sell_button renders link with correct path and attributes" do
    stock_id = 1
    result = sell_button(stock_id)
    expected_path = CGI.escapeHTML(new_order_path(stock_id: stock_id, transaction_type: :sell))

    assert_includes result, expected_path
    assert_match(/data-turbo-frame="modal_frame"/, result)
  end

  test "sell_button accepts additional class option" do
    stock_id = 1
    result = sell_button(stock_id, class: "extra-class")

    assert_match(/class="tw-btn-sell extra-class"/, result)
  end

  test "buy_button with disabled option renders disabled button" do
    stock_id = 1
    result = buy_button(stock_id, disabled: true)

    assert_match(/<button/, result)
    assert_match(/disabled="disabled"/, result)
    assert_match(/class="tw-btn-buy disabled:opacity-50 disabled:pointer-events-none"/, result)
    assert_no_match(/href=/, result)
  end

  test "sell_button with disabled option renders disabled button" do
    stock_id = 1
    result = sell_button(stock_id, disabled: true)

    assert_match(/<button/, result)
    assert_match(/disabled="disabled"/, result)
    assert_match(/class="tw-btn-sell disabled:opacity-50 disabled:pointer-events-none"/, result)
    assert_no_match(/href=/, result)
  end
end
