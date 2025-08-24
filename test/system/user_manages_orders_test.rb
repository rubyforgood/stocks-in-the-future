# frozen_string_literal: true

require "application_system_test_case"

class UserManagesOrdersTest < ApplicationSystemTestCase
  # TODO: Add test for creating a new order
  # TODO: Add test for updating an order

  test "canceling an order" do
    teacher = create(:teacher)
    sign_in(teacher)
    order = create(:order, :pending)

    visit orders_path

    within "#order_#{order.id}" do
      click_on "Cancel"
    end

    accept_confirm do
      click_on "Confirm Cancel"
    end

    assert_text "Order was successfully canceled"
    assert_no_selector "#order_#{order.id}"
  end

  test "canceling an order with modal" do
    teacher = create(:teacher)
    sign_in(teacher)
    order = create(:order, :pending)

    visit orders_path

    within "#order_#{order.id}" do
      click_on "Cancel"
    end

    assert_text "Are you sure you want to cancel this order?"
    click_on "Confirm Cancel"

    assert_text "Order was successfully canceled"
    assert_no_selector "#order_#{order.id}"
  end
end
